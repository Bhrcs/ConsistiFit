const CF_EXERCISE_LIBRARY = (() => {
  const safe = (value='') => String(value).trim();

  const families = [
    {
      key: 'leg-extension',
      match: /leg extension/i,
      motion: 'knee-extension',
      overview: 'A quad-focused knee-extension movement. Set the machine so your knee lines up with the machine pivot, keep your hips down, and extend the knees without kicking or slamming the stack.',
      steps: [
        'Adjust the seat and pad so your knees line up with the machine pivot and the lower pad rests just above your ankles.',
        'Sit tall with your back against the pad and hold the handles.',
        'Brace your core and smoothly straighten your knees until your legs are nearly straight.',
        'Pause briefly while squeezing the quads.',
        'Lower the weight under control until you return to the starting position.'
      ],
      mistakes: ['Using momentum to kick the weight up', 'Letting the hips lift off the seat', 'Dropping the weight stack between reps'],
      cues: ['Smooth up, slower down', 'Keep the hips heavy', 'Squeeze the quads at the top'],
      phases: [['Set up','Knees bent and aligned with the pivot.'],['Extend','Straighten the knees under control.'],['Return','Lower slowly without letting the stack slam.']],
      substitute: 'Dumbbell split squat, reverse lunge, or bodyweight squat.'
    },
    {
      key: 'leg-curl',
      match: /leg curl/i,
      motion: 'knee-flexion',
      overview: 'A hamstring-focused knee-flexion movement. Keep your hips and torso stable while curling the pad toward you using the hamstrings.',
      steps: [
        'Adjust the machine so your knees line up with the pivot and the pad sits just above the heels or ankles.',
        'Brace your trunk and keep your hips pressed into the pad or seat.',
        'Curl the pad through a comfortable range by bending the knees.',
        'Pause briefly when the hamstrings are fully shortened.',
        'Return slowly until the knees are nearly straight.'
      ],
      mistakes: ['Lifting the hips to move more weight', 'Jerking the first part of the rep', 'Letting the return phase drop too quickly'],
      cues: ['Keep the hips pinned', 'Curl with the hamstrings', 'Control the return'],
      phases: [['Set up','Knees almost straight and hips stable.'],['Curl','Bend the knees and pull the pad in.'],['Return','Lengthen the hamstrings under control.']],
      substitute: 'Romanian deadlift, band leg curl, or single-leg glute bridge.'
    },
    {
      key: 'calf',
      match: /calf raise/i,
      motion: 'calf',
      overview: 'A calf-strengthening movement. Move through the ankle instead of bouncing through the knees, and use a full controlled range.',
      steps: [
        'Set your feet so the balls of the feet are supported and the heels can move freely.',
        'Keep the knees softly locked or slightly bent depending on the variation.',
        'Lower the heels until you feel a stretch through the calves.',
        'Drive through the balls of the feet and rise as high as you can without rolling the ankles outward.',
        'Pause at the top, then lower slowly.'
      ],
      mistakes: ['Bouncing through the bottom', 'Rolling the ankles outward', 'Using a very short range of motion'],
      cues: ['Stretch low', 'Rise tall', 'Pause at the top'],
      phases: [['Stretch','Heels lowered under control.'],['Rise','Press through the balls of the feet.'],['Squeeze','Finish tall, then lower slowly.']],
      substitute: 'Standing bodyweight calf raise or dumbbell calf raise.'
    },
    {
      key: 'hip-abduction',
      match: /hip abduction/i,
      motion: 'abduction',
      overview: 'A glute-focused hip-abduction movement. Keep the pelvis stable while moving the thighs outward without bouncing.',
      steps: [
        'Adjust the seat and thigh pads so you can sit tall with the feet supported.',
        'Brace your core and keep the pelvis still against the seat.',
        'Press the knees outward against the pads.',
        'Pause briefly in the open position.',
        'Return slowly until the weight stack is just above resting.'
      ],
      mistakes: ['Rocking the torso for momentum', 'Letting the stack slam shut', 'Using a range that forces the pelvis to rotate'],
      cues: ['Stay tall', 'Open from the hips', 'Control the return'],
      phases: [['Set up','Knees comfortably inside the pads.'],['Open','Drive the thighs outward.'],['Return','Bring the knees back in slowly.']],
      substitute: 'Band lateral walk or side-lying hip abduction.'
    },
    {
      key: 'squat',
      match: /squat|leg press|step-up|lunge/i,
      motion: 'squat',
      overview: 'A lower-body knee-and-hip movement for the quads and glutes. Keep the whole foot planted, brace the trunk, and let the knees track in the same direction as the toes.',
      steps: [
        'Set your stance so you feel balanced through the heel, big toe, and little toe.',
        'Brace your core and keep the ribs stacked over the pelvis.',
        'Bend at the knees and hips together while keeping the knees tracking over the toes.',
        'Lower through a comfortable range without losing foot pressure or trunk control.',
        'Drive the floor away and finish tall without snapping the knees backward.'
      ],
      mistakes: ['Knees collapsing inward', 'Heels lifting or feet rolling', 'Rounding or overextending the lower back', 'Rushing the bottom position'],
      cues: ['Whole foot down', 'Knees follow toes', 'Brace before you move', 'Drive the floor away'],
      phases: [['Set up','Balanced stance with the trunk braced.'],['Lower','Bend knees and hips while staying controlled.'],['Stand','Drive through the whole foot to return tall.']],
      substitute: 'Goblet squat, reverse lunge, split squat, or leg press depending on equipment.'
    },
    {
      key: 'hinge',
      match: /deadlift|romanian|good morning|hinge/i,
      motion: 'hinge',
      overview: 'A hip-hinge pattern for the hamstrings and glutes. The hips travel backward while the spine stays controlled and the weight remains close to the body.',
      steps: [
        'Stand tall with the weight close to your thighs and soften the knees.',
        'Brace the trunk, then push the hips backward as if closing a car door with your hips.',
        'Keep the weight close and continue until you feel a strong hamstring stretch without rounding the back.',
        'Drive the hips forward by squeezing the glutes.',
        'Finish tall with the ribs stacked instead of leaning backward.'
      ],
      mistakes: ['Turning the movement into a squat', 'Letting the weight drift away from the body', 'Rounding the lower back', 'Leaning backward at lockout'],
      cues: ['Hips back', 'Keep the weight close', 'Long spine', 'Squeeze the glutes to stand'],
      phases: [['Set up','Soft knees, weight close, trunk braced.'],['Hinge','Push the hips back and keep the spine controlled.'],['Stand','Drive the hips forward and finish tall.']],
      substitute: 'Dumbbell RDL, kettlebell RDL, band good morning, or glute bridge.'
    },
    {
      key: 'hip-thrust',
      match: /hip thrust|glute bridge/i,
      motion: 'bridge',
      overview: 'A hip-extension movement for the glutes. Keep the ribs down, drive through the feet, and finish with the hips rather than arching the lower back.',
      steps: [
        'Set the upper back on a bench for a hip thrust, or lie on the floor for a glute bridge.',
        'Place the feet so the shins are close to vertical at the top.',
        'Brace the core and gently tuck the pelvis.',
        'Drive through the feet and squeeze the glutes to raise the hips.',
        'Pause at the top, then lower under control.'
      ],
      mistakes: ['Hyperextending the lower back at the top', 'Feet too far away or too close', 'Pushing mainly through the toes'],
      cues: ['Ribs down', 'Drive through the heels', 'Squeeze the glutes, not the low back'],
      phases: [['Set up','Feet planted and ribs stacked.'],['Drive','Raise the hips by squeezing the glutes.'],['Lower','Return under control while keeping tension.']],
      substitute: 'Glute bridge, dumbbell hip thrust, or banded hip thrust.'
    },
    {
      key: 'horizontal-press',
      match: /bench press|chest press|floor press|push-up|pec deck|chest fly/i,
      motion: 'press',
      overview: 'A chest-focused pressing pattern. Keep the shoulder blades controlled, wrists stacked, and press without shrugging the shoulders toward the ears.',
      steps: [
        'Set your body so the chest is open, the upper back is stable, and the feet are supported.',
        'Position the hands so the wrists stay stacked over the forearms.',
        'Lower the handles, dumbbells, bar, or body with control until you reach a comfortable chest stretch.',
        'Press away while keeping the shoulders down and the elbows in a strong path.',
        'Finish the rep without forcefully locking or shrugging.'
      ],
      mistakes: ['Shoulders rolling forward', 'Elbows flaring excessively', 'Bouncing through the bottom', 'Wrists bending backward'],
      cues: ['Chest tall', 'Wrists stacked', 'Shoulders down', 'Press smoothly'],
      phases: [['Set up','Upper back stable and hands aligned.'],['Lower','Bring the resistance toward the chest under control.'],['Press','Drive away and finish without shrugging.']],
      substitute: 'Push-up, dumbbell floor press, machine chest press, or band chest press.'
    },
    {
      key: 'vertical-press',
      match: /shoulder press|overhead press|arnold press|pike push-up/i,
      motion: 'vertical-press',
      overview: 'An overhead pressing pattern for the shoulders and triceps. Keep the ribs controlled and move the load overhead without turning the press into a backbend.',
      steps: [
        'Set the hands just outside shoulder width or in the machine handles.',
        'Brace the core and keep the ribs stacked over the pelvis.',
        'Press the weight upward while keeping the forearms close to vertical.',
        'Finish overhead without aggressively shrugging or arching the lower back.',
        'Lower back to the starting position under control.'
      ],
      mistakes: ['Overarching the lower back', 'Pressing around the face instead of moving the head naturally out of the way', 'Letting the wrists collapse backward'],
      cues: ['Ribs down', 'Forearms vertical', 'Press up, not back', 'Control the lowering phase'],
      phases: [['Set up','Load at shoulder level and core braced.'],['Press','Move the resistance overhead.'],['Return','Lower back to shoulder level slowly.']],
      substitute: 'Dumbbell shoulder press, machine shoulder press, band press, or pike push-up.'
    },
    {
      key: 'row',
      match: /row|reverse snow angel/i,
      motion: 'row',
      overview: 'A horizontal pulling pattern for the back and biceps. Keep the torso stable and pull by driving the elbows rather than yanking with the hands.',
      steps: [
        'Set your chest and torso in a stable position before the first rep.',
        'Reach forward enough to lengthen the back muscles without losing spinal control.',
        'Pull the handle or weight toward the lower ribs by driving the elbows backward.',
        'Pause briefly when the shoulder blades are pulled back without shrugging.',
        'Return slowly until the arms are long again.'
      ],
      mistakes: ['Jerking the torso backward', 'Shrugging the shoulders', 'Pulling too high toward the neck', 'Dropping the weight on the return'],
      cues: ['Lead with the elbows', 'Chest stable', 'Shoulders away from ears', 'Reach, then row'],
      phases: [['Reach','Arms long and torso stable.'],['Pull','Drive the elbows toward the ribs.'],['Return','Reach forward under control.']],
      substitute: 'Dumbbell row, cable row, machine row, barbell row, or band row.'
    },
    {
      key: 'vertical-pull',
      match: /lat pulldown|pull-up|pullover|lat sweep/i,
      motion: 'vertical-pull',
      overview: 'A vertical pulling pattern for the lats and upper back. Keep the ribs controlled and pull the elbows down instead of cranking the neck or swinging the torso.',
      steps: [
        'Take a secure grip and set the shoulders down away from the ears.',
        'Brace the core with the chest tall but not excessively arched.',
        'Pull by driving the elbows down toward the sides of the torso.',
        'Pause briefly when the lats are shortened.',
        'Return to the top under control and allow a comfortable stretch.'
      ],
      mistakes: ['Swinging the torso for momentum', 'Pulling behind the neck', 'Shrugging at the bottom', 'Letting the weight yank the shoulders upward'],
      cues: ['Elbows to your pockets', 'Ribs down', 'Long reach at the top', 'No swinging'],
      phases: [['Reach','Arms long with shoulders controlled.'],['Pull','Drive the elbows down.'],['Return','Lengthen the lats under control.']],
      substitute: 'Lat pulldown, assisted pull-up, band pulldown, or dumbbell pullover.'
    },
    {
      key: 'shoulder-isolation',
      match: /lateral raise|rear delt|reverse pec deck/i,
      motion: 'raise',
      overview: 'A shoulder-isolation movement. Use a light enough load to keep the torso quiet and move from the shoulder rather than swinging the whole body.',
      steps: [
        'Stand or sit tall with a soft bend in the elbows.',
        'Brace the torso before moving.',
        'Raise the arms through the intended path until the target shoulder muscles are working hard.',
        'Pause briefly without shrugging.',
        'Lower slowly and keep tension through the bottom.'
      ],
      mistakes: ['Swinging the torso', 'Shrugging the shoulders', 'Using a load that forces a short uncontrolled range'],
      cues: ['Lead with the elbows', 'Stay tall', 'Shoulders away from ears', 'Slow on the way down'],
      phases: [['Set up','Arms relaxed and torso still.'],['Raise','Lift from the shoulder without swinging.'],['Lower','Return slowly while keeping control.']],
      substitute: 'Dumbbell lateral raise, cable raise, band raise, or reverse fly.'
    },
    {
      key: 'biceps',
      match: /curl/i,
      motion: 'curl',
      overview: 'A biceps elbow-flexion movement. Keep the upper arm quiet and bend the elbow without using the torso to swing the weight.',
      steps: [
        'Stand or sit tall with the upper arms close to the torso.',
        'Brace the core and start with the elbows nearly straight.',
        'Curl the weight by bending the elbows while keeping the upper arms mostly still.',
        'Squeeze briefly near the top.',
        'Lower slowly until the elbows are almost straight again.'
      ],
      mistakes: ['Swinging the torso', 'Letting the elbows travel far forward', 'Dropping the weight quickly'],
      cues: ['Pin the upper arms', 'Curl, do not swing', 'Slow on the way down'],
      phases: [['Start','Arms long and torso still.'],['Curl','Bend the elbows and squeeze.'],['Return','Lower under control.']],
      substitute: 'Dumbbell curl, cable curl, barbell curl, or band curl.'
    },
    {
      key: 'triceps',
      match: /triceps|pressdown/i,
      motion: 'triceps',
      overview: 'A triceps elbow-extension movement. Keep the upper arm stable while straightening the elbow through a controlled range.',
      steps: [
        'Set the shoulders down and keep the upper arms stable.',
        'Brace the core before the first rep.',
        'Straighten the elbows until the triceps are fully contracted without forcing the joint.',
        'Pause briefly at the end of the rep.',
        'Return slowly while keeping the upper arms from drifting.'
      ],
      mistakes: ['Moving the shoulder instead of the elbow', 'Using bodyweight to force the handle down', 'Snapping into lockout'],
      cues: ['Upper arms still', 'Straighten the elbows', 'Control the return'],
      phases: [['Set up','Elbows bent and upper arms stable.'],['Extend','Straighten the elbows.'],['Return','Bend the elbows slowly.']],
      substitute: 'Cable pressdown, overhead dumbbell extension, band pressdown, or close-grip push-up.'
    },
    {
      key: 'plank',
      match: /plank/i,
      motion: 'plank',
      overview: 'An anti-extension core hold. Keep the body in one strong line while breathing normally and preventing the lower back from sagging.',
      steps: [
        'Set the elbows or hands under the shoulders.',
        'Straighten the legs and create a long line from head to heels.',
        'Brace the abs and gently squeeze the glutes.',
        'Keep the ribs down while breathing behind the brace.',
        'End the set when you can no longer hold the same body position.'
      ],
      mistakes: ['Hips sagging', 'Hips excessively high', 'Holding the breath', 'Shrugging into the shoulders'],
      cues: ['Ribs down', 'Squeeze the glutes', 'Push the floor away', 'Stay long'],
      phases: [['Set up','Shoulders stacked and legs long.'],['Brace','Tighten abs and glutes while breathing.'],['Hold','Maintain the same line until the set ends.']],
      substitute: 'Dead bug, elevated plank, or side plank.'
    },
    {
      key: 'dead-bug',
      match: /dead bug/i,
      motion: 'core',
      overview: 'A controlled core drill that teaches you to move the arms and legs while keeping the lower back and ribs stable.',
      steps: [
        'Lie on your back with the hips and knees bent to about 90 degrees and the arms pointed upward.',
        'Gently press the lower back toward the floor and brace the abs.',
        'Slowly extend the opposite arm and leg without letting the ribs flare or back arch.',
        'Return to the start and switch sides.',
        'Move only as far as you can while keeping the trunk position unchanged.'
      ],
      mistakes: ['Arching the lower back', 'Moving too fast', 'Extending farther than you can control'],
      cues: ['Back stays heavy', 'Move slowly', 'Exhale as you extend'],
      phases: [['Set up','Arms up, hips and knees bent.'],['Extend','Reach opposite arm and leg away.'],['Return','Come back to center and switch sides.']],
      substitute: 'Plank, heel tap, or bird dog.'
    },
    {
      key: 'core-flexion',
      match: /crunch|leg raise/i,
      motion: 'core',
      overview: 'A core movement that should be controlled through the trunk rather than created by swinging the legs or pulling on the neck.',
      steps: [
        'Set the pelvis and ribs in a controlled starting position.',
        'Brace the abs before moving.',
        'Move through the intended range using the abdominal muscles rather than momentum.',
        'Pause briefly at the hardest point.',
        'Return slowly without losing trunk control.'
      ],
      mistakes: ['Swinging through the rep', 'Pulling on the neck', 'Letting the lower back arch excessively'],
      cues: ['Move from the abs', 'Stay controlled', 'Exhale through the hard part'],
      phases: [['Set up','Brace the trunk before moving.'],['Contract','Shorten the abs through a controlled range.'],['Return','Lengthen slowly without losing position.']],
      substitute: 'Dead bug, plank, or cable crunch.'
    },
    {
      key: 'cardio',
      match: /walk|run|bike|cardio|interval/i,
      motion: 'cardio',
      overview: 'A conditioning movement. Start easy, build intensity gradually, and keep a pace you can control with good posture.',
      steps: [
        'Begin with an easy warm-up for several minutes.',
        'Set a pace that matches the planned effort for the session.',
        'Keep your posture relaxed and your breathing rhythmic.',
        'For intervals, increase effort only during the work segment and recover fully enough to repeat with control.',
        'Finish with an easier cooldown before stopping.'
      ],
      mistakes: ['Starting too hard', 'Skipping the warm-up', 'Using an intensity that ruins the later intervals', 'Stopping abruptly after hard work'],
      cues: ['Build gradually', 'Relax the shoulders', 'Control the breathing', 'Save enough for the final round'],
      phases: [['Warm up','Begin at an easy pace.'],['Work','Use the planned training pace.'],['Cool down','Gradually reduce intensity.']],
      substitute: 'Walking, stationary bike, elliptical, rower, or another low-impact cardio option.'
    }
  ];

  const defaultGuide = {
    key: 'general',
    motion: 'general',
    overview: 'A controlled resistance-training movement. Use a load you can move through a comfortable range while keeping your joints and trunk stable.',
    steps: [
      'Set up the equipment and your body position before the first repetition.',
      'Brace the trunk and establish a stable starting position.',
      'Move through the intended range smoothly without using momentum.',
      'Pause briefly in the strongest controlled position.',
      'Return to the start slowly and repeat with the same technique.'
    ],
    mistakes: ['Using momentum instead of muscle control', 'Changing body position as fatigue increases', 'Rushing the lowering phase'],
    cues: ['Stay controlled', 'Use a repeatable range', 'Keep the trunk stable'],
    phases: [['Set up','Create a stable starting position.'],['Move','Perform the working portion under control.'],['Return','Come back to the start slowly.']],
    substitute: 'Choose another exercise for the same muscle group that matches your available equipment.'
  };

  function equipment(name) {
    const n = safe(name).toLowerCase();
    if (n.includes('dumbbell')) return 'Dumbbell';
    if (n.includes('barbell')) return 'Barbell';
    if (n.includes('kettlebell')) return 'Kettlebell';
    if (n.includes('band')) return 'Resistance band';
    if (n.includes('cable')) return 'Cable station';
    if (n.includes('machine') || n.includes('leg press') || n.includes('pec deck')) return 'Machine';
    if (n.includes('bench')) return 'Bench';
    if (n.includes('pull-up')) return 'Pull-up bar';
    return 'Bodyweight / selected equipment';
  }

  function find(name) {
    return families.find(item => item.match.test(name)) || defaultGuide;
  }

  function guideFor(name, muscle='') {
    const base = find(name);
    return {
      name: safe(name),
      muscle: safe(muscle) || 'Primary training muscles',
      equipment: equipment(name),
      motion: base.motion,
      overview: base.overview,
      steps: [...base.steps],
      mistakes: [...base.mistakes],
      cues: [...base.cues],
      phases: base.phases.map(p => [...p]),
      substitute: base.substitute,
      safety: 'Use a load and range you can control. Stop the set if you feel sharp pain, numbness, or a loss of normal movement control.'
    };
  }

  function demo(guide) {
    const phases = guide.phases.map((phase, index) => `
      <div class="cf-demo-frame">
        <div class="cf-demo-number">${index + 1}</div>
        <div class="cf-demo-stick cf-motion-${guide.motion}" data-phase="${index}">
          <span class="cf-head"></span><span class="cf-torso"></span><span class="cf-arm left"></span><span class="cf-arm right"></span><span class="cf-leg left"></span><span class="cf-leg right"></span>
        </div>
        <b>${phase[0]}</b>
        <small>${phase[1]}</small>
      </div>`).join('');
    return `<div class="cf-demo-grid">${phases}</div>`;
  }

  return { guideFor, demo };
})();

