import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/env.dart';

class SocialRepository {
  SupabaseClient? get _client => Env.hasSupabase ? Supabase.instance.client : null;

  Future<List<Map<String, dynamic>>> searchProfiles(String query) async {
    final c = _client;
    if (c == null || query.trim().length < 2) return const <Map<String, dynamic>>[];
    final data = await c.rpc('search_profiles', params: <String, dynamic>{'p_query': query.trim()});
    return List<Map<String, dynamic>>.from((data as List).map((row) => Map<String, dynamic>.from(row as Map)));
  }

  Future<List<Map<String, dynamic>>> friendships() async {
    final c = _client;
    if (c == null) return const <Map<String, dynamic>>[];
    final data = await c.from('friendships').select().order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> sendFriendRequest(String addresseeId) async {
    final c = _client;
    if (c == null) return;
    await c.from('friendships').insert(<String, dynamic>{
      'addressee_id': addresseeId,
      'status': 'pending',
    });
  }

  Future<void> updateFriendship(String friendshipId, String status) async {
    final c = _client;
    if (c == null) return;
    if (!const <String>{'accepted', 'blocked'}.contains(status)) {
      throw ArgumentError.value(status, 'status');
    }
    await c.from('friendships').update(<String, dynamic>{'status': status}).eq('id', friendshipId);
  }

  Future<void> removeFriendship(String friendshipId) async {
    final c = _client;
    if (c == null) return;
    await c.from('friendships').delete().eq('id', friendshipId);
  }

  Future<List<Map<String, dynamic>>> squads() async {
    final c = _client;
    if (c == null) return const <Map<String, dynamic>>[];
    final data = await c.from('squads').select().order('created_at', ascending: false).limit(50);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<String?> createSquad(String name, {String? description}) async {
    final c = _client;
    if (c == null) return null;
    final row = await c.from('squads').insert(<String, dynamic>{
      'name': name.trim(),
      'description': description?.trim(),
    }).select('id').single();
    final id = row['id'] as String;
    await c.from('squad_members').insert(<String, dynamic>{'squad_id': id, 'user_id': c.auth.currentUser!.id, 'role': 'owner'});
    return id;
  }

  Future<void> joinSquad(String squadId) async {
    final c = _client;
    if (c == null || c.auth.currentUser == null) return;
    await c.from('squad_members').upsert(<String, dynamic>{
      'squad_id': squadId,
      'user_id': c.auth.currentUser!.id,
      'role': 'member',
    });
  }

  Future<List<Map<String, dynamic>>> challenges() async {
    final c = _client;
    if (c == null) return const <Map<String, dynamic>>[];
    final data = await c.from('challenges').select().gte('ends_at', DateTime.now().toUtc().toIso8601String()).order('ends_at');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<String?> createChallenge({
    required String name,
    required String metric,
    required double target,
    required DateTime startsAt,
    required DateTime endsAt,
    String? squadId,
  }) async {
    final c = _client;
    if (c == null || c.auth.currentUser == null) return null;
    final row = await c.from('challenges').insert(<String, dynamic>{
      'name': name.trim(),
      'metric': metric,
      'target': target,
      'starts_at': startsAt.toUtc().toIso8601String(),
      'ends_at': endsAt.toUtc().toIso8601String(),
      'squad_id': squadId,
    }).select('id').single();
    final id = row['id'] as String;
    await c.from('challenge_members').insert(<String, dynamic>{
      'challenge_id': id,
      'user_id': c.auth.currentUser!.id,
    });
    return id;
  }

  Future<void> joinChallenge(String challengeId) async {
    final c = _client;
    if (c == null || c.auth.currentUser == null) return;
    await c.from('challenge_members').upsert(<String, dynamic>{
      'challenge_id': challengeId,
      'user_id': c.auth.currentUser!.id,
    });
  }

  Future<List<Map<String, dynamic>>> activityFeed() async {
    final c = _client;
    if (c == null) return const <Map<String, dynamic>>[];
    final data = await c.from('activity_feed').select().order('created_at', ascending: false).limit(30);
    return List<Map<String, dynamic>>.from(data);
  }
}
