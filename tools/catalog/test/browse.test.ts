import assert from 'node:assert/strict';
import { test } from 'node:test';
import { buildBrowseList, buildCategories, buildFavoriteShows, buildLanguages, filterBrowse, languageLabel } from '../../../src/lib/browse.ts';
import type { ShowCard } from '../../../src/lib/data.ts';
import type { DirectoryIndex } from '../types.ts';

const card = (x: Partial<ShowCard> = {}): ShowCard => ({
  id: 'feat',
  category: 'Science',
  language: 'en',
  title: 'Featured Show',
  author: 'Host',
  description: 'Deep dives into astronomy',
  image: 'https://f.example/feat.jpg',
  cover: 'covers/feat.webp',
  stale: false,
  latest: '2026-11-20T00:00:00.000Z',
  ...x,
});

const dirIndex: DirectoryIndex = {
  generated: '2026-11-26T00:00:00.000Z',
  categories: ['Technology', 'True Crime', 'Other'],
  languages: ['en', 'in', 'iw', 'pr', ''],
  shows: [
    [101, 'Tech Talk', 'Jane Doe', 0, 0, 'https://d.example/101.jpg', 0, 1795000000],
    [102, 'Berita Harian', 'Redaksi', 1, 2, 'https://d.example/102.jpg', 1, 1794000000],
    [103, 'Café Crime', 'Noir Co', 2, 1, 'https://d.example/103.jpg', 1, 1793000000],
    [104, 'Bogus Lang', 'Nobody', 3, 0, '', 0, 1792000000],
  ],
};

test('buildBrowseList merges featured and directory shows with normalized metadata', () => {
  const list = buildBrowseList([card()], dirIndex);
  assert.equal(list.length, 5);
  assert.equal(list[0].featured, true);
  assert.equal(list[0].id, 'feat');
  assert.equal(list[1].id, 'd-101');
  assert.equal(list[1].featured, false);
  assert.equal(list[1].explicit, false);
  assert.equal(list[2].language, 'id');
  assert.equal(list[2].explicit, true);
  assert.equal(list[3].language, 'he');
  assert.equal(list[3].latest, new Date(1793000000 * 1000).toISOString());
});

test('buildFavoriteShows avoids duplicates and falls back to saved metadata', () => {
  const all = buildBrowseList([card()], dirIndex);
  const favs = buildFavoriteShows(all, ['feat', 'd-101', 'd-999'], {
    'd-101': { title: 'Stale Title', author: 'Old', image: '', language: 'en', category: 'Technology' },
    'd-999': { title: 'Chart Only', author: 'Guest', image: 'https://c.example/999.jpg', language: 'fi', category: 'Music' },
  });
  assert.deepEqual(favs.map((s) => s.id), ['feat', 'd-101', 'd-999']);
  assert.equal(favs[1].title, 'Tech Talk');
  assert.equal(favs[2].title, 'Chart Only');
  assert.equal(favs[2].language, 'fi');
});

test('buildCategories sorts alphabetically with All first and Other last', () => {
  const all = buildBrowseList([card()], dirIndex);
  assert.deepEqual(buildCategories(all), ['All', 'Science', 'Technology', 'True Crime', 'Other']);
});

test('buildLanguages drops invalid codes, normalizes legacy aliases, and sorts by count', () => {
  assert.equal(languageLabel('pr'), '');
  assert.equal(languageLabel('jp'), '');
  assert.equal(languageLabel('in'), 'Indonesian');
  const all = buildBrowseList([card()], dirIndex);
  const langs = buildLanguages(all);
  assert.equal(langs[0].id, 'all');
  assert.equal(langs[0].count, 5);
  assert.deepEqual(langs.slice(1), [
    { id: 'en', name: 'English', count: 2 },
    { id: 'he', name: 'Hebrew', count: 1 },
    { id: 'id', name: 'Indonesian', count: 1 },
  ]);
});

test('filterBrowse ranks exact, prefix, title, author, description matches with accent folding and language filtering', () => {
  const all = buildBrowseList([
    card({ id: 'a', title: 'Crime Wave', description: 'Weekly mystery' }),
    card({ id: 'b', title: 'Space News', description: 'Includes true crime stories' }),
  ], dirIndex);

  const crimeMatches = filterBrowse(all, 'all', 'cafe');
  assert.deepEqual(crimeMatches.map((s) => s.id), ['d-103']);

  const ranked = filterBrowse(all, 'all', 'crime');
  assert.deepEqual(ranked.map((s) => s.id), ['a', 'd-103', 'b']);

  const exactAndAuthor = buildBrowseList([
    card({ id: 'desc', title: 'Other', author: 'Someone', description: 'Talks about jane' }),
    card({ id: 'title-inc', title: 'All Jane', author: 'Someone', description: '' }),
    card({ id: 'exact', title: 'Jane', author: 'Someone', description: '' }),
    card({ id: 'prefix', title: 'Jane Talks', author: 'Someone', description: '' }),
  ], dirIndex);
  assert.deepEqual(filterBrowse(exactAndAuthor, 'all', 'jane').map((s) => s.id), ['exact', 'prefix', 'title-inc', 'd-101', 'desc']);
  assert.deepEqual(filterBrowse(all, 'id', '').map((s) => s.id), ['d-102']);
});
