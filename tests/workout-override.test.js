const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

// Execute the shipping scripts and their real wrapper chain. Only browser paint
// and timers are stubbed: generation, persistence, sessions and rewards are real.
function app(saved) {
  const storage = new Map(saved ? [['consistifit_playable_demo_v1', saved]] : []);
  const node = () => ({innerHTML: '', textContent: '', value: '0', children: [], style: {}, dataset: {},
    classList: {add() {}, remove() {}, toggle() {}, contains() { return false; }},
    querySelector() { return null; }, querySelectorAll() { return []; },
    insertAdjacentHTML() {}, insertAdjacentElement() {}, appendChild() {}, insertBefore() {},
    setAttribute() {}, addEventListener() {}, remove() {}});
  const elements = new Map();
  const context = {console, navigator: {}, Date, Math, JSON, Set, Map,
    setTimeout() { return 1; }, clearTimeout() {}, setInterval() { return 1; }, clearInterval() {},
    requestAnimationFrame() {}, confirm: () => true, addEventListener() {}, scrollTo() {},
    localStorage: {getItem: key => storage.get(key) ?? null, setItem: (key, value) => storage.set(key, value), removeItem: key => storage.delete(key)},
    document: {body: node(), querySelector: () => null, querySelectorAll: () => [],
      createElement: node, getElementById(id) { if (!elements.has(id)) elements.set(id, node()); return elements.get(id); }}
  };
  context.window = context;
  vm.createContext(context);
  const run = source => vm.runInContext(source, context);
  for (const name of ['demo-app.js', 'plan-builder.js', 'exercise-library.js', 'workout-nav.js', 'demo-depth.js', 'demo-cosmetics.js', 'demo-2.js', 'core-loop.js', 'workout-override.js']) {
    vm.runInContext(fs.readFileSync(path.join(__dirname, '..', name), 'utf8'), context, {filename: name});
  }
  run('renderAll = () => {}; renderWorkout = () => {}; toast = () => {};');
  const state = () => run('state');
  function day(weekday) {
    run(`state.demo.dayOffset += (${weekday} - demoDate().getDay() + 7) % 7; ensureDaily();`);
  }
  function complete(fraction = 1) {
    run('startWorkout()');
    const active = state().workout.active;
    assert(active, 'a workout started');
    const sets = active.exercises.flatMap(ex => ex.sets);
    sets.slice(0, Math.ceil(sets.length * fraction)).forEach(set => { set.done = true; });
    run("finishWorkout('Good')");
    return state().history.at(-1);
  }
  return {context, run, state, day, complete, storage, api: context.CFOverride};
}

function test(name, fn) { fn(); console.log(`PASS ${name}`); }

test('all focuses use catalog exercises and every required equipment item', () => {
  const a = app();
  for (const mode of ['home', 'gym', 'custom']) {
    a.run(`state.plan.mode = '${mode}'; state.plan.equipment = CF_EQUIPMENT.map(row => row[0]);`);
    for (const focus of a.api.focuses) {
      const result = a.api.generate(focus);
      assert.equal(result.ok, true, `${mode}/${focus}: ${result.errors}`);
      for (const row of result.template.exercises) {
        const ex = a.context.CF2_EXERCISE_CATALOG.find(ex => ex.name === row[0]);
        assert(ex);
        assert(a.api.compatible(ex));
        if (mode !== 'custom' && ex.equipment.length) assert.equal(ex.mode, mode);
      }
    }
  }
  a.run("state.plan = {...state.plan, mode:'home', equipment:['dumbbells']}");
  for (const focus of a.api.focuses) {
    const result = a.api.generate(focus);
    assert(result.ok);
    assert(result.template.exercises.every(row => !a.context.CF2_EXERCISE_CATALOG.find(ex => ex.name === row[0]).equipment.includes('bench')));
  }
});

