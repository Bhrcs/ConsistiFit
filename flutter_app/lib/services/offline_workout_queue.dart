import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
class OfflineWorkoutQueue {
  static const _key='pending_workout_events_v1';
  final SharedPreferencesAsync _prefs=SharedPreferencesAsync();
  Future<List<Map<String,dynamic>>> pending() async { final rows=await _prefs.getStringList(_key)??const <String>[]; return rows.map((e)=>Map<String,dynamic>.from(jsonDecode(e) as Map)).toList(); }
  Future<void> enqueue(Map<String,dynamic> event) async { final rows=await _prefs.getStringList(_key)??<String>[]; await _prefs.setStringList(_key,[...rows,jsonEncode(event)]); }
  Future<void> removeAt(int index) async { final rows=await _prefs.getStringList(_key)??<String>[]; if(index<0||index>=rows.length)return; rows.removeAt(index); await _prefs.setStringList(_key,rows); }
  Future<void> clear() => _prefs.remove(_key);
}
