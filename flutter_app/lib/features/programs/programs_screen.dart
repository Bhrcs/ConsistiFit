import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/program_generator.dart';

class ProgramsScreen extends StatelessWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final program = const ProgramGenerator().generate(const ProgramPreferences(
      goal: TrainingGoal.muscle,
      experience: ExperienceLevel.beginner,
      equipment: EquipmentLevel.fullGym,
      daysPerWeek: 3,
      sessionMinutes: 45,
    ));
    return Scaffold(
      appBar: AppBar(title: const Text('Your Program')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text('8-WEEK TRAINING BLOCK', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
          Text(program.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          Text('${program.split} · ${program.workouts.length} rotating workouts', style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Week ${program.deloadWeeks.first} is a prescribed recovery/deload week. Completing planned recovery still counts toward consistency; doubling workouts after a miss is not required.'),
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
        ],
      ),
    );
  }

  String _weekday(int weekday) => const <String>['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][weekday - 1];
}
