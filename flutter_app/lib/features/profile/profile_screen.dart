import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../services/health_connection_service.dart';
import '../../services/local_state_service.dart';
import '../../services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final local = LocalStateService();
  final health = HealthConnectionService();

  bool healthConnected = false;
  HealthSnapshot snapshot = const HealthSnapshot(steps: 0, activeCalories: 0, sleepMinutes: 0, savedAt: null);
  bool healthBusy = false;

  @override
  void initState() {
    super.initState();
    _loadHealthState();
  }

  Future<void> _loadHealthState() async {
    final connected = await local.healthConnected();
    final latest = await local.healthSnapshotToday();
    if (!mounted) return;
    setState(() {
      healthConnected = connected;
      snapshot = latest;
    });
  }

  Future<void> _connectHealth() async {
    setState(() => healthBusy = true);
    try {
      final result = await health.connect();
      if (!mounted) return;
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Health access was not granted. You can try again anytime.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Health connected · ${result.summary.steps} steps synced.')));
      }
      await _loadHealthState();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Health connection needs a supported iPhone/Android device: $error')));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Synced ${result.summary.steps} steps · ${result.summary.activeCalories.toStringAsFixed(0)} active calories.')));
      }
      await _loadHealthState();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Health sync failed: $error')));
    } finally {
      if (mounted) setState(() => healthBusy = false);
    }
  }

  Future<void> _disconnectHealth() async {
    await health.disconnect();
    await _loadHealthState();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ConsistiFit stopped reading Health automatically. OS permission can still be changed in system settings.')));
    }
  }

  Future<void> _enableNotifications() async {
    try {
      final notifications = NotificationService();
      await notifications.initialize();
      await notifications.requestPermissions();
      await notifications.showWorkoutReady();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification permissions requested and test reminder sent.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Notification setup needs a supported mobile device: $error')));
    }
  }

  Future<void> _reset() async {
    await local.resetDemo();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Local demo data reset.')));
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: FutureBuilder<ProfileSnapshot>(
          future: local.profile(),
          builder: (context, profileSnapshot) {
            final profile = profileSnapshot.data ?? ProfileSnapshot.demo;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                Text('PROFILE', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
                Text(profile.displayName, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                Text('${profile.currentRank} · Level ${profile.accountLevel} · ${profile.streakDays} day streak', style: const TextStyle(color: Colors.white60)),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(child: _Metric(value: '${profile.accountXp}', label: 'XP')),
                    const SizedBox(width: 10),
                    Expanded(child: _Metric(value: '${profile.coins}', label: 'COINS')),
                    const SizedBox(width: 10),
                    Expanded(child: _Metric(value: '${profile.consistencyPercent.toStringAsFixed(0)}%', label: 'CONSISTENCY')),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(healthConnected ? Icons.favorite : Icons.favorite_outline, color: healthConnected ? Theme.of(context).colorScheme.primary : null),
                            const SizedBox(width: 10),
                            Expanded(child: Text(healthConnected ? 'Health connected' : 'Health not connected', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          healthConnected
                              ? '${snapshot.steps} steps today · ${snapshot.activeCalories.toStringAsFixed(0)} active calories${snapshot.savedAt == null ? '' : ' · synced ${_timeLabel(snapshot.savedAt!)}'}'
                              : 'Connect whenever you want. ConsistiFit will only auto-read Health after you opt in.',
                          style: const TextStyle(color: Colors.white60),
                        ),
                        const SizedBox(height: 14),
                        if (!healthConnected)
                          FilledButton.icon(onPressed: healthBusy ? null : _connectHealth, icon: const Icon(Icons.link), label: Text(healthBusy ? 'Connecting…' : 'Connect Health'))
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              FilledButton.icon(onPressed: healthBusy ? null : _syncHealth, icon: const Icon(Icons.sync), label: Text(healthBusy ? 'Syncing…' : 'Sync now')),
                              OutlinedButton.icon(onPressed: healthBusy ? null : _disconnectHealth, icon: const Icon(Icons.link_off), label: const Text('Disconnect')),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('This build is local-first. Workouts, rewards, missions, rank and Health summaries stay on this device until cloud sync is added later.'))),
                ListTile(title: const Text('Training program'), subtitle: const Text('Schedule, exercises and deloads'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/program')),
                ListTile(title: const Text('Friends & squads'), subtitle: const Text('Local feature preview for now'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/social')),
                ListTile(title: const Text('Rewards shop'), subtitle: const Text('Local cosmetics and utilities'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/shop')),
                ListTile(title: const Text('Rebuild program'), subtitle: const Text('Goal, equipment, days and session length'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/onboarding')),
                const Divider(height: 30),
                ListTile(leading: const Icon(Icons.notifications_none), title: const Text('Enable workout reminders'), subtitle: const Text('Request permission and send a test reminder'), trailing: const Icon(Icons.chevron_right), onTap: _enableNotifications),
                ListTile(leading: const Icon(Icons.restart_alt), title: const Text('Reset local demo data'), onTap: _reset),
              ],
            );
          },
        ),
      );

  String _timeLabel(DateTime time) {
    final localTime = time.toLocal();
    final hour = localTime.hour % 12 == 0 ? 12 : localTime.hour % 12;
    final minute = localTime.minute.toString().padLeft(2, '0');
    final suffix = localTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: <Widget>[
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
            ],
          ),
        ),
      );
}
