import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../services/health_connection_service.dart';
import '../../services/local_state_service.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> with WidgetsBindingObserver {
  final local = LocalStateService();
  final health = HealthConnectionService();
  final Stopwatch mobilityWatch = Stopwatch();

  Set<String> completed = <String>{};
  HealthSnapshot healthSnapshot = const HealthSnapshot(steps: 0, activeCalories: 0, sleepMinutes: 0, savedAt: null);
  bool healthConnected = false;
  bool healthBusy = false;
  bool loading = true;
  int mobilitySavedSeconds = 0;
  Timer? ticker;
  WorkoutTemplate? todayWorkout;
  bool plannedRecovery = false;

  int get mobilityTotalSeconds => mobilitySavedSeconds + mobilityWatch.elapsed.inSeconds;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh(syncHealth: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ticker?.cancel();
    if (mobilityWatch.elapsed.inSeconds > 0) unawaited(_commitMobility(refresh: false));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh(syncHealth: true));
  }

  Future<void> _refresh({bool syncHealth = false}) async {
    final connected = await local.healthConnected();
    if (syncHealth && connected) {
      try {
        await health.syncIfConnected();
      } catch (_) {
        // Keep missions usable even when Health is temporarily unavailable.
      }
    }
    final latestCompleted = await local.completedMissionCodesToday();
    final latestHealth = await local.healthSnapshotToday();
    final mobility = await local.mobilitySecondsToday();
    final workout = await local.todayWorkout();
    final plannedKind = await local.todayPlannedKind();
    if (!mounted) return;
    setState(() {
      healthConnected = connected;
      completed = latestCompleted;
      healthSnapshot = latestHealth;
      mobilitySavedSeconds = mobility;
      todayWorkout = workout;
      plannedRecovery = plannedKind == ProgramDayKind.recovery;
      loading = false;
    });
  }

  Future<void> _connectHealth() async {
    setState(() => healthBusy = true);
    try {
      final result = await health.connect();
      if (!mounted) return;
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Health access was not granted.')));
      } else {
        _showReward(result.stepReward, fallback: 'Health connected · ${result.summary.steps} steps synced.');
      }
      await _refresh();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Health connection failed: $error')));
    } finally {
      if (mounted) setState(() => healthBusy = false);
    }
  }

  Future<void> _syncHealth() async {
    setState(() => healthBusy = true);
    try {
      final result = await health.syncIfConnected();
      if (!mounted) return;
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connect Health first.')));
      } else {
        _showReward(result.stepReward, fallback: 'Synced ${result.summary.steps} steps.');
      }
      await _refresh();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Health sync failed: $error')));
    } finally {
      if (mounted) setState(() => healthBusy = false);
    }
  }

  void _toggleMobility() {
    if (mobilityWatch.isRunning) {
      mobilityWatch.stop();
      ticker?.cancel();
      unawaited(_commitMobility());
      return;
    }
    mobilityWatch.start();
    ticker?.cancel();
    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    setState(() {});
  }

  Future<void> _commitMobility({bool refresh = true}) async {
    final seconds = mobilityWatch.elapsed.inSeconds;
    mobilityWatch
      ..stop()
      ..reset();
    ticker?.cancel();
    if (seconds <= 0) return;
    final reward = await local.addMobilitySeconds(seconds);
    if (!mounted || !refresh) return;
    _showReward(reward, fallback: 'Mobility saved.');
    await _refresh();
  }

  Future<void> _complete(String code) async {
    try {
      final RewardResult? reward = await local.completeDailyMission(code);
      if (!mounted) return;
      _showReward(reward, fallback: 'Already logged today.');
      await _refresh();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _showReward(RewardResult? reward, {required String fallback}) {
    if (!mounted) return;
    final message = reward == null ? fallback : 'Quest complete · +${reward.rp} RP · +${reward.xp} XP · +${reward.coins} Coins';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final mobilityProgress = (mobilityTotalSeconds / 600).clamp(0.0, 1.0);
    final stepProgress = (healthSnapshot.steps / 8000).clamp(0.0, 1.0);
    final staticCodes = <String>{'checkin', 'primary'};
    final count = completed.intersection(<String>{'steps', if (!plannedRecovery) 'mobility', ...staticCodes}).length;
    final missionCount = plannedRecovery ? 3 : 4;
    final mobilityDone = completed.contains('mobility') || (plannedRecovery && completed.contains('primary'));

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text('MISSIONS', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
          Text(loading ? 'Loading…' : '$count of $missionCount logged', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Steps can sync from Apple Health / Health Connect. Mobility is measured with the in-app timer.', style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 20),
          if (todayWorkout != null) Card(
            child: ListTile(
              leading: Icon(completed.contains('primary') ? Icons.check_circle : Icons.fitness_center),
              title: Text(todayWorkout!.name, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(completed.contains('primary') ? 'Primary mission complete · today’s reward earned' : 'Today’s approved workout · complete once for the primary mission'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async { await context.push('/workout'); if (mounted) await _refresh(); },
            ),
          ),
          if (!loading && todayWorkout == null) _SimpleMission(
            done: completed.contains('primary'),
            title: 'Planned recovery',
            subtitle: 'Choose gentle mobility, an easy walk, or full rest.\n+30 RP · one primary reward today',
            onPressed: () => _complete('recovery'),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(completed.contains('steps') ? Icons.check_circle : Icons.directions_walk),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('8,000 steps', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
                      if (completed.contains('steps')) const Text('DONE'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${healthSnapshot.steps} / 8,000 steps · +10 RP', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: stepProgress),
                  const SizedBox(height: 12),
                  if (!healthConnected)
                    FilledButton.icon(onPressed: healthBusy ? null : _connectHealth, icon: const Icon(Icons.link), label: Text(healthBusy ? 'Connecting…' : 'Connect Health'))
                  else
                    OutlinedButton.icon(onPressed: healthBusy ? null : _syncHealth, icon: const Icon(Icons.sync), label: Text(healthBusy ? 'Syncing…' : 'Sync steps now')),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(mobilityDone ? Icons.check_circle : Icons.self_improvement),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('10-minute mobility reset', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
                      if (mobilityDone) const Text('DONE'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${_clock(mobilityTotalSeconds)} / 10:00 · ${plannedRecovery ? 'fulfills planned recovery · +30 RP once' : '+10 RP'}', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  const Text('Move gently through comfortable shoulder, hip, and ankle movements. Pause whenever you need; the timer keeps your saved progress.', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: mobilityProgress),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: mobilityDone ? null : _toggleMobility,
                        icon: Icon(mobilityWatch.isRunning ? Icons.pause : Icons.play_arrow),
                        label: Text(mobilityWatch.isRunning ? 'Pause & save' : 'Start mobility'),
                      ),
                      if (mobilityWatch.elapsed.inSeconds > 0)
                        OutlinedButton(onPressed: () => _commitMobility(), child: const Text('Save session')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _SimpleMission(
            done: completed.contains('checkin'),
            title: 'Training check-in',
            subtitle: 'Reflect on readiness and recovery.\n+5 RP',
            onPressed: () => _complete('checkin'),
          ),
          const SizedBox(height: 18),
          const Text('WEEKLY RULE', style: TextStyle(fontWeight: FontWeight.w900)),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('A perfect planned week earns +50 RP. Consistency below 80% can move current rank down, while permanent account XP never decreases.'),
            ),
          ),
        ],
      ),
    );
  }

  String _clock(int seconds) {
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
  }
}

class _SimpleMission extends StatelessWidget {
  const _SimpleMission({required this.done, required this.title, required this.subtitle, required this.onPressed});

  final bool done;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(subtitle),
          isThreeLine: true,
          trailing: done ? const Text('DONE') : TextButton(onPressed: onPressed, child: const Text('Log')),
        ),
      );
}
