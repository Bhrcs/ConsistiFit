const fs = require('fs');
const path = require('path');

const dist = path.join(process.cwd(), 'dist');
const required = ['index.html', 'offline.html', 'manifest.webmanifest', 'service-worker.js', 'build-info.json'];
for (const file of required) {
  if (!fs.existsSync(path.join(dist, file))) throw new Error(`Build verification failed: missing ${file}`);
}

const html = fs.readFileSync(path.join(dist, 'index.html'), 'utf8');
for (const match of html.matchAll(/(?:src|href)=["']([^"']+)["']/g)) {
  const ref = match[1].split('?')[0].split('#')[0];
  if (!ref || /^(?:https?:|data:|mailto:|tel:|#)/i.test(ref)) continue;
  const relative = ref.replace(/^\.\//, '');
  if (!fs.existsSync(path.join(dist, relative))) throw new Error(`index.html references missing local asset: ${relative}`);
}

const sw = fs.readFileSync(path.join(dist, 'service-worker.js'), 'utf8');
if (sw.includes('__BUILD_ID__')) throw new Error('Service worker build id was not stamped');
if (!sw.includes('consistifit-playable-')) throw new Error('Service worker cache prefix is missing');
for (const match of sw.matchAll(/["']\.\/([^"']+)["']/g)) {
  const relative = match[1];
  if (!fs.existsSync(path.join(dist, relative))) throw new Error(`Service worker caches missing asset: ${relative}`);
}

const manifest = JSON.parse(fs.readFileSync(path.join(dist, 'manifest.webmanifest'), 'utf8'));
if (manifest.name !== 'ConsistiFit') throw new Error('Manifest name is not ConsistiFit');
for (const icon of manifest.icons || []) {
  const relative = String(icon.src || '').replace(/^\.\//, '').replace(/^\//, '');
  if (relative && !fs.existsSync(path.join(dist, relative))) throw new Error(`Manifest references missing icon: ${relative}`);
}

const info = JSON.parse(fs.readFileSync(path.join(dist, 'build-info.json'), 'utf8'));
if (!info.commit || !info.buildId || !info.builtAt) throw new Error('build-info.json is incomplete');
if (!sw.includes(info.buildId)) throw new Error('Service worker cache does not match build-info build id');
console.log(`Verified production artifact ${info.buildId} (${info.commit}).`);
