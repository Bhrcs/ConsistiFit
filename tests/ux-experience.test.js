const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

function harness() {
  const state = {daily:{date:'2026-09-16',claimed:{},steps:0},plan:{days:5},profile:{streak:0},depth:{firstDate:'2026-09-01',dailyArchive:{}},history:[],workout:{active:null}};
  const context = {state,console,Date,Math,JSON,Set,Number,String,Array,
    demoDate:()=>new Date('2026-09-16T12:00:00'), keyForDate:d=>`${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`,
    document:{getElementById:()=>null,querySelector:()=>null,addEventListener:()=>{}},
    CFOverride:{plannedTraining:key=>[1,2,3,5,6].includes(new Date(key+'T12:00:00').getDay())},
    cfProgram:()=>[{name:'Workout A'},{name:'Workout B'}], workoutCount:()=>0,
    saveState:()=>{}, startWorkout:()=>{}, finishWorkout:()=>{}, renderWorkout:()=>{}, renderAll:()=>{},
    openSheet:()=>{},closeSheet:()=>{},ensureDaily:()=>{},toggleWorkoutSet:()=>{},toast:()=>{}
  };
  context.window=context;
  vm.createContext(context);vm.runInContext(fs.readFileSync('ux-experience.js','utf8'),context);
  return context;
}
const h=harness();
// Missing tracked days count as incomplete, while future and pre-install days do not.
h.state.depth.firstDate='2026-09-14';
h.state.depth.dailyArchive['2026-09-14']={date:'2026-09-14',training:true,dayComplete:true,claimed:{workout:{rp:30},checkin:{rp:5}}};
h.state.daily.claimed={recovery:{rp:30}};
let recap=h.CFExperience.weeklyRecap();
assert.equal(recap.elapsed,3);assert.equal(recap.complete,2);assert.equal(recap.score,67);assert.equal(recap.rp,65);assert.equal(recap.recovery,1);assert.equal(recap.longest,1);
h.state.depth.firstDate='2026-09-16';
assert.equal(h.CFExperience.weeklyRecap().elapsed,1);
assert.equal(h.CFExperience.weeklyRecap(-1).elapsed,0);
// Legacy reward-key archives cannot pretend to have exact RP totals.
h.state.depth.firstDate='2026-09-14';
h.state.depth.dailyArchive['2026-09-14'].claimed=['workout'];
assert.equal(h.CFExperience.weeklyRecap().legacyRp,true);
h.state.workoutOverrides={ledger:{'2026-09-14':{date:'2026-09-14',claimed:{workout:{rp:0,migrated:true}}}}};
assert.equal(h.CFExperience.weeklyRecap().legacyRp,true);
// Adaptation ignores the unfinished current day and requires real evidence.
const a=harness();
const suggestion=a.CFExperience.adaptation();
assert(suggestion);assert.equal(suggestion.to,4);assert(suggestion.scheduled>=5);assert.equal(suggestion.completed,0);
assert(suggestion.reason.includes(`0 of your last ${suggestion.scheduled}`));
a.cfUxDismissAdaptation();assert.equal(a.CFExperience.adaptation(),null);assert.equal(a.state.plan.days,5);
const b=harness();b.cfUxAcceptAdaptation();assert.equal(b.state.plan.days,4);
const c=harness();c.state.workout.active={name:'In progress'};c.cfUxAcceptAdaptation();assert.equal(c.state.plan.days,5);
const d=harness();d.state.depth.firstDate='2026-09-16';assert.equal(d.CFExperience.adaptation(),null);
assert(h.CFExperience.milestoneText(7).includes('7-day milestone reached'));
assert.equal(h.CFExperience.nextSchedule().length,7);
console.log('UX regression tests passed: recap boundaries, legacy data, evidence-based adaptation, explicit accept/ignore, active-session guard.');
