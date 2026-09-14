import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/env.dart';
import '../models/models.dart';
import 'offline_workout_queue.dart';
import 'workout_engine.dart';

class SupabaseService {
  static Future<void> initialize() async {
    if (!Env.hasSupabase) return;
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseKey,
    );
  }

  SupabaseClient? get client => Env.hasSupabase ? Supabase.instance.client : null;

  User? get currentUser => client?.auth.currentUser;

  Future<ProfileSnapshot?> profile() async {
    final c = client;
    final user = currentUser;
    if (c == null || user == null) return null;
    final row = await c.from('profiles').select().eq('user_id', user.id).maybeSingle();
    if (row == null) return null;
    return ProfileSnapshot.fromJson(Map<String, dynamic>.from(row));
  }

  Future<RewardResult?> recordAndCompleteWorkout({
    required String workoutName,
    required List<LoggedSet> sets,
    required SessionDifficulty difficulty,
    required DateTime startedAt,
    required int durationSeconds,
  }) async {
    final c = client;
    final user = currentUser;
    if (c == null || user == null) return null;

    final engine = const WorkoutEngine();
    final completedSets = sets.where((set) => set.completed).toList(growable: false);
    final day = startedAt.toIso8601String().substring(0, 10);
    final log = await c
        .from('workout_logs')
        .insert(<String, dynamic>{
          'user_id': user.id,
          'workout_name': workoutName,
          'scheduled_for': day,
          'status': 'in_progress',
          'started_at': startedAt.toUtc().toIso8601String(),
          'duration_seconds': durationSeconds,
          'total_volume': engine.sessionVolume(completedSets),
        })
        .select('id')
        .single();
    final logId = log['id'] as String;

    final setRows = <Map<String, dynamic>>[];
    for (final set in completedSets) {
      final exercise = await c
          .from('exercises')
          .select('id')
          .eq('name', set.exerciseName)
          .maybeSingle();
      if (exercise == null) continue;
      setRows.add(<String, dynamic>{
        'workout_log_id': logId,
        'exercise_id': exercise['id'],
        'set_no': set.setNumber,
        'weight': set.weight,
        'reps': set.reps,
        'completed': true,
      });
    }
    if (setRows.isNotEmpty) {
      await c.from('workout_sets').insert(setRows);
    }

    final data = await c.rpc(
      'complete_workout_and_reward',
      params: <String, dynamic>{
        'p_workout_log_id': logId,
        'p_difficulty': difficulty.name,
      },
    );
    final rows = data as List<dynamic>;
    if (rows.isEmpty) return const RewardResult(rp: 0, xp: 0, coins: 0);
    return RewardResult.fromJson(Map<String, dynamic>.from(rows.first as Map));
  }

  Future<RewardResult?> completeDailyMission(String code) async {
    final c = client;
    if (c == null || currentUser == null) return null;
    final data = await c.rpc('complete_daily_mission', params: <String, dynamic>{'p_code': code});
    final rows = data as List<dynamic>;
    if (rows.isEmpty) return const RewardResult(rp: 0, xp: 0, coins: 0);
    return RewardResult.fromJson(Map<String, dynamic>.from(rows.first as Map));
  }

  Future<List<String>> completedMissionCodesToday() async {
    final c = client;
    final user = currentUser;
    if (c == null || user == null) return const <String>[];
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rows = await c
        .from('mission_completions')
        .select('mission_id, missions!inner(code)')
        .eq('user_id', user.id)
        .eq('completed_on', today);
    return List<Map<String, dynamic>>.from(rows)
        .map((row) => (row['missions'] as Map)['code'] as String)
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> shopItems() async {
    final c = client;
    if (c == null) return const <Map<String, dynamic>>[];
    final rows = await c.from('shop_items').select().eq('active', true).order('coin_price');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> inventory() async {
    final c = client;
    final user = currentUser;
    if (c == null || user == null) return const <Map<String, dynamic>>[];
    final rows = await c.from('inventory').select('quantity, shop_items!inner(code,name,category)').eq('user_id', user.id);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<int?> purchaseShopItem(String itemCode) async {
    final c = client;
    if (c == null || currentUser == null) return null;
    final data = await c.rpc('purchase_shop_item', params: <String, dynamic>{'p_item_code': itemCode});
    final rows = data as List<dynamic>;
    if (rows.isEmpty) return null;
    return (rows.first as Map)['coins_remaining'] as int?;
  }

  Future<int?> applyPreviousWeekConsistency(DateTime weekStart) async {
    final c = client;
    if (c == null || currentUser == null) return null;
    final data = await c.rpc(
      'apply_weekly_consistency_adjustment',
      params: <String, dynamic>{
        'p_week_start': weekStart.toIso8601String().substring(0, 10),
      },
    );
    final rows = data as List<dynamic>;
    if (rows.isEmpty) return null;
    return (rows.first as Map)['rp_adjustment'] as int?;
  }

  Future<void> saveHealthSnapshot({
    required DateTime day,
    int? steps,
    double? activeCalories,
    double? distanceMeters,
    int? sleepMinutes,
    required String source,
  }) async {
    final c = client;
    final user = currentUser;
    if (c == null || user == null) return;
    await c.from('health_daily_snapshots').upsert(<String, dynamic>{
      'user_id': user.id,
      'day': day.toIso8601String().substring(0, 10),
      'steps': steps,
      'active_calories': activeCalories,
      'distance_meters': distanceMeters,
      'sleep_minutes': sleepMinutes,
      'source': source,
      'synced_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<int> syncPendingWorkouts(OfflineWorkoutQueue queue) async {
    if (client == null || currentUser == null) return 0;
    var synced = 0;
    while (true) {
      final pending = await queue.pending();
      if (pending.isEmpty) break;
      final event = pending.first;
      try {
        final rawSets = event['sets'] as List<dynamic>? ?? const <dynamic>[];
        final sets = rawSets
            .map((item) => LoggedSet.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(growable: false);
        await recordAndCompleteWorkout(
          workoutName: event['workoutName'] as String,
          sets: sets,
          difficulty: SessionDifficulty.values.byName(event['difficulty'] as String),
          startedAt: DateTime.parse(event['startedAt'] as String),
          durationSeconds: event['durationSeconds'] as int,
        );
        await queue.removeAt(0);
        synced++;
      } catch (_) {
        break;
      }
    }
    return synced;
  }
}
