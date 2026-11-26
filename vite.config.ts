import { svelte } from '@sveltejs/vite-plugin-svelte';
import { defineConfig } from 'vite';

// Only in the built page: the dev server needs a websocket and inline scripts.
const csp = [
  "default-src 'self'", "img-src 'self' https: data:", 'media-src https:', "style-src 'self' 'unsafe-inline'",
  "connect-src 'self' https:", "base-uri 'none'", "form-action 'none'", "object-src 'none'",
].join('; ');

export default defineConfig({
  base: './',
  plugins: [
    svelte(),
    {
      name: 'csp',
      apply: 'build',
      transformIndexHtml: () => [
        { tag: 'meta', attrs: { 'http-equiv': 'Content-Security-Policy', content: csp }, injectTo: 'head-prepend' },
      ],
    },
  ],
});
