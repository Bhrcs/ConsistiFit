import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'program_generator.dart';
import 'workout_engine.dart';

/// Injectable local storage keeps clock, migration and replay tests offline.
abstract class LocalStateStore {
  Future<String?> getString(String key);
  Future<int?> getInt(String key);
  Future<double?> getDouble(String key);
  Future<bool?> getBool(String key);
  Future<List<String>?> getStringList(String key);
  Future<void> setString(String key, String value);
  Future<void> setInt(String key, int value);
  Future<void> setBool(String key, bool value);
  Future<void> remove(String key);
}

class _PreferencesStore implements LocalStateStore {
  final _prefs = SharedPreferencesAsync();
  @override Future<String?> getString(String key) => _prefs.getString(key);
  @override Future<int?> getInt(String key) => _prefs.getInt(key);
  @override Future<double?> getDouble(String key) => _prefs.getDouble(key);
  @override Future<bool?> getBool(String key) => _prefs.getBool(key);
  @override Future<List<String>?> getStringList(String key) => _prefs.getStringList(key);
  @override Future<void> setString(String key, String value) => _prefs.setString(key, value);
  @override Future<void> setInt(String key, int value) => _prefs.setInt(key, value);
  @override Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);
  @override Future<void> remove(String key) => _prefs.remove(key);
}

class HealthSnapshot {
  const HealthSnapshot({required this.steps, required this.activeCalories,
    required this.sleepMinutes, required this.savedAt});
  final int steps;
  final double activeCalories;
  final int sleepMinutes;
  final DateTime? savedAt;
}

class LocalStateService {
  LocalStateService({LocalStateStore? store, DateTime Function()? clock})
      : _prefs = store ?? _PreferencesStore(), _clock = clock ?? DateTime.now;
  final LocalStateStore _prefs;
  final DateTime Function() _clock;
  static const _engine = WorkoutEngine();
  static const _generator = ProgramGenerator();
  static const _storageKey = 'consistifit_ux_v1';
  static Future<void> _writes = Future<void>.value();
  static const _zeroReward = RewardResult(rp: 0, xp: 0, coins: 0);
  static const _trainingReward = RewardResult(rp: 30, xp: 220, coins: 85);

