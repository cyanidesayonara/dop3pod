// Trending charts from Podcast Index, one list overall plus one per category and language.
//   PODCASTINDEX_KEY=... PODCASTINDEX_SECRET=... node tools/catalog/charts.ts [--out public/data] [--prev <folder or https URL>]
// Without the two secrets, or if the API fails, it keeps the previously published charts.
import { createHash } from 'node:crypto';
import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { parseArgs } from 'node:util';
import { pathToFileURL } from 'node:url';
import type { Fetcher } from './build.ts';
import { httpsUrl, plain } from './rss.ts';
import type { Charts, ChartItem, DirectoryDetail, DirectoryIndex, ShowSource } from './types.ts';

const API = 'https://api.podcastindex.org/api/1.0/podcasts/trending';
const UA = 'dopepod-catalog/1.0 (+https://github.com/cyanidesayonara/dop3pod)';
const SIZE = 50;
// Trending favors new, fast-growing shows, so the site calls these lists "New and rising". A little extra room for repeats.
const ASK = 100;

/** Lists to fetch: Podcast Index category names and language codes. */
export const LISTS: { id: string; label: string; cat?: string; lang?: string }[] = [
  { id: 'all', label: 'All podcasts' },
  ...['Technology', 'Science', 'Society', 'News', 'History', 'Comedy', 'Fiction', 'True Crime', 'Music', 'Arts', 'Sports', 'Business',
    'Education', 'Health', 'Kids'].map((c) => ({ id: `c-${c.toLowerCase().replace(/ /g, '-')}`, label: c, cat: c })),
  ...[['en', 'English'], ['es', 'Español'], ['ca', 'Català'], ['fi', 'Suomi'], ['de', 'Deutsch'], ['fr', 'Français'], ['pt', 'Português'],
    ['it', 'Italiano'], ['sv', 'Svenska']].map(([l, label]) => ({ id: `l-${l}`, label, lang: l })),
];

type Trending = { id: number; url: string; title: string; author: string; description: string; image: string; artwork: string;
  language: string; categories: Record<string, string> | null; trendScore: number };

export function authHeaders(key: string, secret: string, now = Math.floor(Date.now() / 1000)) {
  const date = String(now);
  return {
    'User-Agent': UA, 'X-Auth-Key': key, 'X-Auth-Date': date,
    Authorization: createHash('sha1').update(key + secret + date).digest('hex'),
  };
}

export async function fetchList(list: (typeof LISTS)[number], key: string, secret: string, get: Fetcher = fetch): Promise<Trending[]> {
  const u = new URL(API);
  u.searchParams.set('max', String(ASK));
  if (list.cat) u.searchParams.set('cat', list.cat);
  if (list.lang) u.searchParams.set('lang', list.lang);
  const r = await get(u.href, { headers: authHeaders(key, secret), signal: AbortSignal.timeout(30_000) });
  if (!r.ok) throw new Error(`${list.id}: HTTP ${r.status}`);
  const body = (await r.json()) as { status?: string | boolean; feeds?: Trending[] };
  if (!Array.isArray(body.feeds)) throw new Error(`${list.id}: no feeds in the answer`);
  return [...body.feeds].sort((a, b) => (b.trendScore ?? 0) - (a.trendScore ?? 0));
}

/** Turns API answers into the published charts: top 50, no repeats. Featured and directory shows link to their pages; the rest get a small detail. */
export function buildCharts(
  answers: Map<string, Trending[]>, featured: Map<string, string>, directory: Set<number>, generated: string,
): Charts {
  const charts: Charts = { generated, lists: [], extras: {} };
  for (const list of LISTS) {
    const feeds = answers.get(list.id);
    if (!feeds?.length) continue;
    const items: ChartItem[] = [];
    const titles = new Set<string>();
    for (const f of feeds) {
      if (items.length === SIZE) break;
      const feed = httpsUrl(f.url);
      const title = plain(f.title ?? '', 200);
      if (!feed || !title || !Number.isInteger(f.id)) continue;
      const key = title.toLowerCase();
      if (titles.has(key)) continue;
      titles.add(key);
      const image = httpsUrl(f.artwork) || httpsUrl(f.image);
      const show = featured.get(feed) ?? `d-${f.id}`;
      const language = (/^[a-z]{2}/i.exec(f.language ?? '')?.[0] ?? '').toLowerCase();
      items.push({ show, title, author: plain(f.author ?? '', 120), image, language });
      if (!featured.has(feed) && !directory.has(f.id))
        charts.extras[f.id] ??= {
          title, author: plain(f.author ?? '', 120), image, language, category: Object.values(f.categories ?? {})[0] ?? 'Other', explicit: false,
          feed, link: '', description: plain(f.description ?? '', 600), episodes: 0, newest: null,
        } satisfies DirectoryDetail;
    }
    if (items.length) charts.lists.push({ id: list.id, label: list.label, items });
  }
  return charts;
}

async function readPrev(base: string | undefined) {
  if (!base) return null;
  try {
    const raw = /^https:/.test(base)
      ? await fetch(`${base.replace(/\/$/, '')}/charts.json`, { signal: AbortSignal.timeout(20_000) }).then((r) => (r.ok ? r.text() : Promise.reject()))
      : await readFile(path.join(base, 'charts.json'), 'utf8');
    return raw;
  } catch {
    return null;
  }
}

async function main() {
  const { values } = parseArgs({ options: { out: { type: 'string', default: 'public/data' }, prev: { type: 'string' } } });
  const out = path.resolve(values.out!);
  const key = process.env.PODCASTINDEX_KEY ?? '';
  const secret = process.env.PODCASTINDEX_SECRET ?? '';
  const keep = async (why: string) => {
    const prev = await readPrev(values.prev);
    if (prev) await writeFile(path.join(out, 'charts.json'), prev);
    console.log(`charts: ${why}; ${prev ? 'kept the last published charts' : 'none published yet'}`);
  };
  if (!key || !secret) return keep('no API key');

  const answers = new Map<string, Trending[]>();
  const failed: string[] = [];
  for (const list of LISTS) {
    try { answers.set(list.id, await fetchList(list, key, secret)); } catch (e) { failed.push((e as Error).message); }
    await new Promise((r) => setTimeout(r, 400)); // gentle on a donation-funded service
  }
  if (!answers.get('all')?.length || failed.length > LISTS.length / 2) return keep(`API failed (${failed.slice(0, 3).join('; ')})`);

  const sources = JSON.parse(await readFile('catalog/shows.json', 'utf8')) as ShowSource[];
  const featured = new Map(sources.map((s) => [httpsUrl(s.feed), s.id]));
  let directory = new Set<number>();
  try {
    const d = JSON.parse(await readFile(path.join(out, 'directory', 'index.json'), 'utf8')) as DirectoryIndex;
    directory = new Set(d.shows.map((s) => s[0]));
  } catch { /* no directory yet: every chart show gets its own detail */ }
  const charts = buildCharts(answers, featured, directory, new Date().toISOString());
  await writeFile(path.join(out, 'charts.json'), JSON.stringify(charts));
  console.log(`charts: ${charts.lists.length} lists, ${charts.lists.map((l) => l.items.length).join('/')} shows${failed.length ? `; failed: ${failed.join('; ')}` : ''}`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) await main();
