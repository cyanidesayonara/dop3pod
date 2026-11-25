import { loadShow, type Episode, type Show } from './data.ts';
import { player } from './player.svelte.ts';
import { save, saved } from './saved.svelte.ts';

export const inQueue = (id: string) => saved.queue.some((q) => q.id === id);

export function toggleQueue(show: Pick<Show, 'id' | 'title'>, e: Episode) {
  saved.queue = inQueue(e.id)
    ? saved.queue.filter((q) => q.id !== e.id)
    : [...saved.queue, { id: e.id, show: show.id, title: e.title, showTitle: show.title }].slice(-100);
  save();
}

export function removeFromQueue(id: string) {
  if (!inQueue(id)) return;
  saved.queue = saved.queue.filter((q) => q.id !== id);
  save();
}

/** Takes queued episodes in order until one can be played. False if none could. */
async function playQueued(): Promise<boolean> {
  const before = player.episode;
  while (saved.queue.length) {
    const q = saved.queue[0];
    let found: { show: Show; episode: Episode } | null = null;
    try {
      const show = await loadShow(q.show);
      const episode = show.episodes.find((e) => e.id === q.id);
      if (episode) found = { show, episode };
    } catch {
      if (!navigator.onLine) return false; // keep the queue for later
    }
    if (player.episode !== before) return true; // something else was chosen meanwhile
    removeFromQueue(q.id);
    if (found) {
      player.play(found.show, found.episode);
      return true;
    }
  }
  return false;
}

/** What follows the current episode: the queue first, then the show's next newer episode. */
export async function advance() {
  const { show, next } = player;
  const current = player.episode;
  if (await playQueued()) return;
  if (show && next && player.episode === current) player.play(show, next);
}