test('unavailable focus, malformed targets and unknown exercises fail explicitly', () => {
  const a = app();
  a.run("state.plan.mode = 'custom'; state.plan.equipment = [];");
  assert.equal(a.api.generate('Back').ok, true);
  assert.equal(a.api.generate('Full Body').ok, true);
  a.context.CF2_EXERCISE_CATALOG = a.context.CF2_EXERCISE_CATALOG.filter(ex => !/back|lats/i.test(ex.muscle));
  assert.equal(a.api.generate('Back').ok, false, 'no substitute from a different focus');
  assert.equal(a.api.generate('Full Body').ok, false, 'a full-body routine must retain pulling coverage');
  assert.equal(a.api.generate('Unknown').ok, false);
  assert.equal(a.api.generate('Core').ok, true);
  const valid = a.api.generate('Core').template;
  for (const count of [0, -1, 1.5, '3', Infinity, NaN, 100]) {
    const bad = structuredClone(valid); bad.exercises[0][2] = count;
    assert.equal(a.api.validate(bad).ok, false, String(count));
  }
  assert.equal(a.api.validate({name: 'Empty', exercises: []}).ok, false);
  assert.equal(a.api.validate({name: 'Unknown', exercises: [['Fake row', 'Back', 3, 8, 12, 90]]}).ok, false);
  assert.equal(a.api.apply({name: 'Invalid', exercises: []}).ok, false);
  assert.equal(a.api.current(), null);
});

test('override is a defensive day snapshot; saving is explicit and leaves recurring plan untouched', () => {
  const a = app(); a.day(1);
  const plan = JSON.stringify(a.state().plan);
  const program = a.run('JSON.stringify(cfProgram())');
  const template = a.api.generate('Back').template;
  assert(a.api.apply(template).ok);
  template.exercises[0][0] = 'mutated';
  const exposed = a.api.current(); exposed.template.exercises.length = 0;
  assert(a.api.current().template.exercises.length > 0);
  assert.equal(a.state().workoutOverrides.saved.length, 0);
  assert(a.api.saveCurrent('My back day').ok);
  assert(a.api.saveCurrent('My back day').ok);
  assert.equal(a.state().workoutOverrides.saved.length, 1);
  assert.equal(JSON.stringify(a.state().plan), plan);
  assert.equal(a.run('JSON.stringify(cfProgram())'), program);
  assert(a.api.availableWorkouts().some(item => item.name === 'My back day'));
  a.run('state.demo.dayOffset++; ensureDaily();');
  assert.equal(a.api.current(), null);
  assert.equal(a.run('JSON.stringify(cfProgram())'), program);
});

test('saved and program choices exclude missing equipment instead of silently pruning exercises', () => {
  const a = app();
  const all = a.api.availableWorkouts();
  assert(all.some(item => item.source === 'Current program'));
  assert(all.some(item => item.source === 'Home Foundation'));
  a.state().cf2.customPrograms.push({id:'bad', name:'Bad saved', workouts:[{name:'No equipment', exercises:[['Machine Chest Press','Chest',3,8,12,90]]}]});
  assert(!a.api.availableWorkouts().some(item => item.name === 'No equipment'));
  a.run("state.plan.equipment = ['dumbbells'];");
  for (const choice of a.api.availableWorkouts()) assert(a.api.validate(choice.template).ok);
});

test('approved override awards one primary credit across swaps, repeats, clear, and reload', () => {
  const a = app(); a.day(1);
  assert(a.api.apply(a.api.generate('Back').template).ok);
  const first = a.complete();
  assert.equal(first.primaryCredit, true);
  assert.equal(first.reward.rp, 30);
  assert(a.state().daily.dayComplete);
  const rp = a.state().profile.rp;
  const count = a.run('workoutCount()');
  assert(a.api.apply(a.api.generate('Chest').template).ok);
  const repeat = a.complete();
  assert.equal(repeat.primaryCredit, false);
  assert.equal(repeat.reward.rp, 0);
  assert.equal(repeat.eligible, false);
  assert.equal(a.state().profile.rp, rp);
  assert.equal(a.run('workoutCount()'), count);
  assert(a.api.clear().ok);
  assert.equal(a.run("rewardOnce('recovery', {rp:30, xp:160, coins:65})"), false);
  const b = app(a.storage.get('consistifit_playable_demo_v1'));
  assert.equal(b.api.primaryComplete(), true);
  b.api.apply(b.api.generate('Core').template);
  assert.equal(b.complete().reward.rp, 0);
  assert.equal(b.state().profile.rp, rp);
});

