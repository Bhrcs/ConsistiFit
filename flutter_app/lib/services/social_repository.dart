import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/env.dart';
class SocialRepository {
  SupabaseClient? get _client=>Env.hasSupabase?Supabase.instance.client:null;
  Future<List<Map<String,dynamic>>> activityFeed() async { final c=_client;if(c==null)return const [];final data=await c.from('activity_feed').select().order('created_at',ascending:false).limit(30);return List<Map<String,dynamic>>.from(data); }
  Future<void> sendFriendRequest(String addresseeId) async { final c=_client;if(c==null)return;await c.from('friendships').insert({'addressee_id':addresseeId,'status':'pending'}); }
}
