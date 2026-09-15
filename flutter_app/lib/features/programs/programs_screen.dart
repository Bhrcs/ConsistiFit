import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../services/local_state_service.dart';
import '../../services/program_generator.dart';

class ProgramsScreen extends StatelessWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Your Program'),
          actions: <Widget>[
            TextButton(onPressed: () => context.push('/onboarding'), child: const Text('Change')),
          ],
        ),
        body: FutureBuilder<ProgramPreferences>(
          future: LocalStateService().programPreferences(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final program = const ProgramGenerator().generate(snapshot.data!);
            return ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                Text('8-WEEK TRAINING BLOCK', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
                Text(program.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                Text('${program.environmentLabel} · ${program.split} · ${program.workouts.length} rotating workouts', style: const TextStyle(color: Colors.white60)),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('EQUIPMENT', style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 5),
                        Text(program.equipmentLabel),
                      ],
                    ),
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Week ${program.deloadWeeks.first} is a prescribed recovery/deload week. Planned recovery still counts toward consistency; doubling workouts after a miss is not required.'),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('WEEKLY SCHEDULE', style: TextStyle(fontWeight: FontWeight.w900)),
                for (final day in program.week)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(day.kind == ProgramDayKind.training ? Icons.fitness_center : Icons.self_improvement),
                    title: Text(day.label),
                    subtitle: Text(_weekday(day.weekday)),
                  ),
                const SizedBox(height: 20),
                const Text('WORKOUTS', style: TextStyle(fontWeight: FontWeight.w900)),
                for (final workout in program.workouts)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(workout.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${workout.estimatedMinutes} min · ${workout.exercises.length} exercises'),
                    children: <Widget>[
                      for (final exercise in workout.exercises)
                        ListTile(
                          contentPadding: const EdgeInsets.only(left: 8),
                          title: Text(exercise.name),
                          subtitle: Text(exercise.isTimed
                              ? '${exercise.sets} sets · timed / controlled · ${exercise.restSeconds}s rest'
                              : '${exercise.sets} × ${exercise.repMin}–${exercise.repMax} · ${exercise.restSeconds}s rest'),
                        ),
                    ],
                  ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => context.push('/onboarding'),
                  icon: const Icon(Icons.tune),
                  label: const Text('Rebuild plan or change equipment'),
                ),
              ],
            );
          },
        ),
      );

  String _weekday(int weekday) => const <String>['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][weekday - 1];
}
