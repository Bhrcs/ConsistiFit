import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'workout_engine.dart';

class HealthSnapshot {
  const HealthSnapshot({
    required this.steps,
    required this.activeCalories,
    required this.sleepMinutes,
    required this.savedAt,
  });

  final int steps;
  final double activeCalories;
  final int sleepMinutes;
  final DateTime? savedAt;
}

class LocalStateService {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  static const WorkoutEngine _engine = WorkoutEngine();

  static const Map<String, RewardResult> missionRewards = <String, RewardResult>{
    'steps': RewardResult(rp: 10, xp: 40, coins: 0),
    'mobility': RewardResult(rp: 10, xp: 30, coins: 0),
    'checkin': RewardResult(rp: 5, xp: 20, coins: 0),
    'recovery': RewardResult(rp: 15, xp: 60, coins: 20),
  };

  static const List<Map<String, dynamic>> catalog = <Map<String, dynamic>>[
    <String, dynamic>{'code': 'xp_boost', 'name': 'XP Booster', 'description': 'Adds a cosmetic XP boost token to local inventory.', 'coin_price': 300},
    <String, dynamic>{'code': 'streak_shield', 'name': 'Streak Shield', 'description': 'Prototype recovery utility for a future missed-day system.', 'coin_price': 450},
    <String, dynamic>{'code': 'profile_frame', 'name': 'Lime Profile Frame', 'description': 'Unlocks a cosmetic profile frame.', 'coin_price': 250},
    <String, dynamic>{'code': 'dark_theme', 'name': 'Obsidian Theme', 'description': 'Prototype cosmetic theme unlock.', 'coin_price': 500},
  ];

