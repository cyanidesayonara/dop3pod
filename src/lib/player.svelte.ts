import { artwork, type Episode, type Show } from './data.ts';
import { save, saved } from './saved.svelte.ts';

const audio = new Audio();
audio.preload = 'metadata';

class Player {
  show = $state.raw<Show | null>(null);
  episode = $state.raw<Episode | null>(null);
  playing = $state(false);
  waiting = $state(false);
  time = $state(0);
  duration = $state(0);
  error = $state('');
  /** '' is off, 'end' stops after this episode, otherwise minutes. */
  sleep = $state('');
  sleepLeft = $state(0);
  /** Set by the app: plays whatever follows. */
  advance: () => void = () => {};
  /** Newer episode of the same show: what plays next. */
  next = $derived(this.neighbor(-1));
  previous = $derived(this.neighbor(1));

  #resumeAt = 0;
  #lastSave = 0;
  #sleepAt = 0;
  #sleepTick: ReturnType<typeof setInterval> | undefined;

  constructor() {
    audio.volume = saved.volume;
    const on = (e: string, f: () => void) => audio.addEventListener(e, f);
    on('loadedmetadata', () => {
      audio.playbackRate = saved.rate;
      if (this.#resumeAt > 0 && this.#resumeAt < (audio.duration || Infinity) - 5) audio.currentTime = this.#resumeAt;
      this.#resumeAt = 0;
      this.#length();
    });
    on('durationchange', () => this.#length());
    on('timeupdate', () => {
      if (this.#resumeAt > 0) return;
      this.time = audio.currentTime;
      if (Math.abs(Date.now() - this.#lastSave) > 5000) this.remember();
    });
    on('play', () => { this.playing = true; this.#session(); });
    on('pause', () => { this.playing = false; this.remember(); this.#session(); });
    on('waiting', () => (this.waiting = true));
    on('playing', () => { this.waiting = false; this.error = ''; });
    on('canplay', () => (this.waiting = false));
    on('ended', () => {
      this.remember(true);
      if (this.sleep === 'end') this.setSleep('');
      else this.advance();
    });
    on('error', () => {
      if (!this.episode || !audio.getAttribute('src')) return;
      this.waiting = this.playing = false;
      this.error = navigator.onLine ? "This episode wouldn't load. The publisher may have moved or blocked it." : "You're offline.";
    });
    addEventListener('pagehide', () => this.remember());
    document.addEventListener('visibilitychange', () => { if (document.hidden) this.remember(); });

    const ms = navigator.mediaSession;
    if (ms) {
      const set = (a: MediaSessionAction, f: MediaSessionActionHandler) => { try { ms.setActionHandler(a, f); } catch { /* not supported */ } };
      set('play', () => this.toggle());
      set('pause', () => audio.pause());
      set('seekbackward', (d) => this.skip(-(d.seekOffset ?? 15)));
      set('seekforward', (d) => this.skip(d.seekOffset ?? 30));
      set('seekto', (d) => { if (d.seekTime !== undefined) this.seek(d.seekTime); });
      set('nexttrack', () => this.advance());
      set('previoustrack', () => { if (this.previous && this.show) this.play(this.show, this.previous); });
    }
  }

  neighbor(step: number): Episode | null {
    if (!this.show || !this.episode) return null;
    const i = this.show.episodes.findIndex((e) => e.id === this.episode!.id);
    return i < 0 ? null : (this.show.episodes[i + step] ?? null);
  }

  isCurrent(id: string) { return this.episode?.id === id; }

  play(show: Show, episode: Episode) {
    if (this.isCurrent(episode.id) && !this.error) return this.toggle();
    this.remember();
    const p = saved.progress[episode.id];
    this.show = show;
    this.episode = episode;
    this.error = '';
    this.waiting = true;
    this.#resumeAt = p && !p.done ? p.t : 0;
    this.time = this.#resumeAt;
    this.duration = episode.duration ?? 0;
    audio.src = episode.audio;
    this.#start();
    this.#metadata();
  }

  toggle() {
    if (!this.episode) return;
    if (this.error) return this.retry();
    if (audio.paused) this.#start(); else audio.pause();
  }

  retry() {
    if (!this.episode) return;
    this.error = '';
    this.waiting = true;
    this.#resumeAt = this.time;
    audio.src = this.episode.audio;
    this.#start();
  }

  seek(t: number) {
    if (!this.episode) return;
    const to = Math.max(0, Math.min(t, this.duration ? this.duration - 1 : t));
    this.time = to;
    if (audio.readyState === 0) this.#resumeAt = to; else audio.currentTime = to;
  }
  skip(s: number) { this.seek(this.time + s); }

  setSleep(v: string) {
    clearInterval(this.#sleepTick);
    this.sleep = v;
    const min = Number(v);
    if (!v || !min) return;
    this.#sleepAt = Date.now() + min * 60_000;
    this.sleepLeft = min;
    // A clock time, not a countdown: background tabs run timers late.
    this.#sleepTick = setInterval(() => {
      this.sleepLeft = Math.max(1, Math.ceil((this.#sleepAt - Date.now()) / 60_000));
      if (Date.now() < this.#sleepAt) return;
      this.setSleep('');
      audio.pause();
    }, 1000);
  }

  setRate(r: number) { saved.rate = r; audio.playbackRate = r; save(); }
  setVolume(v: number) { saved.volume = v; audio.volume = v; save(); }

  remember(done = false) {
    const e = this.episode, s = this.show;
    if (!e || !s || (this.time < 3 && !done)) return;
    this.#lastSave = Date.now();
    const d = this.duration;
    saved.progress[e.id] = { t: this.time, d, at: Date.now(), show: s.id, title: e.title, done: done || (d > 60 && this.time > d - 15) };
    save();
  }

  #start() {
    audio.play().catch((e: DOMException) => {
      if (e.name === 'AbortError') return; // another episode was chosen meanwhile
      this.waiting = false;
      if (e.name === 'NotAllowedError') this.playing = false;
    });
  }

  #length() {
    if (Number.isFinite(audio.duration) && audio.duration > 0) this.duration = audio.duration;
  }

  #session() {
    if (navigator.mediaSession) navigator.mediaSession.playbackState = this.playing ? 'playing' : 'paused';
  }

  #metadata() {
    if (!navigator.mediaSession || !this.show || !this.episode) return;
    navigator.mediaSession.metadata = new MediaMetadata({
      title: this.episode.title, artist: this.show.title, artwork: artwork(this.show) ? [{ src: new URL(artwork(this.show), location.href).href }] : [],
    });
  }
}

export const player = new Player();
