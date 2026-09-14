const fs = require('fs');
const assert = require('assert');

const html = fs.readFileSync('index.html', 'utf8');
const app = fs.readFileSync('demo-app.js', 'utf8');
const css = fs.readFileSync('styles.css', 'utf8');
const manifest = JSON.parse(fs.readFileSync('manifest.webmanifest', 'utf8'));
const sw = fs.readFileSync('service-worker.js', 'utf8');

assert(html.includes('manifest.webmanifest'));
assert(html.includes('demo-app.js'));
assert(html.includes('styles.css'));
assert(manifest.name === 'ConsistiFit');
assert(manifest.display === 'standalone');
assert(sw.includes('./demo-app.js'));
assert(sw.includes('./styles.css'));
assert(css.includes('.bottomnav'));

// Syntax check without executing browser globals.
new Function(app);

for (const required of [
  'localStorage.setItem',
  'function startWorkout',
  'function finishWorkout',
  'function saveSteps',
  'function saveMobility',
  'function rewardOnce',
  'function purchaseItem',
  'function advanceDemoDay',
  'function currentRank'
]) assert(app.includes(required), `missing ${required}`);

assert(!`${html}\n${app}`.toLowerCase().includes('supabase'));
assert(!`${html}\n${app}`.toLowerCase().includes('rankfit'));

const buttons = [...`${html}\n${app}`.matchAll(/<button\b([^>]*)>/gi)];
const inactive = buttons.filter(m => !m[1].includes('onclick=') && !m[1].includes('disabled'));
assert.equal(inactive.length, 0, `buttons without actions: ${inactive.length}`);

console.log(`Playable PWA smoke test passed: ${buttons.length} button templates, persistent local progression enabled.`);
