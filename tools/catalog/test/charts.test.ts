import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { test } from 'node:test';
import { authHeaders, buildCharts, fetchList, LISTS } from '../charts.ts';

const feed = (id: number, x: object = {}) => ({
  id, url: `https://f.example/${id}`, title: `Show ${id}`, author: 'Host', description: '<b>About</b>', image: 'https://f.example/i.jpg',
  artwork: '', language: 'en-US', categories: { '102': 'Technology' }, trendScore: 10 - id, ...x,
});

test('requests are signed as the docs describe', () => {
  const h = authHeaders('KEY', 'SECRET', 1700000000);
  assert.equal(h['X-Auth-Date'], '1700000000');
  assert.equal(h.Authorization, createHash('sha1').update('KEYSECRET1700000000').digest('hex'));
  assert.match(h['User-Agent'], /^dopepod-catalog\//);
});

test('fetchList asks for the right list and sorts by trend score', async () => {
  let asked = '';
  const out = await fetchList({ id: 'x', label: 'X', cat: 'True Crime', lang: 'fi' }, 'k', 's', async (u) => {
    asked = u;
    return Response.json({ status: 'true', feeds: [feed(3), feed(1), feed(2)] });
  });
  assert.equal(new URL(asked).searchParams.get('cat'), 'True Crime');
  assert.equal(new URL(asked).searchParams.get('lang'), 'fi');
  assert.deepEqual(out.map((f) => f.id), [1, 2, 3]);
  await assert.rejects(fetchList(LISTS[0], 'k', 's', async () => new Response('no', { status: 401 })), /401/);
  await assert.rejects(fetchList(LISTS[0], 'k', 's', async () => Response.json({ status: 'false' })), /no feeds/);
});

test('only established shows are kept, without repeats', () => {
  const c = buildCharts(new Map([['all', [feed(1), feed(2, { url: 'https://featured.example/rss' }), feed(3), feed(5, { title: 'Show 3' }), feed(4, { url: 'javascript:x' })]]]),
    new Map([['https://featured.example/rss', 'radiolab']]), new Set([3, 4, 5]), 'now');
  assert.deepEqual(c.lists[0].items.map((i) => i.show), ['radiolab', 'd-3']);
  assert.deepEqual(c.extras, {});
});

test('lists with no answer are left out', () => {
  const c = buildCharts(new Map([['all', [feed(1)]], ['c-science', []]]), new Map(), new Set([1]), 'now');
  assert.deepEqual(c.lists.map((l) => l.id), ['all']);
});
