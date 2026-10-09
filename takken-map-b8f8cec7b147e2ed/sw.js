/* 街で宅建 — オフライン用 Service Worker
 * shell: インストール時に保存 / tiles: 全域を先読み保存 (ページ側が進める) / 下地・ハザード: 見た範囲を保存 */
const VERSION = '202610100014';
const SHELL = 'tm-shell-' + VERSION, TILES = 'tm-tiles-1dcf31a5ec', EXT = 'tm-ext-v1';
const SHELL_FILES = ['./', 'index.html', 'zoning.js', 'munis.js', 'munistats.js', 'manifest.webmanifest',
  'vendor/maplibre-gl.js', 'vendor/maplibre-gl.css', 'fonts/OpenSans/0-255.pbf', 'icon-180.png', 'icon-512.png'];
const EXT_MAX = 4000;

self.addEventListener('install', e => {
  e.waitUntil(caches.open(SHELL).then(c => c.addAll(SHELL_FILES)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k.startsWith('tm-') && ![SHELL, TILES, EXT].includes(k)).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});

const EMPTY = () => new Response(new ArrayBuffer(0), {status: 200, headers: {'Content-Type': 'application/x-protobuf'}});
let trimming = false;
async function trimExt() {
  if (trimming) return; trimming = true;
  try { const c = await caches.open(EXT); const ks = await c.keys(); for (let i = 0; i < ks.length - EXT_MAX; i++) await c.delete(ks[i]); }
  finally { trimming = false; }
}

self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);
  if (e.request.method !== 'GET') return;
  if (url.origin === location.origin && url.pathname.includes('/tiles/')) {
    // 都市計画タイル: キャッシュ優先。無いタイル (データなし) やオフラインは空で返す
    e.respondWith(caches.open(TILES).then(async c => {
      const hit = await c.match(e.request); if (hit) return hit;
      try { const r = await fetch(e.request); if (r.ok) { c.put(e.request, r.clone()); return r; } return EMPTY(); }
      catch (_) { return EMPTY(); }
    }));
    return;
  }
  if (url.origin === location.origin) {
    // アプリ本体: ネット優先 (更新を拾う)・失敗したら保存分
    e.respondWith(fetch(e.request).then(r => { if (r.ok) caches.open(SHELL).then(c => c.put(e.request, r.clone())); return r; })
      .catch(() => caches.match(e.request, {ignoreSearch: true}).then(r => r || caches.match('index.html'))));
    return;
  }
  // 下地(地理院タイル)・ハザード(重ねるハザードマップ)は端末に保存しない (利用規約上の複製を避ける)。ネットに任せる
});
