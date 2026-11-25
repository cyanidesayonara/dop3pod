// Everything the app remembers, in this browser only. Storage can be blocked or full, so nothing depends on it.
export type Progress = { t: number; d: number; at: number; show: string; title: string; done: boolean };
export type Queued = { id: string; show: string; title: string; showTitle: string };
export type Theme = 'auto' | 'light' | 'dark';
type Saved = { favorites: string[]; queue: Queued[]; progress: Record<string, Progress>; rate: number; volume: number; theme: Theme };

const KEY = 'dopepod';
const initial: Saved = { favorites: [], queue: [], progress: {}, rate: 1, volume: 1, theme: 'auto' };

function read(): Saved {
  try {
    const v = JSON.parse(localStorage.getItem(KEY) ?? '{}');
    const num = (x: unknown, lo: number, hi: number, d: number) => (typeof x === 'number' && x >= lo && x <= hi ? x : d);
    const progress: Saved['progress'] = {};
    for (const [k, p] of Object.entries((v.progress ?? {}) as Record<string, Progress>))
      if (p && Number.isFinite(p.t) && Number.isFinite(p.d) && Number.isFinite(p.at) && typeof p.show === 'string' && typeof p.title === 'string')
        progress[k] = { t: p.t, d: p.d, at: p.at, show: p.show, title: p.title, done: !!p.done };
    return {
      favorites: Array.isArray(v.favorites) ? v.favorites.filter((x: unknown) => typeof x === 'string') : [],
      queue: (Array.isArray(v.queue) ? (v.queue as Queued[]) : [])
        .filter((q) => q && [q.id, q.show, q.title, q.showTitle].every((x) => typeof x === 'string'))
        .filter((q, i, a) => a.findIndex((o) => o.id === q.id) === i)
        .map((q) => ({ id: q.id, show: q.show, title: q.title, showTitle: q.showTitle })),
      progress, rate: num(v.rate, 0.5, 3, 1), volume: num(v.volume, 0, 1, 1),
      theme: ['auto', 'light', 'dark'].includes(v.theme) ? v.theme : 'auto',
    };
  } catch {
    return { ...initial };
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

export function toggleFavorite(id: string) {
  saved.favorites = saved.favorites.includes(id) ? saved.favorites.filter((x) => x !== id) : [...saved.favorites, id];
  save();
}

export function applyTheme() {
  if (saved.theme === 'auto') delete document.documentElement.dataset.theme;
  else document.documentElement.dataset.theme = saved.theme;
}
