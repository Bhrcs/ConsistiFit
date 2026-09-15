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

  function renderCompactNavigator() {
    const workout = workoutState();
    if (!workout || !workout.exercises.length) return;

    const navigator = document.querySelector('#workoutContent .exercise-tabs');
    if (!navigator) return;

    const index = workout.exerciseIndex;
    const total = workout.exercises.length;
    const previousDisabled = index === 0;
    const nextDisabled = index === total - 1;

    navigator.className = 'cf-workout-nav';
    navigator.innerHTML = `
      <div class="cf-workout-nav-main">
        <button class="cf-nav-arrow" onclick="cfMoveExercise(-1)" ${previousDisabled ? 'disabled' : ''} aria-label="Previous exercise">‹</button>
        <div class="cf-nav-progress">
          <div class="cf-nav-kicker">WORKOUT ORDER</div>
          <div class="cf-nav-count">Exercise <strong>${index + 1}</strong><span> / ${total}</span></div>
          <div class="cf-nav-dots" aria-hidden="true">
            ${workout.exercises.map((_, dotIndex) => `<i class="${dotIndex === index ? 'active' : dotIndex < index ? 'done' : ''}"></i>`).join('')}
          </div>
        </div>
        <button class="cf-nav-arrow" onclick="cfMoveExercise(1)" ${nextDisabled ? 'disabled' : ''} aria-label="Next exercise">›</button>
      </div>
      <button class="cf-workout-list-button" onclick="cfOpenWorkoutNavigatorList()">
        <span>Workout list</span>
        <span class="cf-list-icon">☰</span>
      </button>
    `;

    const bodyCount = [...document.querySelectorAll('#workoutContent .workout-body > .eyebrow')]
      .find((element) => element.textContent.trim().startsWith('EXERCISE'));
    if (bodyCount) bodyCount.classList.add('cf-body-count-hidden');
  }

  window.renderWorkout = function renderWorkoutWithCompactNavigation() {
    previousRenderWorkout();
    renderCompactNavigator();
  };
})();