test('recovery and override share a primary reward and recovery-day budget in either order', () => {
  for (const recoveryFirst of [true, false]) {
    const a = app(); a.day(0);
    const count = a.run('workoutCount()');
    if (recoveryFirst) {
      a.context.document.getElementById('mobilityMinutes').value = 10;
      a.run('saveMobility()');
    }
    a.api.apply(a.api.generate('Core').template);
    const entry = a.complete();
    assert.equal(entry.primaryCredit, !recoveryFirst);
    assert.equal(entry.reward.rp, recoveryFirst ? 0 : 30);
    if (!recoveryFirst) { assert.equal(entry.reward.xp, 160); assert.equal(entry.reward.coins, 65); }
    assert(a.api.clear().ok);
    a.context.document.getElementById('mobilityMinutes').value = 10;
    a.run('saveMobility()');
    assert.equal(a.state().profile.rp, 35); // primary + one check-in
    assert.equal(a.run('workoutCount()'), count, 'recovery override cannot advance the upcoming training rotation');
    assert(a.state().daily.dayComplete);
  }
});

test('partial or shortened workouts cannot earn primary credit', () => {
  const a = app(); a.day(1); a.api.apply(a.api.generate('Back').template);
  assert.equal(a.complete(.3).primaryCredit, false);
  a.run('startWorkout()');
  assert.equal(a.api.clear().ok, false);
  assert.equal(a.api.apply(a.api.generate('Core').template).ok, false);
  const workout = a.state().workout.active;
  workout.exercises.splice(1);
  workout.exercises[0].sets.forEach(set => set.done = true);
  a.run("finishWorkout('Good')");
  assert.equal(a.state().history.at(-1).primaryCredit, false);
  assert.equal(a.state().profile.rp, 5);
});

test('cross-midnight resume credits captured start date; revisiting dates cannot farm any claim', () => {
  const a = app(); a.day(1); a.api.apply(a.api.generate('Back').template);
  a.run('startWorkout()');
  const startDate = a.state().workout.active.startedDate;
  a.run('state.demo.dayOffset++; ensureDaily();');
  const currentDate = a.state().daily.date;
  const b = app(a.storage.get('consistifit_playable_demo_v1'));
  assert.equal(b.state().workout.active.startedDate, startDate);
  b.run('startWorkout()'); // resume even though the current day is recovery
  b.state().workout.active.exercises.forEach(ex => ex.sets.forEach(set => set.done = true));
  b.run("finishWorkout('Good')");
  assert.equal(b.state().history.at(-1).date, startDate);
  assert.equal(b.state().daily.date, currentDate);
  assert.equal(b.api.primaryComplete(), false);
  assert.equal(b.api.primaryComplete(startDate), true);
  const rp = b.state().profile.rp;
  b.run('state.demo.dayOffset--; ensureDaily();');
  assert.equal(b.api.primaryComplete(), true);
  assert.equal(b.complete().reward.rp, 0);
  assert.equal(b.state().profile.rp, rp);
  b.run("rewardOnce('steps', {rp:10, xp:50, coins:25}); advanceDemoDay(); state.demo.dayOffset--; ensureDaily();");
  assert.equal(b.run("rewardOnce('steps', {rp:10, xp:50, coins:25})"), false);
});

test('equipment changes invalidate pending override and unavailable substitutions are blocked', () => {
  const a = app(); a.day(1);
  a.api.apply(a.api.generate('Back').template);
  a.run('state.plan.equipment = []; startWorkout();');
  assert.equal(a.state().workout.active, null);
  a.api.clear(); a.run("state.plan.equipment = ['dumbbells','bench']; startWorkout();");
  const name = a.state().workout.active.exercises[0].name;
  a.context.__cfSubs = [{name:'Machine Chest Press', muscle:'Chest', sets:3, repMin:8, repMax:12, rest:90}];
  a.context.cfReplaceExercise(0);
  assert.equal(a.state().workout.active.exercises[0].name, name);
});

test('existing default program is catalog-backed and a leg press does not imply a hack squat machine', () => {
  const a = app();
  assert(a.api.validate(a.run('todayTemplate()')).ok);
  const hack = a.context.CF2_EXERCISE_CATALOG.find(ex => ex.name === 'Hack Squat');
  a.run("state.plan.mode = 'gym'; state.plan.equipment = ['legpress'];");
  assert.equal(a.api.compatible(hack), false);
  a.run("state.plan.equipment.push('hacksquat');");
  assert.equal(a.api.compatible(hack), true);
});

