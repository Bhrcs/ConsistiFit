/* Premium ConsistiFit UI. Presentation only: existing consistency/reward rules stay authoritative. */
(() => {
  const esc = value => escapeHtml(value ?? '');
  const clone = value => JSON.parse(JSON.stringify(value));
  const tierFor = label => {
    const value = String(label || '').toLowerCase();
    return ['grandmaster','master','diamond','platinum','gold','silver','bronze'].find(t => value.includes(t)) || 'iron';
  };
  const rewardSum = record => {
    if (!record?.claimed || Array.isArray(record.claimed)) return 0;
    return Object.values(record.claimed).reduce((sum, reward) => sum + (Number(reward?.rp) || 0), 0);
  };
  const dayRecord = key => state.daily?.date === key ? state.daily : state.workoutOverrides?.ledger?.[key] || state.depth?.dailyArchive?.[key] || null;
  const shift = (date, amount) => { const next = new Date(date); next.setDate(next.getDate() + amount); return next; };

  function rankProgress() {
    const rank = currentRank(), next = nextRank();
    const start = Number(rank[1]) || 0, end = next ? Number(next[1]) : Math.max(start + 1, Number(state.profile.rp) || start + 1);
    const value = next ? Math.max(0, Math.min(100, ((Number(state.profile.rp) - start) / Math.max(1, end - start)) * 100)) : 100;
    return { rank, next, value };
  }

  function rankEmblem(label) {
    return `<div class="cfp-rank-emblem" data-tier="${tierFor(label)}" aria-label="${esc(label)} rank badge">
      <i class="cfp-emblem-wing left"></i><i class="cfp-emblem-wing right"></i><i class="cfp-emblem-core"></i><i class="cfp-emblem-gem"></i>
    </div>`;
  }

  function rankTrend() {
    const days = [];
    let windowTotal = 0;
    for (let offset = 13; offset >= 0; offset--) {
      const date = shift(demoDate(), -offset), key = keyForDate(date), rp = rewardSum(dayRecord(key));
      windowTotal += rp; days.push({ key, rp });
    }
    let cumulative = Math.max(0, (Number(state.profile.rp) || 0) - windowTotal);
    const values = days.map(day => { cumulative += day.rp; return cumulative; });
    if (!values.some(Boolean)) return values.map((_, index) => index === values.length - 1 ? Number(state.profile.rp) || 0 : 0);
    return values;
  }

  function lineChart(values) {
    const width = 620, height = 150, pad = 10;
    const min = Math.min(...values), max = Math.max(...values), spread = Math.max(1, max - min);
    const points = values.map((value, index) => {
      const x = pad + index * ((width - pad * 2) / Math.max(1, values.length - 1));
      const y = height - pad - ((value - min) / spread) * (height - pad * 2);
      return [x, y];
    });
    const path = points.map((point, index) => `${index ? 'L' : 'M'}${point[0].toFixed(1)} ${point[1].toFixed(1)}`).join(' ');
    const area = `${path} L${points.at(-1)[0].toFixed(1)} ${height - pad} L${points[0][0].toFixed(1)} ${height - pad} Z`;
    return `<svg class="cfp-line-chart" viewBox="0 0 ${width} ${height}" role="img" aria-label="Rank points over the last fourteen days">
      <defs><linearGradient id="cfpArea" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#d7ff3f" stop-opacity=".28"/><stop offset="1" stop-color="#d7ff3f" stop-opacity="0"/></linearGradient></defs>
      <line class="grid" x1="10" x2="610" y1="38" y2="38"/><line class="grid" x1="10" x2="610" y1="76" y2="76"/><line class="grid" x1="10" x2="610" y1="114" y2="114"/>
      <path class="area" d="${area}"/><path class="line" d="${path}"/>${points.filter((_, i) => i === 0 || i === points.length - 1 || i % 3 === 0).map(([x,y]) => `<circle class="dot" cx="${x}" cy="${y}" r="4"/>`).join('')}
    </svg>`;
  }

  function premiumRank() {
    const screen = document.getElementById('screen-rank'); if (!screen) return;
    const { rank, next, value } = rankProgress();
    const recap = window.CFExperience?.weeklyRecap?.(0) || { score: 0, complete: 0, elapsed: 0 };
    const trend = rankTrend();
    screen.innerHTML = `<div class="cfp-rank-page">
      <div><div class="eyebrow">CONSISTENCY RANK</div><h1 class="headline">Show up. Move up.</h1><div class="sub">Rank rewards following your plan—including recovery—not doing the most workouts.</div></div>
      <section class="cfp-rank-stage">${rankEmblem(rank[0])}<div class="cfp-rank-title">${esc(rank[0])}</div><div class="cfp-rank-rp">${formatNum(state.profile.rp)} RP</div>
        <div class="cfp-rank-progress"><div class="bar"><i style="width:${value.toFixed(1)}%"></i></div><div class="cfp-rank-meta"><span>${formatNum(rank[1])} RP</span><span>${next ? `${formatNum(next[1] - state.profile.rp)} RP to ${esc(next[0])}` : 'Highest rank reached'}</span></div></div>
      </section>
      <div class="cfp-metric-grid"><div class="cfp-metric"><b>${recap.elapsed ? recap.score : '—'}${recap.elapsed ? '%' : ''}</b><span>THIS WEEK</span></div><div class="cfp-metric"><b>${state.profile.streak}</b><span>DAY STREAK</span></div><div class="cfp-metric"><b>Lv.${accountLevel()}</b><span>ACCOUNT LEVEL</span></div></div>
      <section class="cfp-chart-card"><div class="cfp-chart-head"><div><b>RP over time</b><div class="sub">Last 14 days</div></div><span>${formatNum(trend[0] || 0)} → ${formatNum(trend.at(-1) || state.profile.rp)}</span></div>${lineChart(trend)}</section>
      <button class="ghost cfp-ladder-toggle" onclick="cfPremiumToggleLadder()"><span>View rank ladder</span><span>⌄</span></button>
      <div id="cfPremiumLadder" class="cfp-ladder-wrap"><div class="card">${[...RANKS].reverse().map(item => `<div class="ladder-row ${item[0] === rank[0] ? 'current' : ''}"><span>${esc(item[0])}${item[0] === rank[0] ? ' · YOU' : ''}</span><span>${formatNum(item[1])} RP</span></div>`).join('')}</div></div>
      <div class="card"><b>Follow the plan, not the leaderboard.</b><p class="sub">A 3-day plan and a 6-day plan can both build rank through consistency. Extra workouts never create extra primary RP.</p></div>
    </div>`;
  }
  window.cfPremiumToggleLadder = () => document.getElementById('cfPremiumLadder')?.classList.toggle('show');

  function workoutSetsFor(group, days = 14) {
    const cutoff = keyForDate(shift(demoDate(), -days));
    const patterns = {
      Chest: /chest|press/i, Back: /back|row|pulldown|pull-up|lat/i, Legs: /leg|quad|hamstring|glute|calf|squat|lunge/i,
      Shoulders: /shoulder|delt|lateral|raise/i, Arms: /bicep|tricep|curl|pressdown/i, Core: /core|plank|crunch|dead bug|raise/i
    };
    const pattern = patterns[group]; let count = 0;
    for (const workout of state.history || []) {
      if (workout.type !== 'workout' || (workout.sessionDate || workout.date || '') < cutoff) continue;
      for (const set of workout.sets || []) if (set.done && pattern.test(`${set.exercise || ''} ${set.muscle || ''}`)) count++;
    }
    return count;
  }

  function trainingBalanceHTML() {
    const groups = ['Chest','Back','Legs','Shoulders','Arms','Core'];
    const rows = groups.map(group => ({ group, sets: workoutSetsFor(group) }));
    const torso = rows.some(x => ['Chest','Back','Core'].includes(x.group) && x.sets > 0), arms = rows.some(x => ['Shoulders','Arms'].includes(x.group) && x.sets > 0), legs = rows.find(x => x.group === 'Legs')?.sets > 0;
    return `<section class="cfp-chart-card"><div class="cfp-chart-head"><div><b>Training balance</b><div class="sub">Recent coverage—not muscle strength ranking</div></div><span>14 DAYS</span></div>
      <div class="cfp-balance"><div class="cfp-body-map"><div class="cfp-body-figure" aria-label="Recent muscle coverage map"><span class="head"></span><span class="torso ${torso ? 'active' : ''}"></span><span class="arm-l ${arms ? 'active' : ''}"></span><span class="arm-r ${arms ? 'active' : ''}"></span><span class="leg-l ${legs ? 'active' : ''}"></span><span class="leg-r ${legs ? 'active' : ''}"></span></div></div>
      <div class="cfp-balance-list">${rows.map(row => { const pct = Math.min(100, row.sets / 8 * 100); return `<div class="cfp-balance-row"><b>${row.group}</b><div class="cfp-balance-bar"><i style="width:${pct}%"></i></div><span>${row.sets} sets</span></div>`; }).join('')}</div></div>
      <p class="sub">Use this to spot areas your current plan has not reached recently. It does not affect RP or rank.</p></section>`;
  }

  function routines() {
    try { return CFOverride.availableWorkouts(); } catch { return []; }
  }
  window.cfPremiumRoutines = () => {
    const list = routines(); window.__cfPremiumRoutines = list; window.__cfUxWorkouts = list;
    openSheet(`<div class="eyebrow">WORKOUT LIBRARY</div><h2>Your routines</h2><p class="sub">Start a compatible program workout or use one for today. Day-only changes never alter tomorrow unless you explicitly save a routine.</p>
      <div class="cfp-routine-grid">${list.length ? list.map((item,index) => { const preview = CFOverride.preview(item.template); return `<article class="cfp-routine-card"><div class="cfp-routine-top"><div><div class="cfp-routine-source">${esc(String(item.source || 'ROUTINE').toUpperCase())}</div><h3>${esc(item.name)}</h3></div><span class="badge">${preview.minutes}m</span></div><div class="cfp-routine-meta"><span>${item.template.exercises.length} exercises</span><span>${preview.totalSets} sets</span><span>${esc((preview.equipment || []).slice(0,2).join(' + ') || 'Bodyweight')}</span></div><div class="cfp-routine-actions"><button class="ghost" onclick="cfPremiumPreviewRoutine(${index})">Preview</button><button class="primary" onclick="cfPremiumUseRoutine(${index})">Use today</button></div></article>`; }).join('') : '<p class="sub">No compatible routines are available yet. Build one from your current equipment.</p>'}</div>
      <button class="primary" style="width:100%;margin-top:14px" onclick="closeSheet();cf2OpenWorkoutBuilder()">Create workout</button>`);
  };
  window.cfPremiumPreviewRoutine = index => { const list = window.__cfPremiumRoutines || routines(); window.__cfUxWorkouts = list; if (list[index]) cfUxSelectWorkout(index); };
  window.cfPremiumUseRoutine = index => {
    const item = (window.__cfPremiumRoutines || routines())[index]; if (!item) return;
    if (state.workout.active) return toast('Finish your active session before changing today.');
    const result = CFOverride.apply(clone(item.template)); if (!result.ok) return toast(result.errors.join(' '));
    closeSheet(); renderAll(); toast(`${item.name} is set for today`);
  };

  function enhanceHome() {
    const screen = document.getElementById('screen-home'); if (!screen || screen.querySelector('.cfp-today-status')) return;
    const headline = screen.querySelector('.headline'), rank = currentRank();
    if (headline) headline.insertAdjacentHTML('afterend', `<div class="cfp-today-status"><div class="cfp-rank-chip"><div class="cfp-kicker">CONSISTENCY RANK</div><strong>${esc(rank[0])}</strong><span>${formatNum(state.profile.rp)} RP · ${nextRank() ? formatNum(nextRank()[1] - state.profile.rp) + ' to next' : 'top rank'}</span></div><div class="cfp-mini-stat"><div class="cfp-kicker">STREAK</div><strong>${state.profile.streak}</strong><span>days</span></div><div class="cfp-mini-stat"><div class="cfp-kicker">LEVEL</div><strong>${accountLevel()}</strong><span>permanent</span></div></div>`);
    const hero = screen.querySelector('.hero');
    if (hero) hero.insertAdjacentHTML('afterend', `<div class="cfp-home-actions"><button class="ghost" onclick="cfPremiumRoutines()">Workout library</button><button class="ghost" onclick="showScreen('rank')">View rank</button></div>`);
  }

  function enhanceProgress() {
    const screen = document.getElementById('screen-progress'); if (!screen) return;
    screen.querySelectorAll('.cfp-progress-premium').forEach(node => node.remove());
    const recap = window.CFExperience?.weeklyRecap?.(0) || { score:0, complete:0, elapsed:0, prs:0 };
    const block = document.createElement('div'); block.className = 'cfp-progress-premium';
    block.innerHTML = `<div class="cfp-progress-hero"><div class="cfp-progress-big"><div class="cfp-kicker">WEEKLY CONSISTENCY</div><b>${recap.elapsed ? recap.score + '%' : '—'}</b><span>${recap.complete} of ${recap.elapsed} planned days complete</span></div><div class="cfp-progress-big"><div class="cfp-kicker">PERSONAL RECORDS</div><b>${recap.prs || 0}</b><span>this week</span></div></div>${trainingBalanceHTML()}<div class="cfp-home-actions"><button class="ghost" onclick="cfPremiumRoutines()">Open workout library</button><button class="ghost" onclick="cfUxRecap()">Weekly recap</button></div>`;
    const anchor = screen.querySelector('.stat-grid') || screen.firstElementChild; if (anchor) anchor.insertAdjacentElement('afterend', block); else screen.prepend(block);
  }

  function previousSet(exerciseName, setNumber) {
    for (const workout of [...(state.history || [])].reverse()) {
      const set = (workout.sets || []).find(item => item.done && item.exercise === exerciseName && Number(item.number || item.setNumber) === Number(setNumber));
      if (set) return set;
    }
    return null;
  }
  function enhanceWorkout() {
    const workout = state.workout.active; if (!workout) return;
    const ex = workout.exercises[workout.exerciseIndex]; if (!ex) return;
    const header = document.querySelector('#workoutContent .set-grid.header');
    if (header && !header.querySelector('.cfp-prev-head')) {
      const marker = document.createElement('span'); marker.className = 'cfp-prev-head'; marker.textContent = 'LAST'; header.insertBefore(marker, header.children[1]);
    }
    document.querySelectorAll('#workoutContent .set-grid:not(.header)').forEach((row, index) => {
      if (row.querySelector('.cfp-prev')) return;
      const prior = previousSet(ex.name, ex.sets[index]?.number || index + 1); const cell = document.createElement('span'); cell.className = 'cfp-prev';
      cell.textContent = prior ? `${Number(prior.weight || 0).toFixed(0)}×${prior.reps}` : '—'; row.insertBefore(cell, row.children[1]);
    });
    const title = document.querySelector('#workoutContent .exercise-title');
    if (title && !document.querySelector('#workoutContent .cfp-exercise-summary')) {
      const completed = ex.sets.filter(set => set.done).length;
      title.insertAdjacentHTML('afterend', `<div class="cfp-exercise-summary"><div><b>${completed}/${ex.sets.length} sets complete</b><span style="display:block">Previous results are shown beside each set</span></div><button class="ghost small" onclick="cfOpenWorkoutNavigatorList()">Workout list</button></div>`);
    }
  }

  const priorRenderAll = renderAll;
  renderAll = function premiumRenderAll() { priorRenderAll(); enhanceHome(); premiumRank(); enhanceProgress(); };
  const priorRenderWorkout = renderWorkout;
  renderWorkout = function premiumRenderWorkout() { priorRenderWorkout(); enhanceWorkout(); };
  const priorToggle = toggleWorkoutSet;
  toggleWorkoutSet = function premiumToggle(ei, si) {
    const before = !!state.workout.active?.exercises?.[ei]?.sets?.[si]?.done; priorToggle(ei, si);
    const after = !!state.workout.active?.exercises?.[ei]?.sets?.[si]?.done;
    if (!before && after) { const rows = document.querySelectorAll('#workoutContent .set-grid:not(.header)'); rows[si]?.classList.add('cfp-set-pulse'); setTimeout(() => rows[si]?.classList.remove('cfp-set-pulse'), 500); }
  };

  renderAll();
})();
