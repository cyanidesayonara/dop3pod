<script lang="ts">
  import type { DirectoryIndex } from '../../tools/catalog/types.ts';
  import { loadDirectory } from '../lib/directory.ts';
  import type { BrowseView } from '../lib/saved.svelte.ts';
  import Cover from './Cover.svelte';

  let { query, category, language, view = 'grid' }: { query: string; category: string; language: string; view?: BrowseView } = $props();
  let index = $state.raw<DirectoryIndex | null>(null);
  let failed = $state(false);
  let limit = $state(30);

  $effect(() => {
    if (index || failed) return;
    loadDirectory().then((d) => (index = d), () => (failed = true));
  });
  $effect(() => { void query; void category; void language; limit = 30; });

  const fold = (s: string) => s.normalize('NFD').replace(/\p{M}/gu, '').toLowerCase();
  const results = $derived.by(() => {
    const q = fold(query.trim());
    if (!index || q.length < 2) return [];
    const cat = index.categories.indexOf(category);
    const lang = index.languages.indexOf(language);
    const out: { s: DirectoryIndex['shows'][number]; rank: number }[] = [];
    for (const s of index.shows) {
      if ((category !== 'All' && s[4] !== cat) || (language !== 'all' && s[3] !== lang)) continue;
      const t = fold(s[1]);
      const rank = t === q ? 0 : t.startsWith(q) ? 1 : t.includes(q) ? 2 : fold(s[2]).includes(q) ? 3 : -1;
      if (rank >= 0) out.push({ s, rank });
    }
    return out.sort((a, b) => a.rank - b.rank || b.s[7] - a.s[7]).map((x) => x.s);
  });
  const names = new Intl.DisplayNames(['en'], { type: 'language' });
  const languageName = (code: string) => { try { return code ? names.of(code) ?? code : ''; } catch { return code; } };
</script>

{#if query.trim().length >= 2}
  <section class="panel list" aria-labelledby="directory">
    <div class="bar-head"><h2 id="directory">More podcasts</h2></div>
    {#if failed}
      <p class="notice" role="alert">Couldn't load the directory. Check your connection.</p>
    {:else if !index}
      <p class="notice" role="status">Searching {category === 'All' ? '' : `${category} `}podcasts…</p>
    {:else if results.length}
      <p class="meta count" role="status">{results.length} {results.length === 1 ? 'match' : 'matches'} among {index.shows.length.toLocaleString('en')} popular shows</p>
      <ul class={view === 'list' ? 'striped browse-list' : 'grid'}>
        {#each results.slice(0, limit) as s (s[0])}
          <li>
            <a class="card" href="#/show/d-{s[0]}">
              <Cover title={s[1]} src={s[5]} size={view === 'list' ? 56 : 72} />
              <span class="grow">
                <strong lang={index.languages[s[3]] || undefined}>{s[1]}</strong>
                {#if s[2] && s[2] !== s[1]}<span class="meta">by {s[2]}</span>{/if}
                <span class="meta">{[index.categories[s[4]], languageName(index.languages[s[3]])].filter(Boolean).join(' · ')}{#if s[6]} · <span class="badge" aria-hidden="true">E</span><span class="sr">Explicit</span>{/if}</span>
              </span>
            </a>
          </li>
        {/each}
      </ul>
      {#if results.length > limit}
        <p class="more"><button class="btn" onclick={() => (limit += 30)}>Show more ({results.length - limit} left)</button></p>
      {/if}
    {:else}
      <p class="notice" role="status">No other podcasts match “{query}”.</p>
    {/if}
  </section>
{/if}
