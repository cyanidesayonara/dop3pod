<script lang="ts">
  import { artwork, clock, day, loadCatalog, loadShow, minutes, type Episode, type Show, type ShowCard } from '../lib/data.ts';
  import { player } from '../lib/player.svelte.ts';
  import { saved } from '../lib/saved.svelte.ts';
  import { removeFromQueue } from '../lib/queue.ts';
  import Cover from './Cover.svelte';
  import Dial from './Dial.svelte';

  let shows = $state.raw<ShowCard[]>([]);
  let failed = $state(false);
  let ready = $state(false);
  let query = $state('');
  let category = $state('All');
  let language = $state('all');
  let problem = $state('');

  async function load() {
    failed = false;
    try {
      shows = (await loadCatalog()).shows;
      ready = true;
    } catch {
      failed = true;
    }
  }
  void load();
  document.title = 'dopepod';

  const categories = $derived(['All', ...new Set(shows.map((s) => s.category))]);
  const favorites = $derived(shows.filter((s) => saved.favorites.includes(s.id)));
  const dial = $derived([...(favorites.length ? ['Favorites'] : []), ...categories]);
  const current = $derived(dial.includes(category) ? category : 'All');
  const NAMES: Record<string, string> = { en: 'English', fi: 'Suomi', es: 'Español', ca: 'Català' };
  const languages = $derived([
    { id: 'all', name: 'All languages' },
    ...[...new Set(shows.map((s) => s.language))].map((id) => ({ id, name: NAMES[id] ?? id })),
  ]);
  const speaks = (s: ShowCard) => language === 'all' || s.language === language;
  const inCategory = (s: ShowCard) => current === 'All' || (current === 'Favorites' ? saved.favorites.includes(s.id) : s.category === current);
  const count = (n: number) => `${n} ${n === 1 ? 'podcast' : 'podcasts'}`;
  const filtered = $derived.by(() => {
    const q = query.trim().toLowerCase();
    return shows.filter((s) => inCategory(s) && speaks(s)).filter((s) => !q || `${s.title} ${s.author} ${s.description}`.toLowerCase().includes(q));
  });
  const resume = $derived(
    Object.entries(saved.progress)
      .filter(([id, p]) => !p.done && !player.isCurrent(id) && shows.some((s) => s.id === p.show))
      .sort((a, b) => b[1].at - a[1].at)
      .slice(0, 4)
      .map(([id, p]) => ({ id, p, show: shows.find((s) => s.id === p.show)! })),
  );

  // The newest unplayed episodes of favorite shows, from the last 30 days.
  let news = $state.raw<{ show: Show; e: Episode }[]>([]);
  $effect(() => {
    const ids = favorites.map((s) => s.id);
    let current = true;
    void Promise.allSettled(ids.map(loadShow)).then((r) => {
      if (!current) return;
      const since = new Date(Date.now() - 30 * 86_400_000).toISOString();
      news = r
        .flatMap((x) => (x.status === 'fulfilled' ? x.value.episodes.slice(0, 5).map((e) => ({ show: x.value, e })) : []))
        .filter(({ e }) => e.date && e.date > since)
        .sort((a, b) => b.e.date!.localeCompare(a.e.date!));
    });
    return () => { current = false; };
  });
  const fresh = $derived(news.filter(({ e }) => !saved.progress[e.id] && !player.isCurrent(e.id)).slice(0, 5));

  async function go(showId: string, episodeId: string) {
    problem = '';
    try {
      const s = await loadShow(showId);
      const e = s.episodes.find((x) => x.id === episodeId);
      if (e) player.play(s, e);
      else problem = 'That episode is no longer in the catalog.';
    } catch {
      problem = "Couldn't load that show. Check your connection.";
    }
  }
</script>

