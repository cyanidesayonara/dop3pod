import assert from 'node:assert/strict';
import { test } from 'node:test';
import { decode, httpsUrl, isoDate, parseFeed, plain, seconds } from '../rss.ts';

const feed = (items: string, head = '') =>
  `<?xml version="1.0"?><rss xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd"><channel><title>Show</title>${head}${items}</channel></rss>`;
const item = (inner = '', url = 'https://a.example/1.mp3', type = 'audio/mpeg') =>
  `<item><title>One</title><enclosure url="${url}" type="${type}" length="5000000"/>${inner}</item>`;

test('durations, including the ones the old parser got wrong', () => {
  const cases: [string | undefined, number | null][] = [
    ['3723', 3723], ['1234.5', 1234], ['1:02:03', 3723], ['1:02:03.5', 3723], ['62:03', 3723], ['00:45', 45], [' 90 ', 90],
    ['', null], [undefined, null], ['soon', null], ['1:2:3:4', null], ['-5', null], ['0', null],
  ];
  for (const [s, n] of cases) assert.equal(seconds(s), n, String(s));
});

test('dates, and a missing date never breaks sorting', () => {
  assert.equal(isoDate('Tue, 24 Nov 2026 10:00:00 EST'), '2026-11-24T15:00:00.000Z');
  assert.equal(isoDate('yesterday-ish'), null);
  const f = parseFeed(feed(
    item('<guid>none</guid>', 'https://a.example/1.mp3') +
    item('<guid>old</guid><pubDate>Mon, 01 Jan 2024 00:00:00 GMT</pubDate>', 'https://a.example/2.mp3') +
    item('<guid>new</guid><pubdate>Wed, 01 Jan 2025 00:00:00 GMT</pubdate>', 'https://a.example/3.mp3')));
  assert.deepEqual(f.episodes.map((e) => e.guid), ['new', 'old', 'none']);
});

test('URLs are https or nothing, and only the scheme changes', () => {
  assert.equal(httpsUrl('http://a.example/x?u=http://b.example/y'), 'https://a.example/x?u=http://b.example/y');
  for (const bad of ['javascript:alert(1)', 'data:audio/mpeg;base64,AA', 'ftp://a.example/x', '/relative', '', 'https://u:p@a.example/'])
    assert.equal(httpsUrl(bad), '', bad);
});

test('only audio enclosures count', () => {
  const f = parseFeed(feed(
    item('', 'https://a.example/v.mp4', 'video/mp4') + item('', 'https://a.example/a.m4a?x=1', '') +
    item('', 'https://a.example/b.mp3', 'video/mp4') + item('', 'javascript:alert(1)') + '<item><title>none</title></item>'));
  assert.deepEqual(f.episodes.map((e) => e.audio), ['https://a.example/a.m4a?x=1']);
});

test('text: entities, CDATA and markup all end as plain text', () => {
  assert.equal(decode('&amp;&#39;&#x2019;&unknown;&#0;'), "&'’&unknown;");
  assert.equal(plain('<p>Hi<br>there <b>you</b></p><script>alert(1)</script>'), 'Hi there you');
  const t = (s: string) => parseFeed(feed(`<item><title>${s}</title><enclosure url="https://a.example/1.mp3" type="audio/mpeg"/></item>`)).episodes[0].title;
  assert.equal(t('Q&amp;A'), 'Q&A');
  assert.equal(t('<![CDATA[Q&A <b>live</b>]]>'), 'Q&A live');
  assert.equal(t('Q&amp;amp;A'), 'Q&A');
  assert.equal(t('a <b>bold</b> one'), 'a bold one');
  assert.equal(t('<![CDATA[1 < 2]]>'), '1 < 2');
});

test('summary falls back through the other fields', () => {
  const s = (x: string) => parseFeed(feed(item(x))).episodes[0].summary;
  assert.equal(s('<itunes:summary>B</itunes:summary><description>A</description>'), 'A');
  assert.equal(s('<description> </description><itunes:summary>B</itunes:summary>'), 'B');
  assert.equal(s('<itunes:subtitle>C</itunes:subtitle>'), 'C');
});

test('an unusual iTunes prefix still works, and one feed does not affect the next', () => {
  const odd = `<rss xmlns:pod="http://www.itunes.com/dtds/podcast-1.0.dtd"><channel>${item('<pod:duration>1:00</pod:duration>')}</channel></rss>`;
  assert.equal(parseFeed(odd).episodes[0].duration, 60);
  assert.equal(parseFeed(feed(item('<pod:duration>1:00</pod:duration>'))).episodes[0].duration, null);
});

test('channel fields are not taken from the image block or the items', () => {
  const f = parseFeed(`<rss><channel><image><title>Logo</title><url>http://a.example/i.png</url><link>https://wrong.example</link></image>
    <title>Show</title><link>https://a.example/</link>${item('<description>ep</description>')}</channel></rss>`);
  assert.equal(f.title, 'Show');
  assert.equal(f.link, 'https://a.example/');
  assert.equal(f.image, 'https://a.example/i.png');
  assert.equal(f.description, '');
});

test('implausible sizes are dropped', () => {
  const b = (n: string) => parseFeed(feed(`<item><enclosure url="https://a.example/1.mp3" type="audio/mpeg" length="${n}"/></item>`)).episodes[0].bytes;
  assert.deepEqual([b('5000000'), b('0'), b('1'), b('big'), b('')], [5000000, null, null, null, null]);
});

test('broken markup never throws and keeps what it can', () => {
  const good = item();
  for (const bad of ['', 'not xml', '<rss>', '<rss><channel><item><title>x', '<a b="', '<![CDATA[', '<!--', '<'.repeat(5000), '<item>'.repeat(500)])
    assert.doesNotThrow(() => parseFeed(bad), bad.slice(0, 20));
  assert.equal(parseFeed(feed(`<item><title>A & B <unclosed></title>${good.slice(6)}`)).episodes.length, 1);
  assert.equal(parseFeed(feed(good + '<item><title>cut off')).episodes.length, 1);
});

test('entity bombs are not expanded', () => {
  const x = `<!DOCTYPE r [<!ENTITY a "aaaa"><!ENTITY b "&a;&a;">]>${feed(`<item><title>&b;</title><enclosure url="https://a.example/1.mp3" type="audio/mpeg"/></item>`)}`;
  assert.equal(parseFeed(x).episodes[0].title, '&b;');
});

test('hostile input stays fast', () => {
  const t0 = performance.now();
  parseFeed('<a b="'.repeat(200_000));
  parseFeed(feed(item(`<description>${'&lt;x '.repeat(200_000)}</description>`)));
  plain('<script '.repeat(50_000));
  assert.ok(performance.now() - t0 < 5000, `${performance.now() - t0} ms`);
});
