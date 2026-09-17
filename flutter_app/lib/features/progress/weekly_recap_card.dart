import 'package:flutter/material.dart';
import '../../models/models.dart';

class WeeklyRecapCard extends StatelessWidget {
  const WeeklyRecapCard({super.key, required this.recap, this.showSchedule = false});
  final WeeklyRecap recap;
  final bool showSchedule;

  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('THIS WEEK’S RECAP', style: TextStyle(fontWeight: FontWeight.w900)),
    const SizedBox(height: 8),
    Text('${recap.completedDays} / ${recap.plannedDays} planned days completed', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
    const SizedBox(height: 6),
    Text('${recap.consistencyPercent.toStringAsFixed(0)}% consistency so far · future days are not missed days'),
    const SizedBox(height: 12),
    LinearProgressIndicator(value: recap.plannedDays == 0 ? 0 : (recap.completedDays / recap.plannedDays).clamp(0.0, 1.0), semanticsLabel: 'Planned days completed'),
    const SizedBox(height: 14),
    Wrap(spacing: 18, runSpacing: 10, children: [
      Text('${recap.workouts} workouts'), Text('${recap.recoveryDays} recovery days'), Text('+${recap.rp} RP'), Text('${recap.personalRecords} PRs'), Text('Longest streak: ${recap.longestStreak} days'),
    ]),
    if (showSchedule) ...[
      const SizedBox(height: 20),
      const Text('NEXT WEEK', style: TextStyle(fontWeight: FontWeight.w900)),
      const Text('Your regular schedule resumes; today’s substitutions stay with today.', style: TextStyle(color: Colors.white70)),
      for (final day in recap.nextWeek) ListTile(contentPadding: EdgeInsets.zero, leading: Icon(day.kind == ProgramDayKind.training ? Icons.fitness_center : Icons.self_improvement), title: Text(day.label), subtitle: Text(const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][day.weekday - 1])),
    ],
  ])));
}
