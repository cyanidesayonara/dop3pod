<script lang="ts">
  import type { DirectoryIndex } from '../../tools/catalog/types.ts';
  import { buildBrowseList, buildCategories, buildFavoriteShows, buildLanguages, buildResumeList, filterBrowse, languageLabel } from '../lib/browse.ts';
  import { artwork, clock, day, loadCatalog, loadShow, minutes, type Episode, type Show, type ShowCard } from '../lib/data.ts';
  import { loadDirectory } from '../lib/directory.ts';
  import { player } from '../lib/player.svelte.ts';
  import { saved, setView } from '../lib/saved.svelte.ts';
  import { removeFromQueue } from '../lib/queue.ts';
  import Cover from './Cover.svelte';
  import Dial from './Dial.svelte';

  let shows = $state.raw<ShowCard[]>([]);
  let directory = $state.raw<DirectoryIndex | null>(null);
  let failed = $state(false);
  let ready = $state(false);
  let dirReady = $state(false);
  let dirFailed = $state(false);
  let query = $state('');
  let category = $state('All');
  let language = $state('all');
  let shown = $state(30);
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
  void loadDirectory().then(
    (d) => {
      directory = d;
      dirReady = true;
    },
    () => {
      dirFailed = true;
    },
  );
  document.title = 'dopepod';

  const allShows = $derived(buildBrowseList(shows, directory));
  const favorites = $derived(buildFavoriteShows(allShows, saved.favorites, saved.favoriteShows));
  const categories = $derived(buildCategories(allShows));
  const dial = $derived([...(favorites.length ? ['Favorites'] : []), ...categories]);
  const current = $derived(dial.includes(category) ? category : 'All');
  const languages = $derived(buildLanguages(allShows));
  const currentLanguage = $derived(languages.some((l) => l.id === language) ? language : 'all');
  const categoryPool = $derived(
    current === 'Favorites' ? favorites : current === 'All' ? allShows : allShows.filter((s) => s.category === current),
  );
  const categoryCount = $derived(categoryPool.length);
  const languageCount = $derived(
    currentLanguage === 'all' ? allShows.length : allShows.filter((s) => s.language === currentLanguage).length,
  );
  const count = (n: number) => `${n.toLocaleString('en')} ${n === 1 ? 'podcast' : 'podcasts'}`;
  const filtered = $derived(filterBrowse(categoryPool, currentLanguage, query));

  $effect(() => {
    void query;
    void current;
    void currentLanguage;
    shown = 30;
  });

  const resume = $derived(buildResumeList(saved.progress, allShows, saved.favoriteShows, player.episode?.id));

  // The newest unplayed episodes of favorite shows, from the last 30 days.
  let news = $state.raw<{ show: Show; e: Episode }[]>([]);
  $effect(() => {
    const ids = favorites.map((s) => s.id);
    if (!ids.length) { news = []; return; }
    let active = true;
    news = news.filter(({ show }) => ids.includes(show.id));
    const loaded = new Map<string, Show>();
    const refresh = () => {
      if (!active) return;
      const since = new Date(Date.now() - 30 * 86_400_000).toISOString();
      news = [...loaded.values()]
        .flatMap((show) => show.episodes.slice(0, 5).map((e) => ({ show, e })))
        .filter(({ e }) => e.date && e.date > since)
        .sort((a, b) => b.e.date!.localeCompare(a.e.date!));
    };
    for (const id of ids) {
      void loadShow(id).then((show) => { loaded.set(id, show); refresh(); }, () => {});
    }
    return () => { active = false; };
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
  <Dial label="Category" options={dial.map((id) => ({ id, name: id === 'All' ? 'All categories' : id }))} bind:value={() => current, (v) => (category = v)} detail={ready ? count(categoryCount) : '…'} disabled={!ready} />
  <div class="pitch">
    <h1><span class="sr">dopepod: </span>Discover and listen to free podcasts on</h1>
    <p class="tiles" aria-hidden="true">{#each 'dopepod' as c, i (i)}<span>{c}</span>{/each}</p>
    <p>A lightweight player that runs in your browser. No account, no sign-up, nothing to install.</p>
  </div>
  <Dial label="Language" options={languages} bind:value={() => currentLanguage, (v) => (language = v)} detail={ready ? count(languageCount) : '…'} disabled={!ready} />
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
      <ul class="striped">
        {#each resume as r (r.id)}
          <li>
            <button class="resume" onclick={() => go(r.show.id, r.id)}>
              <Cover title={r.show.title} src={artwork(r.show)} size={56} />
              <span class="grow">
                <strong lang={r.show.language || undefined}>{r.p.title}</strong>
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
      <ol class="ranked">
        {#each saved.queue as q, i (q.id)}
          <li>
            <span class="dot" aria-hidden="true">{i + 1}</span>
            <button class="resume" onclick={() => go(q.show, q.id)}>
              <span class="grow"><strong>{q.title}</strong><span class="meta">{q.showTitle}</span></span>
            </button>
            <button class="link" aria-label="Remove {q.title} from the queue" onclick={() => removeFromQueue(q.id)}>Remove</button>
          </li>
        {/each}
      </ol>
    </section>
  {/if}
  {#if fresh.length}
    <section class="panel list" aria-labelledby="fresh">
      <h2 id="fresh">New from your favorites</h2>
      <ul class="striped">
        {#each fresh as f (f.e.id)}
          <li>
            <button class="resume" onclick={() => player.play(f.show, f.e)}>
              <Cover title={f.show.title} src={artwork(f.show)} size={56} />
              <span class="grow">
                <strong lang={f.show.language || undefined}>{f.e.title}</strong>
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
      <div class="bar-tools">
        <div class="view-toggle" role="group" aria-label="Layout">
          <button class="icon-btn" aria-pressed={saved.view === 'grid'} aria-label="Grid view" title="Grid view" onclick={() => setView('grid')}>
            <svg viewBox="0 0 24 24" aria-hidden="true"><rect x="3" y="3" width="7" height="7" /><rect x="14" y="3" width="7" height="7" /><rect x="3" y="14" width="7" height="7" /><rect x="14" y="14" width="7" height="7" /></svg>
          </button>
          <button class="icon-btn" aria-pressed={saved.view === 'list'} aria-label="List view" title="List view" onclick={() => setView('list')}>
            <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01" /></svg>
          </button>
        </div>
        <input type="search" placeholder="Search podcasts" aria-label="Search podcasts" bind:value={query} />
      </div>
    </div>
    <div class="chips" role="group" aria-label="Choose a category">
      {#each dial as c (c)}
        <button class="chip" aria-pressed={c === current} onclick={() => (category = c)}>{c}</button>
      {/each}
    </div>
    <div class="browse-meta">
      <p class="meta" role="status">
        {filtered.length.toLocaleString('en')} {query.trim() ? (filtered.length === 1 ? 'match' : 'matches') : (filtered.length === 1 ? 'podcast' : 'podcasts')}{#if !dirReady && !dirFailed} · Loading full directory…{/if}{#if dirFailed} · Showing featured shows only{/if}
      </p>
      <label class="lang-picker">
        <span class="sr">Language</span>
        <select aria-label="Language" bind:value={() => currentLanguage, (v) => (language = v)}>
          {#each languages as l (l.id)}
            <option value={l.id}>{l.id === 'all' ? l.name : `${l.name} (${l.count.toLocaleString('en')})`}</option>
          {/each}
        </select>
      </label>
    </div>
    {#if filtered.length}
      <ul class={saved.view === 'list' ? 'striped browse-list' : 'grid'}>
        {#each filtered.slice(0, shown) as s (s.id)}
          <li>
            <a class="card" href="#/show/{s.id}">
              <Cover title={s.title} src={artwork(s)} size={saved.view === 'list' ? 56 : 88} />
              <span class="grow">
                <strong lang={s.language || undefined}>{s.title}</strong>
                {#if saved.view === 'list'}
                  {@const info = [
                    s.author && s.author !== s.title ? `by ${s.author}` : '',
                    current === 'All' || current === 'Favorites' ? s.category : '',
                    currentLanguage === 'all' ? languageLabel(s.language) : '',
                    s.latest ? `Latest ${day(s.latest)}` : '',
                  ].filter(Boolean).join(' · ')}
                  {#if info || s.explicit}
                    <span class="meta">{info}{#if info && s.explicit} · {/if}{#if s.explicit}<span class="badge" aria-hidden="true">E</span><span class="sr">Explicit</span>{/if}</span>
                  {/if}
                  {#if s.description}<span class="meta">{s.description}</span>{/if}
                {:else}
                  {#if s.author && s.author !== s.title}<span class="meta">by {s.author}</span>{/if}
                  {@const sub = [
                    current === 'All' || current === 'Favorites' ? s.category : '',
                    currentLanguage === 'all' ? languageLabel(s.language) : '',
                    s.latest ? `Latest ${day(s.latest)}` : '',
                  ].filter(Boolean).join(' · ')}
                  {#if sub || s.explicit}
                    <span class="meta">{sub}{#if sub && s.explicit} · {/if}{#if s.explicit}<span class="badge" aria-hidden="true">E</span><span class="sr">Explicit</span>{/if}</span>
                  {/if}
                {/if}
              </span>
            </a>
          </li>
        {/each}
      </ul>
      {#if filtered.length > shown}
        <p class="more"><button class="btn" onclick={() => (shown += 30)}>Show more ({(filtered.length - shown).toLocaleString('en')} left)</button></p>
      {/if}
    {:else}
      <p class="notice" role="status">{query.trim() ? `No podcasts match “${query}”.` : 'No podcasts here yet. Try another category or language.'}</p>
    {/if}
  </section>
{/if}
