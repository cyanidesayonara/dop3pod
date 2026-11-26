import type { RawEpisode } from './rss.ts';

export type ShowSource = { id: string; category: string; language: string; title: string; feed: string };
export type Episode = Omit<RawEpisode, 'guid'> & { id: string };
export type Show = {
  id: string; category: string; language: string; title: string; author: string; description: string; link: string; image: string; cover: string; coverOf: string;
  updated: string; stale: boolean; etag: string; modified: string; episodes: Episode[];
  /** Directory shows whose feed the browser could not read: only the latest episode is known. */
  limited?: boolean;
  explicit?: boolean;
};

/** [id, title, author, language index, category index, cover URL, explicit, newest episode (unix seconds)] */
export type DirectoryEntry = [number, string, string, number, number, string, 0 | 1, number];
export type DirectoryIndex = { generated: string; categories: string[]; languages: string[]; shows: DirectoryEntry[] };
export type DirectoryDetail = {
  title: string; author: string; image: string; language: string; category: string; explicit: boolean;
  feed: string; link: string; description: string; episodes: number;
  newest: { audio: string; date: string; duration: number | null } | null;
};

export type ChartItem = { show: string; title: string; author: string; image: string; language: string; explicit?: boolean };
export type Charts = { generated: string; lists: { id: string; label: string; items: ChartItem[] }[]; extras: Record<string, DirectoryDetail> };
