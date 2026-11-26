// The searchable directory: popular, active shows from Podcast Index's public dump.
//   node tools/catalog/directory.ts --db podcastindex_feeds.db [--out public/data]   rebuild from the dump
//   node tools/catalog/directory.ts --prev <folder or https URL> [--out public/data]  keep the last published one
// Writes directory/index.json (what search needs) and directory/<n>.json (details, in 256 shards).
import { mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { parseArgs } from 'node:util';
import { pathToFileURL } from 'node:url';
import { httpsUrl, plain } from './rss.ts';
import type { DirectoryDetail, DirectoryIndex, ShowSource } from './types.ts';

const SHARDS_DEFAULT = 256;
export const SHARDS = SHARDS_DEFAULT;
const MIN_EPISODES = 10;
const ACTIVE_DAYS = 60;
const LANG_ALIAS: Record<string, string> = { in: 'id', iw: 'he', ji: 'yi' };

// Podcast Index categories to the site's. Anything else falls under "Other".
const CATEGORY: Record<string, string> = {
  technology: 'Technology', science: 'Science', society: 'Society', 'true crime': 'True Crime', news: 'News', government: 'News',
  history: 'History', comedy: 'Comedy', fiction: 'Fiction', music: 'Music', arts: 'Arts', games: 'Games', leisure: 'Leisure',
  sports: 'Sports', business: 'Business', education: 'Education', health: 'Health', religion: 'Religion', kids: 'Kids', tv: 'TV & Film',
};

export type DumpRow = {
  id: number; url: string; title: string; link: string; itunesAuthor: string; explicit: number; imageUrl: string; language: string;
  episodeCount: number; newestItemPubdate: number; newestEnclosureUrl: string; newestEnclosureDuration: number | null;
  description: string; category1: string;
};

/** Turns dump rows into the published index and its detail shards. Rows that can't be shown safely are dropped. */
export function buildDirectory(rows: DumpRow[], featured: Set<string>, generated: string) {
  const index: DirectoryIndex = { generated, categories: [], languages: [], shows: [] };
  const shards: Record<string, DirectoryDetail>[] = Array.from({ length: SHARDS }, () => ({}));
  const cats = new Map<string, number>();
  const langs = new Map<string, number>();
  const seen = new Set<string>();
  for (const r of rows) {
    const feed = httpsUrl(r.url);
    const title = plain(r.title, 200);
    const key = `${title.toLowerCase()}|${(r.itunesAuthor || '').toLowerCase()}`;
    if (!feed || !title || featured.has(feed) || seen.has(key)) continue;
    seen.add(key);
    const cat = CATEGORY[r.category1.toLowerCase()] ?? 'Other';
    const rawLang = (/^[a-z]{2}/i.exec(r.language)?.[0] ?? '').toLowerCase();
    const lang = LANG_ALIAS[rawLang] ?? rawLang;
    if (!cats.has(cat)) cats.set(cat, cats.size);
    if (!langs.has(lang)) langs.set(lang, langs.size);
    index.shows.push([r.id, title, plain(r.itunesAuthor, 120), langs.get(lang)!, cats.get(cat)!, httpsUrl(r.imageUrl), r.explicit ? 1 : 0, r.newestItemPubdate]);
    const audio = httpsUrl(r.newestEnclosureUrl);
    shards[r.id % SHARDS][r.id] = {
      title, author: plain(r.itunesAuthor, 120), image: httpsUrl(r.imageUrl), language: lang, category: cat, explicit: !!r.explicit,
      feed, link: httpsUrl(r.link), description: plain(r.description, 600), episodes: r.episodeCount,
      newest: audio ? { audio, date: new Date(r.newestItemPubdate * 1000).toISOString(), duration: r.newestEnclosureDuration || null } : null,
    };
  }
  index.categories = [...cats.keys()];
  index.languages = [...langs.keys()];
  return { index, shards };
}

async function fromDump(db: string, featured: Set<string>) {
  const { DatabaseSync } = await import('node:sqlite');
  const d = new DatabaseSync(db, { readOnly: true });
  const now = Number((d.prepare('select max(newestItemPubdate) as t from podcasts where newestItemPubdate < ?').get(Date.now() / 1000) as { t: number }).t);
  const rows = d.prepare(`
    select id, url, title, link, itunesAuthor, explicit, imageUrl, language, episodeCount, newestItemPubdate,
           newestEnclosureUrl, newestEnclosureDuration, description, category1
    from podcasts
    where dead = 0 and priority = 5 and popularityScore = 9 and episodeCount >= ? and newestItemPubdate > ?
      and (duplicateOf = '' or duplicateOf is null)
    order by episodeCount desc`).all(MIN_EPISODES, now - ACTIVE_DAYS * 86400) as DumpRow[];
  d.close();
  return buildDirectory(rows, featured, new Date(now * 1000).toISOString());
}

/** Fetches a URL, retrying timeouts and server errors (GitHub Pages answers 503 now and then). */
export async function fetchRetrying(url: string, tries = 4, wait = 2000, get: typeof fetch = fetch): Promise<string> {
  for (let attempt = 1; ; attempt++) {
    let why: string;
    try {
      const r = await get(url, { signal: AbortSignal.timeout(30_000) });
      if (r.ok) return await r.text();
      why = `HTTP ${r.status}`;
      if (r.status < 500 && r.status !== 429) throw new Error(why);
    } catch (e) {
      why = (e as Error).message;
      if (/^HTTP 4/.test(why) && !why.includes('429')) throw e;
    }
    if (attempt >= tries) throw new Error(`${url}: ${why}`);
    await new Promise((r) => setTimeout(r, wait * attempt));
  }
}

async function fromPrevious(base: string) {
  const get = async (f: string) =>
    /^https:/.test(base) ? fetchRetrying(`${base.replace(/\/$/, '')}/directory/${f}`) : readFile(path.join(base, 'directory', f), 'utf8');
  const index = JSON.parse(await get('index.json')) as DirectoryIndex;
  const shards: Record<string, DirectoryDetail>[] = [];
  for (let i = 0; i < SHARDS; i += 16)
    shards.push(...(await Promise.all(Array.from({ length: 16 }, async (_, k) => JSON.parse(await get(`${i + k}.json`))))));
  return { index, shards };
}

async function main() {
  const { values } = parseArgs({ options: { db: { type: 'string' }, prev: { type: 'string' }, out: { type: 'string', default: 'public/data' } } });
  const sources = JSON.parse(await readFile('catalog/shows.json', 'utf8')) as ShowSource[];
  const featured = new Set(sources.map((s) => httpsUrl(s.feed)));
  let built;
  if (values.db) built = await fromDump(values.db, featured);
  else if (values.prev) {
    try { built = await fromPrevious(values.prev); } catch (e) {
      // Fail loudly: the workflow then rebuilds from the dump instead of publishing a site without a directory.
      console.error(`Could not copy the previous directory: ${(e as Error).message}`);
      process.exit(2);
    }
  } else throw new Error('pass --db or --prev');
  const dir = path.join(path.resolve(values.out!), 'directory');
  await rm(dir, { recursive: true, force: true });
  await mkdir(dir, { recursive: true });
  await writeFile(path.join(dir, 'index.json'), JSON.stringify(built.index));
  await Promise.all(built.shards.map((s, i) => writeFile(path.join(dir, `${i}.json`), JSON.stringify(s))));
  console.log(`directory: ${built.index.shows.length} shows, ${built.index.languages.length} languages, from ${built.index.generated}`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) await main();
