/* Day-only changes and reward accounting. All data stays in the existing local save.
 * CFOverride methods return {ok, errors, ...}; read methods return defensive copies.
 * preview.exercises contains the existing [name,muscle,sets,min,max,rest] tuples.
 */
(() => {
  const clone = value => JSON.parse(JSON.stringify(value));
  const focuses = ['Back', 'Chest', 'Legs', 'Shoulders', 'Arms', 'Core', 'Full Body'];
  const groups = {
    Back: /back|lats/i, Chest: /chest/i, Legs: /quads|glutes|hamstrings|calves|legs/i,
    Shoulders: /shoulders|delts/i, Arms: /biceps|triceps|arms/i, Core: /core|abs/i
  };
  // The original picker catalog omitted movements already used by plan-builder.
  // Complete its metadata from those existing exercises rather than inventing a
  // second exercise source. Equipment means *all* listed items are required.
  const existingPlanExercises = [
    ['Bench-Supported Dumbbell Row', 'Back · Biceps', 'home', 'dumbbells,bench'],
    ['Single-Leg Dumbbell Romanian Deadlift', 'Hamstrings · Glutes', 'home', 'dumbbells'],
    ['Dumbbell Curl + Triceps Extension', 'Arms', 'home', 'dumbbells'],
    ['Bench Leg Raise', 'Core', 'home', 'bench'],
    ['Arnold Press', 'Shoulders · Triceps', 'home', 'dumbbells'],
    ['Dumbbell Sumo Squat', 'Quads · Glutes', 'home', 'dumbbells'],
    ['Seated Leg Curl', 'Hamstrings', 'gym', 'legcurl'],
    ['Reverse Pec Deck', 'Rear Delts', 'gym', 'pecdeck'],
    ['Back Squat', 'Quads · Glutes', 'home', 'barbell,rack'],
    ['Kettlebell Goblet Squat', 'Quads · Glutes', 'home', 'kettlebell'],
    ['Band-Resisted Squat', 'Quads · Glutes', 'home', 'bands'],
    ['Tempo Bodyweight Squat', 'Quads · Glutes', 'home', ''],
    ['Barbell Bench Press', 'Chest · Triceps', 'home', 'barbell,bench,rack'],
    ['Standing Cable Chest Press', 'Chest · Triceps', 'gym', 'cable'],
    ['Push-up', 'Chest · Triceps', 'home', ''],
    ['Seated Cable Row', 'Back · Biceps', 'gym', 'cable'],
    ['Barbell Row', 'Back · Biceps', 'home', 'barbell'],
    ['Resistance Band Row', 'Back · Biceps', 'home', 'bands'],
    ['Prone Reverse Snow Angel', 'Upper Back', 'home', ''],
    ['Barbell Romanian Deadlift', 'Hamstrings · Glutes', 'home', 'barbell'],
    ['Kettlebell Romanian Deadlift', 'Hamstrings · Glutes', 'home', 'kettlebell'],
    ['Band Good Morning', 'Hamstrings · Glutes', 'home', 'bands'],
    ['Glute Bridge', 'Hamstrings · Glutes', 'home', ''],
    ['Dumbbell Shoulder Press', 'Shoulders · Triceps', 'home', 'dumbbells'],
    ['Barbell Overhead Press', 'Shoulders · Triceps', 'home', 'barbell'],
    ['Band Shoulder Press', 'Shoulders · Triceps', 'home', 'bands'],
    ['Pike Push-up', 'Shoulders · Triceps', 'home', ''],
    ['Kettlebell Reverse Lunge', 'Quads · Glutes', 'home', 'kettlebell'],
    ['Band Split Squat', 'Quads · Glutes', 'home', 'bands'],
    ['Reverse Lunge', 'Quads · Glutes', 'home', ''],
    ['Pull-up / Assisted Pull-up', 'Back · Biceps', 'home', 'pullup'],
    ['Cable Lat Pulldown', 'Back · Biceps', 'gym', 'cable'],
    ['Band Lat Pulldown', 'Back · Biceps', 'home', 'bands'],
    ['Prone Lat Sweep', 'Back', 'home', ''],
    ['Band Chest Press', 'Chest · Triceps', 'home', 'bands'],
    ['Band Leg Curl', 'Hamstrings', 'home', 'bands'],
    ['Single-Leg Glute Bridge', 'Hamstrings · Glutes', 'home', ''],
    ['Barbell Curl', 'Biceps', 'home', 'barbell'],
    ['Band Curl', 'Biceps', 'home', 'bands'],
    ['Side Plank', 'Core', 'home', ''],
    ['Dumbbell Split Squat', 'Quads · Glutes', 'home', 'dumbbells'],
    ['Single-Leg Press', 'Quads · Glutes', 'gym', 'legpress'],
    ['Bulgarian Split Squat', 'Quads · Glutes', 'home', 'bench'],
    ['Cable Fly', 'Chest', 'gym', 'cable'],
    ['Close-Grip Push-up', 'Chest · Triceps', 'home', ''],
    ['Cable Row', 'Back · Biceps', 'gym', 'cable'],
    ['Cable Pull-Through', 'Glutes · Hamstrings', 'gym', 'cable'],
    ['Band Glute Bridge', 'Glutes', 'home', 'bands'],
    ['Band Curl + Pressdown', 'Arms', 'home', 'bands'],
    ['Diamond Push-up', 'Triceps · Chest', 'home', '']
  ];
  for (const [name, muscle, mode, requirements] of existingPlanExercises) {
    if (!(window.CF2_EXERCISE_CATALOG || []).some(ex => ex.name === name)) {
      window.CF2_EXERCISE_CATALOG?.push({id: `plan_${name.toLowerCase().replace(/[^a-z0-9]+/g, '_')}`, name, muscle, mode, equipment: requirements ? requirements.split(',') : []});
    }
  }
  const hackSquat = (window.CF2_EXERCISE_CATALOG || []).find(ex => ex.name === 'Hack Squat');
  if (hackSquat) hackSquat.equipment = ['hacksquat'];
  if (!CF_EQUIPMENT.some(row => row[0] === 'hacksquat')) CF_EQUIPMENT.push(['hacksquat', 'Hack squat machine']);
  const baseTodayTemplate = todayTemplate;
  const baseTrainingDay = isTrainingDay;
  const baseEnsureDaily = ensureDaily;
  const baseSaveState = saveState;
  const baseRewardOnce = rewardOnce;
  const baseStartWorkout = startWorkout;
  const baseFinishWorkout = finishWorkout;
  let finishing = null;

  function data() {
    state.workoutOverrides ||= {version: 1, days: {}, saved: [], ledger: {}};
    const d = state.workoutOverrides;
    d.days ||= {}; d.saved ||= []; d.ledger ||= {};
    return d;
  }
  function dateKey() { return keyForDate(demoDate()); }
  function setup() {
    if (!state.plan || !Array.isArray(state.plan.equipment)) cfEnsurePlan();
    return {mode: state.plan.mode, equipment: [...state.plan.equipment]};
  }
  function compatible(exercise, environment = setup()) {
    const equipment = exercise?.equipment;
    if (!Array.isArray(equipment)) return false;
    const modeOK = !equipment.length || environment.mode === 'custom' || exercise.mode === environment.mode;
    return modeOK && equipment.every(item => environment.equipment.includes(item));
  }
  function catalog() { return window.CF2_EXERCISE_CATALOG || []; }
  function fail(message) { return {ok: false, errors: [message]}; }
  function validate(template, environment = setup()) {
    const errors = [];
    if (!template || typeof template.name !== 'string' || !template.name.trim()) errors.push('Give the workout a name.');
    const exercises = template?.exercises;
    if (!Array.isArray(exercises) || !exercises.length || exercises.length > 10) return fail('Choose 1–10 exercises from the exercise library.');
    const names = new Set();
    let sets = 0;
    for (const row of exercises) {
      if (!Array.isArray(row) || row.length < 6) { errors.push('An exercise has incomplete set targets.'); continue; }
      const exercise = catalog().find(ex => ex.name === row[0]);
      if (!exercise) errors.push(`${String(row[0])} is not available in the exercise library.`);
      else if (!compatible(exercise, environment)) errors.push(`${exercise.name} needs equipment or an environment outside your selected setup.`);
      if (names.has(row[0])) errors.push(`${row[0]} appears twice. Choose different exercises.`);
      names.add(row[0]);
      const [count, min, max, rest] = row.slice(2, 6);
      if (![count, min, max, rest].every(Number.isInteger) || count < 1 || count > 8 || min < 1 || max < min || max > 200 || rest < 15 || rest > 600) errors.push(`${row[0]} needs valid working sets, rep targets, and rest time.`);
      sets += Number(count) || 0;
    }
    if (sets > 32) errors.push('Keep this workout to 32 working sets or fewer.');
    if (errors.length) return {ok: false, errors};
    return {ok: true, errors: [], template: {
      name: template.name.trim().slice(0, 80),
      exercises: exercises.map(row => [row[0], catalog().find(ex => ex.name === row[0]).muscle, ...row.slice(2, 6)]),
      source: typeof template.source === 'string' ? template.source.slice(0, 100) : 'custom',
      focus: focuses.includes(template.focus) ? template.focus : null
    }};
  }
  function current(key = dateKey()) { return data().days[key] ? clone(data().days[key]) : null; }
  function plannedTraining(key = dateKey()) {
    return data().ledger[key]?.plannedTraining ?? baseTrainingDay(new Date(`${key}T12:00:00`));
  }
  function primaryComplete(key = dateKey()) {
    const day = key === state.daily?.date ? state.daily : data().ledger[key];
    return !!(day?.claimed?.workout || day?.claimed?.recovery);
  }

  // Persist every daily claim, including secondary quests. Returning to an old date
  // must not recreate an empty daily wallet. Migrate the old archive without rewards.
  function ledgerDay(key) {
    if (state.daily?.date === key && data().ledger[key]) return state.daily;
    if (data().ledger[key]) return data().ledger[key];
    const archived = state.depth?.dailyArchive?.[key];
    const day = state.daily?.date === key ? state.daily : {
      date: key, steps: archived?.steps || 0, mobility: archived?.mobility || 0,
      checkin: archived?.checkin || null, claimed: {}, dayComplete: !!archived?.dayComplete,
      perfectClaimed: !!archived?.perfect
    };
    day.claimed ||= {};
    for (const code of Array.isArray(archived?.claimed) ? archived.claimed : []) day.claimed[code] ||= {rp: 0, xp: 0, coins: 0, migrated: true};
    if (day.perfectClaimed) day.claimed.perfect ||= {rp: 0, xp: 0, coins: 0, migrated: true};
    day.plannedTraining ??= archived?.training ?? baseTrainingDay(new Date(`${key}T12:00:00`));
    data().ledger[key] = clone(day);
    return day;
  }
  saveState = function saveOverrideState() {
    if (state.daily?.date) data().ledger[state.daily.date] = clone(state.daily);
    baseSaveState();
  };
  ensureDaily = function ensureOverrideDaily() {
    if (finishing) return;
    if (state.daily?.date) data().ledger[state.daily.date] = clone(state.daily);
    const key = dateKey();
    const known = data().ledger[key];
    const changed = state.daily?.date !== key;
    baseEnsureDaily();
    if (changed && known) state.daily = clone(known);
    if (state.daily.plannedTraining === undefined) {
      state.daily.plannedTraining = state.depth?.dailyArchive?.[key]?.training ?? baseTrainingDay(new Date(`${key}T12:00:00`));
    }
    const archived = state.depth?.dailyArchive?.[key];
    for (const code of Array.isArray(archived?.claimed) ? archived.claimed : []) state.daily.claimed[code] ||= {rp: 0, xp: 0, coins: 0, migrated: true};
    saveState();
  };
  todayTemplate = function overrideTodayTemplate() { return current()?.template || baseTodayTemplate(); };
  isTrainingDay = function overrideTrainingDay(date = demoDate()) {
    const key = keyForDate(date);
    return !!data().days[key] || plannedTraining(key);
  };
  // The program rotation consumes one scheduled slot, never an extra session or
  // a workout chosen on a recovery day. Old history is deduplicated by date.
  workoutCount = function overrideWorkoutCount() {
    const dates = new Set();
    for (const entry of state.history) {
      if (entry.type !== 'workout') continue;
      const inFlight = finishing && entry === state.history[finishing.historyIndex];
      const credited = inFlight ? !!finishing.credit : entry.primaryCredit ?? entry.eligible;
      if (credited && plannedTraining(entry.date)) dates.add(entry.date);
    }
    return dates.size;
  };

  function availableWorkouts() {
    const entries = [];
    const add = (template, id, source) => {
      const result = validate({...template, source});
      if (result.ok) entries.push({id, name: result.template.name, source, template: result.template});
    };
    cfProgram().forEach((w, i) => add(w, `plan:${i}`, 'Current program'));
    for (const p of window.CF2_PROGRAM_LIBRARY || []) (p.workouts || []).forEach((w, i) => add(w, `lib:${p.id}:${i}`, p.name));
    for (const p of state.cf2?.customPrograms || []) (p.workouts || []).forEach((w, i) => add(w, `custom:${p.id}:${i}`, `Saved: ${p.name}`));
    for (const w of data().saved) add(w.template, `saved:${w.id}`, 'Saved workout');
    return clone(entries);
  }
  function generate(focus) {
    if (!focuses.includes(focus)) return fail('Choose a supported muscle focus.');
    const available = catalog().filter(ex => compatible(ex));
    const mainMuscle = ex => ex.muscle.split('·')[0].trim();
    let selected;
    if (focus === 'Full Body') {
      selected = ['Legs', 'Chest', 'Back', 'Core', 'Shoulders'].map(group => available.find(ex => groups[group].test(mainMuscle(ex)))).filter(Boolean);
      if (!['Legs', 'Chest', 'Back'].every(group => selected.some(ex => groups[group].test(mainMuscle(ex))))) return fail('Your selected equipment does not have enough library exercises for a full-body workout. Choose another focus or update your equipment.');
    } else selected = available.filter(ex => groups[focus].test(mainMuscle(ex)));
    if (!selected.length) return fail(`No ${focus.toLowerCase()} exercises match your selected equipment. Choose another focus or update your equipment.`);
    const limit = state.plan.minutes <= 30 ? 3 : state.plan.minutes <= 45 ? 4 : 5;
    const habit = state.plan.goal === 'habit';
    return validate({name: `${focus} · Today`, source: 'Muscle focus', focus, exercises: selected.slice(0, focus === 'Full Body' ? Math.max(4, limit) : limit).map(ex => {
      const timed = /plank/i.test(ex.name);
      return [ex.name, ex.muscle, habit ? 2 : 3, timed ? 30 : 8, timed ? 45 : 12, timed ? 45 : habit ? 60 : 90];
    })});
  }
  function apply(template) {
    ensureDaily();
    if (state.workout.active) return fail('Finish your active workout before changing today’s workout.');
    const result = validate(template);
    if (!result.ok) return result;
    const key = dateKey();
    data().days[key] = {date: key, template: clone(result.template), source: result.template.source, focus: result.template.focus, approvedAt: new Date().toISOString()};
    saveState();
    return {ok: true, errors: [], override: current()};
  }
  function clear() {
    if (state.workout.active) return fail('Finish your active workout before restoring today’s plan.');
    delete data().days[dateKey()]; saveState();
    return {ok: true, errors: []};
  }
  function saveCurrent(name) {
    const active = current();
    if (!active) return fail('Choose a workout for today first.');
    const result = validate({...active.template, name: name || active.template.name});
    if (!result.ok) return result;
    const existing = data().saved.find(w => JSON.stringify(w.template.exercises) === JSON.stringify(result.template.exercises) && w.template.name === result.template.name);
    if (existing) return {ok: true, errors: [], id: existing.id, template: clone(existing.template)};
    const id = `override_${Date.now()}_${data().saved.length}`;
    data().saved.push({id, template: result.template}); saveState();
    return {ok: true, errors: [], id, template: clone(result.template)};
  }
  function preview(template = todayTemplate()) {
    const rows = template.exercises || [];
    const equipment = [...new Set(rows.flatMap(row => catalog().find(ex => ex.name === row[0])?.equipment || []))];
    return {name: template.name, exercises: clone(rows), totalSets: rows.reduce((sum, row) => sum + row[2], 0),
      minutes: Math.max(1, Math.round((rows.reduce((sum, row) => sum + row[2] * (40 + row[5]), 0) + 180) / 60)),
      equipment: equipment.length ? equipment.map(key => CF_EQUIPMENT.find(row => row[0] === key)?.[1] || key) : ['Bodyweight'],
      overridden: !!current(), primaryComplete: primaryComplete(), focus: template.focus || null};
  }

  rewardOnce = function overrideRewardOnce(code, reward) {
    ensureDaily();
    const day = state.daily;
    if (code === 'workout' || code === 'recovery') {
      if (primaryComplete(day.date)) return false;
      if (code === 'workout' && !finishing?.approved) return false;
      if (code === 'recovery' && day.plannedTraining) return false;
      // A recovery-day override uses the same recovery budget: frequency and
      // swapping cannot turn a recovery day into an extra reward source.
      if (code === 'workout' && !day.plannedTraining) reward = {rp: 30, xp: 160, coins: 65};
    }
    if (code === 'mobility' && !day.plannedTraining) return false;
    const awarded = baseRewardOnce(code, reward);
    if (awarded && (code === 'workout' || code === 'recovery')) {
      if (finishing) finishing.credit = clone(day.claimed[code]);
    }
    saveState();
    return awarded;
  };

  markDayComplete = function overrideMarkDayComplete() {
    ensureDaily();
    if (state.daily.dayComplete) return;
    state.daily.dayComplete = true;
    const completeDates = new Set(Object.values(data().ledger).filter(day => day.dayComplete).map(day => day.date));
    completeDates.add(state.daily.date);
    for (const day of Object.values(state.depth?.dailyArchive || {})) if (day.dayComplete) completeDates.add(day.date);
    const latest = [...completeDates].sort().at(-1);
    let streak = 0;
    for (let key = latest; key && completeDates.has(key); key = previousDateKey(new Date(`${key}T12:00:00`))) streak++;
    state.profile.streak = streak;
    state.profile.lastStreakDate = latest;
    state.profile.longestStreak = Math.max(state.profile.longestStreak || 0, streak);
    saveState();
  };
  evaluateDaily = function overrideEvaluateDaily() {
    ensureDaily();
    if (primaryComplete(state.daily.date)) markDayComplete();
    const required = state.daily.plannedTraining ? ['steps', 'mobility', 'checkin'] : ['steps', 'checkin'];
    if (primaryComplete(state.daily.date) && required.every(key => state.daily.claimed[key]) && !state.daily.perfectClaimed) {
      state.daily.perfectClaimed = true;
      if (rewardOnce('perfect', {rp: 15, xp: 60, coins: 30})) toast('Perfect day bonus: +15 RP');
    }
    saveState();
  };

  function snapshot(workout) {
    workout.startedDate ||= state.daily.date;
    workout.approvedTemplate ||= {name: workout.name, exercises: workout.exercises.map(ex => [ex.name, ex.muscle, ex.sets.length, ex.repMin, ex.repMax, ex.rest])};
    workout.overrideSnapshot ??= current(workout.startedDate);
    workout.setupSnapshot ||= setup();
    workout.plannedTraining ??= plannedTraining(workout.startedDate);
    workout.approvedDay ??= workout.plannedTraining || !!workout.overrideSnapshot;
  }
  startWorkout = function overrideStartWorkout() {
    ensureDaily();
    if (state.workout.active) {
      snapshot(state.workout.active); saveState(); renderWorkout();
      document.getElementById('workoutOverlay').classList.add('show');
      document.body.style.overflow = 'hidden';
      return;
    }
    const override = current();
    if (override) {
      const result = validate(override.template);
      if (!result.ok) { toast(result.errors[0]); return; }
    }
    baseStartWorkout();
    if (state.workout.active) { snapshot(state.workout.active); saveState(); }
  };
  function qualifies(workout) {
    const plannedSets = workout.approvedTemplate.exercises.reduce((sum, row) => sum + row[2], 0);
    const sets = workout.exercises.flatMap(ex => ex.sets);
    const valid = set => Number.isFinite(set.weight) && set.weight >= 0 && Number.isInteger(set.reps) && set.reps > 0 && set.reps <= 200;
    const done = sets.filter(set => set.done && valid(set)).length;
    if (!workout.approvedDay || !plannedSets || !sets.length || done < Math.ceil(plannedSets * .7) || done < Math.ceil(sets.length * .7)) return false;
    if (workout.overrideSnapshot && !validate({name: workout.name, exercises: workout.exercises.map(ex => [ex.name, ex.muscle, ex.sets.length, ex.repMin, ex.repMax, ex.rest])}, workout.setupSnapshot).ok) return false;
    return true;
  }
  finishWorkout = function overrideFinishWorkout(difficulty) {
    ensureDaily();
    const workout = state.workout.active;
    if (!workout) return;
    snapshot(workout);
    if (!workout.exercises.some(ex => ex.sets.some(set => set.done))) { toast('Complete at least one set first'); return; }
    const currentDay = state.daily;
    const index = state.history.length;
    finishing = {date: workout.startedDate, approved: qualifies(workout), credit: null, historyIndex: index};
    state.daily = ledgerDay(finishing.date);
    try {
      baseFinishWorkout(difficulty);
      const entry = state.history[index];
      if (entry) {
        entry.completed = finishing.approved;
        entry.primaryCredit = !!finishing.credit;
        entry.eligible = entry.primaryCredit;
        entry.reward = finishing.credit ? {rp: finishing.credit.rp, xp: finishing.credit.xp, coins: finishing.credit.coins} : {rp: 0, xp: 0, coins: 0};
        entry.override = clone(workout.overrideSnapshot);
        entry.plannedTemplate = clone(workout.approvedTemplate);
        entry.sessionDate = workout.startedDate;
      }
    } finally {
      data().ledger[state.daily.date] = clone(state.daily);
      finishing = null;
      state.daily = currentDay;
      ensureDaily(); saveState(); renderAll();
    }
  };

  if (typeof window.cfReplaceExercise === 'function') {
    const baseReplaceExercise = window.cfReplaceExercise;
    window.cfReplaceExercise = function overrideReplaceExercise(index) {
      const ex = window.__cfSubs?.[index];
      const match = ex && catalog().find(item => item.name === ex.name);
      if (!match || !compatible(match)) return toast('This exercise is not compatible with your selected equipment.');
      return baseReplaceExercise(index);
    };
  }

  function programByRef(ref) {
    if (typeof ref !== 'string') return null;
    if (ref.startsWith('lib:')) return (window.CF2_PROGRAM_LIBRARY || []).find(program => program.id === ref.slice(4));
    if (ref.startsWith('custom:')) return (state.cf2?.customPrograms || []).find(program => program.id === ref.slice(7));
    return null;
  }
  function programCompatibility(program) {
    const workouts = program?.workouts || [];
    if (!workouts.length) return fail('This program has no workouts.');
    const errors = [...new Set(workouts.flatMap(workout => validate(workout).errors))];
    return {ok: errors.length === 0, errors};
  }
  function programEquipment(program) {
    const keys = [...new Set((program.workouts || []).flatMap(workout => (workout.exercises || []).flatMap(row => catalog().find(ex => ex.name === row[0])?.equipment || [])))];
    return keys.length ? keys.map(key => CF_EQUIPMENT.find(row => row[0] === key)?.[1] || key).join(' · ') : 'Bodyweight';
  }
  if (typeof window.cf2UseProgram === 'function') {
    const baseUseProgram = window.cf2UseProgram;
    window.cf2UseProgram = function activateCompatibleProgram(ref) {
      if (state.workout.active) return toast('Finish your active session before changing your program.');
      const program = programByRef(ref);
      if (!program) return toast('This program is no longer available.');
      const result = programCompatibility(program);
      if (!result.ok) {
        openSheet(`<div class="eyebrow">YOUR EQUIPMENT COMES FIRST</div><h2>Update your setup before using this program</h2><p class="sub">${escapeHtml(program.name)} requires exercises outside your selected equipment or environment. Your current plan is still active.</p><div class="card"><b>Equipment used</b><p class="sub">${escapeHtml(programEquipment(program))}</p></div><ul>${result.errors.slice(0, 8).map(error => `<li>${escapeHtml(error)}</li>`).join('')}</ul><div class="ux-actions"><button class="primary" onclick="openPlanBuilder()">Update training setup</button><button class="ghost" onclick="closeSheet()">Keep current plan</button></div>`);
        return;
      }
      const selectedSetup = setup();
      baseUseProgram(ref);
      // Program activation may update its schedule and goal, but the user's
      // explicit equipment/environment selection remains the source of truth.
      state.plan.mode = selectedSetup.mode;
      state.plan.equipment = selectedSetup.equipment;
      saveState(); renderAll();
    };
  }
  if (typeof window.cf2ProgramDetails === 'function') {
    const baseProgramDetails = window.cf2ProgramDetails;
    window.cf2ProgramDetails = function compatibleProgramDetails(ref) {
      baseProgramDetails(ref);
      const program = programByRef(ref), sheet = document.getElementById('sheetContent');
      if (!program || !sheet) return;
      const result = programCompatibility(program);
      sheet.insertAdjacentHTML('beforeend', `<div class="card"><b>${result.ok ? 'Matches your selected setup' : 'Requires selected equipment · update setup first'}</b><p class="sub">Equipment used: ${escapeHtml(programEquipment(program))}.</p><p class="sub">${result.ok ? 'Your equipment and environment stay in place when you activate this program.' : 'The full program must match your selected equipment and environment before it can become active.'}</p>${result.ok ? '' : '<button class="ghost" onclick="openPlanBuilder()">Update training setup</button>'}</div>`);
    };
  }
  window.CFOverride = Object.freeze({focuses: Object.freeze(focuses), availableWorkouts, generate, validate, apply, clear, current, saveCurrent, preview, primaryComplete, plannedTraining, compatible});
  ensureDaily();
  if (state.workout.active) { snapshot(state.workout.active); saveState(); }
})();
