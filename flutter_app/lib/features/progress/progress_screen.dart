import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/local_state_service.dart';
import 'weekly_recap_card.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  Future<_ProgressData> _load() async {
    final local = LocalStateService();
    return _ProgressData(recap: await local.weeklyRecap(), history: await local.workoutHistory());
  }

  @override
  Widget build(BuildContext context) => SafeArea(child: FutureBuilder<_ProgressData>(
    future: _load(),
    builder: (context, snapshot) {
      if (snapshot.hasError) return const Center(child: Text('Your recap could not be loaded. Please reopen Progress.'));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final data = snapshot.data!;
      final recap = data.recap;
      final score = recap.plannedDays == 0 ? 0 : (recap.consistencyPercent).round();
      final groups = _coverage(data.history);
      return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 120), children: [
        Text('PROGRESS', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
        const Text('See the habit taking shape.', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -1.1)),
        const SizedBox(height: 8),
        const Text('Consistency, training balance, and personal progress live here. Nothing is scored by who lifts the most.', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: _BigMetric(kicker: 'WEEKLY CONSISTENCY', value: recap.plannedDays == 0 ? '—' : '$score%', detail: '${recap.completedDays}/${recap.plannedDays} planned days')),
          const SizedBox(width: 10),
          Expanded(child: _BigMetric(kicker: 'PERSONAL RECORDS', value: '${recap.personalRecords}', detail: 'this week')),
        ]),
        const SizedBox(height: 18),
        _TrainingBalance(groups: groups),
        const SizedBox(height: 18),
        WeeklyRecapCard(recap: recap, showSchedule: true),
        const SizedBox(height: 18),
        const Text('RECENT WORKOUTS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .7)),
        const SizedBox(height: 10),
        if (data.history.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Complete your first workout to unlock exercise history and recent training coverage.')))
        else
          Card(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(children: [
              for (final entry in data.history.take(8))
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: .10),
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(entry.primaryCompleted ? Icons.check_rounded : Icons.fitness_center_rounded),
                  ),
                  title: Text(entry.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${entry.completedAt.month}/${entry.completedAt.day} · ${(entry.durationSeconds / 60).round()} min · ${entry.sets.length} sets'),
                  trailing: entry.personalRecords > 0 ? Text('${entry.personalRecords} PR', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900)) : null,
                ),
            ]),
          )),
      ]);
    },
  ));

  Map<String, int> _coverage(List<WorkoutHistoryEntry> history) {
    final result = <String, int>{'Chest':0,'Back':0,'Legs':0,'Shoulders':0,'Arms':0,'Core':0};
    final cutoff = DateTime.now().subtract(const Duration(days: 14));
    for (final entry in history) {
      if (entry.completedAt.isBefore(cutoff)) continue;
      final template = entry.template;
      if (template == null) continue;
      for (final exercise in template.exercises) {
        final completed = entry.sets.where((set) => set.completed && set.exerciseName == exercise.name).length;
        final muscle = exercise.muscleGroup.toLowerCase();
        String? group;
        if (muscle.contains('chest')) group = 'Chest';
        else if (muscle.contains('back') || muscle.contains('lat')) group = 'Back';
        else if (muscle.contains('leg') || muscle.contains('quad') || muscle.contains('ham') || muscle.contains('glute') || muscle.contains('calf')) group = 'Legs';
        else if (muscle.contains('shoulder') || muscle.contains('delt')) group = 'Shoulders';
        else if (muscle.contains('bicep') || muscle.contains('tricep') || muscle.contains('arm')) group = 'Arms';
        else if (muscle.contains('core') || muscle.contains('ab')) group = 'Core';
        if (group != null) result[group] = (result[group] ?? 0) + completed;
      }
    }
    return result;
  }
}

class _BigMetric extends StatelessWidget {
  const _BigMetric({required this.kicker, required this.value, required this.detail});
  final String kicker;
  final String value;
  final String detail;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: .08)),
      gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary.withValues(alpha: .12), const Color(0xFF101410)]),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(kicker, style: const TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.w900, letterSpacing: .6)),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
      Text(detail, style: const TextStyle(fontSize: 11, color: Colors.white60)),
    ]),
  );
}

class _TrainingBalance extends StatelessWidget {
  const _TrainingBalance({required this.groups});
  final Map<String, int> groups;
  @override
  Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.all(18),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('Training balance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          SizedBox(height: 3),
          Text('Recent coverage · last 14 days', style: TextStyle(color: Colors.white60)),
        ])),
        Icon(Icons.accessibility_new_rounded, color: Theme.of(context).colorScheme.primary),
      ]),
      const SizedBox(height: 16),
      for (final entry in groups.entries) ...[
        Row(children: [
          SizedBox(width: 82, child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w700))),
          Expanded(child: LinearProgressIndicator(value: (entry.value / 8).clamp(0.0, 1.0), minHeight: 7, borderRadius: BorderRadius.circular(99))),
          const SizedBox(width: 10),
          SizedBox(width: 46, child: Text('${entry.value} sets', textAlign: TextAlign.end, style: const TextStyle(fontSize: 11, color: Colors.white60))),
        ]),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 2),
      const Text('This helps you see what your plan has touched recently. It does not create a separate muscle rank or affect RP.', style: TextStyle(color: Colors.white60)),
    ]),
  ));
}

class _ProgressData {
  const _ProgressData({required this.recap, required this.history});
  final WeeklyRecap recap;
  final List<WorkoutHistoryEntry> history;
}
