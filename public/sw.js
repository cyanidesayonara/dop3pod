// Keeps the app shell working offline. Audio and covers come from other sites and are never cached here.
const CACHE = 'dopepod-1';
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (e) => e.waitUntil(
  caches.keys().then((ks) => Promise.all(ks.filter((k) => k.startsWith('dopepod-') && k !== CACHE).map((k) => caches.delete(k)))).then(() => self.clients.claim()),
));
self.addEventListener('fetch', (e) => {
  const u = new URL(e.request.url);
  if (e.request.method !== 'GET' || u.origin !== location.origin || !u.href.startsWith(self.registration.scope)) return;
  e.respondWith((async () => {
    const c = await caches.open(CACHE);
    const hashed = u.pathname.includes('/assets/');
    const hit = await c.match(e.request);
    if (hit && hashed) return hit;
    try {
      const r = await fetch(e.request);
      if (r.ok) e.waitUntil(c.put(e.request, r.clone()));
      return r;
    } catch (err) {
      if (hit) return hit;
      throw err;
    }
  })());
});
