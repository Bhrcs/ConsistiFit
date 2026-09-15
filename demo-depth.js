(() => {
  const ACHIEVEMENTS = [
    ['first_workout','First Workout','Complete your first workout.',50],
    ['streak_7','One Week Strong','Reach a 7-day consistency streak.',75],
    ['workouts_10','Double Digits','Complete 10 workouts.',100],
    ['workouts_25','Built a Habit','Complete 25 workouts.',150],
    ['first_pr','New Standard','Set your first personal record.',75],
    ['volume_100k','100K Club','Accumulate 100,000 lb of training volume.',150],
    ['bronze_rank','Bronze Bound','Reach Bronze III.',100],
    ['perfect_day','Perfect Day','Complete every mission in one day.',75],
    ['level_5','Level Five','Reach account level 5.',100]
  ];
  const EXTRA_SHOP = [
    {code:'badge_founder',name:'Consistency Badge',price:220,desc:'Adds a small profile badge cosmetic.'},
    {code:'theme_lime_glow',name:'Lime Glow Theme',price:350,desc:'A brighter lime accent treatment that keeps the original dark design.'},
    {code:'finish_burst',name:'Finish Burst',price:275,desc:'Adds a subtle lime completion effect after workouts.'}
  ];
  for (const item of EXTRA_SHOP) if (!SHOP.some(existing => existing.code === item.code)) SHOP.push(item);

  function depth() {
    if (!state.depth) state.depth = {};
    const d = state.depth;
    d.firstDate ||= state.daily?.date || keyForDate(demoDate());
    d.dailyArchive ||= {};
    d.achievements ||= {};
    d.bodyweight ||= [];
    d.cosmetics ||= {frame:null,title:null,badge:null,theme:null,finish:null};
    d.prefs ||= {restSound:false,restVibrate:true};
    d.best ||= {};
    return d;
  }
  depth();

  function archiveDaily() {
    if (!state.daily?.date) return;
    const d = depth();
    d.dailyArchive[state.daily.date] = {
      date: state.daily.date,
      dayComplete: !!state.daily.dayComplete,
      perfect: !!state.daily.perfectClaimed,
      steps: Number(state.daily.steps)||0,
      mobility: Number(state.daily.mobility)||0,
      checkin: state.daily.checkin || null,
      training: isTrainingDay(new Date(`${state.daily.date}T12:00:00`)),
      claimed: Object.keys(state.daily.claimed || {})
    };
  }

  const baseEnsureDaily = ensureDaily;
  ensureDaily = function ensureDailyWithArchive() {
    const expected = keyForDate(demoDate());
    if (state.daily?.date && state.daily.date !== expected) archiveDaily();
    baseEnsureDaily();
    depth();
  };

  const baseAdvanceDemoDay = advanceDemoDay;
  advanceDemoDay = function advanceDemoDayWithArchive() {
    archiveDaily();
    baseAdvanceDemoDay();
  };
  const baseReturnToToday = returnToToday;
  returnToToday = function returnToTodayWithArchive() {
    archiveDaily();
    baseReturnToToday();
  };

  function iso(date) { return keyForDate(date); }
  function parseDate(key) { return new Date(`${key}T12:00:00`); }
  function startOfWeek(date) {
    const d = new Date(date); const day = d.getDay(); const shift = day === 0 ? -6 : 1-day;
    d.setDate(d.getDate()+shift); d.setHours(12,0,0,0); return d;
  }
  function dayRecord(key) {
    if (state.daily?.date === key) return {
      date:key, dayComplete:!!state.daily.dayComplete, perfect:!!state.daily.perfectClaimed,
      steps:Number(state.daily.steps)||0, mobility:Number(state.daily.mobility)||0,
      training:isTrainingDay(parseDate(key)), claimed:Object.keys(state.daily.claimed||{})
    };
    return depth().dailyArchive[key] || null;
  }
  function weeklyConsistency() {
    const start = startOfWeek(demoDate()); let elapsed=0, complete=0;
    const days=[];
    for(let i=0;i<7;i++){
      const date=new Date(start); date.setDate(start.getDate()+i); const key=iso(date);
      const future=date>demoDate(); const beforeStart=key<depth().firstDate; const record=dayRecord(key);
      if(!future&&!beforeStart){elapsed++; if(record?.dayComplete)complete++;}
      days.push({date,key,record,future,beforeStart,training:isTrainingDay(date)});
    }
    return {complete,elapsed,score:elapsed?Math.round(complete/elapsed*100):0,days};
  }

  function programForWeek() {
    const trainingDays = typeof cfTrainingDays === 'function' ? cfTrainingDays() : [1,3,5];
    const program = typeof cfProgram === 'function' ? cfProgram() : PROGRAM;
    const start = startOfWeek(demoDate()); let workoutIndex=0;
    return Array.from({length:7},(_,i)=>{
      const date=new Date(start); date.setDate(start.getDate()+i); const training=trainingDays.includes(date.getDay());
      const workout=training ? program[workoutIndex++ % program.length] : null;
      const record=dayRecord(iso(date));
      return {date,training,workout,record,current:iso(date)===iso(demoDate())};
    });
  }

  function exerciseHistory(name) {
    return state.history.filter(h=>h.type==='workout'&&Array.isArray(h.sets)&&h.sets.some(s=>s.exercise===name&&s.done)).map(h=>({
      ...h,
      exerciseSets:h.sets.filter(s=>s.exercise===name&&s.done)
    })).reverse();
  }
  function lastPerformance(name) { return exerciseHistory(name)[0] || null; }
  function estimate1RM(weight,reps){return weight>0&&reps>0?weight*(1+reps/30):0}
  function recommendation(ex) {
    const last=lastPerformance(ex.name); if(!last) return {weight:0,text:'Start light and leave 2–3 good reps in reserve while you learn the movement.'};
    const sets=last.exerciseSets; const weight=Math.max(...sets.map(s=>Number(s.weight)||0));
    const allTop=sets.length>=Math.min(ex.sets.length,2)&&sets.every(s=>(Number(s.reps)||0)>=Number(ex.repMax));
    const avg=sets.reduce((a,s)=>a+(Number(s.reps)||0),0)/Math.max(sets.length,1);
    if(last.difficulty==='Too Hard'&&weight>0) return {weight:Math.max(0,weight-5),text:`Last session was too hard. Consider ${Math.max(0,weight-5)} lb and rebuild clean reps.`};
    if(allTop&&weight>0) return {weight:weight+5,text:`You reached the top of the rep range last time. Try ${weight+5} lb today.`};
    if(weight>0&&avg>=ex.repMin) return {weight,text:`Repeat ${weight} lb and try to beat last session by 1–2 total reps.`};
    return {weight,text:`Stay around ${weight||'a comfortable weight'} and focus on controlled reps inside the target range.`};
  }

  function priorBest(exerciseName, history=state.history) {
    let weight=0,e1rm=0,repsAtWeight={};
    for(const h of history){
      for(const s of h.sets||[]){if(!s.done||s.exercise!==exerciseName)continue; const w=Number(s.weight)||0,r=Number(s.reps)||0; weight=Math.max(weight,w);e1rm=Math.max(e1rm,estimate1RM(w,r));repsAtWeight[w]=Math.max(repsAtWeight[w]||0,r);}
    }
    return {weight,e1rm,repsAtWeight};
  }
  function detectPRs(workout) {
    const prs=[];
    for(const ex of workout.exercises){
      const best=priorBest(ex.name); const done=ex.sets.filter(s=>s.done);
      if(!done.length)continue;
      const maxW=Math.max(...done.map(s=>Number(s.weight)||0));
      const maxE=Math.max(...done.map(s=>estimate1RM(Number(s.weight)||0,Number(s.reps)||0)));
      if(maxW>0&&maxW>best.weight) prs.push({exercise:ex.name,type:'Weight PR',value:`${maxW} lb`});
      else if(maxE>0&&maxE>best.e1rm+0.5) prs.push({exercise:ex.name,type:'Estimated strength PR',value:`${Math.round(maxE)} lb e1RM`});
      const repSet=done.find(s=>(Number(s.weight)||0)>0&&(Number(s.reps)||0)>(best.repsAtWeight[Number(s.weight)||0]||0));
      if(repSet&&maxW<=best.weight&&maxE<=best.e1rm+0.5) prs.push({exercise:ex.name,type:'Rep PR',value:`${repSet.weight} lb × ${repSet.reps}`});
    }
    return prs;
  }

  function lifetimeVolume(){return state.history.filter(h=>h.type==='workout').reduce((a,h)=>a+(Number(h.volume)||0),0)}
  function allPRs(){return state.history.flatMap(h=>(h.prs||[]).map(pr=>({...pr,date:h.date})))}
  function achievementReady(code){
    const workouts=workoutCount(), rank=currentRank()[0], prs=allPRs();
    return ({first_workout:workouts>=1,streak_7:state.profile.streak>=7,workouts_10:workouts>=10,workouts_25:workouts>=25,first_pr:prs.length>=1,volume_100k:lifetimeVolume()>=100000,bronze_rank:!rank.startsWith('Iron'),perfect_day:!!state.daily.perfectClaimed||Object.values(depth().dailyArchive).some(d=>d.perfect),level_5:accountLevel()>=5})[code];
  }
  function evaluateAchievements(silent=false){
    const d=depth(); let changed=false;
    for(const [code,name,,coins] of ACHIEVEMENTS){
      if(!d.achievements[code]&&achievementReady(code)){
        d.achievements[code]={at:new Date().toISOString()}; state.profile.coins+=coins; changed=true;
        if(!silent) toast(`${name} unlocked · +${coins} Coins`);
      }
    }
    if(changed) saveState();
  }

  function questProgress(title){
    const lower=title.toLowerCase();
    if(lower.includes('step'))return Math.min(100,(state.daily.steps||0)/8000*100);
    if(lower.includes('mobility')||lower.includes('recovery'))return Math.min(100,(state.daily.mobility||0)/10*100);
    if(lower.includes('check-in'))return state.daily.checkin?100:0;
    if(lower.includes('workout')){
      if(state.daily.claimed?.workout)return 100; const w=state.workout.active;if(!w)return 0;
      const sets=w.exercises.flatMap(e=>e.sets);return sets.length?sets.filter(s=>s.done).length/sets.length*100:0;
    }
    return 0;
  }

  function calendarHTML(){
    const today=demoDate(),year=today.getFullYear(),month=today.getMonth(),first=new Date(year,month,1,12),last=new Date(year,month+1,0,12);
    const blanks=(first.getDay()+6)%7; const cells=[];
    for(let i=0;i<blanks;i++)cells.push('<span class="cf-cal empty"></span>');
    for(let day=1;day<=last.getDate();day++){
      const date=new Date(year,month,day,12),key=iso(date),rec=dayRecord(key),future=date>today,before=key<depth().firstDate;
      let cls='neutral',label='Not started';
      if(future||before){cls='neutral';label=future?'Future day':'Before demo tracking';}
      else if(rec?.dayComplete){cls=rec.training?'complete training':'complete recovery';label=rec.training?'Training complete':'Recovery complete';}
      else {cls='missed';label='Planned day missed';}
      if(key===iso(today))cls+=' today';
      cells.push(`<span class="cf-cal ${cls}" title="${label}">${day}</span>`);
    }
    return `<div class="cf-calendar-head"><span>MON</span><span>TUE</span><span>WED</span><span>THU</span><span>FRI</span><span>SAT</span><span>SUN</span></div><div class="cf-calendar">${cells.join('')}</div><div class="cf-legend"><span><i class="training"></i>Training</span><span><i class="recovery"></i>Recovery</span><span><i class="missed"></i>Missed</span></div>`;
  }

  function volumeChart(){
    const data=state.history.filter(h=>h.type==='workout').slice(-8); if(!data.length)return '<div class="sub">Complete workouts to build your volume chart.</div>';
    const max=Math.max(...data.map(h=>Number(h.volume)||0),1);
    return `<div class="cf-chart">${data.map(h=>`<div class="cf-chart-col"><div class="cf-chart-bar" style="height:${Math.max(5,(h.volume/max)*100)}%"></div><small>${String(h.date||'').slice(5)}</small></div>`).join('')}</div>`;
  }
  function weightChart(){
    const data=depth().bodyweight.slice(-8); if(!data.length)return '<div class="sub">Log bodyweight from Profile to see a trend.</div>';
    const vals=data.map(x=>x.weight),min=Math.min(...vals),max=Math.max(...vals),range=Math.max(1,max-min);
    return `<div class="cf-line-chart">${data.map((x,i)=>`<div class="cf-weight-point" style="bottom:${12+((x.weight-min)/range)*70}%;left:${data.length===1?50:(i/(data.length-1))*94+3}%"><b>${x.weight}</b><i></i></div>`).join('')}</div>`;
  }

  function weekHTML(){
    return `<div class="cf-week-strip">${programForWeek().map(day=>`<div class="cf-week-day ${day.current?'current':''} ${day.record?.dayComplete?'done':''}"><span>${day.date.toLocaleDateString(undefined,{weekday:'short'}).toUpperCase()}</span><b>${day.training?'TRAIN':'REC'}</b><small>${day.record?.dayComplete?'✓':day.current?'TODAY':''}</small></div>`).join('')}</div>`;
  }

  function enhanceHome(){
    const screen=document.getElementById('screen-home');if(!screen||screen.querySelector('.cf-week-overview'))return;
    const hero=screen.querySelector('.hero'); if(!hero)return;
    const weekly=weeklyConsistency();
    hero.insertAdjacentHTML('afterend',`<div class="card cf-week-overview"><div class="row between"><div><div class="eyebrow">THIS WEEK</div><b>${weekly.complete} / ${weekly.elapsed||0} planned days complete</b></div><strong class="cf-score">${weekly.score}%</strong></div>${weekHTML()}</div>`);
  }
  function enhanceMissions(){
    document.querySelectorAll('#screen-missions .quest').forEach(q=>{
      if(q.querySelector('.cf-quest-progress'))return; const title=q.querySelector('h3')?.textContent||''; const p=questProgress(title);
      const copy=q.children[1]; if(copy) copy.insertAdjacentHTML('beforeend',`<div class="cf-quest-progress"><i style="width:${p}%"></i></div>`);
    });
  }
  function enhanceProgress(){
    const screen=document.getElementById('screen-progress');if(!screen||screen.querySelector('.cf-progress-depth'))return;
    const weekly=weeklyConsistency(),prs=allPRs().slice(-8).reverse();
    screen.insertAdjacentHTML('beforeend',`<div class="cf-progress-depth">
      <div class="section-title">CONSISTENCY</div><div class="card"><div class="row between"><div><b>${weekly.complete} / ${weekly.elapsed} this week</b><div class="sub">Successful training and planned recovery both count.</div></div><strong class="cf-score">${weekly.score}%</strong></div>${weekHTML()}</div>
      <div class="section-title">${demoDate().toLocaleDateString(undefined,{month:'long'}).toUpperCase()} CALENDAR</div><div class="card">${calendarHTML()}</div>
      <div class="section-title">TRAINING VOLUME</div><div class="card cf-chart-card">${volumeChart()}</div>
      <div class="section-title">BODYWEIGHT TREND</div><div class="card cf-chart-card">${weightChart()}</div>
      <div class="section-title">PERSONAL RECORDS</div><div class="card">${prs.length?prs.map(pr=>`<div class="cf-pr-row"><span><b>${escapeHtml(pr.exercise)}</b><small>${pr.date} · ${pr.type}</small></span><strong>${escapeHtml(pr.value)}</strong></div>`).join(''):'<div class="sub">Your first PR will appear here after a workout.</div>'}</div>
    </div>`);
  }
  function cosmeticOwned(code){return (state.inventory[code]||0)>0||state.purchased.includes(code)}
  function saveBodyweight(){const el=document.getElementById('cfBodyweight');const weight=Number(el?.value)||0;if(weight<50||weight>700)return toast('Enter a bodyweight between 50 and 700 lb');const d=depth();const key=state.daily.date;const existing=d.bodyweight.find(x=>x.date===key);if(existing)existing.weight=weight;else d.bodyweight.push({date:key,weight});d.bodyweight.sort((a,b)=>a.date.localeCompare(b.date));saveState();renderAll();toast('Bodyweight saved')}
  window.cfSaveBodyweight=saveBodyweight;
  function setCosmetic(category,code){if(code&&!cosmeticOwned(code))return toast('Purchase this cosmetic first');depth().cosmetics[category]=code||null;saveState();applyCosmetics();renderAll();toast(code?'Cosmetic equipped':'Cosmetic removed')}
  window.cfSetCosmetic=setCosmetic;
  function togglePref(key){depth().prefs[key]=!depth().prefs[key];saveState();renderAll()}
  window.cfTogglePref=togglePref;
  function enhanceProfile(){
    const screen=document.getElementById('screen-profile');if(!screen||screen.querySelector('.cf-profile-depth'))return;
    const d=depth(),latest=d.bodyweight.at(-1)?.weight||'',unlocked=ACHIEVEMENTS.filter(([c])=>d.achievements[c]);
    screen.insertAdjacentHTML('beforeend',`<div class="cf-profile-depth">
      <div class="section-title">BODYWEIGHT</div><div class="card"><div class="sub">Optional. Used only for your local progress trend.</div><div class="input-row"><input id="cfBodyweight" type="number" min="50" max="700" step="0.1" value="${latest}" placeholder="Weight in lb"><button class="primary small" onclick="cfSaveBodyweight()">Save</button></div></div>
      <div class="section-title">ACHIEVEMENTS · ${unlocked.length}/${ACHIEVEMENTS.length}</div><div class="cf-achievements">${ACHIEVEMENTS.map(([code,name,desc])=>`<div class="cf-achievement ${d.achievements[code]?'unlocked':''}"><i>${d.achievements[code]?'✓':'◇'}</i><span><b>${name}</b><small>${desc}</small></span></div>`).join('')}</div>
      <div class="section-title">PROFILE STYLE</div><div class="card cf-cosmetics">
        <button class="sheet-option" onclick="cfSetCosmetic('frame',${d.cosmetics.frame?"null":"'frame_lime'"})"><span><b>Lime profile frame</b><small class="sub">${cosmeticOwned('frame_lime')?(d.cosmetics.frame?'Equipped · tap to remove':'Owned · tap to equip'):'Buy it in the Coin Shop'}</small></span><span>${d.cosmetics.frame?'✓':'›'}</span></button>
        <button class="sheet-option" onclick="cfSetCosmetic('title',${d.cosmetics.title?"null":"'title_consistent'"})"><span><b>“Consistent” title</b><small class="sub">${cosmeticOwned('title_consistent')?(d.cosmetics.title?'Equipped · tap to remove':'Owned · tap to equip'):'Buy it in the Coin Shop'}</small></span><span>${d.cosmetics.title?'✓':'›'}</span></button>
        <button class="sheet-option" onclick="cfSetCosmetic('badge',${d.cosmetics.badge?"null":"'badge_founder'"})"><span><b>Consistency badge</b><small class="sub">${cosmeticOwned('badge_founder')?(d.cosmetics.badge?'Equipped · tap to remove':'Owned · tap to equip'):'Buy it in the Coin Shop'}</small></span><span>${d.cosmetics.badge?'✓':'›'}</span></button>
        <button class="sheet-option" onclick="cfSetCosmetic('theme',${d.cosmetics.theme?"null":"'theme_lime_glow'"})"><span><b>Lime Glow theme</b><small class="sub">${cosmeticOwned('theme_lime_glow')?(d.cosmetics.theme?'Equipped · tap to remove':'Owned · tap to equip'):'Buy it in the Coin Shop'}</small></span><span>${d.cosmetics.theme?'✓':'›'}</span></button>
      </div>
      <div class="section-title">WORKOUT TIMER</div><div class="card"><button class="sheet-option" onclick="cfTogglePref('restVibrate')"><span><b>Rest vibration</b><small class="sub">Vibrate when rest ends when supported.</small></span><span>${d.prefs.restVibrate?'ON':'OFF'}</span></button><button class="sheet-option" onclick="cfTogglePref('restSound')"><span><b>Rest sound</b><small class="sub">Play a short tone when rest ends.</small></span><span>${d.prefs.restSound?'ON':'OFF'}</span></button></div>
    </div>`);
  }
  function applyCosmetics(){
    const c=depth().cosmetics; document.body.classList.toggle('cf-lime-glow',c.theme==='theme_lime_glow');
    document.body.classList.toggle('cf-profile-frame',c.frame==='frame_lime');
  }

  function openExerciseHistory(name){
    const entries=exerciseHistory(name).slice(0,10);openSheet(`<div class="eyebrow">EXERCISE HISTORY</div><h2>${escapeHtml(name)}</h2><div class="sub">Your most recent completed sets.</div><div class="cf-ex-history">${entries.length?entries.map(h=>`<div class="cf-ex-history-row"><span><b>${h.date}</b><small>${h.difficulty||'No rating'}</small></span><strong>${h.exerciseSets.map(s=>`${s.weight||0} × ${s.reps}`).join(' · ')}</strong></div>`).join(''):'<div class="card"><div class="sub">No completed history yet.</div></div>'}</div>`);
  }
  window.cfOpenExerciseHistory=openExerciseHistory;

  function movementFamily(ex){const n=ex.name.toLowerCase();if(/squat|lunge|leg press|step-up|extension/.test(n))return'legs';if(/deadlift|curl machine|leg curl|good morning|hip thrust|bridge/.test(n))return'posterior';if(/bench|chest|push-up|pec deck|floor press/.test(n))return'chest';if(/row|pulldown|pull-up|pullover/.test(n))return'back';if(/shoulder|overhead|lateral|rear delt/.test(n))return'shoulder';if(/curl/.test(n))return'biceps';if(/triceps|pressdown/.test(n))return'triceps';return'core'}
  function availableSubstitutes(ex){
    const program=typeof cfProgram==='function'?cfProgram():PROGRAM; const family=movementFamily(ex); const seen=new Set(); const out=[];
    for(const w of program){for(const item of w.exercises||[]){const candidate={name:item[0],muscle:item[1],sets:item[2],repMin:item[3],repMax:item[4],rest:item[5]};if(candidate.name!==ex.name&&movementFamily(candidate)===family&&!seen.has(candidate.name)){seen.add(candidate.name);out.push(candidate)}}}
    return out.slice(0,6);
  }
  function openSubstitutes(){const w=state.workout.active;if(!w)return;const ex=w.exercises[w.exerciseIndex],subs=availableSubstitutes(ex);openSheet(`<div class="eyebrow">REPLACE EXERCISE</div><h2>${escapeHtml(ex.name)}</h2><div class="sub">Only movements available in your current equipment-based program are shown.</div>${subs.length?subs.map((s,i)=>`<button class="sheet-option" onclick="cfReplaceExercise(${i})"><span><b>${escapeHtml(s.name)}</b><small class="sub">${escapeHtml(s.muscle)} · ${s.sets} × ${s.repMin}–${s.repMax}</small></span><span>›</span></button>`).join(''):'<div class="card"><div class="sub">No compatible replacement found in this plan.</div></div>'}`); window.__cfSubs=subs}
  window.cfOpenSubstitutes=openSubstitutes;
  window.cfReplaceExercise=function(index){const w=state.workout.active,s=window.__cfSubs?.[index];if(!w||!s)return;w.exercises[w.exerciseIndex]={...s,sets:Array.from({length:s.sets},(_,i)=>({number:i+1,weight:lastWeight(s.name),reps:s.repMin,done:false}))};saveState();closeSheet();renderWorkout();toast(`Replaced with ${s.name}`)};

  function toggleWarmups(){const w=state.workout.active;if(!w)return;w.showWarmups=!w.showWarmups;saveState();renderWorkout()}
  window.cfToggleWarmups=toggleWarmups;
  function setExerciseRpe(value){const w=state.workout.active;if(!w)return;w.exerciseRpe||={};w.exerciseRpe[w.exercises[w.exerciseIndex].name]=value;saveState();renderWorkout()}
  window.cfSetExerciseRpe=setExerciseRpe;
  function togglePause(){const w=state.workout.active;if(!w)return;if(!w.paused){w.paused=true;w.pausedAt=Date.now();skipRest();}else{w.startedAt+=Date.now()-(w.pausedAt||Date.now());w.paused=false;w.pausedAt=null;}saveState();renderWorkout()}
  window.cfTogglePause=togglePause;

  function workoutExtras(){
    const w=state.workout.active;if(!w)return;const ex=w.exercises[w.exerciseIndex],body=document.querySelector('#workoutContent .workout-body');if(!body)return;
    const guideButton=[...body.querySelectorAll('button')].find(b=>b.textContent.includes('How to perform'));
    if(guideButton&&!body.querySelector('.cf-exercise-tools')){
      const last=lastPerformance(ex.name),rec=recommendation(ex);
      guideButton.insertAdjacentHTML('beforebegin',`<div class="cf-performance-card"><div><div class="eyebrow">LAST SESSION</div><b>${last?last.exerciseSets.map(s=>`${s.weight||0} × ${s.reps}`).join(' · '):'No history yet'}</b></div><div><div class="eyebrow">TODAY'S TARGET</div><b>${escapeHtml(rec.text)}</b></div></div>`);
      guideButton.insertAdjacentHTML('afterend',`<div class="cf-exercise-tools"><button class="ghost small" onclick="cfOpenExerciseHistory('${escapeHtml(ex.name).replace(/'/g,"&#39;")}')">History</button><button class="ghost small" onclick="cfOpenSubstitutes()">Replace</button><button class="ghost small" onclick="cfToggleWarmups()">${w.showWarmups?'Hide warm-up':'Warm-up sets'}</button></div>`);
    }
    if(w.showWarmups&&!body.querySelector('.cf-warmups')){
      const target=recommendation(ex).weight||Math.max(...ex.sets.map(s=>Number(s.weight)||0),0);const warm=target>0?[Math.max(5,Math.round(target*.5/5)*5),Math.max(5,Math.round(target*.7/5)*5)]:[];
      const tools=body.querySelector('.cf-exercise-tools');tools?.insertAdjacentHTML('afterend',`<div class="cf-warmups card"><div class="row between"><b>Optional warm-up</b><span class="badge">Not counted</span></div>${warm.length?warm.map((v,i)=>`<div class="cf-warm-row"><span>Warm-up ${i+1}</span><b>${v} lb × ${i?5:8}</b></div>`).join(''):'<div class="sub">Use 1–2 easy practice sets before your working sets.</div>'}</div>`);
    }
    const sections=[...body.querySelectorAll('.section-title')];const session=sections.find(x=>x.textContent.trim()==='SESSION');
    if(session&&!body.querySelector('.cf-rpe')){
      const rating=w.exerciseRpe?.[ex.name]||'';session.insertAdjacentHTML('beforebegin',`<div class="cf-rpe"><div><b>How does this exercise feel?</b><div class="sub">Optional exercise difficulty rating.</div></div><div class="cf-rpe-buttons">${['Easy','Good','Hard'].map(x=>`<button class="${rating===x?'active':''}" onclick="cfSetExerciseRpe('${x}')">${x}</button>`).join('')}</div></div>`);
    }
    const switcher=body.querySelector('.cf-exercise-switcher');
    if(switcher&&!body.querySelector('.cf-session-actions'))switcher.insertAdjacentHTML('beforebegin',`<div class="cf-session-actions"><button class="ghost" onclick="cfTogglePause()">${w.paused?'Resume workout':'Pause workout'}</button><button class="ghost" onclick="cfOpenWorkoutNavigatorList()">Workout list</button></div>`);
    if(w.paused&&!body.querySelector('.cf-pause-overlay'))body.insertAdjacentHTML('afterbegin',`<div class="cf-pause-overlay"><div class="eyebrow">SESSION PAUSED</div><h2>Take your time.</h2><div class="sub">Your workout remains saved on this device.</div><button class="primary" onclick="cfTogglePause()">Resume workout</button></div>`);
    const rest=document.getElementById('restBox');
    if(rest&&restRemaining>0&&!rest.querySelector('.cf-rest-ring')){
      const next=w.exercises[w.exerciseIndex+1];rest.insertAdjacentHTML('afterbegin',`<div class="cf-rest-ring" style="--rest:${Math.min(100,restRemaining/(ex.rest||1)*100)}"><span>${formatRest(restRemaining)}</span></div>`);if(next)rest.insertAdjacentHTML('beforeend',`<div class="cf-rest-next"><small>NEXT</small><b>${escapeHtml(next.name)}</b></div>`);
    }
  }

  let restVisualTimer=null,lastRestRemaining=0;
  function updateRestVisual(){const ring=document.querySelector('.cf-rest-ring');if(ring&&state.workout.active){const ex=state.workout.active.exercises[state.workout.active.exerciseIndex];ring.style.setProperty('--rest',Math.min(100,restRemaining/(ex.rest||1)*100));const span=ring.querySelector('span');if(span)span.textContent=formatRest(restRemaining)}if(lastRestRemaining>0&&restRemaining===0)restAlert();lastRestRemaining=restRemaining;}
  function restAlert(){const p=depth().prefs;if(p.restVibrate&&navigator.vibrate)navigator.vibrate([120,70,120]);if(p.restSound){try{const ctx=new (window.AudioContext||window.webkitAudioContext)(),osc=ctx.createOscillator(),gain=ctx.createGain();osc.connect(gain);gain.connect(ctx.destination);osc.frequency.value=660;gain.gain.value=.04;osc.start();osc.stop(ctx.currentTime+.12)}catch{}}}
  const baseStartRest=startRest;
  startRest=function(seconds){baseStartRest(seconds);clearInterval(restVisualTimer);lastRestRemaining=seconds;restVisualTimer=setInterval(updateRestVisual,250);setTimeout(updateRestVisual,0)};
  const baseSkipRest=skipRest;
  skipRest=function(){baseSkipRest();updateRestVisual();clearInterval(restVisualTimer)};

  function setWorkoutNote(value){if(state.workout.active){state.workout.active.note=value;saveState()}}
  window.cfSetWorkoutNote=setWorkoutNote;
  openFinishWorkout=function(){const w=state.workout.active;if(!w)return;const done=w.exercises.flatMap(e=>e.sets).filter(s=>s.done).length;if(!done){toast('Complete at least one set first');return}openSheet(`<div class="eyebrow">POST-WORKOUT CHECK-IN</div><h2>Finish your session</h2><label class="sub">Workout notes</label><textarea class="cf-notes" maxlength="400" placeholder="How did the session feel? Any pain, wins, or changes for next time?" oninput="cfSetWorkoutNote(this.value)">${escapeHtml(w.note||'')}</textarea><div class="sub">How hard was today overall?</div><div class="rating-grid" style="margin-top:14px"><button onclick="finishWorkout('Too Easy')"><b>Too easy</b><div class="sub">Increase next time</div></button><button onclick="finishWorkout('Good')"><b>Good</b><div class="sub">Stay on track</div></button><button onclick="finishWorkout('Hard')"><b>Hard</b><div class="sub">Watch recovery</div></button><button onclick="finishWorkout('Too Hard')"><b>Too hard</b><div class="sub">Back off next time</div></button></div>`)};

  finishWorkout=function(difficulty){
    const w=state.workout.active;if(!w)return;const rankBefore=currentRank()[0],levelBefore=accountLevel(),prs=detectPRs(w);
    const allSets=w.exercises.flatMap(e=>e.sets.map(s=>({...s,exercise:e.name}))),doneSets=allSets.filter(s=>s.done),ratio=doneSets.length/allSets.length,eligible=ratio>=.7,duration=Math.max(1,Math.round((Date.now()-w.startedAt)/60000)),volume=doneSets.reduce((sum,s)=>sum+(s.weight*s.reps),0);
    state.history.push({type:'workout',date:state.daily.date,name:w.name,duration,volume,completedSets:doneSets.length,totalSets:allSets.length,difficulty,eligible,sets:allSets,prs,note:w.note||'',exerciseRpe:w.exerciseRpe||{}});
    state.workout.active=null;if(eligible&&rewardOnce('workout',{rp:30,xp:220,coins:85})){}state.daily.checkin=difficulty;rewardOnce('checkin',{rp:5,xp:20,coins:10});saveState();evaluateDaily();evaluateAchievements(true);archiveDaily();
    const rankAfter=currentRank()[0],levelAfter=accountLevel(),rankUp=rankAfter!==rankBefore,levelUp=levelAfter>levelBefore;closeSheet();closeWorkout();renderAll();
    const finishEffect=depth().cosmetics.finish==='finish_burst'?' cf-finish-burst':'';
    setTimeout(()=>openSheet(`<div class="cf-summary${finishEffect}"><div class="eyebrow">SESSION SAVED</div><h2>${eligible?'Workout complete':'Partial workout saved'}</h2>${rankUp?`<div class="cf-level-up"><small>RANK UP</small><strong>${rankAfter}</strong></div>`:''}${levelUp?`<div class="cf-level-up"><small>LEVEL UP</small><strong>Level ${levelAfter}</strong></div>`:''}<div class="stat-grid" style="margin:16px 0"><div class="stat"><strong>${duration}m</strong><span>DURATION</span></div><div class="stat"><strong>${doneSets.length}/${allSets.length}</strong><span>SETS</span></div><div class="stat"><strong>${formatNum(volume)}</strong><span>VOLUME LB</span></div></div><div class="card"><div class="row between"><b>${eligible?'+30 RP · +220 XP · +85 Coins':'Partial session'}</b><span class="badge">${state.profile.streak} day streak</span></div>${w.note?`<div class="sub cf-summary-note">“${escapeHtml(w.note)}”</div>`:''}</div>${prs.length?`<div class="section-title">NEW PERSONAL RECORDS</div><div class="card">${prs.map(pr=>`<div class="cf-pr-row"><span><b>${escapeHtml(pr.exercise)}</b><small>${pr.type}</small></span><strong>${escapeHtml(pr.value)}</strong></div>`).join('')}</div>`:''}<button class="primary" style="width:100%;margin-top:16px" onclick="closeSheet();showScreen('progress')">View progress</button></div>`),120);
    setTimeout(()=>evaluateAchievements(false),450);
  };

  const baseOpenPlanSheet=openPlanSheet;
  openPlanSheet=function(){
    const program=typeof cfProgram==='function'?cfProgram():PROGRAM;const days=programForWeek();openSheet(`<div class="eyebrow">${typeof cfPlanName==='function'?cfPlanName().toUpperCase():'CONSISTIFIT PROGRAM'}</div><h2>This week</h2><div class="sub">Your plan follows the training days and equipment you selected.</div><div class="cf-week-plan">${days.map(day=>`<div class="cf-week-plan-row ${day.current?'current':''}"><span><b>${day.date.toLocaleDateString(undefined,{weekday:'short'})}</b><small>${day.date.toLocaleDateString(undefined,{month:'short',day:'numeric'})}</small></span><span><b>${day.training?escapeHtml(day.workout?.name||'Workout'):'Recovery + Mobility'}</b><small>${day.record?.dayComplete?'Completed ✓':day.current?'Today':'Planned'}</small></span></div>`).join('')}</div><div class="section-title">PROGRAM WORKOUTS</div>${program.map(w=>`<div class="card cf-program-card"><b>${escapeHtml(w.name)}</b><div class="sub">${w.exercises.length} exercises</div></div>`).join('')}`)
  };

  const baseRenderAll=renderAll;
  renderAll=function renderAllWithDepth(){baseRenderAll();depth();applyCosmetics();evaluateAchievements(true);enhanceHome();enhanceMissions();enhanceProgress();enhanceProfile();};
  const previousRenderWorkout=window.renderWorkout;
  window.renderWorkout=function renderWorkoutWithDepth(){previousRenderWorkout();workoutExtras();};

  const basePurchaseItem=purchaseItem;
  purchaseItem=function(code){const before=cosmeticOwned(code);basePurchaseItem(code);if(!before&&cosmeticOwned(code)){const map={frame_lime:'frame',title_consistent:'title',badge_founder:'badge',theme_lime_glow:'theme',finish_burst:'finish'};if(map[code]&&!depth().cosmetics[map[code]])depth().cosmetics[map[code]]=code;saveState();applyCosmetics();}};

  applyCosmetics();
})();