<script lang="ts">
  import { artwork, clock, day, loadCatalog, loadShow, type ShowCard } from '../lib/data.ts';
  import { player } from '../lib/player.svelte.ts';
  import { saved } from '../lib/saved.svelte.ts';
  import Cover from './Cover.svelte';

  let shows = $state.raw<ShowCard[]>([]);
  let failed = $state(false);
  let ready = $state(false);
  let query = $state('');
  let category = $state('All');
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
  const at = $derived(Math.max(0, dial.indexOf(category)));
  const current = $derived(dial[at] ?? 'All');
  const inDial = (c: string) => (c === 'All' ? shows : c === 'Favorites' ? favorites : shows.filter((s) => s.category === c));
  const filtered = $derived.by(() => {
    const q = query.trim().toLowerCase();
    return inDial(current).filter((s) => !q || `${s.title} ${s.author} ${s.description}`.toLowerCase().includes(q));
  });
  const resume = $derived(
    Object.entries(saved.progress)
      .filter(([id, p]) => !p.done && !player.isCurrent(id) && shows.some((s) => s.id === p.show))
      .sort((a, b) => b[1].at - a[1].at)
      .slice(0, 4)
      .map(([id, p]) => ({ id, p, show: shows.find((s) => s.id === p.show)! })),
  );

  const turn = (n: number) => (category = dial[(at + n + dial.length) % dial.length]);

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
  <div class="pitch">
    <h1><span class="sr">dopepod: </span>Discover and listen to free podcasts on</h1>
    <p class="tiles" aria-hidden="true">{#each 'dopepod' as c, i (i)}<span>{c}</span>{/each}</p>
    <p>A lightweight player that runs in your browser. No account, no sign-up, nothing to install.</p>
  </div>
  <div class="dial" role="group" aria-label="Category">
    <button class="square" onclick={() => turn(-1)} aria-label="Previous category" disabled={!ready}>
      <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M6 15l6-6 6 6" /></svg>
    </button>
    <div class="circle" aria-live="polite">
      <strong>{current}</strong>
      <span>{ready ? `${inDial(current).length} ${inDial(current).length === 1 ? 'podcast' : 'podcasts'}` : '…'}</span>
    </div>
    <button class="square" onclick={() => turn(1)} aria-label="Next category" disabled={!ready}>
      <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M6 9l6 6 6-6" /></svg>
    </button>
  </div>
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
                <strong>{s.title}</strong>
                {#if s.author && s.author !== s.title}<span class="meta">by {s.author}</span>{/if}
                {#if s.latest}<span class="meta">Latest {day(s.latest)}</span>{/if}
              </span>
            </a>
          </li>
        {/each}
      </ul>
    {:else}
      <p class="notice" role="status">No podcasts match “{query}”.</p>
    {/if}
  </section>
{/if}
