import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/local_state_service.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  final state = LocalStateService();
  Set<String> completed = <String>{};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    completed = await state.completedMissionCodesToday();
    if (mounted) setState(() => loading = false);
  }

  Future<void> _complete(String code) async {
    try {
      final RewardResult? reward = await state.completeDailyMission(code);
      if (!mounted) return;
      setState(() => completed.add(code));
      final message = reward == null
          ? 'Already logged today.'
          : '+${reward.rp} RP · +${reward.xp} XP · +${reward.coins} Coins';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final daily = <({String code, String title, String subtitle, int rp})>[
      (code: 'steps', title: '8,000 steps', subtitle: 'Log your step goal after checking Apple Health / Health Connect.', rp: 10),
      (code: 'mobility', title: 'Mobility reset', subtitle: 'Log a planned mobility session.', rp: 10),
      (code: 'checkin', title: 'Training check-in', subtitle: 'Reflect on readiness and recovery.', rp: 5),
      (code: 'recovery', title: 'Planned recovery', subtitle: 'Recovery days count toward consistency instead of forcing extra training.', rp: 15),
    ];
    final count = completed.intersection(daily.map((item) => item.code).toSet()).length;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text('MISSIONS', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
          Text(loading ? 'Loading…' : '$count of ${daily.length} logged', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Rewards are stored locally on this device for the current prototype. Extra workouts still do not farm RP.', style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 20),
          const Card(
            child: ListTile(
              leading: Icon(Icons.fitness_center),
              title: Text('Scheduled workout', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('+35 RP with the post-workout check-in'),
              trailing: Icon(Icons.lock_outline),
            ),
          ),
          for (final mission in daily)
            Card(
              child: ListTile(
                leading: Icon(completed.contains(mission.code) ? Icons.check_circle : Icons.radio_button_unchecked),
                title: Text(mission.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${mission.subtitle}\n+${mission.rp} RP'),
                isThreeLine: true,
                trailing: completed.contains(mission.code)
                    ? const Text('DONE')
                    : TextButton(onPressed: () => _complete(mission.code), child: const Text('Log')),
              ),
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
}
