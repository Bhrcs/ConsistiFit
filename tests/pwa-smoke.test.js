const fs = require('fs');
const assert = require('assert');

const html = fs.readFileSync('index.html', 'utf8');
const app = fs.readFileSync('demo-app.js', 'utf8');
const plans = fs.readFileSync('plan-builder.js', 'utf8');
const guides = fs.readFileSync('exercise-library.js', 'utf8');
const workoutNav = fs.readFileSync('workout-nav.js', 'utf8');
const depth = fs.readFileSync('demo-depth.js', 'utf8');
const cosmetics = fs.readFileSync('demo-cosmetics.js', 'utf8');
const css = fs.readFileSync('styles.css', 'utf8');
const planCss = fs.readFileSync('plan-builder.css', 'utf8');
const guideCss = fs.readFileSync('exercise-guides.css', 'utf8');
const workoutNavCss = fs.readFileSync('workout-nav.css', 'utf8');
const depthCss = fs.readFileSync('demo-depth.css', 'utf8');
const cosmeticsCss = fs.readFileSync('demo-cosmetics.css', 'utf8');
const manifest = JSON.parse(fs.readFileSync('manifest.webmanifest', 'utf8'));
const sw = fs.readFileSync('service-worker.js', 'utf8');

for (const asset of ['manifest.webmanifest','demo-app.js','plan-builder.js','exercise-library.js','workout-nav.js','demo-depth.js','demo-cosmetics.js','styles.css','plan-builder.css','exercise-guides.css','workout-nav.css','demo-depth.css','demo-cosmetics.css']) {
  assert(html.includes(asset), `index missing ${asset}`);
}
assert(manifest.name === 'ConsistiFit');
assert(manifest.display === 'standalone');
for (const asset of ['./demo-app.js','./plan-builder.js','./exercise-library.js','./workout-nav.js','./demo-depth.js','./demo-cosmetics.js','./styles.css','./plan-builder.css','./exercise-guides.css','./workout-nav.css','./demo-depth.css','./demo-cosmetics.css']) {
  assert(sw.includes(asset), `service worker missing ${asset}`);
}
assert(sw.includes('consistifit-playable-v8'));
assert(css.includes('.bottomnav'));
assert(planCss.includes('.plan-mode-grid'));
assert(planCss.includes('.equipment-grid'));
assert(guideCss.includes('.cf-guide-arrow'));
assert(guideCss.includes('.cf-demo-grid'));
assert(workoutNavCss.includes('.cf-workout-nav-main'));
assert(workoutNavCss.includes('.cf-nav-dots'));
assert(workoutNavCss.includes('.cf-workout-list-row'));
assert(workoutNavCss.includes('.cf-exercise-switcher'));
assert(workoutNavCss.includes('.cf-switch-button'));
assert(depthCss.includes('.cf-calendar'));
assert(depthCss.includes('.cf-performance-card'));
assert(depthCss.includes('.cf-rest-ring'));
assert(depthCss.includes('.cf-achievements'));
assert(cosmeticsCss.includes('.cf-profile-flair'));

// Syntax check without executing browser globals.
new Function(app);
new Function(plans);
new Function(guides);
new Function(workoutNav);
new Function(depth);
new Function(cosmetics);

for (const required of [
  'localStorage.setItem','function startWorkout','function finishWorkout','function saveSteps','function saveMobility','function rewardOnce','function purchaseItem','function advanceDemoDay','function currentRank'
]) assert(app.includes(required), `missing ${required}`);

for (const required of [
  'function openPlanBuilder','function cfSavePlan','function cfCustomFull','function cfProgram',"mode:'home'","state.plan.mode==='gym'","state.plan.mode==='custom'",'Dumbbells + adjustable bench + bodyweight','Machines + cables + cardio equipment','Choose My Equipment'
]) assert(plans.includes(required), `missing plan feature ${required}`);

for (const required of [
  'CF_EXERCISE_LIBRARY','function cfOpenExerciseGuide','function cfOpenExerciseGuideByName','How to perform + demo','COMMON MISTAKES','COACHING CUES','DEMONSTRATION'
]) assert(guides.includes(required), `missing guide feature ${required}`);

for (const required of [
  'cfMoveExercise','cfOpenWorkoutNavigatorList','renderTopProgress','renderBottomExerciseControls','WORKOUT PROGRESS','Workout list','cf-nav-dots','Previous exercise','Next exercise','cf-exercise-switcher'
]) assert(workoutNav.includes(required), `missing workout nav feature ${required}`);
assert(!workoutNav.includes('cf-nav-arrow'), 'top navigation arrows should not exist');

for (const required of [
  'recommendation(ex)','detectPRs','weeklyConsistency','calendarHTML','volumeChart','weightChart','cfSaveBodyweight','ACHIEVEMENTS','cfSetCosmetic','cfOpenExerciseHistory','cfOpenSubstitutes','cfToggleWarmups','cfSetExerciseRpe','cfTogglePause','cf-rest-ring','Workout notes','NEW PERSONAL RECORDS','Lime Glow Theme','finish_burst'
]) assert(depth.includes(required), `missing depth feature ${required}`);

for (const required of ['cf-profile-flair','Finish Burst effect','title_consistent','badge_founder']) {
  assert(cosmetics.includes(required), `missing cosmetic feature ${required}`);
}

const combined = `${html}\n${app}\n${plans}\n${guides}\n${workoutNav}\n${depth}\n${cosmetics}`;
assert(!combined.toLowerCase().includes('supabase'));
assert(!combined.toLowerCase().includes('rankfit'));

const buttons = [...combined.matchAll(/<button\b([^>]*)>/gi)];
const inactive = buttons.filter(m => !m[1].includes('onclick=') && !m[1].includes('disabled'));
assert.equal(inactive.length, 0, `buttons without actions: ${inactive.length}`);

console.log(`Playable PWA smoke test passed: ${buttons.length} button templates with progression suggestions, PRs, calendar, achievements, charts, substitutions, warmups, pause, notes, cosmetics, and exercise history enabled.`);
