import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/env.dart';
import '../../models/models.dart';
import '../../services/health_service.dart';
import '../../services/notification_service.dart';
import '../../services/supabase_service.dart';

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
      final summary = await health.syncToday(SupabaseService());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Health synced · ${summary.steps} steps · ${summary.activeCalories.toStringAsFixed(0)} active calories · ${summary.sleepMinutes} sleep minutes.')));
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

  Future<void> _signOut(BuildContext context) async {
    if (!Env.hasSupabase) return;
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: FutureBuilder<ProfileSnapshot?>(
          future: SupabaseService().profile(),
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
                ListTile(title: const Text('Training program'), subtitle: const Text('Schedule, exercises and deloads'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/program')),
                ListTile(title: const Text('Friends & squads'), subtitle: const Text('Friends, challenges and team goals'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/social')),
                ListTile(title: const Text('Rewards shop'), subtitle: const Text('Cosmetics and non-RP rewards'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/shop')),
                ListTile(title: const Text('Rebuild program'), subtitle: const Text('Goal, equipment, days and session length'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/onboarding')),
                const Divider(height: 30),
                ListTile(
                  leading: const Icon(Icons.favorite_outline),
                  title: const Text('Connect & sync health data'),
                  subtitle: const Text('Apple Health / Health Connect daily summary'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _connectHealth(context),
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_none),
                  title: const Text('Enable workout reminders'),
                  subtitle: const Text('Request permission and send a test reminder'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _enableNotifications(context),
                ),
                if (Env.hasSupabase)
                  ListTile(leading: const Icon(Icons.logout), title: const Text('Sign out'), onTap: () => _signOut(context)),
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
