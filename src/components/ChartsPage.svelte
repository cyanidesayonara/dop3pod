<script lang="ts">
  import type { Charts } from '../../tools/catalog/types.ts';
  import { loadCharts } from '../lib/directory.ts';
  import Cover from './Cover.svelte';

  let { list }: { list: string } = $props();
  let charts = $state.raw<Charts | null>(null);
  let failed = $state(false);

  function load() {
    failed = false;
    loadCharts().then((c) => (charts = c), () => (failed = true));
  }
  load();

  const current = $derived(charts?.lists.find((l) => l.id === list) ?? charts?.lists[0]);
  $effect(() => { document.title = `New and rising${current && current.id !== 'all' ? `: ${current.label}` : ''} · dopepod`; });
  const groups = $derived([
    { label: 'Categories', lists: charts?.lists.filter((l) => !l.id.startsWith('l-')) ?? [] },
    { label: 'Languages', lists: charts?.lists.filter((l) => l.id.startsWith('l-')) ?? [] },
  ]);
  const names = new Intl.DisplayNames(['en'], { type: 'language' });
  const languageName = (code: string) => { try { return code ? names.of(code) ?? code : ''; } catch { return code; } };
</script>

<section class="panel list" aria-labelledby="charts">
  <div class="bar-head">
    <h1 id="charts">New and rising{current && current.id !== 'all' ? `: ${current.label}` : ''}</h1>
  </div>
  {#if failed}
    <div class="notice" role="alert">
      <p>Couldn't load the charts. Check your connection.</p>
      <button class="btn" onclick={load}>Try again</button>
    </div>
  {:else if !charts}
    <p class="notice" role="status">Loading charts…</p>
  {:else if !current}
    <p class="notice" role="status">No charts yet. They're updated once a day.</p>
  {:else}
    <p class="meta count">Shows growing fastest right now, so expect new and unfamiliar names.</p>
    {#each groups as g (g.label)}
      {#if g.lists.length}
        <div class="chips" role="group" aria-label={g.label}>
          {#each g.lists as l (l.id)}
            <a class="chip" href="#/charts/{l.id}" aria-current={l.id === current.id ? 'page' : undefined}>{l.label}</a>
          {/each}
        </div>
      {/if}
    {/each}
    <ol class="ranked charts">
      {#each current.items as item, i (item.show)}
        <li>
          <span class="dot" aria-hidden="true">{i + 1}</span>
          <a class="card" href="#/show/{item.show}">
            <Cover title={item.title} src={item.image} size={64} />
            <span class="grow">
              <strong lang={item.language || undefined}>{item.title}</strong>
              {#if item.author && item.author !== item.title}<span class="meta">by {item.author}</span>{/if}
              {#if item.language || item.explicit}<span class="meta">{languageName(item.language)}{#if item.language && item.explicit} · {/if}{#if item.explicit}<span class="badge" aria-hidden="true">E</span><span class="sr">Explicit</span>{/if}</span>{/if}
            </span>
          </a>
        </li>
      {/each}
    </ol>
    <p class="meta count">Trending on <a href="https://podcastindex.org" target="_blank" rel="noopener noreferrer">Podcast Index</a>, updated {new Intl.DateTimeFormat('en', { month: 'short', day: 'numeric' }).format(new Date(charts.generated))}.</p>
  {/if}
</section>
