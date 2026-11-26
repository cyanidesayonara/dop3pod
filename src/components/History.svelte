<script lang="ts">
  import { clock, day } from '../lib/data.ts';
  import { save, saved } from '../lib/saved.svelte.ts';

  document.title = 'Last played · dopepod';
  const played = $derived(Object.entries(saved.progress).sort((a, b) => b[1].at - a[1].at).slice(0, 50));

  function clear() {
    if (!confirm('Forget everything you have played in this browser?')) return;
    saved.progress = {};
    save();
  }
</script>

<section class="panel list" aria-labelledby="played">
  <div class="bar-head">
    <h1 id="played">Last played</h1>
    {#if played.length}<button class="btn on-teal" onclick={clear}>Clear</button>{/if}
  </div>
  {#if played.length}
    <ol class="ranked">
      {#each played as [id, p], i (id)}
        <li>
          <span class="dot" aria-hidden="true">{i + 1}</span>
          <a class="grow" href="#/show/{p.show}/{id}">
            <strong>{p.title}</strong>
            <span class="meta">{p.done ? 'Played' : `${clock(p.t)}${p.d ? ` of ${clock(p.d)}` : ''}`} · {day(new Date(p.at).toISOString())}</span>
          </a>
        </li>
      {/each}
    </ol>
  {:else}
    <p class="notice" role="status">Nothing yet. Episodes you play appear here.</p>
  {/if}
</section>