<section class="hero panel">
  <Dial label="Category" options={dial.map((id) => ({ id, name: id === 'All' ? 'All categories' : id }))} bind:value={() => current, (v) => (category = v)} detail={ready ? count(shows.filter(inCategory).length) : '…'} disabled={!ready} />
  <div class="pitch">
    <h1><span class="sr">dopepod: </span>Discover and listen to free podcasts on</h1>
    <p class="tiles" aria-hidden="true">{#each 'dopepod' as c, i (i)}<span>{c}</span>{/each}</p>
    <p>A lightweight player that runs in your browser. No account, no sign-up, nothing to install.</p>
  </div>
  <Dial label="Language" options={languages} bind:value={language} detail={ready ? count(shows.filter(speaks).length) : '…'} disabled={!ready} />
</section>

{#if failed}
  <div class="notice" role="alert">
    <p>Couldn't load the catalog. Check your connection.</p>
    <button class="btn" onclick={load}>Try again</button>
  </div>
{:else if !ready}
  <p class="notice" role="status">Loading podcasts…</p>
{:else}
  {#if problem}<p class="notice" role="alert">{problem}</p>{/if}
  {#if resume.length}
    <section class="panel list" aria-labelledby="resume">
      <h2 id="resume">Continue listening</h2>
      <ul>
        {#each resume as r (r.id)}
          <li>
            <button class="resume" onclick={() => go(r.show.id, r.id)}>
              <Cover title={r.show.title} src={artwork(r.show)} size={56} />
              <span class="grow">
                <strong>{r.p.title}</strong>
                <span class="meta">{r.show.title} · {clock(r.p.t)}{r.p.d ? ` of ${clock(r.p.d)}` : ''}</span>
                {#if r.p.d}<span class="bar"><span style:width="{Math.min(100, (r.p.t / r.p.d) * 100)}%"></span></span>{/if}
              </span>
            </button>
          </li>
        {/each}
      </ul>
    </section>
  {/if}

  {#if saved.queue.length}
    <section class="panel list" aria-labelledby="queue">
      <h2 id="queue">Up next</h2>
      <ul>
        {#each saved.queue as q (q.id)}
          <li class="row">
            <button class="resume" onclick={() => go(q.show, q.id)}>
              <span class="grow"><strong>{q.title}</strong><span class="meta">{q.showTitle}</span></span>
            </button>
            <button class="link" aria-label="Remove {q.title} from the queue" onclick={() => removeFromQueue(q.id)}>Remove</button>
          </li>
        {/each}
      </ul>
    </section>
  {/if}
  {#if fresh.length}
    <section class="panel list" aria-labelledby="fresh">
      <h2 id="fresh">New from your favorites</h2>
      <ul>
        {#each fresh as f (f.e.id)}
          <li>
            <button class="resume" onclick={() => player.play(f.show, f.e)}>
              <Cover title={f.show.title} src={artwork(f.show)} size={56} />
              <span class="grow">
                <strong lang={f.show.language}>{f.e.title}</strong>
                <span class="meta">{[f.show.title, day(f.e.date), minutes(f.e.duration)].filter(Boolean).join(' · ')}</span>
              </span>
            </button>
          </li>
        {/each}
      </ul>
    </section>
  {/if}

  <section class="panel list" aria-labelledby="browse">
    <div class="bar-head">
      <h2 id="browse">{current === 'All' ? 'All podcasts' : current}</h2>
      <input type="search" placeholder="Filter podcasts" aria-label="Filter podcasts" bind:value={query} />
    </div>
    <div class="chips" role="group" aria-label="Choose a category">
      {#each dial as c (c)}
        <button class="chip" aria-pressed={c === current} onclick={() => (category = c)}>{c}</button>
      {/each}
    </div>
    {#if filtered.length}
      <ul class="grid">
        {#each filtered as s (s.id)}
          <li>
            <a class="card" href="#/show/{s.id}">
              <Cover title={s.title} src={artwork(s)} size={88} />
              <span class="grow">
                <strong lang={s.language}>{s.title}</strong>
                {#if s.author && s.author !== s.title}<span class="meta">by {s.author}</span>{/if}
                {#if s.latest}<span class="meta">Latest {day(s.latest)}</span>{/if}
              </span>
            </a>
          </li>
        {/each}
      </ul>
    {:else}
      <p class="notice" role="status">{query.trim() ? `No podcasts match “${query}”.` : 'No podcasts here yet. Try another category or language.'}</p>
    {/if}
  </section>
{/if}
