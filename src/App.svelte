<script lang="ts">
  import { tick } from 'svelte';
  import ChartsPage from './components/ChartsPage.svelte';
  import History from './components/History.svelte';
  import Home from './components/Home.svelte';
  import PlayerBar from './components/PlayerBar.svelte';
  import ShowPage from './components/ShowPage.svelte';
  import { player } from './lib/player.svelte.ts';
  import { advance, removeFromQueue } from './lib/queue.ts';
  import { applyTheme, save, saved } from './lib/saved.svelte.ts';

  type Route = { name: 'home' } | { name: 'played' } | { name: 'charts'; list: string } | { name: 'show'; id: string; episode: string };
  function parse(): Route {
    const [, kind, id = '', episode = ''] = location.hash.replace(/^#/, '').split('/');
    if (kind === 'played') return { name: 'played' };
    if (kind === 'charts') return { name: 'charts', list: id };
    return kind === 'show' && id ? { name: 'show', id, episode } : { name: 'home' };
  }

  let route = $state.raw<Route>(parse());
  let main: HTMLElement;

  async function changed() {
    route = parse();
    await tick();
    window.scrollTo(0, 0);
    main.focus({ preventScroll: true });
  }

  player.advance = () => void advance();
  $effect(() => { if (player.episode) removeFromQueue(player.episode.id); });

  applyTheme();
  // One click always flips what you see. Until the first click the theme follows the system.
  const systemScheme = matchMedia('(prefers-color-scheme: dark)');
  let systemDark = $state(systemScheme.matches);
  systemScheme.addEventListener('change', (e) => (systemDark = e.matches));
  const dark = $derived(saved.theme === 'dark' || (saved.theme === 'auto' && systemDark));
  function toggleTheme() {
    saved.theme = dark ? 'light' : 'dark';
    applyTheme();
    save();
  }

  function keys(e: KeyboardEvent) {
    if (e.ctrlKey || e.metaKey || e.altKey || e.defaultPrevented || !player.episode) return;
    const el = e.target as HTMLElement;
    if (el.closest('input, select, textarea, [contenteditable]')) return;
    if (e.key === 'k' || (e.key === ' ' && !el.closest('button, a, summary'))) player.toggle();
    else if (e.key === 'j') player.skip(-15);
    else if (e.key === 'l') player.skip(30);
    else return;
    e.preventDefault();
  }
</script>

<svelte:window onhashchange={changed} onkeydown={keys} />

<a class="skip" href="#main" onclick={(e) => { e.preventDefault(); main.focus(); }}>Skip to content</a>
<header class="top">
  <nav class="top-links" aria-label="Main">
    <a href="#/" aria-current={route.name === 'home' ? 'page' : undefined}>Browse</a>
    <a href="#/charts" aria-current={route.name === 'charts' ? 'page' : undefined}>Charts</a>
    <a href="#/played" aria-current={route.name === 'played' ? 'page' : undefined}>Last played</a>
  </nav>
  <a class="wordmark" href="#/" aria-label="dopepod home">dopepod</a>
  <button class="icon-btn theme" onclick={toggleTheme} aria-label={dark ? 'Switch to light theme' : 'Switch to dark theme'} title={dark ? 'Switch to light theme' : 'Switch to dark theme'}>
    <svg viewBox="0 0 24 24" aria-hidden="true" class:lit={!dark}>
      <path d="M9 18h6M10 21h4M12 3a6 6 0 0 0-3.6 10.8c.6.5 1 1.2 1 2V16h5.2v-.2c0-.8.4-1.5 1-2A6 6 0 0 0 12 3z" />
    </svg>
  </button>
</header>

<main id="main" tabindex="-1" bind:this={main}>
  {#if route.name === 'show'}
    {#key route.id}<ShowPage id={route.id} linked={route.episode} />{/key}
  {:else if route.name === 'charts'}
    <ChartsPage list={route.list} />
  {:else if route.name === 'played'}
    <History />
  {:else}
    <Home />
  {/if}
</main>

<footer class:with-player={player.episode}>
  Episodes stream straight from their publishers. dopepod stores nothing about you outside this browser.
  <a href="https://github.com/cyanidesayonara/dop3pod">Source</a>
</footer>

<PlayerBar />