test('focus targets primary muscles and a short full-body session retains core coverage', () => {
  const a = app();
  const arms = a.api.generate('Arms').template;
  assert(arms.exercises.every(row => /biceps|triceps|arms/i.test(row[1].split('·')[0])));
  assert(!arms.exercises.some(row => /bench|row/i.test(row[0])));
  a.run('state.plan.minutes = 30;');
  const muscles = a.api.generate('Full Body').template.exercises.map(row => row[1].split('·')[0]);
  for (const pattern of [/quads|legs|glutes/i, /chest/i, /back|lats/i, /core/i]) assert(muscles.some(muscle => pattern.test(muscle)));
});

test('all no-equipment program sessions retain unique compatible exercises', () => {
  const a = app();
  a.run("state.plan.mode = 'custom'; state.plan.equipment = [];");
  for (const days of [2, 3, 4, 5, 6]) {
    a.state().plan.days = days;
    for (const template of a.run('cfProgram()')) {
      const result = a.api.validate(template);
      assert(result.ok, `${days} days / ${template.name}: ${result.errors}`);
      assert(template.exercises.length >= 3, 'a low-equipment workout still has useful movement variety');
      assert(template.exercises.every(row => a.context.CF2_EXERCISE_CATALOG.find(ex => ex.name === row[0]).equipment.length === 0));
    }
  }
  for (const equipment of [['bands'], ['barbell'], ['dumbbells'], ['cable'], ['bench']]) {
    a.state().plan.equipment = equipment;
    for (const template of a.run('cfProgram()')) {
      const result = a.api.validate(template);
      assert(result.ok, `${equipment} / ${template.name}: ${result.errors}`);
      assert(template.exercises.length >= 3);
    }
  }
});

test('invalid completed-set values and empty sessions never qualify', () => {
  const a = app(); a.day(1); a.api.apply(a.api.generate('Core').template); a.run('startWorkout()');
  a.run("finishWorkout('Good')");
  assert.equal(a.state().history.length, 0);
  a.state().workout.active.exercises.forEach(ex => ex.sets.forEach(set => { set.done = true; set.reps = 0; }));
  a.run("finishWorkout('Good')");
  assert.equal(a.state().history.at(-1).primaryCredit, false);
});

test('incompatible program activation explains setup requirements without changing the plan', () => {
  const a = app();
  const plan = JSON.stringify(a.state().plan), activeProgram = a.state().cf2.activeProgram;
  a.context.cf2UseProgram('lib:machine_foundation');
  assert.equal(JSON.stringify(a.state().plan), plan);
  assert.equal(a.state().cf2.activeProgram, activeProgram);
  const message = a.context.document.getElementById('sheetContent').innerHTML;
  assert(message.includes('Update training setup'));
  assert(message.includes('Keep current plan'));
  assert(message.includes('Leg press'));
  assert(message.includes('environment'));
  const sheet = a.context.document.getElementById('sheetContent');
  sheet.insertAdjacentHTML = (_, html) => { sheet.innerHTML += html; };
  a.context.cf2ProgramDetails('lib:machine_foundation');
  assert(sheet.innerHTML.includes('update setup first'));
});

test('program activation respects active sessions and preserves a compatible custom environment', () => {
  const a = app(); a.day(1); a.run('startWorkout()');
  const plan = JSON.stringify(a.state().plan), active = JSON.stringify(a.state().workout.active);
  a.context.cf2UseProgram('lib:home_foundation');
  assert.equal(JSON.stringify(a.state().plan), plan);
  assert.equal(JSON.stringify(a.state().workout.active), active);
  assert.equal(a.state().cf2.activeProgram, null);
  a.state().workout.active = null;
  a.run("state.plan.mode = 'custom'; state.plan.equipment = CF_EQUIPMENT.map(row => row[0]);");
  const equipment = JSON.stringify(a.state().plan.equipment);
  a.context.cf2UseProgram('lib:five_day_builder');
  assert.equal(a.state().cf2.activeProgram, 'lib:five_day_builder');
  assert.equal(a.state().plan.mode, 'custom');
  assert.equal(JSON.stringify(a.state().plan.equipment), equipment);
  assert.equal(a.state().plan.days, 5);
  for (const template of a.run('cfProgram()')) assert(a.api.validate(template).ok);
});

console.log('Workout override production regression tests passed.');
