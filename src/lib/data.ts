import type { Episode, Show } from '../../tools/catalog/types.ts';
export type { Episode, Show };
export type ShowCard = Pick<Show, 'id' | 'category' | 'title' | 'author' | 'description' | 'image' | 'cover' | 'stale'> & { latest: string | null };
export type Catalog = { generated: string; shows: ShowCard[] };

async function load<T>(file: string): Promise<T> {
  const r = await fetch(`./data/${file}`);
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  return r.json();
}

let catalog: Promise<Catalog> | undefined;
export const loadCatalog = () => (catalog ??= load<Catalog>('catalog.json').catch((e) => { catalog = undefined; throw e; }));

const shows = new Map<string, Promise<Show>>();
export function loadShow(id: string): Promise<Show> {
  if (!/^[a-z0-9-]{1,80}$/.test(id)) return Promise.reject(new Error('unknown show'));
  let p = shows.get(id);
  if (!p) {
    p = load<Show>(`shows/${id}.json`).catch((e) => { shows.delete(id); throw e; });
    shows.set(id, p);
  }
  return p;
}

/** The small copy made by the build, or the publisher's original if that failed. */
export const artwork = (s: Pick<Show, 'image' | 'cover'>) => (s.cover ? `./data/${s.cover}` : s.image);

export function clock(s: number): string {
  const n = Math.max(0, Math.floor(Number.isFinite(s) ? s : 0));
  const h = Math.floor(n / 3600), m = Math.floor((n % 3600) / 60);
  return `${h ? `${h}:${String(m).padStart(2, '0')}` : m}:${String(n % 60).padStart(2, '0')}`;
}
export const minutes = (s: number | null) =>
  !s ? '' : s < 3600 ? `${Math.max(1, Math.round(s / 60))} min` : `${Math.floor(s / 3600)} h ${Math.floor((s % 3600) / 60)} min`;
const df = new Intl.DateTimeFormat('en', { year: 'numeric', month: 'short', day: 'numeric' });
export const day = (iso: string | null) => (iso ? df.format(new Date(iso)) : '');
