# dopepod

A lightweight podcast player that runs entirely in your browser. No account, no server, nothing to install.

Browse a hand-picked catalog in four languages, queue episodes, change speed, set a sleep timer, keep favorites and
pick up where you left off.
Everything it remembers stays in your browser.

## How it works

- **No backend.** The site is static files on GitHub Pages, written in TypeScript and Svelte.
- **A daily catalog.** Browsers may not read many podcast feeds directly, so a scheduled GitHub Action reads the
  feeds in [`catalog/shows.json`](catalog/shows.json) and publishes small JSON files and cover thumbnails.
  A show that fails keeps its last good episodes.
- **A searchable directory.** Once a month the same Action builds an index of about 27,000 popular, active shows from
  [Podcast Index](https://podcastindex.org)'s public data dump. Opening one reads its feed in the browser when the
  publisher allows it; otherwise its latest episode still plays.
- **New and rising charts.** Once a day the Action asks Podcast Index's API for trending shows, overall and by category and language.
  The API key is a GitHub Actions secret used only by the Action; the site only receives the finished lists.
- **Audio comes straight from the publishers.** No audio is copied or re-hosted.
- **Feeds are untrusted.** [`tools/catalog/rss.ts`](tools/catalog/rss.ts) tolerates broken XML, expands no custom
  entities, accepts only https audio, and reduces every description to plain text.

## Run it

Needs Node 22.18 or newer.

```sh
npm install
npm run catalog   # reads the feeds into public/data
npm run dev
```

`npm test` runs the catalog tests. `npm run build` type-checks and builds into `dist/`.
Keys while listening: <kbd>K</kbd> play or pause, <kbd>J</kbd> back 15 seconds, <kbd>L</kbd> forward 30.

## Earlier versions

1. [dopepod](https://github.com/cyanidesayonara/dopepod): a Django and jQuery web app that began as a CS50 final project.
2. dop3pod: a Django REST Framework, Celery and Scrapy backend with a Flutter app. Its code is in this repository's
   history, up to commit [`92ffd4c`](https://github.com/cyanidesayonara/dop3pod/tree/92ffd4c002a9dc4c05a3980c5833b6c2e61c82ef).
3. This one, with the original look and no servers to look after.

## License

[MIT](LICENSE). The Orbitron and Exo 2 fonts are under the SIL Open Font License; see [`public/fonts`](public/fonts).
Podcast titles, covers and audio belong to their publishers.
