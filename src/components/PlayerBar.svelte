<script lang="ts">
  import { artwork, clock } from '../lib/data.ts';
  import { player } from '../lib/player.svelte.ts';
  import { saved } from '../lib/saved.svelte.ts';
  import Cover from './Cover.svelte';

  const RATES = [0.75, 1, 1.25, 1.5, 1.75, 2];
  let drag = $state<number | null>(null);
  const shown = $derived(drag ?? player.time);
  const pct = $derived(player.duration ? Math.min(100, (shown / player.duration) * 100) : 0);
</script>

{#if player.episode && player.show}
  <section class="player" aria-label="Player">
    {#if player.error}
      <p class="player-error" role="alert">
        {player.error}
        <button class="link" onclick={() => player.retry()}>Try again</button>
        {#if player.show.link}<a href={player.show.link} target="_blank" rel="noopener noreferrer">Show website</a>{/if}
      </p>
    {/if}
    <input
      class="seek" type="range" min="0" max={Math.max(1, Math.floor(player.duration))} step="1" value={shown} style:--p="{pct}%"
      aria-label="Seek" aria-valuetext="{clock(shown)} of {clock(player.duration)}"
      oninput={(e) => (drag = e.currentTarget.valueAsNumber)}
      onchange={(e) => { player.seek(e.currentTarget.valueAsNumber); drag = null; }}
    />
    <div class="player-row">
      <a class="now-playing" href="#/show/{player.show.id}/{player.episode.id}">
        <Cover title={player.show.title} src={artwork(player.show)} size={48} />
        <span class="grow">
          <strong>{player.episode.title}</strong>
          <span class="meta">{player.waiting && !player.error ? 'Loading…' : player.show.title}</span>
        </span>
      </a>
      <div class="controls">
        <button class="icon-btn opt" disabled={!player.previous} aria-label="Older episode" title="Older episode" onclick={() => player.play(player.show!, player.previous!)}>
          <svg viewBox="0 0 24 24" aria-hidden="true"><path class="fill" d="M6 5h2v14H6zM20 5v14L9 12z" /></svg>
        </button>
        <button class="icon-btn num" aria-label="Back 15 seconds" title="Back 15 seconds (J)" onclick={() => player.skip(-15)}>−15</button>
        <button class="round big" aria-label={player.playing ? 'Pause' : 'Play'} title="Play or pause (K)" onclick={() => player.toggle()}>
          <svg viewBox="0 0 24 24" aria-hidden="true">
            {#if player.playing}<path class="fill" d="M7 5h4v14H7zM13 5h4v14h-4z" />{:else}<path class="fill" d="M8 5v14l11-7z" />{/if}
          </svg>
        </button>
        <button class="icon-btn num" aria-label="Forward 30 seconds" title="Forward 30 seconds (L)" onclick={() => player.skip(30)}>+30</button>
        <button class="icon-btn opt" disabled={!player.next} aria-label="Newer episode" title="Newer episode" onclick={() => player.play(player.show!, player.next!)}>
          <svg viewBox="0 0 24 24" aria-hidden="true"><path class="fill" d="M16 5h2v14h-2zM4 5v14l11-7z" /></svg>
        </button>
      </div>
      <div class="extras">
        <span class="time">{clock(shown)} / {clock(player.duration)}</span>
        <select aria-label="Speed" value={saved.rate} onchange={(e) => player.setRate(Number(e.currentTarget.value))}>
          {#each RATES as r (r)}<option value={r}>{r}×</option>{/each}
        </select>
        <input class="volume" type="range" min="0" max="1" step="0.05" value={saved.volume} style:--p="{saved.volume * 100}%" aria-label="Volume" oninput={(e) => player.setVolume(e.currentTarget.valueAsNumber)} />
      </div>
    </div>
  </section>
{/if}
