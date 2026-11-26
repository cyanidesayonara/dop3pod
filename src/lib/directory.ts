// Shows from the directory: the published details, plus the feed itself when the publisher lets browsers read it.
import { parseFeed } from '../../tools/catalog/rss.ts';
import type { DirectoryDetail, DirectoryIndex, Episode, Show } from '../../tools/catalog/types.ts';

const SHARDS = 256;
const MAX_FEED = 15_000_000;

async function json<T>(file: string): Promise<T> {
  const r = await fetch(`./data/directory/${file}`);
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  return r.json();
}

let index: Promise<DirectoryIndex> | undefined;
export const loadDirectory = () => (index ??= json<DirectoryIndex>('index.json').catch((e) => { index = undefined; throw e; }));

const shards = new Map<number, Promise<Record<string, DirectoryDetail>>>();
function shard(n: number) {
  let p = shards.get(n);
  if (!p) {
    p = json<Record<string, DirectoryDetail>>(`${n}.json`).catch((e) => { shards.delete(n); throw e; });
    shards.set(n, p);
  }
  return p;
}

async function hash(s: string) {
  const d = new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(s)));
  return [...d.slice(0, 6)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

/** The feed as text, or null when the publisher doesn't allow it (or it is too big, or not https). */
async function readFeed(url: string): Promise<string | null> {
  try {
    const r = await fetch(url, { credentials: 'omit', referrerPolicy: 'no-referrer', signal: AbortSignal.timeout(20_000) });
    if (!r.ok || !r.url.startsWith('https:') || Number(r.headers.get('content-length')) > MAX_FEED || !r.body) return null;
    const reader = r.body.getReader();
    const parts: Uint8Array[] = [];
    let n = 0;
    for (;;) {
      const { done, value } = await reader.read();
      if (done) break;
      n += value.length;
      if (n > MAX_FEED) { void reader.cancel(); return null; }
      parts.push(value);
    }
    const all = new Uint8Array(n);
    let at = 0;
    for (const p of parts) { all.set(p, at); at += p.length; }
    const declared = /encoding=["']([\w-]+)["']/i.exec(new TextDecoder('latin1').decode(all.subarray(0, 200)))?.[1] ?? 'utf-8';
    try { return new TextDecoder(declared).decode(all); } catch { return new TextDecoder().decode(all); }
  } catch {
    return null; // blocked by the publisher's settings (CORS), offline or timed out
  }
}

export async function loadDirectoryShow(id: string): Promise<Show> {
  const pid = Number(id.slice(2));
  const d = (await shard(pid % SHARDS))[pid];
  if (!d) throw new Error('unknown show');
  const show: Show = {
    id, category: d.category, language: d.language, title: d.title, author: d.author, description: d.description, link: d.link,
    image: d.image, cover: '', coverOf: '', updated: '', stale: false, etag: '', modified: '', episodes: [], limited: true, explicit: d.explicit,
  };
  const text = await readFeed(d.feed);
  const feed = text ? parseFeed(text) : null;
  if (feed?.episodes.length) {
    const seen = new Set<string>();
    const episodes: Episode[] = [];
    for (const { guid, ...e } of feed.episodes.slice(0, 200)) {
      const eid = 'd' + (await hash(`${pid}|${guid}`));
      if (seen.has(eid)) continue;
      seen.add(eid);
      episodes.push({ id: eid, ...e });
    }
    return { ...show, episodes, limited: false, description: feed.description || show.description, image: show.image || feed.image };
  }
  if (d.newest)
    show.episodes = [{ id: 'd' + (await hash(`${pid}|${d.newest.audio}`)), title: `Latest episode of ${d.title}`, date: d.newest.date,
      duration: d.newest.duration, summary: '', audio: d.newest.audio, bytes: null }];
  return show;
}