function cfOpenExerciseGuideByName(name, muscle='') {
  const guide = CF_EXERCISE_LIBRARY.guideFor(name, muscle);
  openSheet(`
    <div class="eyebrow">EXERCISE GUIDE</div>
    <div class="cf-guide-title-row"><div><h2>${escapeHtml(guide.name)}</h2><div class="sub">${escapeHtml(guide.muscle)} · ${escapeHtml(guide.equipment)}</div></div><span class="badge">FORM</span></div>
    <div class="cf-guide-card"><b>What this movement should feel like</b><p>${escapeHtml(guide.overview)}</p></div>
    <div class="section-title">DEMONSTRATION</div>
    ${CF_EXERCISE_LIBRARY.demo(guide)}
    <div class="section-title">HOW TO DO IT</div>
    <ol class="cf-guide-list">${guide.steps.map(step => `<li>${escapeHtml(step)}</li>`).join('')}</ol>
    <div class="section-title">COACHING CUES</div>
    <div class="cf-chip-row">${guide.cues.map(cue => `<span class="cf-cue">${escapeHtml(cue)}</span>`).join('')}</div>
    <div class="section-title">COMMON MISTAKES</div>
    <ul class="cf-mistakes">${guide.mistakes.map(item => `<li>${escapeHtml(item)}</li>`).join('')}</ul>
    <div class="section-title">IF YOU NEED A SUBSTITUTE</div>
    <div class="cf-guide-card"><p>${escapeHtml(guide.substitute)}</p></div>
    <div class="cf-safety">${escapeHtml(guide.safety)}</div>
    <button class="primary" style="width:100%;margin-top:16px" onclick="closeSheet()">Back to workout</button>
  `);
}

