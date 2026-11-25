<script lang="ts">
  import { tick } from 'svelte';
  import { artwork, day, loadShow, minutes, type Episode, type Show } from '../lib/data.ts';
  import { player } from '../lib/player.svelte.ts';
  import { saved, toggleFavorite } from '../lib/saved.svelte.ts';
  import Cover from './Cover.svelte';

  let { id, linked }: { id: string; linked: string } = $props();
  let show = $state.raw<Show | null>(null);
  let failed = $state(false);
  let query = $state('');
  let copied = $state('');

  async function load() {
    failed = false;
    try {
      show = await loadShow(id);
      document.title = `${show.title} · dopepod`;
      await tick();
      if (linked) document.getElementById(`e-${linked}`)?.scrollIntoView({ block: 'center' });
    } catch {
      failed = true;
    }
  }
  // svelte-ignore state_referenced_locally -- App keys this component by id
  void load();

  const favorite = $derived(saved.favorites.includes(id));
  const episodes = $derived.by(() => {
    const q = query.trim().toLowerCase();
    return (show?.episodes ?? []).filter((e) => !q || `${e.title} ${e.summary}`.toLowerCase().includes(q));
  });

  function status(e: Episode) {
    const p = saved.progress[e.id];
    if (!p) return '';
    if (p.done) return 'Played';
    const left = p.d - p.t;
    return left > 0 ? `${minutes(left)} left` : '';
  }

  async function share(e: Episode) {
    const url = `${location.href.split('#')[0]}#/show/${id}/${e.id}`;
    try {
      await navigator.clipboard.writeText(url);
      copied = e.id;
      setTimeout(() => { if (copied === e.id) copied = ''; }, 2000);
    } catch {
      location.hash = `/show/${id}/${e.id}`;
    }
  }
</script>

<a class="back" href="#/">← All podcasts</a>
{#if failed}
  <div class="notice" role="alert">
    <p>Couldn't load this podcast. It may have left the catalog.</p>
    <button class="btn" onclick={load}>Try again</button>
  </div>
{:else if !show}
  <p class="notice" role="status">Loading…</p>
{:else}
  {@const s = show}
  <section class="panel show-head">
    <Cover title={s.title} src={artwork(s)} size={160} />
    <div class="grow">
      <h1>{s.title}</h1>
      {#if s.author && s.author !== s.title}<p class="meta">by {s.author}</p>{/if}
      <p>{s.description}</p>
      <p class="actions">
        <button class="btn" aria-pressed={favorite} onclick={() => toggleFavorite(id)}>{favorite ? '★ Favorite' : '☆ Add to favorites'}</button>
        {#if s.link}<a class="btn ghost" href={s.link} target="_blank" rel="noopener noreferrer">Show website</a>{/if}
      </p>
      {#if s.stale}<p class="meta">The latest update failed, so newer episodes may be missing.</p>{/if}
    </div>
  </section>

  <section class="panel list" aria-labelledby="episodes">
    <div class="bar-head">
      <h2 id="episodes">Episodes</h2>
      <input type="search" placeholder="Filter episodes" aria-label="Filter episodes" bind:value={query} />
    </div>
    <ul>
      {#each episodes as e (e.id)}
        {@const now = player.isCurrent(e.id)}
        <li class="episode" class:now class:linked={e.id === linked} id="e-{e.id}">
          <button class="round" onclick={() => player.play(s, e)} aria-label="{now && player.playing ? 'Pause' : 'Play'} {e.title}">
            <svg viewBox="0 0 24 24" aria-hidden="true">
              {#if now && player.playing}<path class="fill" d="M7 5h4v14H7zM13 5h4v14h-4z" />{:else}<path class="fill" d="M8 5v14l11-7z" />{/if}
            </svg>
          </button>
          <div class="grow">
            <strong>{e.title}</strong>
            <p class="meta">{[day(e.date), status(e) || minutes(e.duration)].filter(Boolean).join(' · ')}</p>
            {#if e.summary}
              <details><summary>About<span class="sr"> {e.title}</span></summary><p>{e.summary}</p></details>
            {/if}
          </div>
          <button class="link" onclick={() => share(e)} aria-label="Copy link to {e.title}">{copied === e.id ? 'Copied' : 'Link'}</button>
        </li>
      {:else}
        <li class="notice" role="status">No episodes match “{query}”.</li>
      {/each}
    </ul>
  </section>
{/if}
<span class="sr" role="status">{copied ? 'Link copied' : ''}</span>
