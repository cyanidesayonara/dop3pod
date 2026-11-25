import assert from 'node:assert/strict';
import { test } from 'node:test';
import sharp from 'sharp';
import { coverFor, thumbnail } from '../covers.ts';
import type { Show } from '../types.ts';

const png = (w: number, h: number) => sharp({ create: { width: w, height: h, channels: 3, background: '#00bfa5' } }).png().toBuffer();
const show = (x: Partial<Show> = {}): Show => ({
  id: 'a', category: 'C', language: 'en', title: 'A', author: '', description: '', link: '', image: 'https://a.example/i.png',
  cover: '', coverOf: '', updated: '', stale: false, etag: '', modified: '', episodes: [], ...x,
});
const body = (b: Buffer | string) => async () => new Response(b as BodyInit);
const none = { prev: null, read: async () => null };
const quiet = () => {};

test('any shape becomes a small square WebP', async () => {
  const out = await thumbnail(await png(1400, 900));
  const m = await sharp(out).metadata();
  assert.deepEqual([m.format, m.width, m.height], ['webp', 320, 320]);
});

test('SVG and junk are refused', async () => {
  await assert.rejects(thumbnail(Buffer.from('<svg xmlns="http://www.w3.org/2000/svg" width="9" height="9"/>')));
  await assert.rejects(thumbnail(Buffer.from('not an image')));
});

test('unchanged artwork is reused without a download', async () => {
  const kept = Buffer.from('kept');
  const out = await coverFor(show(), { prev: show({ cover: 'covers/a.webp', coverOf: 'https://a.example/i.png' }), read: async () => kept },
    async () => { throw new Error('should not be called'); }, 'ua', quiet);
  assert.equal(out, kept);
});

test('a failed download keeps the last cover, or none', async () => {
  const kept = Buffer.from('kept');
  const bad = async () => new Response('no', { status: 429 });
  const prev = show({ cover: 'covers/a.webp', coverOf: 'https://a.example/old.png' });
  assert.equal(await coverFor(show(), { prev, read: async () => kept }, bad, 'ua', quiet), kept);
  assert.equal(await coverFor(show(), none, bad, 'ua', quiet), null);
  assert.equal(await coverFor(show({ image: '' }), none, bad, 'ua', quiet), null);
});

test('oversized and broken images never stop the build', async () => {
  assert.equal(await coverFor(show(), none, body(Buffer.alloc(16_000_000)), 'ua', quiet), null);
  assert.equal(await coverFor(show(), none, body('<html>'), 'ua', quiet), null);
  assert.ok(await coverFor(show(), none, body(await png(50, 50)), 'ua', quiet));
});
