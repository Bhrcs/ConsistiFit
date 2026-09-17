const fs = require('fs');
const assert = require('assert');

const html = fs.readFileSync('index.html', 'utf8');
const app = fs.readFileSync('demo-app.js', 'utf8');
const plans = fs.readFileSync('plan-builder.js', 'utf8');
const guides = fs.readFileSync('exercise-library.js', 'utf8');
const workoutNav = fs.readFileSync('workout-nav.js', 'utf8');
const depth = fs.readFileSync('demo-depth.js', 'utf8');
const cosmetics = fs.readFileSync('demo-cosmetics.js', 'utf8');
const demo2 = fs.readFileSync('demo-2.js', 'utf8');
const core = fs.readFileSync('core-loop.js', 'utf8');
const premium = fs.readFileSync('premium-ui.js', 'utf8');
const css = fs.readFileSync('styles.css', 'utf8');
const planCss = fs.readFileSync('plan-builder.css', 'utf8');
const guideCss = fs.readFileSync('exercise-guides.css', 'utf8');
const workoutNavCss = fs.readFileSync('workout-nav.css', 'utf8');
const depthCss = fs.readFileSync('demo-depth.css', 'utf8');
const cosmeticsCss = fs.readFileSync('demo-cosmetics.css', 'utf8');
const demo2Css = fs.readFileSync('demo-2.css', 'utf8');
const coreCss = fs.readFileSync('core-loop.css', 'utf8');
const premiumCss = fs.readFileSync('premium-ui.css', 'utf8');
const manifest = JSON.parse(fs.readFileSync('manifest.webmanifest', 'utf8'));
const sw = fs.readFileSync('service-worker.js', 'utf8');

for (const asset of ['manifest.webmanifest','demo-app.js','plan-builder.js','exercise-library.js','workout-nav.js','demo-depth.js','demo-cosmetics.js','demo-2.js','core-loop.js','premium-ui.js','styles.css','plan-builder.css','exercise-guides.css','workout-nav.css','demo-depth.css','demo-cosmetics.css','demo-2.css','core-loop.css','premium-ui.css']) assert(html.includes(asset), `index missing ${asset}`);
assert(manifest.name === 'ConsistiFit');
assert(manifest.display === 'standalone');
for (const asset of ['./demo-app.js','./plan-builder.js','./exercise-library.js','./workout-nav.js','./demo-depth.js','./demo-cosmetics.js','./demo-2.js','./core-loop.js','./premium-ui.js','./styles.css','./plan-builder.css','./exercise-guides.css','./workout-nav.css','./demo-depth.css','./demo-cosmetics.css','./demo-2.css','./core-loop.css','./premium-ui.css']) assert(sw.includes(asset), `service worker missing ${asset}`);
assert(sw.includes("const CACHE_PREFIX = 'consistifit-playable-';"));
assert(sw.includes('__BUILD_ID__'), 'source service worker must contain build-id placeholder');
assert(css.includes('.bottomnav'));
assert(planCss.includes('.plan-mode-grid'));
assert(planCss.includes('.equipment-grid'));
assert(guideCss.includes('.cf-guide-arrow'));
assert(workoutNavCss.includes('.cf-exercise-switcher'));
assert(depthCss.includes('.cf-calendar'));
assert(depthCss.includes('.cf-rest-ring'));
assert(cosmeticsCss.includes('.cf-profile-flair'));
assert(demo2Css.includes('.cf2-onboarding'));
assert(demo2Css.includes('.cf2-builder-row'));
assert(demo2Css.includes('.cf2-smart-target'));
assert(coreCss.includes('.cf-core-focus'));
assert(coreCss.includes('.cf-core-program-quality'));
assert(coreCss.includes('.cf-core-planfit'));
assert(premiumCss.includes('.cfp-rank-stage'));
assert(premiumCss.includes('.cfp-balance'));
assert(premiumCss.includes('.cfp-routine-card'));
assert(premiumCss.includes('.cfp-prev'));

for (const source of [app,plans,guides,workoutNav,depth,cosmetics,demo2,core,premium]) new Function(source);

