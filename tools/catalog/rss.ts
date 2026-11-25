// A small, forgiving RSS reader. Real podcast feeds are often not valid XML, so this never throws on bad markup:
// it keeps whatever it can find. No DTD or external entity is ever read.

export type RawEpisode = {
  guid: string;
  title: string;
  date: string | null;
  duration: number | null;
  summary: string;
  audio: string;
  bytes: number | null;
};
export type Feed = { title: string; author: string; description: string; link: string; image: string; episodes: RawEpisode[] };

const ITUNES = 'http://www.itunes.com/dtds/podcast-1.0.dtd';
const NAMED: Record<string, string> = {
  amp: '&', lt: '<', gt: '>', quot: '"', apos: "'", nbsp: ' ', hellip: '…', mdash: '—', ndash: '–',
  lsquo: '‘', rsquo: '’', ldquo: '“', rdquo: '”', bull: '•', eacute: 'é', copy: '©', reg: '®', trade: '™',
};

export function decode(s: string): string {
  return s.replace(/&(#x[0-9a-f]{1,6}|#\d{1,7}|[a-z]{2,8});/gi, (all, e: string) => {
    if (e[0] !== '#') return NAMED[e.toLowerCase()] ?? all;
    const n = /^#x/i.test(e) ? parseInt(e.slice(2), 16) : parseInt(e.slice(1), 10);
    return n > 0 && n <= 0x10ffff && !(n >= 0xd800 && n <= 0xdfff) ? String.fromCodePoint(n) : '';
  });
}

/** HTML to plain text. The site only ever shows this as text, never as markup. */
export function plain(s: string, max = 600): string {
  const t = decode(
    s.slice(0, 50_000)
      .replace(/<(script|style)\b[^>]{0,500}>[\s\S]*?<\/\1>/gi, ' ')
      .replace(/<\/?(p|br|div|li|h[1-6])\b[^>]{0,500}>/gi, ' ')
      .replace(/<\/?[a-z!][^<>]{0,2000}>/gi, ''),
  ).replace(/\s+/g, ' ').trim();
  return t.length > max ? t.slice(0, max).replace(/\s+\S*$/, '') + '…' : t;
}

/** "3723", "1234.5", "62:03" or "1:02:03.5" in whole seconds. */
export function seconds(s: string | undefined): number | null {
  const m = /^(?:(?:(\d{1,3}):)?(\d{1,4}):)?(\d{1,6})(?:[.,]\d+)?$/.exec((s ?? '').trim());
  if (!m) return null;
  const n = Number(m[1] ?? 0) * 3600 + Number(m[2] ?? 0) * 60 + Number(m[3]);
  return n > 0 && n < 200_000 ? n : null;
}

export function isoDate(s: string | undefined): string | null {
  const t = Date.parse((s ?? '').trim());
  return Number.isNaN(t) ? null : new Date(t).toISOString();
}

/** An https URL, upgrading http, or '' for anything else. */
export function httpsUrl(s: string | undefined): string {
  try {
    const u = new URL((s ?? '').trim());
    if (u.protocol === 'http:') u.protocol = 'https:';
    return u.protocol === 'https:' && !u.username && !u.password ? u.href : '';
  } catch {
    return '';
  }
}

