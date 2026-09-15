const fs = require('fs');
const assert = require('assert');

const html = fs.readFileSync('index.html', 'utf8');
const app = fs.readFileSync('demo-app.js', 'utf8');
const plans = fs.readFileSync('plan-builder.js', 'utf8');
const guides = fs.readFileSync('exercise-library.js', 'utf8');
const workoutNav = fs.readFileSync('workout-nav.js', 'utf8');
const css = fs.readFileSync('styles.css', 'utf8');
const planCss = fs.readFileSync('plan-builder.css', 'utf8');
const guideCss = fs.readFileSync('exercise-guides.css', 'utf8');
const workoutNavCss = fs.readFileSync('workout-nav.css', 'utf8');
const manifest = JSON.parse(fs.readFileSync('manifest.webmanifest', 'utf8'));
const sw = fs.readFileSync('service-worker.js', 'utf8');

assert(html.includes('manifest.webmanifest'));
assert(html.includes('demo-app.js'));
assert(html.includes('plan-builder.js'));
assert(html.includes('exercise-library.js'));
assert(html.includes('workout-nav.js'));
assert(html.includes('styles.css'));
assert(html.includes('plan-builder.css'));
assert(html.includes('exercise-guides.css'));
assert(html.includes('workout-nav.css'));
assert(manifest.name === 'ConsistiFit');
assert(manifest.display === 'standalone');
assert(sw.includes('./demo-app.js'));
assert(sw.includes('./plan-builder.js'));
assert(sw.includes('./exercise-library.js'));
assert(sw.includes('./workout-nav.js'));
assert(sw.includes('./styles.css'));
assert(sw.includes('./plan-builder.css'));
assert(sw.includes('./exercise-guides.css'));
assert(sw.includes('./workout-nav.css'));
assert(css.includes('.bottomnav'));
assert(planCss.includes('.plan-mode-grid'));
assert(planCss.includes('.equipment-grid'));
assert(guideCss.includes('.cf-guide-arrow'));
assert(guideCss.includes('.cf-demo-grid'));
assert(workoutNavCss.includes('.cf-workout-nav-main'));
assert(workoutNavCss.includes('.cf-nav-dots'));
assert(workoutNavCss.includes('.cf-workout-list-row'));

// Syntax check without executing browser globals.
new Function(app);
new Function(plans);
new Function(guides);
new Function(workoutNav);

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

for (const required of [
  'CF_EXERCISE_LIBRARY',
  'function cfOpenExerciseGuide',
  'function cfOpenExerciseGuideByName',
  'How to perform + demo',
  'COMMON MISTAKES',
  'COACHING CUES',
  'DEMONSTRATION'
]) assert(guides.includes(required), `missing guide feature ${required}`);

for (const required of [
  'cfMoveExercise',
  'cfOpenWorkoutNavigatorList',
  'WORKOUT ORDER',
  'Workout list',
  'cf-nav-dots',
  'Previous exercise',
  'Next exercise'
]) assert(workoutNav.includes(required), `missing workout nav feature ${required}`);

const combined = `${html}\n${app}\n${plans}\n${guides}\n${workoutNav}`;
assert(!combined.toLowerCase().includes('supabase'));
assert(!combined.toLowerCase().includes('rankfit'));

const buttons = [...combined.matchAll(/<button\b([^>]*)>/gi)];
const inactive = buttons.filter(m => !m[1].includes('onclick=') && !m[1].includes('disabled'));
assert.equal(inactive.length, 0, `buttons without actions: ${inactive.length}`);

console.log(`Playable PWA smoke test passed: ${buttons.length} button templates, persistent progression, plan generation, exercise guides, and compact workout navigation enabled.`);
