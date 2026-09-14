import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../services/health_service.dart';
import '../../services/local_state_service.dart';
import '../../services/notification_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _connectHealth(BuildContext context) async {
    try {
      final health = HealthService();
      await health.configure();
      final granted = await health.requestReadAccess();
      if (!granted) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Health access was not granted.')));
        return;
      }
      final summary = await health.syncToday();
      await LocalStateService().saveHealthSnapshot(
        steps: summary.steps,
        activeCalories: summary.activeCalories,
        sleepMinutes: summary.sleepMinutes,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Health saved locally · ${summary.steps} steps · ${summary.activeCalories.toStringAsFixed(0)} active calories · ${summary.sleepMinutes} sleep minutes.')));
      }
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Health setup needs a supported iPhone/Android device: $error')));
    }
  }

  Future<void> _enableNotifications(BuildContext context) async {
    try {
      final notifications = NotificationService();
      await notifications.initialize();
      await notifications.requestPermissions();
      await notifications.showWorkoutReady();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification permissions requested and test reminder sent.')));
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Notification setup needs a supported mobile device: $error')));
    }
  }

  Future<void> _reset(BuildContext context) async {
    await LocalStateService().resetDemo();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Local demo data reset.')));
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: FutureBuilder<ProfileSnapshot>(
          future: LocalStateService().profile(),
          builder: (context, snapshot) {
            final profile = snapshot.data ?? ProfileSnapshot.demo;
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
                const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('This build is local-first. Workout history, rewards, missions, rank and health summaries stay on this device until a backend is added later.'))),
                ListTile(title: const Text('Training program'), subtitle: const Text('Schedule, exercises and deloads'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/program')),
                ListTile(title: const Text('Friends & squads'), subtitle: const Text('Local feature preview for now'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/social')),
                ListTile(title: const Text('Rewards shop'), subtitle: const Text('Local cosmetics and utilities'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/shop')),
                ListTile(title: const Text('Rebuild program'), subtitle: const Text('Goal, equipment, days and session length'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/onboarding')),
                const Divider(height: 30),
                ListTile(leading: const Icon(Icons.favorite_outline), title: const Text('Read health data'), subtitle: const Text('Apple Health / Health Connect daily summary saved locally'), trailing: const Icon(Icons.chevron_right), onTap: () => _connectHealth(context)),
                ListTile(leading: const Icon(Icons.notifications_none), title: const Text('Enable workout reminders'), subtitle: const Text('Request permission and send a test reminder'), trailing: const Icon(Icons.chevron_right), onTap: () => _enableNotifications(context)),
                ListTile(leading: const Icon(Icons.restart_alt), title: const Text('Reset local demo data'), onTap: () => _reset(context)),
              ],
            );
          },
        ),
      );
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
