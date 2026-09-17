import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:consistifit/models/models.dart';
import 'package:consistifit/services/local_state_service.dart';
import 'package:consistifit/services/program_generator.dart';

class MemoryStore implements LocalStateStore {
  final values = <String, Object>{};
  bool failNextWrite = false;
  @override Future<String?> getString(String key) async => values[key] as String?;
  @override Future<int?> getInt(String key) async => values[key] as int?;
  @override Future<double?> getDouble(String key) async => values[key] as double?;
  @override Future<bool?> getBool(String key) async => values[key] as bool?;
  @override Future<List<String>?> getStringList(String key) async => values[key] as List<String>?;
  @override Future<void> setString(String key, String value) async {
    if (failNextWrite) { failNextWrite = false; throw StateError('Disk unavailable'); }
    values[key] = value;
  }
  @override Future<void> setInt(String key, int value) async { values[key] = value; }
  @override Future<void> setBool(String key, bool value) async { values[key] = value; }
  @override Future<void> remove(String key) async { values.remove(key); }
}

List<LoggedSet> completeSets(WorkoutTemplate workout, {double weight = 20, bool top = false}) => [
  for (final exercise in workout.exercises)
    for (var number = 1; number <= exercise.sets; number++)
      LoggedSet(exerciseName: exercise.name, setNumber: number, weight: exercise.isTimed ? 0 : weight,
        reps: (top ? exercise.repMax : exercise.repMin) ?? 0, completed: true),
];