  Future<ProfileSnapshot> profile() async {
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
      consistencyPercent: await _prefs.getDouble('profile_consistency') ?? demo.consistencyPercent,
    );
  }

  Future<void> _saveProfile(ProfileSnapshot profile) async {
    await _prefs.setString('profile_name', profile.displayName);
    await _prefs.setInt('profile_xp', profile.accountXp);
    await _prefs.setInt('profile_level', profile.accountLevel);
    await _prefs.setInt('profile_coins', profile.coins);
    await _prefs.setInt('profile_rp', profile.rankPoints);
    await _prefs.setString('profile_rank', profile.currentRank);
    await _prefs.setInt('profile_streak', profile.streakDays);
    await _prefs.setInt('profile_longest_streak', profile.longestStreak);
    await _prefs.setDouble('profile_consistency', profile.consistencyPercent);
  }

  Future<RewardResult> _applyReward(RewardResult reward, {bool addStreakDay = false}) async {
    final current = await profile();
    final newXp = current.accountXp + reward.xp;
    final newRp = (current.rankPoints + reward.rp).clamp(0, 999999).toInt();
    final newStreak = addStreakDay ? current.streakDays + 1 : current.streakDays;
    final updated = ProfileSnapshot(
      displayName: current.displayName,
      accountXp: newXp,
      accountLevel: _engine.accountLevel(newXp),
      coins: current.coins + reward.coins,
      rankPoints: newRp,
      currentRank: _engine.rankFromRp(newRp),
      streakDays: newStreak,
      longestStreak: newStreak > current.longestStreak ? newStreak : current.longestStreak,
      consistencyPercent: current.consistencyPercent,
    );
    await _saveProfile(updated);
    return RewardResult(rp: reward.rp, xp: reward.xp, coins: reward.coins, newRankPoints: newRp, newRank: updated.currentRank);
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<Set<String>> completedMissionCodesToday() async {
    final rows = await _prefs.getStringList('missions_${_todayKey()}') ?? const <String>[];
    return rows.toSet();
  }

  Future<RewardResult?> completeDailyMission(String code) async {
    final reward = missionRewards[code];
    if (reward == null) throw ArgumentError.value(code, 'code', 'Unknown mission');
    final completed = await completedMissionCodesToday();
    if (completed.contains(code)) return null;
    completed.add(code);
    await _prefs.setStringList('missions_${_todayKey()}', completed.toList()..sort());
    return _applyReward(reward);
  }

  Future<bool> healthConnected() async => await _prefs.getBool('health_connected') ?? false;

  Future<void> setHealthConnected(bool connected) => _prefs.setBool('health_connected', connected);

  Future<void> saveHealthSnapshot({required int steps, required double activeCalories, required int sleepMinutes}) async {
    await _prefs.setString(
      'health_${_todayKey()}',
      jsonEncode(<String, dynamic>{
        'steps': steps,
        'activeCalories': activeCalories,
        'sleepMinutes': sleepMinutes,
        'savedAt': DateTime.now().toIso8601String(),
      }),
    );
  }

  Future<HealthSnapshot> healthSnapshotToday() async {
    final raw = await _prefs.getString('health_${_todayKey()}');
    if (raw == null) {
      return const HealthSnapshot(steps: 0, activeCalories: 0, sleepMinutes: 0, savedAt: null);
    }
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return HealthSnapshot(
      steps: (data['steps'] as num?)?.toInt() ?? 0,
      activeCalories: (data['activeCalories'] as num?)?.toDouble() ?? 0,
      sleepMinutes: (data['sleepMinutes'] as num?)?.toInt() ?? 0,
      savedAt: DateTime.tryParse(data['savedAt'] as String? ?? ''),
    );
  }

  Future<RewardResult?> applyHealthProgress({
    required int steps,
    required double activeCalories,
    required int sleepMinutes,
  }) async {
    await saveHealthSnapshot(steps: steps, activeCalories: activeCalories, sleepMinutes: sleepMinutes);
    if (steps >= 8000) return completeDailyMission('steps');
    return null;
  }

  Future<int> mobilitySecondsToday() async => await _prefs.getInt('mobility_seconds_${_todayKey()}') ?? 0;

  Future<RewardResult?> addMobilitySeconds(int seconds) async {
    if (seconds <= 0) return null;
    final total = (await mobilitySecondsToday()) + seconds;
    await _prefs.setInt('mobility_seconds_${_todayKey()}', total);
    if (total >= 600) return completeDailyMission('mobility');
    return null;
  }

  Future<RewardResult> recordWorkout({
    required String workoutName,
    required List<LoggedSet> sets,
    required SessionDifficulty difficulty,
    required int durationSeconds,
  }) async {
    final completedSets = sets.where((set) => set.completed).toList(growable: false);
    await _prefs.setString('last_workout', jsonEncode(<String, dynamic>{
      'name': workoutName,
      'difficulty': difficulty.name,
      'durationSeconds': durationSeconds,
      'completedAt': DateTime.now().toIso8601String(),
      'sets': completedSets.map((set) => set.toJson()).toList(growable: false),
    }));
    final workouts = await _prefs.getInt('workout_count') ?? 0;
    await _prefs.setInt('workout_count', workouts + 1);
    return _applyReward(const RewardResult(rp: 35, xp: 240, coins: 85), addStreakDay: true);
  }

  Future<List<Map<String, dynamic>>> shopItems() async => catalog.map((item) => Map<String, dynamic>.from(item)).toList(growable: false);

  Future<int> purchaseShopItem(String code) async {
    Map<String, dynamic>? item;
    for (final row in catalog) {
      if (row['code'] == code) { item = row; break; }
    }
    if (item == null) throw ArgumentError.value(code, 'code', 'Unknown shop item');
    final price = item['coin_price'] as int;
    final current = await profile();
    if (current.coins < price) throw StateError('Not enough Coins.');
    final inventory = await _prefs.getStringList('inventory') ?? <String>[];
    inventory.add(code);
    await _prefs.setStringList('inventory', inventory);
    final updated = ProfileSnapshot(
      displayName: current.displayName,
      accountXp: current.accountXp,
      accountLevel: current.accountLevel,
      coins: current.coins - price,
      rankPoints: current.rankPoints,
      currentRank: current.currentRank,
      streakDays: current.streakDays,
      longestStreak: current.longestStreak,
      consistencyPercent: current.consistencyPercent,
    );
    await _saveProfile(updated);
    return updated.coins;
  }

  Future<void> resetDemo() async {
    for (final key in <String>[
      'profile_name', 'profile_xp', 'profile_level', 'profile_coins', 'profile_rp', 'profile_rank',
      'profile_streak', 'profile_longest_streak', 'profile_consistency', 'workout_count', 'last_workout', 'inventory',
      'health_${_todayKey()}', 'mobility_seconds_${_todayKey()}', 'missions_${_todayKey()}',
    ]) {
      await _prefs.remove(key);
    }
  }
}
