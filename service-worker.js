const CACHE_PREFIX = 'consistifit-playable-';
const CACHE = `${CACHE_PREFIX}__BUILD_ID__`;
const CORE = [
  './', './index.html', './styles.css', './plan-builder.css', './exercise-guides.css', './workout-nav.css', './demo-depth.css', './demo-cosmetics.css', './demo-2.css', './core-loop.css', './premium-ui.css', './demo-app.js', './plan-builder.js', './exercise-library.js', './workout-nav.js', './demo-depth.js', './demo-cosmetics.js', './demo-2.js', './core-loop.js', './workout-override.js', './ux-experience.js', './ux-experience.css', './premium-ui.js', './offline.html', './manifest.webmanifest',
  './assets/icons/icon-192.png', './assets/icons/icon-512.png', './assets/icons/apple-touch-icon.png'
];
self.addEventListener('install', event => {
  event.waitUntil(caches.open(CACHE).then(cache => cache.addAll(CORE)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', event => {
  event.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(key => key.startsWith(CACHE_PREFIX) && key !== CACHE).map(key => caches.delete(key)))).then(() => self.clients.claim()));
});
self.addEventListener('fetch', event => {
  if (event.request.method !== 'GET') return;
  event.respondWith(
    caches.match(event.request).then(cached => cached || fetch(event.request).then(response => {
      const copy = response.clone();
      caches.open(CACHE).then(cache => cache.put(event.request, copy)).catch(() => {});
      return response;
    }).catch(() => event.request.mode === 'navigate' ? caches.match('./offline.html') : cached))
  );
});
