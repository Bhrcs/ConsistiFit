(() => {
  const CORE_VERSION = 1;
  const TRAINING_RP = 30;
  const RECOVERY_RP = 30;
  const RECOVERY_XP = 160;
  const RECOVERY_COINS = 65;

  function coreState() {
    state.core ||= {};
    const c = state.core;
    c.version = CORE_VERSION;
    c.programAudits ||= {};
    c.migrated ||= false;
    return c;
  }

  function normalizeGoal(value) {
    const text = String(value || '').toLowerCase();
    if (text.includes('strong')) return 'strength';
    if (text.includes('habit')) return 'habit';
    return 'muscle';
  }

  function activeProgram() {
    const ref = state.cf2?.activeProgram;
    if (!ref) return null;
    if (ref.startsWith('lib:')) return (window.CF2_PROGRAM_LIBRARY || []).find(p => p.id === ref.slice(4)) || null;
    if (ref.startsWith('custom:')) return (state.cf2?.customPrograms || []).find(p => p.id === ref.slice(7)) || null;
    return null;
  }

  function activeGoal() {
    return normalizeGoal(activeProgram()?.goal || state.plan?.goal);
  }

  function coreHistory(name) {
    return state.history
      .filter(h => h.type === 'workout' && (h.sets || []).some(s => s.done && s.exercise === name))
      .slice(-3);
  }

  function roundLoad(value, increment = 5) {
    return Math.max(0, Math.round(Number(value || 0) / increment) * increment);
  }

  function isHard(historyEntry, name) {
    const rating = historyEntry?.exerciseRpe?.[name] || historyEntry?.difficulty || '';
    return /hard|too hard/i.test(rating);
  }

  function isEasyOrGood(historyEntry, name) {
    const rating = historyEntry?.exerciseRpe?.[name] || historyEntry?.difficulty || '';
    return /easy|good/i.test(rating);
  }

  function workingSets(historyEntry, name) {
    return (historyEntry?.sets || []).filter(s => s.done && s.exercise === name);
  }

  function loadIncrement(name) {
    return /leg press|hack squat|calf raise machine/i.test(name) ? 10 : 5;
  }

  function coreRecommendation(ex) {
    const history = coreHistory(ex.name);
    const goal = activeGoal();
    const recent = history.at(-1);
    const sets = workingSets(recent, ex.name);
    const weighted = sets.filter(s => Number(s.weight) > 0);
    const currentWeight = weighted.length ? Math.max(...weighted.map(s => Number(s.weight) || 0)) : 0;
    const avgReps = sets.length ? sets.reduce((sum, s) => sum + (Number(s.reps) || 0), 0) / sets.length : 0;
    const allTop = sets.length > 0 && sets.every(s => (Number(s.reps) || 0) >= Number(ex.repMax));
    const lastTwo = history.slice(-2);
    const repeatedHard = lastTwo.length === 2 && lastTwo.every(h => isHard(h, ex.name));
    const readinessLow = /tired|sore/i.test(state.daily?.checkin || '');
    const increment = loadIncrement(ex.name);

    if (!history.length) {
      return {
        weight: 0,
        reps: Number(ex.repMin),
        confidence: 'LEARN',
        mode: 'Technique first',
        reason: 'No recent history yet. Start light, use clean form, and finish with 2–3 good reps still available.'
      };
    }

    if (repeatedHard && currentWeight > 0) {
      const reduced = roundLoad(currentWeight * 0.9, 5);
      return {
        weight: reduced,
        reps: Number(ex.repMin),
        confidence: 'RECOVER',
        mode: 'Back off today',
        reason: `Two recent sessions were hard. Use about 10% less load (${reduced} lb), keep the reps clean, and rebuild from there.`
      };
    }

    if (readinessLow && currentWeight > 0) {
      return {
        weight: currentWeight,
        reps: Math.max(Number(ex.repMin), Math.min(Number(ex.repMax), Math.floor(avgReps || ex.repMin))),
        confidence: 'RECOVER',
        mode: 'Hold the load',
        reason: `You checked in as ${state.daily.checkin.toLowerCase()}. Keep the load steady today and avoid forcing progression.`
      };
    }

    if (goal === 'habit') {
      const lastTwoTop = lastTwo.length === 2 && lastTwo.every(h => {
        const s = workingSets(h, ex.name);
        return s.length && s.every(set => (Number(set.reps) || 0) >= Number(ex.repMax)) && !isHard(h, ex.name);
      });
      if (lastTwoTop && currentWeight > 0) {
        return {
          weight: roundLoad(currentWeight + increment, increment),
          reps: Number(ex.repMin),
          confidence: 'HIGH',
          mode: 'Small progression',
          reason: 'You repeated the top of the rep range twice with manageable effort. Make one small load increase and keep the session predictable.'
        };
      }
      return {
        weight: currentWeight,
        reps: Math.min(Number(ex.repMax), Math.max(Number(ex.repMin), Math.round(avgReps || ex.repMin) + 1)),
        confidence: history.length >= 2 ? 'HIGH' : 'MED',
        mode: 'Repeatable progress',
        reason: 'Habit plans progress conservatively. Keep the same load and add a rep before making the workout harder.'
      };
    }

    if (goal === 'strength') {
      if (allTop && currentWeight > 0 && !isHard(recent, ex.name)) {
        const next = roundLoad(currentWeight + increment, increment);
        return {
          weight: next,
          reps: Number(ex.repMin),
          confidence: isEasyOrGood(recent, ex.name) ? 'HIGH' : 'MED',
          mode: 'Add load',
          reason: `You completed the top of the strength range. Move to ${next} lb and restart near ${ex.repMin} reps.`
        };
      }
      if (currentWeight > 0 && avgReps < Number(ex.repMin) && isHard(recent, ex.name)) {
        const reduced = roundLoad(Math.max(0, currentWeight - increment), increment);
        return {
          weight: reduced,
          reps: Number(ex.repMin),
          confidence: 'RECOVER',
          mode: 'Rebuild',
          reason: `Reps fell below target and the set was hard. Drop to ${reduced} lb and rebuild the bottom of the range.`
        };
      }
      return {
        weight: currentWeight,
        reps: Math.min(Number(ex.repMax), Math.max(Number(ex.repMin), Math.round(avgReps || ex.repMin) + 1)),
        confidence: history.length >= 2 ? 'HIGH' : 'MED',
        mode: 'Earn the increase',
        reason: 'Keep the current load and add clean reps. Increase weight only after you own the top of the range.'
      };
    }

    const prior = history.length > 1 ? history.at(-2) : null;
    const priorSets = workingSets(prior, ex.name);
    const priorNearTop = priorSets.length > 0 && priorSets.every(s => (Number(s.reps) || 0) >= Number(ex.repMax) - 1);
    if (allTop && currentWeight > 0 && !isHard(recent, ex.name) && (isEasyOrGood(recent, ex.name) || priorNearTop)) {
      const next = roundLoad(currentWeight + increment, increment);
      return {
        weight: next,
        reps: Number(ex.repMin),
        confidence: history.length >= 2 ? 'HIGH' : 'MED',
        mode: 'Double progression',
        reason: `You reached the top of the hypertrophy range with control. Try ${next} lb and restart near ${ex.repMin} reps.`
      };
    }
    return {
      weight: currentWeight,
      reps: Math.min(Number(ex.repMax), Math.max(Number(ex.repMin), Math.round(avgReps || ex.repMin) + 1)),
      confidence: history.length >= 2 ? 'HIGH' : 'MED',
      mode: 'Add reps first',
      reason: 'Keep the same load and beat your recent total by about 1–2 reps before increasing weight.'
    };
  }

  window.cfCoreRecommendation = coreRecommendation;

  function movementFamily(name) {
    const n = String(name).toLowerCase();
    if (/squat|lunge|leg press|leg extension|step-up|split squat|hack squat/.test(n)) return 'knee';
    if (/deadlift|leg curl|hip thrust|bridge|good morning/.test(n)) return 'hinge';
    if (/bench|chest press|push-up|pec deck|floor press/.test(n)) return 'push';
    if (/row|pulldown|pull-up|pullover|lat sweep/.test(n)) return 'pull';
    if (/shoulder press|overhead press|lateral raise|rear delt|arnold press/.test(n)) return 'shoulders';
    if (/plank|dead bug|crunch|leg raise|side plank/.test(n)) return 'core';
    return 'accessory';
  }

  function auditProgram(program) {
    const workouts = program?.workouts || [];
    const all = workouts.flatMap(w => w.exercises || []);
    const families = new Set(all.map(e => movementFamily(e[0])));
    const totalSets = all.reduce((sum, e) => sum + (Number(e[2]) || 0), 0);
    const problems = [];
    if (!workouts.length) problems.push('No workouts');
    if (!families.has('knee')) problems.push('Missing knee-dominant lower-body work');
    if (!families.has('hinge')) problems.push('Missing hip-hinge / posterior-chain work');
    if (!families.has('push')) problems.push('Missing pressing work');
    if (!families.has('pull')) problems.push('Missing pulling work');
    for (const workout of workouts) {
      if ((workout.exercises || []).length < 3) problems.push(`${workout.name}: too few exercises`);
      if ((workout.exercises || []).length > 8) problems.push(`${workout.name}: too many exercises`);
      const sets = (workout.exercises || []).reduce((sum, e) => sum + (Number(e[2]) || 0), 0);
      if (sets > 26) problems.push(`${workout.name}: too many working sets`);
      const names = (workout.exercises || []).map(e => e[0]);
      if (new Set(names).size !== names.length) problems.push(`${workout.name}: duplicate movement`);
    }
    return {
      ok: problems.length === 0,
      problems,
      totalSets,
      families: [...families],
      summary: problems.length
        ? `${problems.length} balance item${problems.length === 1 ? '' : 's'} to review`
        : 'Balanced push, pull, lower-body and posterior-chain coverage'
    };
  }

  window.cfCoreAuditProgram = auditProgram;

  function findProgramByRef(ref) {
    if (!ref) return null;
    if (ref.startsWith('lib:')) return (window.CF2_PROGRAM_LIBRARY || []).find(p => p.id === ref.slice(4)) || null;
    if (ref.startsWith('custom:')) return (state.cf2?.customPrograms || []).find(p => p.id === ref.slice(7)) || null;
    return null;
  }

  function auditBuiltIns() {
    const c = coreState();
    for (const p of window.CF2_PROGRAM_LIBRARY || []) c.programAudits[p.id] = auditProgram(p);
    saveState();
  }

  const baseRewardOnce = rewardOnce;
  rewardOnce = function coreRewardOnce(code, reward) {
    if (code === 'recovery') reward = { ...reward, rp: RECOVERY_RP, xp: RECOVERY_XP, coins: RECOVERY_COINS };
    if (code === 'perfect') reward = { ...reward, rp: 15, xp: 60, coins: 30 };
    return baseRewardOnce(code, reward);
  };

  saveMobility = function coreSaveMobility() {
    const input = document.getElementById('mobilityMinutes');
    const value = Math.max(0, Number(input?.value) || 0);
    state.daily.mobility = Math.round(value);
    if (value >= 10) {
      const training = isTrainingDay();
      const code = training ? 'mobility' : 'recovery';
      const reward = training
        ? { rp: 10, xp: 50, coins: 25 }
        : { rp: RECOVERY_RP, xp: RECOVERY_XP, coins: RECOVERY_COINS };
      if (rewardOnce(code, reward)) toast(`${training ? 'Mobility' : 'Planned recovery'} complete: +${reward.rp} RP`);
    }
    saveState();
    evaluateDaily();
    renderAll();
  };

  const baseRenderMissions = renderMissions;
  renderMissions = function coreRenderMissions() {
    baseRenderMissions();
    const screen = document.getElementById('screen-missions');
    if (!screen) return;
    const training = isTrainingDay();
    const checkin = state.daily?.checkin || '';
    const sub = screen.querySelector('.sub');
    const focusText = training
      ? 'Complete the workout you planned. Extra workouts do not earn extra RP.'
      : 'Recovery is part of the plan, not a missed training day. Ten intentional minutes completes today’s primary mission.';
    const readiness = /tired|sore/i.test(checkin)
      ? `You checked in as ${checkin.toLowerCase()}. Keep today conservative and prioritize clean movement.`
      : training
        ? 'Follow the planned session and let Smart Progression decide whether today is a load-increase day.'
        : 'Use mobility, easy walking, or another low-fatigue recovery activity.';
    sub?.insertAdjacentHTML('afterend', `<div class="cf-core-focus"><div><small>${training ? 'TRAINING DAY' : 'RECOVERY DAY'} · PLAN FIRST</small><b>${focusText}</b><span>${readiness}</span></div></div>`);
    if (!training) {
      for (const quest of screen.querySelectorAll('.quest')) {
        if (quest.querySelector('h3')?.textContent.includes('Planned recovery')) {
          const reward = quest.querySelector('.reward');
          if (reward && reward.textContent !== 'DONE') reward.textContent = `+${RECOVERY_RP} RP`;
        }
      }
    }
    const primaryTitle = training ? 'Scheduled workout' : 'Planned recovery';
    for (const q of screen.querySelectorAll('.quest')) {
      if (q.querySelector('h3')?.textContent === primaryTitle && !q.querySelector('.cf-core-primary')) {
        q.querySelector('h3')?.insertAdjacentHTML('afterend', '<span class="cf-core-primary">PRIMARY PLAN MISSION</span>');
      }
    }
  };

  const baseStartWorkout = startWorkout;
  startWorkout = function coreStartWorkout() {
    const hadWorkout = !!state.workout.active;
    baseStartWorkout();
    const workout = state.workout.active;
    if (!workout || hadWorkout) return;
    for (const ex of workout.exercises) {
      const rec = coreRecommendation(ex);
      ex.coreTarget = rec;
      if (rec.weight > 0) {
        for (const set of ex.sets) {
          set.weight = rec.weight;
          set.reps = rec.reps;
        }
      } else {
        for (const set of ex.sets) set.reps = rec.reps;
      }
    }
    saveState();
    renderWorkout();
  };

  const baseRenderWorkout = renderWorkout;
  renderWorkout = function coreRenderWorkout() {
    baseRenderWorkout();
    const w = state.workout.active;
    if (!w) return;
    const ex = w.exercises[w.exerciseIndex];
    const body = document.querySelector('#workoutContent .workout-body');
    if (!body) return;
    const rec = coreRecommendation(ex);
    const smart = body.querySelector('.cf2-smart-target');
    if (smart) {
      smart.classList.add('cf-core-smart');
      smart.innerHTML = `<div><small>SMART PROGRESSION · ${rec.confidence}</small><b>${escapeHtml(rec.mode)}</b><p>${escapeHtml(rec.weight > 0 ? `${rec.weight} lb · target ${rec.reps}+ reps. ${rec.reason}` : rec.reason)}</p></div><button onclick="cfOpenExerciseHistory('${escapeHtml(ex.name).replace(/'/g, '&#39;')}')">History</button>`;
    }
    if (/RECOVER/.test(rec.confidence) && !body.querySelector('.cf-core-recovery-note')) {
      smart?.insertAdjacentHTML('afterend', '<div class="cf-core-recovery-note"><b>Recovery-aware session</b><span>Today is not a test. Keep technique clean and stop a set if form noticeably breaks down.</span></div>');
    }
  };

  function recentAdherence() {
    const archive = state.depth?.dailyArchive || {};
    const today = demoDate();
    let eligible = 0;
    let complete = 0;
    for (let i = 0; i < 7; i++) {
      const d = new Date(today);
      d.setDate(today.getDate() - i);
      const key = keyForDate(d);
      const record = state.daily?.date === key ? state.daily : archive[key];
      if (!record) continue;
      eligible++;
      if (record.dayComplete) complete++;
    }
    return { eligible, complete, score: eligible ? Math.round((complete / eligible) * 100) : 100 };
  }

  function addHomePlanFit() {
    const screen = document.getElementById('screen-home');
    if (!screen || screen.querySelector('.cf-core-planfit')) return;
    const a = recentAdherence();
    if (a.eligible < 3) return;
    const days = Math.max(2, Number(state.plan?.days) || 3);
    let message = 'Your current schedule looks repeatable. Keep the plan steady and let progression happen gradually.';
    let action = '';
    if (a.score < 60 && days > 2) {
      message = 'Your recent consistency suggests the schedule may be asking for too much. Reducing one training day can be better than repeatedly missing sessions.';
      action = '<button class="ghost small" onclick="openPlanBuilder()">Adjust plan</button>';
    } else if (a.score < 80) {
      message = 'Consistency is building. Keep your workload stable this week instead of adding extra sessions.';
    }
    const anchor = screen.querySelector('.cf-week-overview') || screen.querySelector('.hero');
    anchor?.insertAdjacentHTML('afterend', `<div class="card cf-core-planfit"><div><div class="eyebrow">PLAN FIT</div><b>${a.score}% recent consistency</b><div class="sub">${message}</div></div>${action}</div>`);
  }

  function addRankPhilosophy() {
    const screen = document.getElementById('screen-rank');
    if (!screen || screen.querySelector('.cf-core-rank-note')) return;
    const firstCard = screen.querySelector('.card');
    firstCard?.insertAdjacentHTML('afterend', '<div class="card cf-core-rank-note"><b>Follow the plan, not the leaderboard.</b><div class="sub">A planned recovery day carries the same base RP as a planned workout. Higher training frequency only creates a small progression difference; extra workouts still earn 0 RP.</div></div>');
  }

  function cleanProfileUI() {
    const screen = document.getElementById('screen-profile');
    if (!screen) return;
    for (const title of [...screen.querySelectorAll('.section-title')]) {
      if (title.textContent.trim() === 'DEMO CONTROLS') {
        const card = title.nextElementSibling;
        title.remove();
        card?.remove();
      }
    }
    const tools = screen.querySelector('.cf2-profile-tools');
    if (tools) {
      const heading = tools.querySelector('.section-title');
      if (heading) heading.textContent = 'TRAINING SETUP';
      for (const button of [...tools.querySelectorAll('button')]) {
        if (button.textContent.includes('Balance Lab')) button.remove();
      }
    }
  }

  function addProgramAuditToSheet(ref) {
    const program = findProgramByRef(ref);
    const sheet = document.getElementById('sheetContent');
    if (!program || !sheet) return;
    const audit = auditProgram(program);
    const primary = sheet.querySelector('button.primary');
    const html = `<div class="cf-core-program-quality ${audit.ok ? 'good' : 'review'}"><small>PROGRAM QUALITY</small><b>${escapeHtml(audit.summary)}</b><span>${audit.totalSets} working sets across the full rotation${audit.ok ? ' · session volume inside guardrails' : ''}</span></div>`;
    if (primary) primary.insertAdjacentHTML('beforebegin', html);
    else sheet.insertAdjacentHTML('beforeend', html);
  }

  if (typeof window.cf2ProgramDetails === 'function') {
    const baseProgramDetails = window.cf2ProgramDetails;
    window.cf2ProgramDetails = function coreProgramDetails(ref) {
      baseProgramDetails(ref);
      addProgramAuditToSheet(ref);
    };
  }

  if (typeof window.cf2UseProgram === 'function') {
    const baseUseProgram = window.cf2UseProgram;
    window.cf2UseProgram = function coreUseProgram(ref) {
      const p = findProgramByRef(ref);
      if (p) {
        state.plan ||= {};
        state.plan.goal = normalizeGoal(p.goal);
      }
      baseUseProgram(ref);
    };
  }

  const baseRenderAll = renderAll;
  renderAll = function coreRenderAll() {
    baseRenderAll();
    addHomePlanFit();
    addRankPhilosophy();
    cleanProfileUI();
  };

  function migrate() {
    const c = coreState();
    if (!c.migrated) {
      if (state.demo) state.demo.dayOffset = 0;
      c.migrated = true;
      saveState();
    }
    auditBuiltIns();
  }

  migrate();
  renderAll();
})();