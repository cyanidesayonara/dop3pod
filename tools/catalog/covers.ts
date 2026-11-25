// Small square covers, because publishers' originals run to several megabytes each.
import sharp from 'sharp';
import type { Fetcher } from './build.ts';
import type { Show } from './types.ts';

const SIZE = 320;
const MAX_BYTES = 15_000_000;
const TYPES = new Set(['jpeg', 'png', 'webp', 'gif']);

export async function thumbnail(input: Buffer): Promise<Buffer> {
  // SVG and other complex formats are refused: these files come from strangers.
  const { format } = await sharp(input, { limitInputPixels: 50_000_000 }).metadata();
  if (!TYPES.has(format ?? '')) throw new Error(`unsupported image type ${format}`);
  return sharp(input, { limitInputPixels: 50_000_000 }).rotate().resize(SIZE, SIZE, { fit: 'cover' }).webp({ quality: 78 }).toBuffer();
}

async function download(url: string, get: Fetcher, userAgent: string): Promise<Buffer> {
  const res = await get(url, { headers: { 'User-Agent': userAgent, Accept: 'image/*' }, signal: AbortSignal.timeout(30_000) });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  if (res.url && !res.url.startsWith('https:')) throw new Error('not served over https');
  const chunks: Uint8Array[] = [];
  let n = 0;
  for await (const c of res.body ?? []) {
    n += c.length;
    if (n > MAX_BYTES) throw new Error('image too large');
    chunks.push(c);
  }
  return Buffer.concat(chunks);
}

export type CoverSource = { prev: Show | null; read: (file: string) => Promise<Buffer | null> };

/** The cover's bytes, or null to leave the site on the publisher's original. Never throws. */
export async function coverFor(
  show: Show, { prev, read }: CoverSource, get: Fetcher, userAgent: string, log: (s: string) => void,
): Promise<Buffer | null> {
  const kept = async () => (prev?.cover ? read(prev.cover) : null);
  if (!show.image) return null;
  if (prev?.coverOf === show.image) {
    const same = await kept();
    if (same) return same;
  }
  try {
    return await thumbnail(await download(show.image, get, userAgent));
  } catch (e) {
    log(`COVER ${show.id}: ${(e as Error).message}`);
    return kept();
  }
}
