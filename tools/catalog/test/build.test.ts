import assert from 'node:assert/strict';
import { test } from 'node:test';
import { buildCatalog, loadShow, readCapped, type Show, type ShowSource } from '../build.ts';

const xml = (n = 1) => `<rss><channel><title>T</title>${Array.from({ length: n }, (_, i) =>
  `<item><title>E${i}</title><guid>g${i}</guid><enclosure url="https://a.example/${i}.mp3" type="audio/mpeg"/></item>`).join('')}</channel></rss>`;
const src = (id: string): ShowSource => ({ id, category: 'C', language: 'en', title: id, feed: `https://f.example/${id}` });
const ok = async () => new Response(xml(), { headers: { etag: '"1"' } });
const quiet = () => {};

test('caps episodes, drops repeats and keeps the etag', async () => {
  const s = await loadShow(src('a'), null, async () => new Response(xml(80) + xml(80), { headers: { etag: '"1"' } }));
  assert.equal(s.episodes.length, 50);
  assert.equal(new Set(s.episodes.map((e) => e.id)).size, 50);
  assert.equal(s.etag, '"1"');
});

test('304 reuses the last episodes and sends the etag', async () => {
  const prev = await loadShow(src('a'), null, ok);
  let sent = '';
  const s = await loadShow(src('a'), { ...prev, stale: true }, async (_u, i) => {
    sent = (i.headers as Record<string, string>)['If-None-Match'];
    return new Response(null, { status: 304 });
  });
  assert.equal(sent, '"1"');
  assert.deepEqual(s.episodes, prev.episodes);
  assert.equal(s.stale, false);
});

test('a failing show keeps its last good episodes and is marked stale', async () => {
  const prev = await loadShow(src('a'), null, ok);
  const r = await buildCatalog([src('a'), src('b'), src('c'), src('d'), src('e')], async (id): Promise<Show | null> => (id === 'a' ? prev : null),
    async (u) => (u.endsWith('/a') ? new Response('gone', { status: 500 }) : ok()), quiet);
  assert.deepEqual(r.failed, ['a']);
  assert.equal(r.tooMany, false);
  assert.equal(r.shows[0].stale, true);
  assert.equal(r.shows.length, 5);
});

test('a failing show with no history is left out', async () => {
  const r = await buildCatalog([src('a'), src('b'), src('c'), src('d'), src('e')], async () => null,
    async (u) => (u.endsWith('/a') ? new Response(xml(0)) : ok()), quiet);
  assert.deepEqual(r.shows.map((s) => s.id), ['b', 'c', 'd', 'e']);
});

test('more than 20% failures is too many', async () => {
  const r = await buildCatalog([src('a'), src('b'), src('c'), src('d'), src('e')], async () => null,
    async (u) => { if (/[ab]$/.test(u)) throw new Error('offline'); return ok(); }, quiet);
  assert.equal(r.tooMany, true);
});

test('oversized feeds are refused and declared encodings are honored', async () => {
  await assert.rejects(readCapped(new Response('x'.repeat(100)), 50), /larger/);
  const latin = Buffer.from('<?xml version="1.0" encoding="ISO-8859-1"?><t>caf\xe9</t>', 'latin1');
  assert.match(await readCapped(new Response(latin)), /café/);
});
