const fs = require('fs');
const assert = require('assert');

const html = fs.readFileSync('index.html', 'utf8');
const app = fs.readFileSync('demo-app.js', 'utf8');
const plans = fs.readFileSync('plan-builder.js', 'utf8');
const css = fs.readFileSync('styles.css', 'utf8');
const planCss = fs.readFileSync('plan-builder.css', 'utf8');
const manifest = JSON.parse(fs.readFileSync('manifest.webmanifest', 'utf8'));
const sw = fs.readFileSync('service-worker.js', 'utf8');

assert(html.includes('manifest.webmanifest'));
assert(html.includes('demo-app.js'));
assert(html.includes('plan-builder.js'));
assert(html.includes('styles.css'));
assert(html.includes('plan-builder.css'));
assert(manifest.name === 'ConsistiFit');
assert(manifest.display === 'standalone');
assert(sw.includes('./demo-app.js'));
assert(sw.includes('./plan-builder.js'));
assert(sw.includes('./styles.css'));
assert(sw.includes('./plan-builder.css'));
assert(css.includes('.bottomnav'));
assert(planCss.includes('.plan-mode-grid'));
assert(planCss.includes('.equipment-grid'));

// Syntax check without executing browser globals.
new Function(app);
new Function(plans);

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

for (const required of [
  'function openPlanBuilder',
  'function cfSavePlan',
  'function cfCustomFull',
  'function cfProgram',
  "mode:'home'",
  "state.plan.mode==='gym'",
  "state.plan.mode==='custom'",
  'Dumbbells + adjustable bench + bodyweight',
  'Machines + cables + cardio equipment',
  'Choose My Equipment'
]) assert(plans.includes(required), `missing plan feature ${required}`);

assert(!`${html}\n${app}\n${plans}`.toLowerCase().includes('supabase'));
assert(!`${html}\n${app}\n${plans}`.toLowerCase().includes('rankfit'));

const buttons = [...`${html}\n${app}\n${plans}`.matchAll(/<button\b([^>]*)>/gi)];
const inactive = buttons.filter(m => !m[1].includes('onclick=') && !m[1].includes('disabled'));
assert.equal(inactive.length, 0, `buttons without actions: ${inactive.length}`);

console.log(`Playable PWA smoke test passed: ${buttons.length} button templates, persistent progression and equipment-based plan generation enabled.`);