type Attrs = Record<string, string>;
function attributes(s: string): Attrs {
  const out: Attrs = {};
  for (const m of s.matchAll(/([\w:.-]+)\s*=\s*(?:"([^"]*)"|'([^']*)')/g)) out[m[1].toLowerCase()] ??= decode(m[2] ?? m[3] ?? '');
  return out;
}

/** End of the tag that starts at `i`, skipping quoted attribute values. */
function tagEnd(x: string, i: number): number {
  const close = x.indexOf('>', i);
  if (close < 0) return -1;
  let q = '';
  for (let k = i; k < x.length && k < i + 20_000; k++) {
    const c = x[k];
    if (q) { if (c === q) q = ''; } else if (c === '"' || c === "'") q = c;
    else if (c === '>') return k;
  }
  return close; // an unbalanced quote: settle for the first ">"
}

const isAudio = (type: string, url: string) =>
  /^audio\//i.test(type) || (!/^video\//i.test(type) && /\.(mp3|m4a|aac|ogg|opus)$/i.test(url.split(/[?#]/)[0]));

type Fields = Record<string, string>;

export function parseFeed(x: string): Feed {
  const channel: Fields = {};
  const items: Fields[] = [];
  const prefixes = new Set(['itunes']);
  let item: Fields | null = null;
  let inImage = false;
  let cap: { tag: string; key: string; depth: number; text: string } | null = null;

  const key = (tag: string) => {
    const [p, local] = tag.includes(':') ? tag.split(':', 2) : ['', tag];
    return p ? (prefixes.has(p) ? `itunes:${local}` : `${p}:${local}`) : local;
  };
  const store = (c: NonNullable<typeof cap>) => {
    const target = item ?? channel;
    if (!item && inImage && c.key !== 'url') return;
    const k = !item && inImage ? 'image' : c.key;
    const t = c.text.trim();
    if (t) target[k] ??= t;
  };

  for (let i = 0; i < x.length; ) {
    const lt = x.indexOf('<', i);
    if (lt < 0) break;
    if (cap) cap.text += x.slice(i, lt);
    if (x.startsWith('<!--', lt)) { const e = x.indexOf('-->', lt); i = e < 0 ? x.length : e + 3; continue; }
    if (x.startsWith('<![CDATA[', lt)) {
      const e = x.indexOf(']]>', lt);
      const body = x.slice(lt + 9, e < 0 ? x.length : e);
      // Escaped so the one decode at the end leaves CDATA text as it was.
      if (cap) cap.text += body.replaceAll('&', '&amp;').replaceAll('<', '&lt;');
      i = e < 0 ? x.length : e + 3;
      continue;
    }
    if (!/[A-Za-z/!?]/.test(x[lt + 1] ?? '')) { if (cap) cap.text += '&lt;'; i = lt + 1; continue; }
    const end = tagEnd(x, lt);
    if (end < 0) break;
    const raw = x.slice(lt + 1, end);
    i = end + 1;
    if (raw[0] === '!' || raw[0] === '?') continue;

    if (raw[0] === '/') {
      const tag = raw.slice(1).trim().toLowerCase();
      if (tag === 'item') { if (cap) { store(cap); cap = null; } item = null; continue; }
      if (cap && tag === cap.tag && --cap.depth === 0) { store(cap); cap = null; }
      else if (tag === 'image') inImage = false;
      continue;
    }

    const name = /^[\w:.-]+/.exec(raw)?.[0] ?? '';
    const tag = name.toLowerCase();
    const selfClosed = raw.endsWith('/');
    if (tag === 'item') { cap = null; item = {}; items.push(item); inImage = false; continue; }
    if (cap) {
      if (tag === cap.tag && !selfClosed) cap.depth++;
      continue;
    }
    if (tag === 'rss' || tag === 'channel') {
      for (const [k, v] of Object.entries(attributes(raw)))
        if (k.startsWith('xmlns:') && v.toLowerCase() === ITUNES) prefixes.add(k.slice(6));
      continue;
    }
    const k = key(tag);
    if (k === 'enclosure') {
      const a = attributes(raw.slice(name.length));
      const url = httpsUrl(a.url);
      if (item && !item.audio && url && isAudio(a.type ?? '', url)) { item.audio = url; item.bytes = a.length ?? ''; }
      continue;
    }
    if (k === 'itunes:image') {
      const href = httpsUrl(attributes(raw.slice(name.length)).href);
      if (href && !item) channel['itunes:image'] ??= href;
      continue;
    }
    if (k === 'image' && !item) { inImage = !selfClosed; continue; }
    if (!selfClosed) cap = { tag, key: k, depth: 1, text: '' };
  }

  const text = (f: Fields, keys: string[], max?: number) => {
    for (const k of keys) { const t = f[k] && plain(decode(f[k]), max); if (t) return t; }
    return '';
  };
  const episodes = items.filter((f) => f.audio).map((f): RawEpisode => {
    const bytes = Number(f.bytes);
    return {
      guid: decode(f.guid ?? '') || f.audio,
      title: text(f, ['title', 'itunes:title'], 200) || 'Untitled',
      date: isoDate(f.pubdate),
      duration: seconds(f['itunes:duration']),
      summary: text(f, ['description', 'itunes:summary', 'content:encoded', 'itunes:subtitle']),
      audio: f.audio,
      bytes: bytes > 10_000 ? bytes : null, // some feeds put 0, 1 or a duration here
    };
  });
  // Newest first; undated ones keep feed order at the end.
  episodes.sort((a, b) => (a.date && b.date ? b.date.localeCompare(a.date) : a.date ? -1 : b.date ? 1 : 0));
  return {
    title: text(channel, ['title'], 200),
    author: text(channel, ['itunes:author'], 200),
    description: text(channel, ['description', 'itunes:summary', 'itunes:subtitle']),
    link: httpsUrl(decode(channel.link ?? '')),
    image: channel['itunes:image'] ?? httpsUrl(decode(channel.image ?? '')),
    episodes,
  };
}