  // All reward-bearing writes share one queue and one JSON commit, including
  // across screen/service instances. History, claim and balance change together.
  Future<T> _serial<T>(Future<T> Function() operation) {
    final result = _writes.then((_) => operation());
    _writes = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  static const Map<String, RewardResult> missionRewards = <String, RewardResult>{
    'steps': RewardResult(rp: 10, xp: 40, coins: 0),
    'mobility': RewardResult(rp: 10, xp: 30, coins: 0),
    'checkin': RewardResult(rp: 5, xp: 20, coins: 0),
    'recovery': RewardResult(rp: 30, xp: 160, coins: 65),
  };
  static const catalog = <Map<String, dynamic>>[
    {'code': 'xp_boost', 'name': 'XP Booster', 'description': 'Adds a cosmetic XP boost token to local inventory.', 'coin_price': 300},
    {'code': 'streak_shield', 'name': 'Streak Shield', 'description': 'Prototype recovery utility for a future missed-day system.', 'coin_price': 450},
    {'code': 'profile_frame', 'name': 'Lime Profile Frame', 'description': 'Unlocks a cosmetic profile frame.', 'coin_price': 250},
    {'code': 'dark_theme', 'name': 'Obsidian Theme', 'description': 'Prototype cosmetic theme unlock.', 'coin_price': 500},
  ];

  String _key(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  String _todayKey() => _key(_clock());
  Map<String, dynamic> _map(dynamic value) => Map<String, dynamic>.from(value as Map);

  Future<Map<String, dynamic>> _load() async {
    final raw = await _prefs.getString(_storageKey);
    if (raw != null) {
      final data = _map(jsonDecode(raw));
      if (data['version'] != 1) throw StateError('This local save uses an unsupported version.');
      if (data['trackingStartedDay'] == null) {
        final known = <String>{_todayKey(), ...(data['days'] as Map).keys.cast<String>()}.toList()..sort();
        data['trackingStartedDay'] = known.first;
      }
      return data;
    }
    final data = <String, dynamic>{'version': 1, 'days': <String, dynamic>{},
      'history': <dynamic>[], 'saved': <dynamic>[], 'sessions': <String, dynamic>{},
      'dismissed': <String>[], 'nextId': 0, 'trackingStartedDay': _todayKey()};
    // Legacy profiles already include the last workout's reward. Import its
    // completion without awarding again; older unknown history stays unknown.
    final legacy = await _prefs.getString('last_workout');
    if (legacy != null) {
      try {
        final row = _map(jsonDecode(legacy));
        final at = DateTime.parse(row['completedAt'] as String).toLocal();
        final dayKey = _key(at);
        final entry = WorkoutHistoryEntry(id: 'legacy-$dayKey', name: row['name'] as String,
          dayKey: dayKey, completedAt: at,
          sets: (row['sets'] as List<dynamic>).map((set) => LoggedSet.fromJson(_map(set))).toList(),
          difficulty: SessionDifficulty.values.byName(row['difficulty'] as String),
          durationSeconds: (row['durationSeconds'] as num).toInt(), rp: 35, primaryCompleted: true);
        (data['history'] as List).add(entry.toJson());
        (data['days'] as Map)[dayKey] = <String, dynamic>{
          'primary': true, 'codes': <String>['primary', 'workout'], 'rp': 35,
          'completionKind': 'workout', 'legacy': true,
        };
        if (dayKey.compareTo(data['trackingStartedDay'] as String) < 0) data['trackingStartedDay'] = dayKey;
      } catch (_) {
        // A malformed old optional history must not destroy the profile.
      }
    }
    // Old daily missions have no global start timestamp. Known mission dates
    // this week establish the earliest observable tracking date for the recap.
    final now = _clock();
    for (var offset = 0; offset < now.weekday; offset++) {
      final dayKey = _key(DateTime(now.year, now.month, now.day - offset));
      final missions = await _prefs.getStringList('missions_$dayKey');
      if (missions != null && missions.isNotEmpty && dayKey.compareTo(data['trackingStartedDay'] as String) < 0) {
        data['trackingStartedDay'] = dayKey;
      }
    }
    return data;
  }

  Future<void> _save(Map<String, dynamic> data) => _prefs.setString(_storageKey, jsonEncode(data));

  Future<ProgramPreferences> programPreferences() async {
    final raw = await _prefs.getString('program_preferences');
    if (raw == null) return ProgramPreferences.homeDefault;
    try { return ProgramPreferences.fromJson(_map(jsonDecode(raw))); }
    catch (_) { return ProgramPreferences.homeDefault; }
  }
  Future<void> saveProgramPreferences(ProgramPreferences preferences) =>
      _serial(() => _prefs.setString('program_preferences', jsonEncode(preferences.toJson())));

  Future<Map<String, dynamic>> _day(Map<String, dynamic> data, String key) async {
    final days = data['days'] as Map<String, dynamic>;
    final row = days[key] == null ? <String, dynamic>{} : _map(days[key]);
    if (row['plannedKind'] == null) {
      final program = _generator.generate(await programPreferences());
      final planned = program.week[DateTime.parse(key).weekday - 1];
      row['plannedKind'] = planned.kind.name;
      row['planned'] = planned.workout?.toJson();
    }
    final codes = <String>{...((row['codes'] as List?) ?? []).cast<String>()};
    var migratedRp = 0;
    for (final code in await _prefs.getStringList('missions_$key') ?? <String>[]) {
      // Old recovery saves awarded 15 RP. Keep that history truthful when
      // migrating to the current planned-recovery reward.
      if (codes.add(code)) migratedRp += code == 'recovery' ? 15 : missionRewards[code]?.rp ?? 0;
    }
    if (row['legacy'] == true && codes.contains('workout')) codes.add('checkin');
    if (codes.contains('recovery') || codes.contains('workout')) {
      row['primary'] = true;
      codes.add('primary');
      row['completionKind'] ??= codes.contains('workout') ? 'workout' : 'recovery';
    }
    row['codes'] = codes.toList();
    row['rp'] = (row['rp'] as num? ?? 0).toInt() + migratedRp;
    days[key] = row;
    return row;
  }

  Future<ProfileSnapshot> _profile(Map<String, dynamic> data) async {
    if (data['profile'] is Map) return ProfileSnapshot.fromJson(_map(data['profile']));
    final demo = ProfileSnapshot.demo;
    return ProfileSnapshot(
      displayName: await _prefs.getString('profile_name') ?? demo.displayName,
      accountXp: await _prefs.getInt('profile_xp') ?? demo.accountXp,
      accountLevel: await _prefs.getInt('profile_level') ?? demo.accountLevel,
      coins: await _prefs.getInt('profile_coins') ?? demo.coins,
      rankPoints: await _prefs.getInt('profile_rp') ?? demo.rankPoints,
      currentRank: await _prefs.getString('profile_rank') ?? demo.currentRank,
      streakDays: await _prefs.getInt('profile_streak') ?? demo.streakDays,
      longestStreak: await _prefs.getInt('profile_longest_streak') ?? demo.longestStreak,
      consistencyPercent: await _prefs.getDouble('profile_consistency') ?? demo.consistencyPercent);
  }
  Future<ProfileSnapshot> profile() async => _profile(await _load());

  Future<RewardResult> _award(Map<String, dynamic> data, Map<String, dynamic> day,
      RewardResult reward, {String? primaryDay}) async {
    final current = await _profile(data);
    var streak = current.streakDays;
    if (primaryDay != null) {
      final previous = data['lastPrimaryDay'] as String?;
      if (previous == null) {
        streak++;
        data['lastPrimaryDay'] = primaryDay;
      } else if (primaryDay.compareTo(previous) > 0) {
        final date = DateTime.parse(primaryDay);
        streak = previous == _key(DateTime(date.year, date.month, date.day - 1)) ? streak + 1 : 1;
        data['lastPrimaryDay'] = primaryDay;
      }
    }
    final xp = current.accountXp + reward.xp;
    final rp = current.rankPoints + reward.rp;
    data['profile'] = <String, dynamic>{
      'display_name': current.displayName, 'account_xp': xp, 'account_level': _engine.accountLevel(xp),
      'coins': current.coins + reward.coins, 'rank_points': rp, 'current_rank': _engine.rankFromRp(rp),
      'streak_days': streak, 'longest_streak': streak > current.longestStreak ? streak : current.longestStreak,
      'consistency_percent': current.consistencyPercent,
    };
    day['rp'] = (day['rp'] as num).toInt() + reward.rp;
    return RewardResult(rp: reward.rp, xp: reward.xp, coins: reward.coins,
      newRankPoints: rp, newRank: _engine.rankFromRp(rp));
  }

  Future<Set<String>> completedMissionCodesToday() async {
    final data = await _load();
    return ((await _day(data, _todayKey()))['codes'] as List).cast<String>().toSet();
  }
  Future<RewardResult?> completeDailyMission(String code) => _serial(() async {
    if (!missionRewards.containsKey(code)) throw ArgumentError.value(code, 'code', 'Unknown mission');
    final data = await _load();
    final key = _todayKey();
    final day = await _day(data, key);
    final codes = (day['codes'] as List).cast<String>().toSet();
    final recoveryMobility = code == 'mobility' && day['plannedKind'] == ProgramDayKind.recovery.name;
    final mission = recoveryMobility ? 'recovery' : code;
    if (code == 'mobility' && (await mobilitySecondsToday()) < 600) return null;
    if (codes.contains(mission) || (mission == 'recovery' && day['primary'] == true)) {
      if (recoveryMobility && codes.add('mobility')) {
        day['codes'] = codes.toList();
        await _save(data);
      }
      return null;
    }
    if (mission == 'recovery' && day['plannedKind'] != ProgramDayKind.recovery.name) {
      throw StateError('Recovery credit is available on a planned recovery day.');
    }
    codes.add(mission);
    if (recoveryMobility) codes.add('mobility');
    if (mission == 'recovery') {
      day['primary'] = true;
      day['completionKind'] = 'recovery';
      codes.add('primary');
    }
    day['codes'] = codes.toList();
    final result = await _award(data, day, missionRewards[mission]!, primaryDay: mission == 'recovery' ? key : null);
    await _save(data);
    return result;
  });

  WorkoutTemplate? _template(dynamic row) => row is Map ? WorkoutTemplate.fromJson(_map(row)) : null;
  Future<WorkoutTemplate?> _effective(Map<String, dynamic> day) async {
    final override = _template(day['override']);
    final preferences = await programPreferences();
    if (override != null && _generator.isCompatible(override, preferences)) return override;
    final planned = _template(day['planned']);
    // An equipment change must not expose a stale unsafe replacement.
    if (planned != null && _generator.isCompatible(planned, preferences)) return planned;
    final current = _generator.generate(preferences).week[_clock().weekday - 1];
    return day['plannedKind'] == 'training' ? current.workout : null;
  }
  Future<WorkoutTemplate?> todayWorkout() => _serial(() async {
    final data = await _load();
    final day = await _day(data, _todayKey());
    final active = (data['sessions'] as Map)[day['activeId']];
    final result = active is Map ? ActiveWorkoutSession.fromJson(_map(active)).template : await _effective(day);
    await _save(data);
    return result;
  });
  Future<ProgramDayKind> todayPlannedKind() => _serial(() async {
    final data = await _load();
    final day = await _day(data, _todayKey());
    await _save(data);
    return ProgramDayKind.values.byName(day['plannedKind'] as String);
  });
  Future<WorkoutTemplate?> todayOverride() async {
    final day = await _day(await _load(), _todayKey());
    final template = _template(day['override']);
    return template != null && _generator.isCompatible(template, await programPreferences()) ? template : null;
  }
  Future<void> setTodayOverride(WorkoutTemplate template, {bool saveTemplate = false}) => _serial(() async {
    if (!_generator.isCompatible(template, await programPreferences())) {
      throw StateError('This workout includes an unknown exercise or unavailable equipment.');
    }
    final data = await _load();
    final day = await _day(data, _todayKey());
    if (day['activeId'] != null) throw StateError('Finish or discard the active workout before changing today.');
    day['override'] = template.toJson();
    if (saveTemplate) {
      final saved = data['saved'] as List;
      final serialized = jsonEncode(template.toJson());
      if (!saved.any((row) => jsonEncode(row) == serialized)) saved.add(template.toJson());
    }
    await _save(data);
  });
  Future<void> clearTodayOverride() => _serial(() async {
    final data = await _load();
    final day = await _day(data, _todayKey());
    if (day['activeId'] != null) throw StateError('Finish or discard the active workout before restoring today.');
    day.remove('override');
    await _save(data);
  });
  Future<List<WorkoutTemplate>> savedWorkouts({bool compatibleOnly = true}) async {
    final data = await _load();
    final preferences = await programPreferences();
    return (data['saved'] as List).map((row) => WorkoutTemplate.fromJson(_map(row)))
      .where((workout) => !compatibleOnly || _generator.isCompatible(workout, preferences)).toList();
  }

  Future<ActiveWorkoutSession> _start(Map<String, dynamic> data) async {
    final key = _todayKey();
    final day = await _day(data, key);
    final sessions = data['sessions'] as Map<String, dynamic>;
    if (day['activeId'] != null && sessions[day['activeId']] != null) {
      return ActiveWorkoutSession.fromJson(_map(sessions[day['activeId']]));
    }
    final workout = await _effective(day);
    if (workout == null) throw StateError('Today is a recovery day. Choose a day-only workout first to train.');
    if (!_generator.isCompatible(workout, await programPreferences())) throw StateError('Update your workout to match your equipment.');
    final sequence = (data['nextId'] as num).toInt() + 1;
    data['nextId'] = sequence;
    final session = ActiveWorkoutSession(id: '$key-$sequence', dayKey: key,
      template: WorkoutTemplate.fromJson(workout.toJson()), startedAt: _clock(),
      plannedKind: ProgramDayKind.values.byName(day['plannedKind'] as String));
    sessions[session.id] = session.toJson();
    day['activeId'] = session.id;
    return session;
  }
  Future<ActiveWorkoutSession> startWorkout() => _serial(() async {
    final data = await _load();
    final session = await _start(data);
    await _save(data);
    return session;
  });
  Future<void> discardWorkout(String sessionId) => _serial(() async {
    final data = await _load();
    final row = (data['sessions'] as Map).remove(sessionId);
    if (row is Map) {
      final day = await _day(data, row['dayKey'] as String);
      if (day['activeId'] == sessionId) day.remove('activeId');
    }
    await _save(data);
  });

  Future<List<WorkoutHistoryEntry>> workoutHistory() async =>
    ((await _load())['history'] as List).map((row) => WorkoutHistoryEntry.fromJson(_map(row))).toList();

  Future<RewardResult> recordWorkout({required String workoutName,
    required List<LoggedSet> sets, required SessionDifficulty difficulty,
    required int durationSeconds, String? sessionId}) => _serial(() async {
    final data = await _load();
    final history = (data['history'] as List).map((row) => WorkoutHistoryEntry.fromJson(_map(row))).toList();
    if (sessionId != null && history.any((entry) => entry.id == sessionId)) return _zeroReward;
    final sessionRow = sessionId == null ? null : (data['sessions'] as Map)[sessionId];
    if (sessionId != null && sessionRow == null) throw StateError('This workout session is no longer active.');
    final session = sessionRow == null ? await _start(data) : ActiveWorkoutSession.fromJson(_map(sessionRow));
    if (workoutName != session.template.name || durationSeconds < 0) throw ArgumentError('Workout does not match the active session.');
    final expected = <String, ExercisePrescription>{for (final exercise in session.template.exercises) exercise.name: exercise};
    final keys = <String>{};
    final completed = <LoggedSet>[];
    for (final set in sets) {
      final exercise = expected[set.exerciseName];
      if (exercise == null || set.setNumber < 1 || set.setNumber > exercise.sets ||
          !keys.add('${set.exerciseName}:${set.setNumber}') || !set.weight.isFinite || set.weight < 0 || set.reps < 0 ||
          set.reps > (exercise.isTimed ? 86400 : 1000) || (set.completed && set.reps == 0)) {
        throw ArgumentError('Invalid or duplicate set in this workout.');
      }
      if (set.completed) completed.add(set);
    }
    if (completed.isEmpty) throw StateError('Complete at least one set before saving.');
    final day = await _day(data, session.dayKey);
    final qualifies = completed.length >= session.template.requiredCompletedSets;
    final earnsPrimary = qualifies && day['primary'] != true;
    final codes = <String>{...(day['codes'] as List).cast<String>()};
    var base = _zeroReward;
    if (earnsPrimary) {
      day['primary'] = true;
      day['completionKind'] = 'workout';
      codes.addAll(<String>['primary', 'workout']);
      base = session.plannedKind == ProgramDayKind.recovery ? missionRewards['recovery']! : _trainingReward;
    }
    // The explicit difficulty response is a daily check-in, including after a
    // partial session. It never grants the primary workout mission by itself.
    final checkin = codes.add('checkin') ? missionRewards['checkin']! : _zeroReward;
    day['codes'] = codes.toList();
    final reward = await _award(data, day, RewardResult(rp: base.rp + checkin.rp,
      xp: base.xp + checkin.xp, coins: base.coins), primaryDay: earnsPrimary ? session.dayKey : null);
    var records = 0;
    for (final exercise in session.template.exercises.where((exercise) => !exercise.isTimed)) {
      final before = history.expand((entry) => entry.sets).where((set) => set.exerciseName == exercise.name);
      final current = completed.where((set) => set.exerciseName == exercise.name);
      if (before.isNotEmpty && current.any((set) => before.every((old) =>
        set.weight > old.weight || (set.weight == old.weight && set.reps > old.reps)))) records++;
    }
    final entry = WorkoutHistoryEntry(id: session.id, name: session.template.name, dayKey: session.dayKey,
      completedAt: _clock(), sets: completed, difficulty: difficulty, durationSeconds: durationSeconds,
      rp: reward.rp, primaryCompleted: earnsPrimary, personalRecords: records, template: session.template);
    (data['history'] as List).insert(0, entry.toJson());
    (data['sessions'] as Map).remove(session.id);
    if (day['activeId'] == session.id) day.remove('activeId');
    await _save(data);
    return reward;
  });

  Future<List<String>> nextTimeRecommendations(WorkoutTemplate workout, List<LoggedSet> sets,
      SessionDifficulty difficulty) async {
    final lines = <String>[];
    for (final exercise in workout.exercises) {
      final completed = sets.where((set) => set.completed && set.exerciseName == exercise.name).toList();
      if (completed.isEmpty) continue;
      if (exercise.isTimed) { lines.add('${exercise.name}: repeat a controlled hold or interval.'); continue; }
      final sameLoad = completed.every((set) => set.weight == completed.first.weight);
      final eligible = completed.length == exercise.sets && sameLoad &&
        difficulty != SessionDifficulty.hard && difficulty != SessionDifficulty.tooHard && completed.first.weight > 0;
      final load = _engine.recommendedLoad(currentLoad: completed.first.weight,
        completedReps: completed.map((set) => set.reps).toList(), repMax: exercise.repMax!,
        formControlled: eligible, increment: exercise.loadIncrement);
      final target = load > 0 ? '${load.toStringAsFixed(load % 1 == 0 ? 0 : 1)} lb × ' : '';
      lines.add('${exercise.name}: $target${exercise.repMin}–${exercise.repMax} reps${load > completed.first.weight ? ' if form stays controlled' : '; build consistent reps first'}.');
    }
    final tomorrow = DateTime(_clock().year, _clock().month, _clock().day + 1);
    final next = _generator.generate(await programPreferences()).week[tomorrow.weekday - 1];
    lines.add('Tomorrow: ${next.label}.');
    return lines;
  }

  Future<WeeklyRecap> weeklyRecap() => _serial(() async {
    final data = await _load();
    final now = _clock();
    final monday = DateTime(now.year, now.month, now.day - now.weekday + 1);
    var completed = 0, recovery = 0, rp = 0, streak = 0, longest = 0;
    var plannedDays = 0;
    final trackingStart = data['trackingStartedDay'] as String;
    final keys = <String>{};
    for (var offset = 0; offset < now.weekday; offset++) {
      final key = _key(DateTime(monday.year, monday.month, monday.day + offset));
      if (key.compareTo(trackingStart) < 0) continue;
      plannedDays++;
      keys.add(key);
      final row = await _day(data, key);
      if (row['primary'] == true) {
        completed++;
        streak++;
        if (row['completionKind'] == 'recovery') recovery++;
      } else { streak = 0; }
      if (streak > longest) longest = streak;
      rp += (row['rp'] as num).toInt();
    }
    final history = (data['history'] as List).map((row) => WorkoutHistoryEntry.fromJson(_map(row)))
      .where((entry) => keys.contains(entry.dayKey)).toList();
    await _save(data);
    return WeeklyRecap(plannedDays: plannedDays, completedDays: completed,
      workouts: history.length, recoveryDays: recovery, rp: rp,
      personalRecords: history.fold(0, (count, entry) => count + entry.personalRecords),
      longestStreak: longest, nextWeek: _generator.generate(await programPreferences()).week);
  });

  Future<PlanAdaptationSuggestion?> adaptationSuggestion() async {
    final data = await _load();
    final day = await _day(data, _todayKey());
    if (day['override'] != null || day['primary'] == true || day['activeId'] != null) return null;
    final workout = await _effective(day);
    if (workout == null) return null;
    final history = (data['history'] as List).map((row) => WorkoutHistoryEntry.fromJson(_map(row))).toList();
    if (history.isEmpty) return null;
    final last = history.first;
    if (last.difficulty != SessionDifficulty.hard && last.difficulty != SessionDifficulty.tooHard) return null;
    if (_clock().difference(last.completedAt).inDays > 7) return null;
    final id = '${_todayKey()}:${last.id}';
    if ((data['dismissed'] as List).contains(id)) return null;
    final adapted = WorkoutTemplate(name: '${workout.name} · Easier today',
      estimatedMinutes: workout.estimatedMinutes, kind: workout.kind,
      exercises: workout.exercises.map((exercise) => _engine.adaptPrescription(exercise, last.difficulty)).toList());
    return PlanAdaptationSuggestion(id: id, title: 'Make today more manageable',
      explanation: 'Your last session felt ${last.difficulty == SessionDifficulty.tooHard ? 'too hard' : 'hard'}. '
        '${last.difficulty == SessionDifficulty.tooHard ? 'One fewer set per exercise (at least one), with' : 'Try'} '
        '15 seconds more rest. This changes today only and keeps the planned daily reward. You can keep the original plan.',
      workout: adapted);
  }
  Future<void> acceptAdaptation(String id) async {
    final suggestion = await adaptationSuggestion();
    if (suggestion == null || suggestion.id != id) throw StateError('This suggestion is no longer current.');
    await setTodayOverride(suggestion.workout);
  }
  Future<void> dismissAdaptation(String id) => _serial(() async {
    final data = await _load();
    final dismissed = data['dismissed'] as List;
    if (!dismissed.contains(id)) dismissed.add(id);
    await _save(data);
  });

  Future<bool> healthConnected() async => await _prefs.getBool('health_connected') ?? false;
  Future<void> setHealthConnected(bool connected) => _prefs.setBool('health_connected', connected);
  Future<void> saveHealthSnapshot({required int steps, required double activeCalories, required int sleepMinutes}) =>
    _prefs.setString('health_${_todayKey()}', jsonEncode(<String, dynamic>{
      'steps': steps, 'activeCalories': activeCalories, 'sleepMinutes': sleepMinutes,
      'savedAt': _clock().toIso8601String()}));
  Future<HealthSnapshot> healthSnapshotToday() async {
    final raw = await _prefs.getString('health_${_todayKey()}');
    if (raw == null) return const HealthSnapshot(steps: 0, activeCalories: 0, sleepMinutes: 0, savedAt: null);
    final data = _map(jsonDecode(raw));
    return HealthSnapshot(steps: (data['steps'] as num? ?? 0).toInt(),
      activeCalories: (data['activeCalories'] as num? ?? 0).toDouble(),
      sleepMinutes: (data['sleepMinutes'] as num? ?? 0).toInt(),
      savedAt: DateTime.tryParse(data['savedAt'] as String? ?? ''));
  }
  Future<RewardResult?> applyHealthProgress({required int steps, required double activeCalories, required int sleepMinutes}) async {
    await saveHealthSnapshot(steps: steps, activeCalories: activeCalories, sleepMinutes: sleepMinutes);
    return steps >= 8000 ? completeDailyMission('steps') : null;
  }
  Future<int> mobilitySecondsToday() async => await _prefs.getInt('mobility_seconds_${_todayKey()}') ?? 0;
  Future<RewardResult?> addMobilitySeconds(int seconds) async {
    if (seconds <= 0) return null;
    final total = await _serial(() async {
      final total = (await mobilitySecondsToday()) + seconds;
      await _prefs.setInt('mobility_seconds_${_todayKey()}', total);
      return total;
    });
    return total >= 600 ? completeDailyMission('mobility') : null;
  }
  Future<List<Map<String, dynamic>>> shopItems() async => catalog.map((row) => Map<String, dynamic>.from(row)).toList();
  Future<int> purchaseShopItem(String code) => _serial(() async {
    final matches = catalog.where((item) => item['code'] == code);
    if (matches.isEmpty) throw ArgumentError.value(code, 'code', 'Unknown shop item');
    final data = await _load();
    final current = await _profile(data);
    final price = matches.first['coin_price'] as int;
    if (current.coins < price) throw StateError('Not enough Coins.');
    final day = await _day(data, _todayKey());
    await _award(data, day, RewardResult(rp: 0, xp: 0, coins: -price));
    data['inventory'] ??= await _prefs.getStringList('inventory') ?? <String>[];
    (data['inventory'] as List).add(code);
    await _save(data);
    return current.coins - price;
  });
  Future<void> resetDemo() => _serial(() async {
    final data = await _load();
    final days = <String>{...(data['days'] as Map).keys.cast<String>(), _todayKey()};
    for (final key in <String>[_storageKey, 'program_preferences',
      'profile_name', 'profile_xp', 'profile_level', 'profile_coins', 'profile_rp', 'profile_rank',
      'profile_streak', 'profile_longest_streak', 'profile_consistency', 'workout_count', 'last_workout', 'inventory',
      for (final day in days) ...<String>['health_$day', 'mobility_seconds_$day', 'missions_$day'],
    ]) { await _prefs.remove(key); }
  });
}
