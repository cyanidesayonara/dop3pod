import assert from 'node:assert/strict';
import { test } from 'node:test';
import { buildDirectory, fetchRetrying, SHARDS, type DumpRow } from '../directory.ts';

const row = (x: Partial<DumpRow> = {}): DumpRow => ({
  id: 1000, url: 'https://f.example/feed', title: 'Show', link: 'https://f.example/', itunesAuthor: 'Host', explicit: 0,
  imageUrl: 'https://f.example/i.jpg', language: 'en-US', episodeCount: 50, newestItemPubdate: 1795000000,
  newestEnclosureUrl: 'https://f.example/1.mp3', newestEnclosureDuration: 1800, description: '<p>About <b>it</b></p>', category1: 'technology', ...x,
});

test('rows become an index entry and a detail in the right shard', () => {
  const { index, shards } = buildDirectory([row()], new Set(), 'now');
  assert.equal(shards.length, SHARDS);
  assert.deepEqual(index.shows[0], [1000, 'Show', 'Host', 0, 0, 'https://f.example/i.jpg', 0, 1795000000]);
  assert.deepEqual([index.languages, index.categories], [['en'], ['Technology']]);
  const d = shards[1000 % SHARDS][1000];
  assert.equal(d.description, 'About it');
  assert.deepEqual(d.newest, { audio: 'https://f.example/1.mp3', date: new Date(1795000000 * 1000).toISOString(), duration: 1800 });
});

test('featured shows, duplicates and unsafe feeds are left out', () => {
  const { index } = buildDirectory([
    row({ id: 1 }), row({ id: 2 }), row({ id: 3, url: 'https://featured.example/rss', title: 'Other' }),
    row({ id: 4, url: 'javascript:alert(1)', title: 'Bad' }), row({ id: 5, title: '' }),
  ], new Set(['https://featured.example/rss']), 'now');
  assert.deepEqual(index.shows.map((s) => s[0]), [1]);
});

test('http becomes https and other schemes disappear', () => {
  const { index, shards } = buildDirectory([row({ url: 'http://f.example/rss', imageUrl: 'data:image/png;base64,AA', newestEnclosureUrl: 'ftp://x/1.mp3' })], new Set(), 'now');
  assert.equal(shards[1000 % SHARDS][1000].feed, 'https://f.example/rss');
  assert.equal(index.shows[0][5], '');
  assert.equal(shards[1000 % SHARDS][1000].newest, null);
});

test('titles and descriptions are plain text, and unknown categories become Other', () => {
  const { index, shards } = buildDirectory([row({ title: 'A &amp; <i>B</i>', category1: 'crafts', explicit: 1, language: '' })], new Set(), 'now');
  assert.equal(index.shows[0][1], 'A & B');
  assert.equal(index.categories[index.shows[0][4]], 'Other');
  assert.equal(index.shows[0][6], 1);
  assert.equal(index.languages[index.shows[0][3]], '');
  assert.equal(shards[1000 % SHARDS][1000].explicit, true);
});

test('copying retries server errors but not missing files', async () => {
  let n = 0;
  const flaky = async () => (++n < 3 ? new Response('busy', { status: 503 }) : new Response('ok'));
  assert.equal(await fetchRetrying('https://x.example/a', 4, 1, flaky as typeof fetch), 'ok');
  assert.equal(n, 3);
  n = 0;
  await assert.rejects(fetchRetrying('https://x.example/a', 4, 1, (async () => { n++; return new Response('no', { status: 404 }); }) as typeof fetch), /404/);
  assert.equal(n, 1);
  await assert.rejects(fetchRetrying('https://x.example/a', 2, 1, (async () => new Response('busy', { status: 503 })) as typeof fetch), /503/);
});
