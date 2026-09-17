const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const root = process.cwd();
const dist = path.join(root, 'dist');

function safeBuildId() {
  let sha = process.env.GITHUB_SHA || process.env.CONSISTIFIT_BUILD_ID || '';
  if (!sha) {
    try { sha = execSync('git rev-parse HEAD', { encoding: 'utf8' }).trim(); } catch (_) { sha = String(Date.now()); }
  }
  return sha.replace(/[^a-zA-Z0-9._-]/g, '').slice(0, 16) || String(Date.now());
}

function copyFile(relativePath) {
  const source = path.join(root, relativePath);
  const destination = path.join(dist, relativePath);
  if (!fs.existsSync(source)) throw new Error(`Missing web asset: ${relativePath}`);
  fs.mkdirSync(path.dirname(destination), { recursive: true });
  fs.copyFileSync(source, destination);
}

function copyDirectory(sourceDir, destinationDir) {
  if (!fs.existsSync(sourceDir)) return;
  fs.mkdirSync(destinationDir, { recursive: true });
  for (const entry of fs.readdirSync(sourceDir, { withFileTypes: true })) {
    const source = path.join(sourceDir, entry.name);
    const destination = path.join(destinationDir, entry.name);
    if (entry.isDirectory()) copyDirectory(source, destination);
    else fs.copyFileSync(source, destination);
  }
}

fs.rmSync(dist, { recursive: true, force: true });
fs.mkdirSync(dist, { recursive: true });

const html = fs.readFileSync(path.join(root, 'index.html'), 'utf8');
const localRefs = new Set(['index.html', 'offline.html', 'manifest.webmanifest', 'service-worker.js']);
for (const match of html.matchAll(/(?:src|href)=["']([^"']+)["']/g)) {
  const ref = match[1].split('?')[0].split('#')[0];
  if (!ref || /^(?:https?:|data:|mailto:|tel:|#)/i.test(ref)) continue;
  localRefs.add(ref.replace(/^\.\//, ''));
}
for (const file of localRefs) copyFile(file);
copyDirectory(path.join(root, 'assets'), path.join(dist, 'assets'));

const buildId = safeBuildId();
const serviceWorkerPath = path.join(dist, 'service-worker.js');
let sw = fs.readFileSync(serviceWorkerPath, 'utf8');
if (!sw.includes('__BUILD_ID__')) throw new Error('service-worker.js is missing the __BUILD_ID__ placeholder');
sw = sw.replaceAll('__BUILD_ID__', buildId);
fs.writeFileSync(serviceWorkerPath, sw);

let fullSha = process.env.GITHUB_SHA || buildId;
try { if (!process.env.GITHUB_SHA) fullSha = execSync('git rev-parse HEAD', { encoding: 'utf8' }).trim(); } catch (_) {}
const info = {
  app: 'ConsistiFit',
  commit: fullSha,
  buildId,
  builtAt: new Date().toISOString(),
  repository: 'Bhrcs/ConsistiFit',
  environment: process.env.GITHUB_ACTIONS ? 'github-actions' : 'local'
};
fs.writeFileSync(path.join(dist, 'build-info.json'), `${JSON.stringify(info, null, 2)}\n`);
console.log(`Built ConsistiFit web artifact ${buildId} with ${localRefs.size} root assets.`);
