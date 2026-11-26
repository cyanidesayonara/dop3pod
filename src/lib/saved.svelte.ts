import { httpsUrl } from '../../tools/catalog/rss.ts';

// Everything the app remembers, in this browser only. Storage can be blocked or full, so nothing depends on it.
export type Progress = { t: number; d: number; at: number; show: string; title: string; done: boolean };
export type Queued = { id: string; show: string; title: string; showTitle: string };
export type FavoriteShow = { title: string; author: string; image: string; language: string; category: string };
export type BrowseView = 'grid' | 'list';
export type Theme = 'auto' | 'light' | 'dark';
type Saved = {
  favorites: string[];
  favoriteShows: Record<string, FavoriteShow>;
  queue: Queued[];
  progress: Record<string, Progress>;
  rate: number;
  volume: number;
  theme: Theme;
  view: BrowseView;
};

const KEY = 'dopepod';
const initial: Saved = { favorites: [], favoriteShows: {}, queue: [], progress: {}, rate: 1, volume: 1, theme: 'auto', view: 'grid' };

function normalizeMeta(show: FavoriteShow): FavoriteShow {
  return {
    title: show.title.trim().slice(0, 200),
    author: show.author.slice(0, 120),
    image: httpsUrl(show.image),
    language: show.language.slice(0, 12),
    category: show.category.slice(0, 40),
  };
}

function read(): Saved {
  try {
    const v = JSON.parse(localStorage.getItem(KEY) ?? '{}');
    const num = (x: unknown, lo: number, hi: number, d: number) => (typeof x === 'number' && x >= lo && x <= hi ? x : d);
    const rawFavorites = Array.isArray(v.favorites)
      ? v.favorites
        .filter((x: unknown): x is string => typeof x === 'string' && /^[a-z0-9-]{1,80}$/.test(x))
        .filter((x: string, i: number, a: string[]) => a.indexOf(x) === i)
      : [];
    const favSet = new Set(rawFavorites);
    const favoriteShows: Record<string, FavoriteShow> = {};
    if (v.favoriteShows && typeof v.favoriteShows === 'object' && !Array.isArray(v.favoriteShows)) {
      for (const [k, raw] of Object.entries(v.favoriteShows as Record<string, unknown>)) {
        if (!favSet.has(k) || !raw || typeof raw !== 'object' || Array.isArray(raw)) continue;
        const m = raw as Record<string, unknown>;
        if (typeof m.title !== 'string' || !m.title.trim()) continue;
        favoriteShows[k] = {
          title: m.title.trim().slice(0, 200),
          author: typeof m.author === 'string' ? m.author.slice(0, 120) : '',
          image: typeof m.image === 'string' ? httpsUrl(m.image) : '',
          language: typeof m.language === 'string' ? m.language.slice(0, 12) : '',
          category: typeof m.category === 'string' ? m.category.slice(0, 40) : '',
        };
      }
    }
    const favorites = rawFavorites.filter((id: string) => !id.startsWith('d-') || Boolean(favoriteShows[id]));
    const progress: Saved['progress'] = {};
    for (const [k, p] of Object.entries((v.progress ?? {}) as Record<string, Progress>))
      if (p && Number.isFinite(p.t) && Number.isFinite(p.d) && Number.isFinite(p.at) && typeof p.show === 'string' && typeof p.title === 'string')
        progress[k] = { t: p.t, d: p.d, at: p.at, show: p.show, title: p.title, done: !!p.done };
    return {
      favorites,
      favoriteShows,
      queue: (Array.isArray(v.queue) ? (v.queue as Queued[]) : [])
        .filter((q) => q && [q.id, q.show, q.title, q.showTitle].every((x) => typeof x === 'string'))
        .filter((q, i, a) => a.findIndex((o) => o.id === q.id) === i)
        .map((q) => ({ id: q.id, show: q.show, title: q.title, showTitle: q.showTitle })),
      progress, rate: num(v.rate, 0.5, 3, 1), volume: num(v.volume, 0, 1, 1),
      theme: ['auto', 'light', 'dark'].includes(v.theme) ? v.theme : 'auto',
      view: v.view === 'list' ? 'list' : 'grid',
    };
  } catch {
    return { ...initial, favorites: [], favoriteShows: {}, queue: [], progress: {} };
  }
}

export const saved = $state<Saved>(read());

// Another tab saved: take its state, so this tab's next save doesn't undo it.
addEventListener('storage', (e) => { if (e.key === KEY || e.key === null) { Object.assign(saved, read()); applyTheme(); } });

export function save() {
  const all = Object.entries(saved.progress);
  if (all.length > 300) saved.progress = Object.fromEntries(all.sort((a, b) => b[1].at - a[1].at).slice(0, 200));
  try { localStorage.setItem(KEY, JSON.stringify(saved)); } catch { /* keep going without it */ }
}

export function toggleFavorite(show: FavoriteShow & { id: string }) {
  if (saved.favorites.includes(show.id)) {
    saved.favorites = saved.favorites.filter((x) => x !== show.id);
    if (show.id in saved.favoriteShows) {
      const next = { ...saved.favoriteShows };
      delete next[show.id];
      saved.favoriteShows = next;
    }
  } else {
    saved.favorites = [...saved.favorites, show.id];
    if (show.id.startsWith('d-')) {
      saved.favoriteShows = { ...saved.favoriteShows, [show.id]: normalizeMeta(show) };
    }
  }
  save();
}

export function syncFavoriteMeta(show: FavoriteShow & { id: string }) {
  if (!show.id.startsWith('d-') || !saved.favorites.includes(show.id)) return;
  const next = normalizeMeta(show);
  const prev = saved.favoriteShows[show.id];
  if (prev && prev.title === next.title && prev.author === next.author && prev.image === next.image
    && prev.language === next.language && prev.category === next.category) return;
  saved.favoriteShows = { ...saved.favoriteShows, [show.id]: next };
  save();
}

export function setView(view: BrowseView) {
  saved.view = view;
  save();
}

export function applyTheme() {
  if (saved.theme === 'auto') delete document.documentElement.dataset.theme;
  else document.documentElement.dataset.theme = saved.theme;
}