for (const required of ['localStorage.setItem','function startWorkout','function finishWorkout','function saveSteps','function saveMobility','function rewardOnce','function purchaseItem','function currentRank']) assert(app.includes(required), `missing ${required}`);
for (const required of ['function openPlanBuilder','function cfSavePlan','function cfCustomFull','function cfProgram','Choose My Equipment']) assert(plans.includes(required), `missing plan feature ${required}`);
for (const required of ['CF_EXERCISE_LIBRARY','function cfOpenExerciseGuide','How to perform + demo','COMMON MISTAKES','COACHING CUES','DEMONSTRATION']) assert(guides.includes(required), `missing guide feature ${required}`);
for (const required of ['cfMoveExercise','cfOpenWorkoutNavigatorList','WORKOUT PROGRESS','Previous exercise','Next exercise']) assert(workoutNav.includes(required), `missing workout nav feature ${required}`);
assert(!workoutNav.includes('cf-nav-arrow'), 'top navigation arrows should not exist');
for (const required of ['detectPRs','weeklyConsistency','calendarHTML','volumeChart','weightChart','cfSaveBodyweight','ACHIEVEMENTS','cfOpenExerciseHistory','cfOpenSubstitutes','cfToggleWarmups','cfSetExerciseRpe','cfTogglePause','Workout notes','NEW PERSONAL RECORDS']) assert(depth.includes(required), `missing depth feature ${required}`);
for (const required of ['cf-profile-flair','Finish Burst effect','title_consistent','badge_founder']) assert(cosmetics.includes(required), `missing cosmetic feature ${required}`);
for (const required of ['PROGRAM_LIBRARY','EXERCISE_CATALOG','cf2OnboardFinish','cf2RedoOnboarding','cf2OpenProgramLibrary','cf2ProgramDetails','cf2UseProgram','cf2OpenWorkoutBuilder','cf2SaveCustomWorkout','cf2OpenExercisePicker','cf2SmartRecommendation','SMART PROGRESSION','Drag rows on desktop']) assert(demo2.includes(required), `missing Demo 2.0 feature ${required}`);
for (const program of ['Home Foundation','Dumbbell Muscle Builder','Dumbbell Strength','Machine Foundation','Machine Muscle Builder','Machine Strength','2-Day Habit Starter','5-Day Gym Builder']) assert(demo2.includes(program), `missing program ${program}`);
for (const required of ['cfCoreRecommendation','cfCoreAuditProgram','Double progression','Two recent sessions were hard','RECOVERY_RP = 30','PRIMARY PLAN MISSION','PLAN FIT','Follow the plan, not the leaderboard','cleanProfileUI','button.textContent.includes(\'Balance Lab\')','state.demo.dayOffset = 0']) assert(core.includes(required), `missing core-loop feature ${required}`);
assert(core.includes("title.textContent.trim() === 'DEMO CONTROLS'"), 'developer controls must be stripped from Profile');
assert(!core.includes('cf2OpenBalanceLab()'), 'core product layer must not expose a Balance Lab action');
for (const required of ['premiumRank','rankEmblem','rankTrend','trainingBalanceHTML','cfPremiumRoutines','enhanceWorkout','LAST','Follow the plan, not the leaderboard']) assert(premium.includes(required), `missing premium UI feature ${required}`);
assert(!premium.toLowerCase().includes('global leaderboard'), 'premium UI must not invent a fake global leaderboard');

const combined = `${html}\n${app}\n${plans}\n${guides}\n${workoutNav}\n${depth}\n${cosmetics}\n${demo2}\n${core}\n${premium}`;
assert(!combined.toLowerCase().includes('supabase'));
assert(!combined.toLowerCase().includes('rankfit'));
const buttons = [...combined.matchAll(/<button\b([^>]*)>/gi)];
const inactive = buttons.filter(m => !m[1].includes('onclick=') && !m[1].includes('disabled'));
assert.equal(inactive.length, 0, `buttons without actions: ${inactive.length}`);
console.log(`Playable PWA smoke test passed: ${buttons.length} button templates with premium rank, workout, routine, progress, and consistency UX.`);

for (const asset of ['workout-override.js','ux-experience.js','ux-experience.css','premium-ui.js','premium-ui.css']) { assert(html.includes(asset)); assert(sw.includes('./' + asset)); }
for (const file of ['workout-override.js','ux-experience.js','premium-ui.js']) new Function(fs.readFileSync(file, 'utf8'));
