// Reads every feed in catalog/shows.json and writes the site's data files.
//   node tools/catalog/build.ts [--out public/data] [--prev <folder or https URL of the last data>]
// A show that fails keeps its last good episodes. The build fails if more than 20% of the shows fail.
import { createHash } from 'node:crypto';
import { mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { parseArgs } from 'node:util';
import { pathToFileURL } from 'node:url';
import { coverFor } from './covers.ts';
import { parseFeed } from './rss.ts';
import type { Episode, Show, ShowSource } from './types.ts';

export type { Episode, Show, ShowSource };
export type Fetcher = (url: string, init: RequestInit) => Promise<Response>;

const UA = 'dopepod-catalog/1.0 (+https://github.com/cyanidesayonara/dop3pod)';
const MAX_BYTES = 40_000_000;
const MAX_EPISODES = 50;
const MAX_FAILED = 0.2;

export async function readCapped(res: Response, max = MAX_BYTES): Promise<string> {
  const chunks: Uint8Array[] = [];
  let n = 0;
  for await (const c of res.body ?? []) {
    n += c.length;
    if (n > max) throw new Error(`feed is larger than ${max} bytes`);
    chunks.push(c);
  }
  const buf = Buffer.concat(chunks);
  const declared = /encoding=["']([\w-]+)["']/i.exec(buf.subarray(0, 200).toString('latin1'))?.[1] ?? 'utf-8';
  try { return new TextDecoder(declared).decode(buf); } catch { return new TextDecoder().decode(buf); }
}

export async function loadShow(src: ShowSource, prev: Show | null, get: Fetcher = fetch): Promise<Show> {
  const headers: Record<string, string> = { 'User-Agent': UA, Accept: 'application/rss+xml, application/xml, text/xml, */*' };
  if (prev?.etag) headers['If-None-Match'] = prev.etag;
  if (prev?.modified) headers['If-Modified-Since'] = prev.modified;
  const res = await get(src.feed, { headers, redirect: 'follow', signal: AbortSignal.timeout(60_000) });
  if (res.status === 304 && prev) return { ...prev, category: src.category, title: src.title, stale: false };
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  if (res.url && !res.url.startsWith('https:')) throw new Error('feed was not served over https');
  const feed = parseFeed(await readCapped(res));
  if (!feed.episodes.length) throw new Error('no playable audio episodes');
  const seen = new Set<string>();
  const episodes: Episode[] = [];
  for (const { guid, ...e } of feed.episodes) {
    const id = createHash('sha256').update(guid).digest('hex').slice(0, 12);
    if (seen.has(id)) continue;
    seen.add(id);
    episodes.push({ id, ...e });
    if (episodes.length === MAX_EPISODES) break;
  }
  return {
    id: src.id, category: src.category, title: src.title, author: feed.author, description: feed.description,
    link: feed.link, image: feed.image, cover: '', coverOf: '', updated: new Date().toISOString(), stale: false,
    etag: res.headers.get('etag') ?? '', modified: res.headers.get('last-modified') ?? '', episodes,
  };
}

async function readPrevious(base: string | undefined, file: string): Promise<Buffer | null> {
  if (!base) return null;
  try {
    if (!/^https:/.test(base)) return await readFile(path.join(base, file));
    const r = await fetch(`${base.replace(/\/$/, '')}/${file}`, { signal: AbortSignal.timeout(20_000) });
    return r.ok ? Buffer.from(await r.arrayBuffer()) : null;
  } catch {
    return null;
  }
}

async function previous(base: string | undefined, id: string): Promise<Show | null> {
  try {
    const raw = await readPrevious(base, `shows/${id}.json`);
    if (!raw) return null;
    const s = JSON.parse(raw.toString('utf8')) as Show;
    return s.id === id && Array.isArray(s.episodes) && s.episodes.length ? s : null;
  } catch {
    return null;
  }
}

export async function buildCatalog(
  sources: ShowSource[], prevOf: (id: string) => Promise<Show | null>, get: Fetcher = fetch, log: (s: string) => void = console.log,
) {
  const shows: Show[] = new Array(sources.length);
  const failed: string[] = [];
  let next = 0;
  const worker = async () => {
    while (next < sources.length) {
      const i = next++;
      const src = sources[i];
      const prev = await prevOf(src.id);
      try {
        shows[i] = await loadShow(src, prev, get);
      } catch (e) {
        failed.push(src.id);
        log(`FAILED ${src.id}: ${(e as Error).message}${prev ? ' (kept the last good episodes)' : ' (left out)'}`);
        if (prev) shows[i] = { ...prev, category: src.category, title: src.title, stale: true };
      }
    }
  };
  await Promise.all(Array.from({ length: 6 }, worker));
  return { shows: shows.filter(Boolean), failed, tooMany: failed.length > sources.length * MAX_FAILED };
}

async function main() {
  const { values } = parseArgs({ options: { out: { type: 'string', default: 'public/data' }, prev: { type: 'string' } } });
  const out = path.resolve(values.out!);
  const sources = JSON.parse(await readFile('catalog/shows.json', 'utf8')) as ShowSource[];
  const boothIds = JSON.parse(await readFile('catalog/booth.json', 'utf8')) as string[];
  const before = new Map<string, Show | null>();
  const { shows, failed, tooMany } = await buildCatalog(sources, async (id) => {
    const p = await previous(values.prev, id);
    before.set(id, p);
    return p;
  });
  if (tooMany) throw new Error(`${failed.length} of ${sources.length} feeds failed; not publishing`);

  const covers = new Map<string, Buffer>();
  const queue = [...shows];
  await Promise.all(Array.from({ length: 6 }, async () => {
    for (let s = queue.shift(); s; s = queue.shift()) {
      const prev = before.get(s.id) ?? null;
      const bytes = await coverFor(s, { prev, read: () => readPrevious(values.prev, `covers/${s.id}.webp`) }, fetch, UA, console.log);
      s.cover = bytes ? `covers/${s.id}.webp` : '';
      s.coverOf = bytes ? s.image : '';
      if (bytes) covers.set(s.id, bytes);
    }
  }));

  // Everything was read before this point, so --prev may be the same folder as --out.
  await rm(path.join(out, 'covers'), { recursive: true, force: true });
  await mkdir(path.join(out, 'covers'), { recursive: true });
  await Promise.all([...covers].map(([id, b]) => writeFile(path.join(out, 'covers', `${id}.webp`), b)));
  await rm(path.join(out, 'shows'), { recursive: true, force: true });
  await mkdir(path.join(out, 'shows'), { recursive: true });
  const generated = new Date().toISOString();
  const put = (f: string, v: unknown) => writeFile(path.join(out, f), JSON.stringify(v));
  await Promise.all(shows.map((s) => put(`shows/${s.id}.json`, s)));
  await put('catalog.json', {
    generated,
    shows: shows.map(({ id, category, title, author, description, image, cover, stale, episodes }) => ({
      id, category, title, author, description: description.slice(0, 200), image, cover, stale, latest: episodes[0]?.date ?? null,
    })),
  });
  await put('booth.json', {
    generated,
    shows: boothIds.map((id) => shows.find((s) => s.id === id)).filter((s) => s !== undefined).map((s) => ({
      id: s.id, title: s.title, author: s.author, link: s.link,
      episodes: s.episodes.slice(0, 3).map(({ id, title, duration, audio }) => ({ id, title, duration, audio })),
    })),
  });
  console.log(`${shows.length} shows and ${covers.size} covers written, ${failed.length} failed`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) await main();
