(() => {
  const previousRenderWorkout = window.renderWorkout;
  if (typeof previousRenderWorkout !== 'function') return;

  function workoutState() {
    return state && state.workout ? state.workout.active : null;
  }

  function clampIndex(index, length) {
    return Math.max(0, Math.min(length - 1, index));
  }

  window.cfMoveExercise = function cfMoveExercise(direction) {
    const workout = workoutState();
    if (!workout || !workout.exercises.length) return;
    const nextIndex = clampIndex(workout.exerciseIndex + direction, workout.exercises.length);
    if (nextIndex === workout.exerciseIndex) return;
    selectExercise(nextIndex);
  };

  window.cfOpenWorkoutNavigatorList = function cfOpenWorkoutNavigatorList() {
    const workout = workoutState();
    if (!workout) return;

    openSheet(`
      <div class="eyebrow">WORKOUT ORDER</div>
      <h2 style="margin-bottom:4px">${escapeHtml(workout.name)}</h2>
      <div class="sub">Choose an exercise, or open its form guide without changing your logged sets.</div>
      <div class="cf-workout-list">
        ${workout.exercises.map((exercise, index) => `
          <div class="cf-workout-list-row ${index === workout.exerciseIndex ? 'active' : ''}">
            <button class="cf-workout-list-select" onclick="closeSheet();selectExercise(${index})">
              <span class="cf-list-number">${index + 1}</span>
              <span class="cf-list-copy">
                <b>${escapeHtml(exercise.name)}</b>
                <small>${exercise.sets.length} sets · ${exercise.repMin}–${exercise.repMax} reps</small>
              </span>
              ${index === workout.exerciseIndex ? '<span class="cf-current-label">CURRENT</span>' : ''}
            </button>
            <button class="cf-list-guide" aria-label="Open form guide for ${escapeHtml(exercise.name)}" onclick="cfOpenExerciseGuide(${index})">›</button>
          </div>
        `).join('')}
      </div>
    `);
  };

  function renderTopProgress(workout) {
    const navigator = document.querySelector('#workoutContent .exercise-tabs');
    if (!navigator) return;

    const index = workout.exerciseIndex;
    const total = workout.exercises.length;

    navigator.className = 'cf-workout-nav';
    navigator.innerHTML = `
      <div class="cf-workout-nav-main">
        <div class="cf-nav-progress">
          <div class="cf-nav-kicker">WORKOUT PROGRESS</div>
          <div class="cf-nav-count">Exercise <strong>${index + 1}</strong><span> of ${total}</span></div>
          <div class="cf-nav-dots" aria-hidden="true">
            ${workout.exercises.map((_, dotIndex) => `<i class="${dotIndex === index ? 'active' : dotIndex < index ? 'done' : ''}"></i>`).join('')}
          </div>
        </div>
        <button class="cf-workout-list-button" onclick="cfOpenWorkoutNavigatorList()">
          <span>Workout list</span>
          <span class="cf-list-icon">☰</span>
        </button>
      </div>
    `;

    const bodyCount = [...document.querySelectorAll('#workoutContent .workout-body > .eyebrow')]
      .find((element) => element.textContent.trim().startsWith('EXERCISE'));
    if (bodyCount) bodyCount.classList.add('cf-body-count-hidden');
  }

  function renderBottomExerciseControls(workout) {
    const body = document.querySelector('#workoutContent .workout-body');
    if (!body) return;

    const oldControls = body.querySelector('.cf-exercise-switcher');
    if (oldControls) oldControls.remove();

    const index = workout.exerciseIndex;
    const total = workout.exercises.length;
    const previous = index > 0 ? workout.exercises[index - 1] : null;
    const next = index < total - 1 ? workout.exercises[index + 1] : null;
    const controls = document.createElement('div');
    controls.className = 'cf-exercise-switcher';
    controls.setAttribute('aria-label', 'Exercise navigation');
    controls.innerHTML = `
      <button class="cf-switch-button cf-switch-previous" onclick="cfMoveExercise(-1)" ${previous ? '' : 'disabled'}>
        <span class="cf-switch-direction">‹ Previous exercise</span>
        <b>${previous ? `${index}. ${escapeHtml(previous.name)}` : 'Start of workout'}</b>
      </button>
      <button class="cf-switch-button cf-switch-next" onclick="cfMoveExercise(1)" ${next ? '' : 'disabled'}>
        <span class="cf-switch-direction">Next exercise ›</span>
        <b>${next ? `${index + 2}. ${escapeHtml(next.name)}` : 'Workout complete'}</b>
      </button>
    `;
    body.appendChild(controls);
  }

  window.renderWorkout = function renderWorkoutWithCleanNavigation() {
    previousRenderWorkout();
    const workout = workoutState();
    if (!workout || !workout.exercises.length) return;
    renderTopProgress(workout);
    renderBottomExerciseControls(workout);
  };
})();
