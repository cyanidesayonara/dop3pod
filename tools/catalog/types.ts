import type { RawEpisode } from './rss.ts';

export type ShowSource = { id: string; category: string; language: string; title: string; feed: string };
export type Episode = Omit<RawEpisode, 'guid'> & { id: string };
export type Show = {
  id: string; category: string; language: string; title: string; author: string; description: string; link: string; image: string; cover: string; coverOf: string;
  updated: string; stale: boolean; etag: string; modified: string; episodes: Episode[];
};