void main() {
  const generator = ProgramGenerator();
  late MemoryStore store;
  late DateTime now;
  late LocalStateService state;
  setUp(() {
    store = MemoryStore();
    now = DateTime(2026, 9, 14, 12); // Monday training day.
    state = LocalStateService(store: store, clock: () => now);
  });

  Future<RewardResult> finish(LocalStateService service, ActiveWorkoutSession session,
      {List<LoggedSet>? sets, SessionDifficulty difficulty = SessionDifficulty.good}) => service.recordWorkout(
    workoutName: session.template.name, sets: sets ?? completeSets(session.template),
    difficulty: difficulty, durationSeconds: 1800, sessionId: session.id);

  test('override is day-only, keeps scheduled program and survives reload', () async {
    final original = await state.todayWorkout();
    final back = generator.generateFocused(ProgramPreferences.homeDefault, 'Back');
    await state.setTodayOverride(back);
    final reloaded = LocalStateService(store: store, clock: () => now);
    expect((await reloaded.todayWorkout())!.name, 'Back Focus');
    expect(await reloaded.savedWorkouts(), isEmpty);
    expect(generator.generate(await reloaded.programPreferences()).week.first.workout!.name, original!.name);
    now = DateTime(2026, 9, 15, 12);
    expect(await reloaded.todayWorkout(), isNull);
    expect(await reloaded.todayOverride(), isNull);
  });

  test('explicit save persists template; equipment changes hide incompatible saves', () async {
    final back = generator.generateFocused(ProgramPreferences.homeDefault, 'Back');
    await state.setTodayOverride(back, saveTemplate: true);
    await state.setTodayOverride(back, saveTemplate: true);
    expect(await state.savedWorkouts(), hasLength(1));
    await state.saveProgramPreferences(const ProgramPreferences(goal: TrainingGoal.muscle,
      experience: ExperienceLevel.beginner, environment: TrainingEnvironment.custom,
      daysPerWeek: 3, sessionMinutes: 45));
    expect(await state.savedWorkouts(), isEmpty);
    expect(await state.savedWorkouts(compatibleOnly: false), hasLength(1));
    expect(await state.todayOverride(), isNull);
    expect(generator.isCompatible((await state.todayWorkout())!, await state.programPreferences()), isTrue);
  });

  test('training override awards exactly once across replay, replacements and service instances', () async {
    final before = await state.profile();
    await state.setTodayOverride(generator.generateFocused(ProgramPreferences.homeDefault, 'Back'));
    final active = await state.startWorkout();
    final secondService = LocalStateService(store: store, clock: () => now);
    final rewards = await Future.wait([finish(state, active), finish(secondService, active)]);
    expect(rewards.fold<int>(0, (sum, reward) => sum + reward.rp), 35);
    expect(await state.workoutHistory(), hasLength(1));
    expect(await state.completedMissionCodesToday(), containsAll(['primary', 'workout']));
    await state.setTodayOverride(generator.generateFocused(ProgramPreferences.homeDefault, 'Chest'));
    expect((await finish(state, await state.startWorkout())).rp, 0);
    final after = await state.profile();
    expect(after.rankPoints - before.rankPoints, 35);
    expect(after.accountXp - before.accountXp, 240);
    expect(after.coins - before.coins, 85);
    expect(after.streakDays - before.streakDays, 1);
  });

  test('recovery override preserves recovery reward and shares primary claim', () async {
    now = DateTime(2026, 9, 15, 12);
    await state.setTodayOverride(generator.generateFocused(ProgramPreferences.homeDefault, 'Core'));
    final active = await state.startWorkout();
    final reward = await finish(state, active);
    expect(reward.rp, 35);
    expect(reward.xp, 180);
    expect(reward.coins, 65);
    expect(await state.completeDailyMission('recovery'), isNull);
    expect(await state.completeDailyMission('checkin'), isNull);
    expect(await state.completedMissionCodesToday(), contains('primary'));
  });

  test('recovery completed first prevents override farming', () async {
    now = DateTime(2026, 9, 15, 12);
    expect((await state.completeDailyMission('recovery'))!.rp, 30);
    await state.setTodayOverride(generator.generateFocused(ProgramPreferences.homeDefault, 'Back'));
    expect((await finish(state, await state.startWorkout())).rp, 5);
    expect(await state.completeDailyMission('checkin'), isNull);
    expect((await finish(state, await state.startWorkout())).rp, 0);
  });

  test('training day cannot claim recovery as an extra primary reward', () async {
    await expectLater(state.completeDailyMission('recovery'), throwsStateError);
  });

  test('recovery has no accidental fallback workout', () async {
    now = DateTime(2026, 9, 15, 12);
    expect(await state.todayWorkout(), isNull);
    await expectLater(state.startWorkout(), throwsStateError);
  });

  test('active workout is immutable and remains tied to start day after midnight', () async {
    now = DateTime(2026, 9, 14, 23, 55);
    final active = await state.startWorkout();
    await expectLater(state.setTodayOverride(generator.generateFocused(ProgramPreferences.homeDefault, 'Back')), throwsStateError);
    final reloaded = LocalStateService(store: store, clock: () => now);
    expect((await reloaded.startWorkout()).id, active.id);
    now = DateTime(2026, 9, 15, 0, 5);
    expect((await finish(reloaded, active)).rp, 35);
    expect(await reloaded.completedMissionCodesToday(), isNot(contains('primary')));
    expect((await reloaded.completeDailyMission('recovery'))!.rp, 30);
    expect((await reloaded.workoutHistory()).first.dayKey, '2026-09-14');
  });

  test('partial workout records progress without claiming the primary mission', () async {
    final active = await state.startWorkout();
    expect((await finish(state, active, sets: completeSets(active.template).take(1).toList())).rp, 5);
    expect(await state.completedMissionCodesToday(), isNot(contains('primary')));
    expect(await state.completedMissionCodesToday(), contains('checkin'));
    expect((await state.workoutHistory()).first.primaryCompleted, isFalse);
    expect((await finish(state, await state.startWorkout())).rp, 30);
  });

  test('empty, foreign, zero-rep and duplicate sets cannot earn rewards', () async {
    final active = await state.startWorkout();
    final sets = completeSets(active.template);
    await expectLater(finish(state, active, sets: []), throwsStateError);
    await expectLater(finish(state, active, sets: [...sets, sets.first]), throwsArgumentError);
    await expectLater(finish(state, active, sets: [sets.first.copyWith(reps: 0)]), throwsArgumentError);
    await expectLater(finish(state, active, sets: [const LoggedSet(exerciseName: 'Invented move',
      setNumber: 1, weight: 1, reps: 1, completed: true)]), throwsArgumentError);
    expect(await state.workoutHistory(), isEmpty);
    expect(await state.completedMissionCodesToday(), isNot(contains('primary')));
  });

  test('timed catalog exercises can complete at zero reps', () async {
    await state.setTodayOverride(generator.generateFocused(ProgramPreferences.homeDefault, 'Core'));
    final active = await state.startWorkout();
    expect(active.template.exercises.any((exercise) => exercise.isTimed), isTrue);
    expect((await finish(state, active)).rp, 35);
  });

  test('failed atomic commit can retry without lost or duplicated reward', () async {
    final active = await state.startWorkout();
    final before = await state.profile();
    store.failNextWrite = true;
    await expectLater(finish(state, active), throwsStateError);
    expect((await state.profile()).rankPoints, before.rankPoints);
    expect(await state.workoutHistory(), isEmpty);
    expect((await finish(state, active)).rp, 35);
    expect((await finish(state, active)).rp, 0);
  });

  test('legacy last workout protects already paid day and profile survives migration', () async {
    store.values['profile_rp'] = 900;
    final template = generator.generate(ProgramPreferences.homeDefault).workouts.first;
    store.values['last_workout'] = jsonEncode({'name': template.name, 'difficulty': 'good',
      'durationSeconds': 1800, 'completedAt': now.toIso8601String(),
      'sets': completeSets(template).map((set) => set.toJson()).toList()});
    expect(await state.completedMissionCodesToday(), contains('primary'));
    expect((await finish(state, await state.startWorkout())).rp, 0);
    expect((await state.profile()).rankPoints, 900);
    expect(await state.workoutHistory(), hasLength(2));
  });

  test('legacy recovery claim cannot be awarded again', () async {
    now = DateTime(2026, 9, 15, 12);
    store.values['missions_2026-09-15'] = <String>['recovery', 'checkin'];
    expect(await state.completeDailyMission('recovery'), isNull);
    expect((await state.weeklyRecap()).rp, 20);
    await state.setTodayOverride(generator.generateFocused(ProgramPreferences.homeDefault, 'Back'));
    expect((await finish(state, await state.startWorkout())).rp, 0);
  });

  test('weekly recap uses actual elapsed days and separates workouts from recovery', () async {
    await finish(state, await state.startWorkout());
    now = DateTime(2026, 9, 15, 12);
    await state.completeDailyMission('recovery');
    final recap = await state.weeklyRecap();
    expect(recap.plannedDays, 2);
    expect(recap.completedDays, 2);
    expect(recap.consistencyPercent, 100);
    expect(recap.workouts, 1);
    expect(recap.recoveryDays, 1);
    expect(recap.rp, 65);
    expect(recap.longestStreak, 2);
    expect(recap.nextWeek, hasLength(7));
    now = DateTime(2026, 9, 21, 12);
    final nextWeek = await state.weeklyRecap();
    expect(nextWeek.completedDays, 0);
    expect(nextWeek.rp, 0);
  });

  test('adapting requires accept and never mutates the repeating schedule', () async {
    await finish(state, await state.startWorkout(), difficulty: SessionDifficulty.tooHard);
    now = DateTime(2026, 9, 16, 12);
    final original = await state.todayWorkout();
    final suggestion = await state.adaptationSuggestion();
    expect(suggestion, isNotNull);
    expect(suggestion!.explanation, contains('today only'));
    expect((await state.todayWorkout())!.totalSets, original!.totalSets);
    await state.acceptAdaptation(suggestion.id);
    expect((await state.todayWorkout())!.totalSets, lessThan(original.totalSets));
    expect(generator.generate(await state.programPreferences()).week[2].workout!.totalSets, original.totalSets);
    expect(await state.adaptationSuggestion(), isNull);
  });

  test('dismissed adaptation stays dismissed after reload', () async {
    await finish(state, await state.startWorkout(), difficulty: SessionDifficulty.hard);
    now = DateTime(2026, 9, 16, 12);
    final suggestion = (await state.adaptationSuggestion())!;
    await state.dismissAdaptation(suggestion.id);
    expect(await LocalStateService(store: store, clock: () => now).adaptationSuggestion(), isNull);
  });

  test('next-time load only rises after all sets reach top at same load', () async {
    final workout = generator.generateFocused(ProgramPreferences.homeDefault, 'Back');
    final full = completeSets(workout, weight: 20, top: true);
    expect((await state.nextTimeRecommendations(workout, full, SessionDifficulty.good)).first, contains('25 lb'));
    expect((await state.nextTimeRecommendations(workout, full.take(1).toList(), SessionDifficulty.good)).first, contains('20 lb'));
    expect((await state.nextTimeRecommendations(workout, full, SessionDifficulty.tooHard)).first, contains('20 lb'));
    expect((await state.nextTimeRecommendations(workout, full, SessionDifficulty.good)).last, contains('Tomorrow: Recovery'));
  });

  test('discard unlocks a frozen workout without completion or reward', () async {
    final active = await state.startWorkout();
    await state.discardWorkout(active.id);
    await state.setTodayOverride(generator.generateFocused(ProgramPreferences.homeDefault, 'Legs'));
    expect((await state.todayWorkout())!.name, 'Legs Focus');
    await expectLater(finish(state, active), throwsStateError);
  });

  test('check-in and workout pay the same total in either order', () async {
    final before = await state.profile();
    expect((await state.completeDailyMission('checkin'))!.rp, 5);
    final reward = await finish(state, await state.startWorkout());
    expect(reward.rp, 30);
    expect(reward.xp, 220);
    expect(await state.completeDailyMission('checkin'), isNull);
    final after = await state.profile();
    expect(after.rankPoints - before.rankPoints, 35);
    expect(after.accountXp - before.accountXp, 240);
  });

  test('reset clears saved templates, claims, history and active sessions', () async {
    await state.setTodayOverride(generator.generateFocused(ProgramPreferences.homeDefault, 'Legs'), saveTemplate: true);
    await finish(state, await state.startWorkout());
    await state.resetDemo();
    expect(await state.savedWorkouts(), isEmpty);
    expect(await state.workoutHistory(), isEmpty);
    expect(await state.completedMissionCodesToday(), isEmpty);
    expect((await state.profile()).rankPoints, ProfileSnapshot.demo.rankPoints);
  });
}
