import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/env.dart';
import '../models/models.dart';
class SupabaseService {
  static Future<void> initialize() async { if(!Env.hasSupabase)return; await Supabase.initialize(url:Env.supabaseUrl,anonKey:Env.supabaseAnonKey); }
  SupabaseClient? get client=>Env.hasSupabase?Supabase.instance.client:null;
  Future<RewardResult> completeWorkout({required String workoutLogId,required SessionDifficulty difficulty}) async {
    final c=client; if(c==null)return const RewardResult(rp:35,xp:240,coins:85);
    final data=await c.rpc('complete_workout_and_reward',params:{'p_workout_log_id':workoutLogId,'p_difficulty':difficulty.name});
    final row=(data as List).first as Map<String,dynamic>;
    return RewardResult(rp:row['rp_awarded'] as int,xp:row['xp_awarded'] as int,coins:row['coins_awarded'] as int);
  }
}
