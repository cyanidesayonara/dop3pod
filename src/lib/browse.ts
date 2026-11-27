// Unified browse list, filtering, ranking, and full genre/language options across featured + directory shows.
import type { DirectoryIndex } from '../../tools/catalog/types.ts';
import type { ShowCard } from './data.ts';

export type FavoriteMeta = { title: string; author: string; image: string; language: string; category: string };

export type BrowseShow = {
  id: string;
  title: string;
  author: string;
  category: string;
  language: string;
  image: string;
  cover: string;
  description: string;
  latest: string | null;
  latestTs: number;
  explicit: boolean;
  featured: boolean;
  _t: string;
  _a: string;
  _d: string;
};

export type LanguageOption = { id: string; name: string; count: number };

const LANG_ALIAS: Record<string, string> = { in: 'id', iw: 'he', ji: 'yi' };
const langNames = new Intl.DisplayNames(['en'], { type: 'language' });

export const fold = (s: string): string =>
  /[^\x00-\x7f]/.test(s) ? s.normalize('NFD').replace(/\p{M}/gu, '').toLowerCase() : s.toLowerCase();

export function normalizeLang(code: string): string {
  const c = code.trim().toLowerCase();
  return LANG_ALIAS[c] ?? c;
}

export function languageLabel(code: string): string {
  const c = normalizeLang(code);
  if (!/^[a-z]{2,3}$/.test(c)) return '';
  try {
    const name = langNames.of(c);
    return name && name.toLowerCase() !== c && !/^unknown\b/i.test(name) ? name : '';
  } catch {
    return '';
  }
}

export function buildBrowseList(featured: ShowCard[], directory: DirectoryIndex | null): BrowseShow[] {
  const out: BrowseShow[] = featured.map((s) => ({
    id: s.id,
    title: s.title,
    author: s.author,
    category: s.category,
    language: normalizeLang(s.language),
    image: s.image,
    cover: s.cover,
    description: s.description,
    latest: s.latest,
    latestTs: s.latest ? Date.parse(s.latest) || 0 : 0,
    explicit: false,
    featured: true,
    _t: fold(s.title),
    _a: fold(s.author),
    _d: fold(s.description),
  }));

  if (!directory) return out;

  for (const s of directory.shows) {
    const [pid, title, author, langIdx, catIdx, image, explicit, newestSec] = s;
    const latestTs = newestSec ? newestSec * 1000 : 0;
    out.push({
      id: `d-${pid}`,
      title,
      author,
      category: directory.categories[catIdx] || 'Other',
      language: normalizeLang(directory.languages[langIdx] ?? ''),
      image,
      cover: '',
      description: '',
      latest: latestTs ? new Date(latestTs).toISOString() : null,
      latestTs,
      explicit: explicit === 1,
      featured: false,
      _t: fold(title),
      _a: fold(author),
      _d: '',
    });
  }

  return out;
}

export function buildFavoriteShows(
  allShows: BrowseShow[],
  favoriteIds: string[],
  favoriteMeta: Record<string, FavoriteMeta>,
): BrowseShow[] {
  const byId = new Map(allShows.map((s) => [s.id, s]));
  const out: BrowseShow[] = [];
  for (const id of favoriteIds) {
    const existing = byId.get(id);
    if (existing) {
      out.push(existing);
      continue;
    }
    const m = id.startsWith('d-') ? favoriteMeta[id] : undefined;
    if (!m) continue;
    out.push({
      id,
      title: m.title,
      author: m.author,
      category: m.category || 'Other',
      language: normalizeLang(m.language),
      image: m.image,
      cover: '',
      description: '',
      latest: null,
      latestTs: 0,
      explicit: false,
      featured: false,
      _t: fold(m.title),
      _a: fold(m.author),
      _d: '',
    });
  }
  return out;
}

export function buildCategories(allShows: BrowseShow[]): string[] {
  const cats = [...new Set(allShows.map((s) => s.category || 'Other'))].sort((a, b) => {
    if (a === 'Other') return 1;
    if (b === 'Other') return -1;
    return a.localeCompare(b);
  });
  return ['All', ...cats];
}

export function buildLanguages(allShows: BrowseShow[]): LanguageOption[] {
  const counts = new Map<string, number>();
  for (const s of allShows) {
    if (!s.language || !languageLabel(s.language)) continue;
    counts.set(s.language, (counts.get(s.language) ?? 0) + 1);
  }
  const list = [...counts.entries()]
    .map(([id, count]) => ({ id, name: languageLabel(id), count }))
    .sort((a, b) => b.count - a.count || a.name.localeCompare(b.name));
  return [{ id: 'all', name: 'All languages', count: allShows.length }, ...list];
}

export function filterBrowse(pool: BrowseShow[], language: string, query: string): BrowseShow[] {
  const byLang = language === 'all' ? pool : pool.filter((s) => s.language === language);
  const q = fold(query.trim());
  if (!q) return byLang;
  const ranked: { s: BrowseShow; rank: number }[] = [];
  for (const s of byLang) {
    const rank =
      s._t === q ? 0
      : s._t.startsWith(q) ? 1
      : s._t.includes(q) ? 2
      : s._a.includes(q) ? 3
      : s._d.includes(q) ? 4
      : -1;
    if (rank >= 0) ranked.push({ s, rank });
  }
  return ranked
    .sort((a, b) => a.rank - b.rank || Number(b.s.featured) - Number(a.s.featured) || b.s.latestTs - a.s.latestTs)
    .map((x) => x.s);
}

export type ResumeProgress = { t: number; d: number; at: number; show: string; title: string; done: boolean };
export type ResumeItem = { id: string; p: ResumeProgress; show: Pick<BrowseShow, 'id' | 'title' | 'image' | 'cover' | 'language'> };

export function buildResumeList(
  progress: Record<string, ResumeProgress>,
  allShows: BrowseShow[],
  favoriteMeta: Record<string, FavoriteMeta>,
  currentEpisodeId?: string,
): ResumeItem[] {
  const byId = new Map(allShows.map((s) => [s.id, s]));
  const items: ResumeItem[] = [];
  for (const [id, p] of Object.entries(progress)) {
    if (p.done || id === currentEpisodeId) continue;
    const found = byId.get(p.show);
    if (found) {
      items.push({ id, p, show: found });
      continue;
    }
    const m = p.show.startsWith('d-') ? favoriteMeta[p.show] : undefined;
    if (m) {
      items.push({
        id,
        p,
        show: { id: p.show, title: m.title, image: m.image, cover: '', language: normalizeLang(m.language) },
      });
    }
  }
  return items.sort((a, b) => b.p.at - a.p.at).slice(0, 4);
}
