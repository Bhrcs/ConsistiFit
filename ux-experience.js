/* Local-first presentation and recap helpers. Loaded after the workout domain. */
(() => {
  const clone = value => JSON.parse(JSON.stringify(value));
  const dateAt = key => new Date(`${key}T12:00:00`);
  const shiftDate = (date, days) => { const next = new Date(date); next.setDate(next.getDate() + days); return next; };
  const weekStart = date => shiftDate(date, -((date.getDay() + 6) % 7));
  const claimed = record => Array.isArray(record?.claimed) ? record.claimed : Object.keys(record?.claimed || {});
  const primaryDone = record => !!record?.dayComplete || claimed(record).some(x => x === 'workout' || x === 'recovery');
  const ux = () => (state.ux ||= { dismissedSuggestions: {} });
  const recordFor = key => state.daily?.date === key ? { ...state.daily, training: CFOverride.plannedTraining(key) } : state.workoutOverrides?.ledger?.[key] || state.depth?.dailyArchive?.[key];
  const firstDate = () => state.depth?.firstDate || state.daily.date;

  function weeklyRecap(offset = 0) {
    const today = keyForDate(demoDate());
    const start = shiftDate(weekStart(demoDate()), offset * 7);
    const days = Array.from({ length: 7 }, (_, i) => {
      const date = shiftDate(start, i), key = keyForDate(date), record = recordFor(key);
      return { key, date, record, tracked: key >= firstDate() && key <= today, complete: primaryDone(record) };
    });
    const elapsed = days.filter(d => d.tracked), complete = elapsed.filter(d => d.complete).length;
    const keys = new Set(days.map(d => d.key));
    const workouts = state.history.filter(h => h.type === 'workout' && keys.has(h.date));
    let rp = 0, legacyRp = false;
    for (const d of elapsed) {
      const rewards = d.record?.claimed;
      if (Array.isArray(rewards)) {
        // Older archives stored only reward keys. Never invent an exact historical RP total.
        if (rewards.length) legacyRp = true;
      } else if (rewards) {
        if (Object.values(rewards).some(reward => reward?.migrated)) legacyRp = true;
        rp += Object.values(rewards).reduce((sum, reward) => sum + (Number(reward?.rp) || 0), 0);
      }
    }
    let longest = 0, run = 0;
    for (const d of elapsed) { run = d.complete ? run + 1 : 0; longest = Math.max(longest, run); }
    return { start: keyForDate(start), days, elapsed: elapsed.length, complete, score: elapsed.length ? Math.round(complete / elapsed.length * 100) : 0,
      workouts: workouts.length, recovery: elapsed.filter(d => claimed(d.record).includes('recovery')).length,
      rp, legacyRp, prs: workouts.reduce((sum, h) => sum + (h.prs?.length || 0), 0), longest };
  }

  function adaptation() {
    const today = demoDate(), days = Number(state.plan?.days) || 3;
    let scheduled = 0, completed = 0;
    for (let i = 14; i >= 1; i--) {
      const date = shiftDate(today, -i), key = keyForDate(date);
      if (key < firstDate()) continue;
      const record = recordFor(key);
      const training = record?.training ?? CFOverride.plannedTraining(keyForDate(date));
      if (!training) continue;
      scheduled++;
      if (primaryDone(record)) completed++;
    }
    if (scheduled < 5 || completed / scheduled >= .7 || days <= 2) return null;
    const id = `${keyForDate(weekStart(today))}:${days}`;
    if (ux().dismissedSuggestions?.[id]) return null;
    return { id, scheduled, completed, from: days, to: days - 1,
      reason: `You completed ${completed} of your last ${scheduled} scheduled workouts. A ${days - 1}-day plan may be easier to sustain.` };
  }

  function nextSchedule(start = shiftDate(weekStart(demoDate()), 7)) {
    const program = cfProgram();
    let index = typeof workoutCount === 'function' ? workoutCount() : 0;
    return Array.from({ length: 7 }, (_, i) => {
      const date = shiftDate(start, i), training = CFOverride.plannedTraining(keyForDate(date));
      return { date: keyForDate(date), label: date.toLocaleDateString(undefined, { weekday: 'short' }),
        name: training ? program[index++ % program.length]?.name || 'Planned workout' : 'Recovery + Mobility' };
    });
  }

  function milestoneText(streak) {
    const milestones = [3, 7, 14, 30, 60, 90];
    const reached = milestones.filter(x => x <= streak).at(-1), next = milestones.find(x => x > streak);
    if (!streak) return 'One planned day is a fresh start. Recovery counts too.';
    return `${streak} consistent days${reached ? ` · ${reached}-day milestone reached` : ''}.${next ? ` Next milestone: ${next} days.` : ' Keep your rhythm.'}`;
  }

  function exerciseRows(template) {
    return template.exercises.map((e, index) => {
      const recent = [...state.history].reverse().find(h => (h.sets || []).some(s => s.done && s.exercise === e[0]));
      const sets = recent?.sets.filter(s => s.done && s.exercise === e[0]) || [];
      const previous = sets.length ? `${recent.date}: ${sets.map(s => `${s.weight || 0} lb × ${s.reps}`).join(' · ')}` : 'Complete this exercise to unlock your history.';
      const unit = /plank/i.test(e[0]) ? 'sec' : 'reps';
      return `<li><div class="ux-exercise-heading"><b>${index + 1}. ${escapeHtml(e[0])}</b><span>${e[2]} sets</span></div><div class="sub">${e[3]}–${e[4]} ${unit} · ${e[5]} sec rest</div><div class="sub">Last time: ${escapeHtml(previous)}</div></li>`;
    }).join('');
  }

  let pendingTemplate = null;
  function openPreview(template = todayTemplate(), replacement = false) {
    pendingTemplate = clone(template);
    const p = CFOverride.preview(template), validation = CFOverride.validate(template);
    openSheet(`<div class="eyebrow">${replacement ? 'CHANGE TODAY ONLY' : 'PRE-WORKOUT PREVIEW'}</div><h2>${escapeHtml(template.name)}</h2>
      <p class="sub">About ${p.minutes} min · ${p.totalSets} working sets · ${CFOverride.primaryComplete() ? 'Primary reward already earned today' : '+30 base RP when completed'}</p>
      <div class="card"><b>Equipment</b><p class="sub">${escapeHtml(Array.isArray(p.equipment) ? p.equipment.join(' · ') || 'Bodyweight' : p.equipment || 'Bodyweight')}</p></div>
      <ol class="ux-exercise-list">${exerciseRows(template)}</ol>
      ${validation.ok ? '' : `<p class="ux-notice" role="status">${escapeHtml(validation.errors.join(' '))}</p>`}
      <p class="sub">${replacement ? 'This replaces today only. Your recurring program stays in place. Save separately if you want to reuse it.' : 'Complete at least 70% of the approved working sets. Your primary mission earns credit once today.'}</p>
      <div class="ux-actions"><button class="primary" onclick="${replacement ? 'cfUxApplyOverride()' : 'cfUxBeginWorkout()'}" ${validation.ok ? '' : 'disabled'}>${replacement ? 'Use for today' : 'Start workout'}</button><button class="ghost" onclick="cfUxChangeToday()">Choose another workout</button></div>`);
  }
  window.cfUxPreview = () => state.workout.active ? startWorkout() : openPreview();
  window.cfUxBeginWorkout = () => { closeSheet(); beginWorkout(); };
  window.cfUxApplyOverride = () => {
    const result = CFOverride.apply(pendingTemplate);
    if (!result.ok) return toast(result.errors.join(' '));
    closeSheet(); renderAll(); toast('Workout changed for today only'); openPreview();
  };
  window.cfUxChangeToday = () => {
    if (state.workout.active) return toast('Finish your active session before changing today.');
    const workouts = CFOverride.availableWorkouts();
    window.__cfUxWorkouts = workouts;
    openSheet(`<div class="eyebrow">YOUR DAY, YOUR PLAN</div><h2>Change today’s workout</h2><p class="sub">Choose a muscle focus or a compatible saved workout. The change applies to today only; your primary reward can be earned once.</p>
      <div class="section-title">BUILD FROM YOUR EXERCISE LIBRARY</div><div class="ux-focus-grid">${CFOverride.focuses.map((focus, i) => `<button class="ghost" onclick="cfUxGenerate(${i})">${escapeHtml(focus)}</button>`).join('')}</div>
      <p class="sub">Filtered to your selected environment and equipment. If a focus has no compatible exercises, update your equipment or choose another focus.</p>
      <div class="section-title">SAVED + PROGRAM WORKOUTS</div>${workouts.length ? workouts.map((w, i) => `<button class="sheet-option" onclick="cfUxSelectWorkout(${i})"><span><b>${escapeHtml(w.name)}</b><small class="sub">${escapeHtml(w.source)}</small></span><span aria-hidden="true">›</span></button>`).join('') : '<p class="sub">No saved workouts match this equipment yet. Try a muscle focus above.</p>'}
      ${CFOverride.current() ? '<button class="ghost" onclick="cfUxClearOverride()">Restore today’s planned session</button><button class="ghost" onclick="cfUxSaveOverride()">Save today’s workout to my library</button>' : ''}`);
  };
  window.cfUxGenerate = index => {
    const result = CFOverride.generate(CFOverride.focuses[index]);
    if (!result.ok) return toast(result.errors.join(' '));
    openPreview(result.template, true);
  };
  window.cfUxSelectWorkout = index => { const choice = window.__cfUxWorkouts?.[index]; if (choice) openPreview(choice.template, true); };
  window.cfUxClearOverride = () => { const result = CFOverride.clear(); if (!result.ok) return toast(result.errors.join(' ')); closeSheet(); renderAll(); toast('Today’s plan restored'); };
  window.cfUxSaveOverride = () => { const result = CFOverride.saveCurrent(); toast(result.ok ? 'Saved to your library. Your recurring plan is unchanged.' : result.errors.join(' ')); };

  const beginWorkout = startWorkout;
  startWorkout = function previewBeforeWorkout() {
    ensureDaily();
    if (state.workout.active) return beginWorkout();
    if (!isTrainingDay()) return window.cfUxRecovery();
    openPreview();
  };

  window.cfUxRecovery = () => {
    openSheet(`<div class="eyebrow">RECOVERY IS PART OF CONSISTENCY</div><h2>Give yourself room to recover.</h2><p class="sub">Today still counts toward your rank. Ten minutes of intentional recovery completes your primary mission.</p>
      <div class="card"><b>A gentle 10-minute reset</b><ol class="ux-recovery-list"><li>2 minutes of relaxed walking and breathing</li><li>4 minutes of comfortable shoulder and upper-back mobility</li><li>4 minutes of gentle hip and ankle movement</li></ol><p class="sub">Stay within a comfortable range. Choose easy movement that suits how you feel.</p></div>
      <label for="uxRecoveryMinutes">Recovery minutes</label><div class="input-row"><input id="uxRecoveryMinutes" inputmode="numeric" type="number" min="0" max="180" value="${Number(state.daily.mobility) || 0}"><button class="primary" onclick="cfUxLogRecovery()">Save recovery</button></div>
      <p class="sub" role="status">${CFOverride.primaryComplete() ? 'Primary mission complete. Your progress is saved.' : '30 base RP available once today.'}</p>
      <div class="section-title">HOW ARE YOU FEELING?</div><div class="ux-focus-grid">${['Ready', 'Tired', 'Sore'].map(value => `<button class="ghost" aria-pressed="${state.daily.checkin === value}" onclick="completeCheckin('${value}');cfUxRecovery()">${value}</button>`).join('')}</div>
      <p class="sub">Easy walking is optional; ${formatNum(state.daily.steps || 0)} steps logged today.</p><button class="ghost" onclick="closeSheet();showScreen('missions')">Log steps and other missions</button><button class="ghost" onclick="cfUxChangeToday()">Choose a workout for today instead</button>`);
  };

  window.cfUxLogRecovery = () => {
    ensureDaily();
    const minutes = Number(document.getElementById('uxRecoveryMinutes')?.value);
    if (!Number.isFinite(minutes) || minutes < 0 || minutes > 180) return toast('Enter recovery minutes from 0 to 180.');
    state.daily.mobility = Math.round(minutes);
    if (minutes >= 10) {
      const training = CFOverride.plannedTraining(state.daily.date);
      rewardOnce(training ? 'mobility' : 'recovery', training ? {rp:10,xp:50,coins:25} : {rp:30,xp:160,coins:65});
    }
    saveState(); evaluateDaily(); renderAll(); window.cfUxRecovery();
  };

  window.cfUxDismissAdaptation = () => { const suggestion = adaptation(); if (suggestion) { ux().dismissedSuggestions ||= {}; ux().dismissedSuggestions[suggestion.id] = true; saveState(); renderAll(); } };
  window.cfUxAcceptAdaptation = () => {
    const suggestion = adaptation();
    if (!suggestion) return;
    if (state.workout.active) return toast('Finish your active session before changing your schedule.');
    state.plan.days = suggestion.to;
    ux().dismissedSuggestions ||= {}; ux().dismissedSuggestions[suggestion.id] = true;
    saveState(); renderAll(); toast(`Your schedule is now ${suggestion.to} training days per week.`);
  };

  function recapHTML(offset) {
    const r = weeklyRecap(offset);
    return `<div class="eyebrow">${offset ? 'LAST WEEK' : 'THIS WEEK'} · WEEK OF ${r.start}</div><h2>${r.complete} / ${r.elapsed} planned days</h2><p class="sub">${r.elapsed ? `${r.score}% consistency so far. Training and planned recovery count equally.` : 'Your first recap will appear as you complete planned days.'}</p>
      <div class="ux-metrics"><div><b>${r.workouts}</b><span>Workouts logged</span></div><div><b>${r.recovery}</b><span>Recovery days</span></div><div><b>${r.legacyRp ? '—' : '+' + r.rp}</b><span>RP earned</span></div><div><b>${r.prs}</b><span>Personal records</span></div></div>
      ${r.legacyRp ? '<p class="sub">Exact RP was not recorded in older daily archives.</p>' : ''}<p class="sub">Longest streak this week: ${r.longest} days. ${escapeHtml(milestoneText(state.profile.streak))}</p>
      <div class="section-title">NEXT WEEK · CURRENT PLAN</div><p class="sub">Workout order is projected from your current rotation.</p>${nextSchedule(shiftDate(dateAt(r.start), 7)).map(d => `<div class="ux-schedule-row"><span>${d.label}</span><b>${escapeHtml(d.name)}</b></div>`).join('')}`;
  }
  window.cfUxRecap = (offset = 0) => openSheet(`${recapHTML(offset)}<div class="ux-actions"><button class="ghost" onclick="cfUxRecap(${offset ? 0 : -1})">${offset ? 'This week' : 'Last week'}</button></div>`);

  function enhanceToday() {
    const screen = document.getElementById('screen-home');
    if (!screen) return;
    screen.querySelector('.cf-core-planfit')?.remove();
    const hero = screen.querySelector('.hero');
    if (hero) {
      const training = isTrainingDay(), active = state.workout.active, template = active ? { name: active.name, exercises: active.exercises.map(e => [e.name, e.muscle, e.sets.length, e.repMin, e.repMax, e.rest]) } : todayTemplate();
      const p = CFOverride.preview(template), complete = CFOverride.primaryComplete();
      const earlierSession = active?.startedDate && active.startedDate !== state.daily.date;
      const recent = [...state.history].reverse().find(h => h.type === 'workout' && h.name === template.name);
      hero.classList.add('ux-today');
      hero.innerHTML = `<div class="eyebrow">TODAY · ${CFOverride.current() ? 'DAY-ONLY WORKOUT' : training ? 'PLANNED TRAINING' : 'PLANNED RECOVERY'}</div><h2>${escapeHtml(active ? active.name : training ? template.name : 'Recover with purpose')}</h2>
        <p>${training || active ? `About ${p.minutes} min · ${p.totalSets} working sets · ${template.exercises.length} exercises` : '10 minutes · gentle mobility · optional easy walking'}</p>
        <div class="ux-reward">${earlierSession ? `Resume your ${escapeHtml(active.startedDate)} session` : complete ? '✓ Primary mission complete' : '+30 base RP · your primary mission'}</div>
        ${earlierSession ? '<p class="sub">This session counts toward its start date. Today’s mission remains separate.</p>' : ''}
        <p class="sub">${training ? recent ? `Last time: ${recent.date} · ${recent.completedSets} sets completed` : 'Your first session builds a starting point for next time.' : 'Recovery supports tomorrow’s training and counts toward your consistency.'}</p>
        <div class="ux-actions"><button class="primary" onclick="${training || active ? 'startWorkout()' : 'cfUxRecovery()'}">${active ? 'Resume workout' : training ? 'Preview workout' : 'Open recovery'}</button><button class="ghost" onclick="cfUxChangeToday()" ${active ? 'disabled' : ''}>Change today</button></div>
        ${CFOverride.current() ? '<div class="ux-actions"><button class="ghost small" onclick="cfUxSaveOverride()">Save to my library</button><button class="ghost small" onclick="cfUxClearOverride()">Restore plan</button></div>' : ''}`;
    }
    screen.querySelector('.ux-streak')?.remove();
    hero?.insertAdjacentHTML('afterend', `<p class="sub ux-streak">${escapeHtml(milestoneText(state.profile.streak))}</p>`);
    const week = screen.querySelector('.cf-week-overview');
    if (week && !week.querySelector('.ux-recap-button')) week.insertAdjacentHTML('beforeend', '<button class="ghost ux-recap-button" onclick="cfUxRecap()">View weekly recap</button>');
    screen.querySelector('.ux-adaptation')?.remove();
    const suggestion = adaptation();
    if (suggestion) hero?.insertAdjacentHTML('afterend', `<div class="card ux-adaptation"><div class="eyebrow">PLAN FIT · YOUR CHOICE</div><b>Make room for a repeatable week</b><p class="sub">${escapeHtml(suggestion.reason)} This updates your training frequency to ${suggestion.to} days and keeps your workout rotation.</p><div class="ux-actions"><button class="primary" onclick="cfUxAcceptAdaptation()">Use ${suggestion.to} days</button><button class="ghost" onclick="cfUxDismissAdaptation()">Keep my plan</button></div></div>`);
  }

  // Store full reward receipts for new archives; previous versions stored keys only.
  const ensureBeforeUx = ensureDaily;
  ensureDaily = function archiveRewardDetails() {
    const previous = state.daily?.date && state.daily.date !== keyForDate(demoDate()) ? clone(state.daily) : null;
    ensureBeforeUx();
    if (previous && state.depth?.dailyArchive?.[previous.date]) {
      state.depth.dailyArchive[previous.date].claimed = previous.claimed;
      saveState();
    }
  };

  let sessionForSummary = null;
  const finishBeforeUx = finishWorkout;
  finishWorkout = function finishWithNextTime(difficulty) {
    sessionForSummary = state.workout.active ? clone(state.workout.active) : null;
    finishBeforeUx(difficulty);
  };
  function summaryHTML() {
    const h = [...state.history].reverse().find(x => x.type === 'workout');
    if (!h || !sessionForSummary) return null;
    const reward = h.reward || {}, rp = Number(reward.rp) || 0;
    const creditedDay = h.sessionDate && h.sessionDate !== state.daily.date ? `The primary mission for ${h.sessionDate} is complete. Today’s mission remains separate.` : 'Today’s primary mission is complete.';
    const next = nextSchedule(shiftDate(demoDate(), 1))[0];
    const recommendations = sessionForSummary.exercises.filter(e => e.sets.some(s => s.done)).map(ex => {
      const recommendation = cfCoreRecommendation(ex);
      const prior = state.history.filter(x => x !== h && x.type === 'workout' && (x.sets || []).some(s => s.done && s.exercise === ex.name)).at(-1);
      const currentSets = (h.sets || []).filter(s => s.done && s.exercise === ex.name), priorSets = (prior?.sets || []).filter(s => s.done && s.exercise === ex.name);
      const comparable = priorSets.length === currentSets.length && priorSets.length && currentSets.every((s, i) => Number(s.weight) === Number(priorSets[i].weight));
      const delta = comparable ? currentSets.reduce((sum, s) => sum + Number(s.reps), 0) - priorSets.reduce((sum, s) => sum + Number(s.reps), 0) : null;
      return `<li><b>${escapeHtml(ex.name)}</b><div>${recommendation.weight ? `${recommendation.weight} lb × ` : ''}${recommendation.reps} ${/plank/i.test(ex.name) ? 'sec' : 'reps'}</div><p class="sub">${escapeHtml(recommendation.reason)}${delta > 0 ? ` You added ${delta} reps at the same load.` : ''}</p></li>`;
    }).join('');
    const prs = (h.prs || []).map(pr => `<li><b>${escapeHtml(pr.exercise)}</b><div class="sub">${escapeHtml(pr.type)} · ${escapeHtml(pr.value)}</div></li>`).join('');
    return `<div class="eyebrow">SESSION SAVED ON THIS DEVICE</div><h2>${h.completed ? 'You showed up.' : 'Progress, one set at a time.'}</h2><p class="sub">${h.completedSets} / ${h.totalSets} sets · ${h.duration} min</p><div class="card"><b>${rp ? `+${rp} RP · +${reward.xp || 0} XP · +${reward.coins || 0} Coins` : 'Session logged · no additional primary reward'}</b><p class="sub">${h.primaryCredit ? escapeHtml(creditedDay) : h.completed ? 'Primary credit is available once per planned day.' : 'Complete at least 70% of the approved sets to satisfy the primary workout mission.'}</p></div>${prs ? `<div class="section-title">PERSONAL RECORDS</div><ul class="ux-exercise-list">${prs}</ul>` : ''}<div class="section-title">NEXT TIME</div><ol class="ux-exercise-list">${recommendations}</ol><div class="card"><b>Tomorrow: ${escapeHtml(next.name)}</b><p class="sub">${escapeHtml(milestoneText(state.profile.streak))}</p></div><button class="primary" onclick="closeSheet();showScreen('progress')">View progress</button>`;
  }

  let restoreFocus = null;
  const openBeforeUx = openSheet, closeBeforeUx = closeSheet;
  openSheet = function accessibleSheet(html) {
    if (html.includes('cf-summary') && sessionForSummary) html = summaryHTML() || html;
    const sheet = document.getElementById('sheetContent'), back = document.getElementById('sheetBack');
    if (!back.classList.contains('show')) restoreFocus = document.activeElement;
    openBeforeUx(`<button class="ghost ux-sheet-close" aria-label="Close dialog" onclick="closeSheet()">Close ×</button>${html}`);
    sheet.setAttribute('role', 'dialog'); sheet.setAttribute('aria-modal', 'true'); sheet.setAttribute('tabindex', '-1');
    sheet.setAttribute('aria-label', sheet.querySelector('h2')?.textContent || 'ConsistiFit details');
    document.querySelector('.app')?.setAttribute('inert', ''); document.querySelector('.bottomnav')?.setAttribute('inert', '');
    document.getElementById('workoutOverlay')?.setAttribute('inert', '');
    sheet.focus();
  };
  closeSheet = function closeAccessibleSheet() {
    closeBeforeUx();
    document.querySelector('.app')?.removeAttribute('inert'); document.querySelector('.bottomnav')?.removeAttribute('inert');
    document.getElementById('workoutOverlay')?.removeAttribute('inert');
    if (restoreFocus?.isConnected) restoreFocus.focus();
  };
  document.addEventListener('keydown', event => {
    if (!document.getElementById('sheetBack')?.classList.contains('show')) return;
    if (event.key === 'Escape') { event.preventDefault(); closeSheet(); }
    if (event.key !== 'Tab') return;
    const sheet = document.getElementById('sheetContent'), targets = [...sheet.querySelectorAll('button:not([disabled]), input, select, textarea, [tabindex="0"]')].filter(el => !el.hidden);
    const first = targets[0], last = targets.at(-1);
    if (!first) return event.preventDefault();
    if (event.shiftKey && (document.activeElement === first || document.activeElement === sheet)) { event.preventDefault(); last.focus(); }
    else if (!event.shiftKey && (document.activeElement === last || document.activeElement === sheet)) { event.preventDefault(); first.focus(); }
  });

  const renderWorkoutBeforeUx = renderWorkout;
  renderWorkout = function accessibleWorkout() {
    renderWorkoutBeforeUx();
    const workout = state.workout.active;
    if (!workout) return;
    const ex = workout.exercises[workout.exerciseIndex];
    document.querySelectorAll('#workoutContent .set-grid:not(.header)').forEach((row, i) => {
      const inputs = row.querySelectorAll('input');
      inputs[0]?.setAttribute('aria-label', `${ex.name}, set ${i + 1}, weight in pounds`);
      inputs[1]?.setAttribute('aria-label', `${ex.name}, set ${i + 1}, ${/plank/i.test(ex.name) ? 'seconds' : 'reps'}`);
      row.querySelector('button')?.setAttribute('aria-label', `${ex.sets[i]?.done ? 'Unmark' : 'Complete'} ${ex.name} set ${i + 1}`);
      row.querySelector('button')?.setAttribute('aria-pressed', String(!!ex.sets[i]?.done));
    });
    const body = document.querySelector('#workoutContent .workout-body');
    if (body && !body.querySelector('.ux-preparation')) {
      const guide = CF_EXERCISE_LIBRARY.guideFor(ex.name, ex.muscle);
      body.insertAdjacentHTML('afterbegin', `<details class="card ux-preparation"><summary>Equipment setup + preparation</summary><p class="sub">${escapeHtml(guide.steps?.[0] || guide.overview)}</p><p class="sub">Previous working weight: ${lastWeight(ex.name) || 'No recorded load'}${lastWeight(ex.name) ? ' lb' : ''}. Full form guidance is available below.</p></details>`);
    }
  };
  const toggleBeforeUx = toggleWorkoutSet;
  toggleWorkoutSet = function setFeedback(ei, si) {
    const ex = state.workout.active?.exercises[ei], set = ex?.sets[si];
    if (!set) return;
    const wasDone = set.done;
    const old = state.history.flatMap(h => (h.sets || []).filter(s => s.done && s.exercise === ex.name));
    toggleBeforeUx(ei, si);
    if (!wasDone && set.done) {
      const sameLoad = old.filter(s => Number(s.weight) === Number(set.weight));
      const bestReps = sameLoad.length ? Math.max(...sameLoad.map(s => Number(s.reps))) : null;
      const bestWeight = old.length ? Math.max(...old.map(s => Number(s.weight))) : null;
      const feedback = bestWeight !== null && set.weight > bestWeight ? ' · Weight PR' : bestReps !== null && set.reps > bestReps ? ` · +${set.reps - bestReps} reps at this load` : '';
      toast(`Set ${si + 1} complete${feedback} · rest ${ex.rest} sec`);
      const rows = document.querySelectorAll('#workoutContent .set-grid:not(.header)');
      rows[si]?.classList.add('ux-set-complete');
      rows[si]?.querySelector('button')?.focus({ preventScroll: true });
    }
  };

  const renderBeforeUx = renderAll;
  renderAll = function renderExperience() {
    renderBeforeUx(); enhanceToday();
    const missions = document.getElementById('screen-missions');
    if (missions) {
      const firstSub = missions.querySelector('.sub');
      if (firstSub) firstSub.textContent = 'Follow your plan. Your primary mission earns credit once each day, including an approved day-only workout.';
      const plannedTraining = CFOverride.plannedTraining(state.daily.date);
      const overridden = !!CFOverride.current();
      const complete = CFOverride.primaryComplete();
      for (const quest of missions.querySelectorAll('.quest')) {
        const title = quest.querySelector('h3');
        if (['Scheduled workout', 'Planned recovery'].includes(title?.textContent)) {
          if (overridden) title.textContent = 'Today’s approved workout';
          quest.classList.toggle('done', complete);
          if (complete) {
            const icon = quest.querySelector('.quest-icon'); if (icon) icon.textContent = '✓';
            const reward = quest.querySelector('.reward'); if (reward) reward.textContent = 'DONE';
          }
        }
        if (!plannedTraining && overridden && title?.textContent === 'Mobility reset') quest.remove();
      }
      const focus = missions.querySelector('.cf-core-focus b');
      if (focus && overridden) focus.textContent = complete ? 'Your primary mission is already complete. Extra sessions do not add primary RP.' : 'Your approved workout counts for today’s primary mission. Tomorrow follows your regular plan.';
    }
    for (const [id, label] of [['missionSteps', 'Steps today'], ['quickSteps', 'Steps today'], ['mobilityMinutes', 'Mobility minutes']]) document.getElementById(id)?.setAttribute('aria-label', label);
    const progress = document.getElementById('screen-progress');
    if (progress && !progress.querySelector('.ux-recap-button')) progress.insertAdjacentHTML('afterbegin', '<button class="ghost ux-recap-button" onclick="cfUxRecap()">View weekly recap</button>');
    const live = document.getElementById('toast'); live?.setAttribute('role', 'status'); live?.setAttribute('aria-live', 'polite');
  };
  window.CFExperience = { weeklyRecap, adaptation, nextSchedule, milestoneText };
  renderAll();
})();