function cfOpenExerciseGuide(index) {
  const workout = state.workout && state.workout.active;
  if (!workout || !workout.exercises || !workout.exercises[index]) return;
  const ex = workout.exercises[index];
  cfOpenExerciseGuideByName(ex.name, ex.muscle);
}

(() => {
  const originalRenderWorkout = window.renderWorkout;
  if (typeof originalRenderWorkout !== 'function') return;

  window.renderWorkout = function renderWorkoutWithGuides() {
    originalRenderWorkout();
    const workout = state.workout && state.workout.active;
    if (!workout) return;

    const body = document.querySelector('#workoutContent .workout-body');
    if (body && !body.querySelector('.cf-active-guide')) {
      const sub = body.querySelector('.exercise-title + .sub');
      const button = document.createElement('button');
      button.className = 'ghost cf-active-guide';
      button.innerHTML = 'How to perform + demo <span>›</span>';
      button.onclick = () => cfOpenExerciseGuide(workout.exerciseIndex);
      if (sub) sub.insertAdjacentElement('afterend', button);
    }

    const tabs = document.querySelector('#workoutContent .exercise-tabs');
    if (tabs) {
      tabs.innerHTML = workout.exercises.map((ex, index) => `
        <div class="cf-exercise-tab-row">
          <button class="${index === workout.exerciseIndex ? 'active' : ''}" onclick="selectExercise(${index})">${index + 1}. ${escapeHtml(ex.name)}</button>
          <button class="cf-guide-arrow" aria-label="How to perform ${escapeHtml(ex.name)}" onclick="event.stopPropagation();cfOpenExerciseGuide(${index})">›</button>
        </div>`).join('');
    }
  };
})();
