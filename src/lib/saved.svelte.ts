// Everything the app remembers, in this browser only. Storage can be blocked or full, so nothing depends on it.
export type Progress = { t: number; d: number; at: number; show: string; title: string; done: boolean };
export type Theme = 'auto' | 'light' | 'dark';
type Saved = { favorites: string[]; progress: Record<string, Progress>; rate: number; volume: number; theme: Theme };

const KEY = 'dopepod';
const initial: Saved = { favorites: [], progress: {}, rate: 1, volume: 1, theme: 'auto' };

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
      progress, rate: num(v.rate, 0.5, 3, 1), volume: num(v.volume, 0, 1, 1),
      theme: ['auto', 'light', 'dark'].includes(v.theme) ? v.theme : 'auto',
    };
  } catch {
    return { ...initial };
  }
}

export const saved = $state<Saved>(read());

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
