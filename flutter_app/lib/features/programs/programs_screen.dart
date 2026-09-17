import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../services/local_state_service.dart';
import '../../services/program_generator.dart';

class ProgramsScreen extends StatelessWidget {
  const ProgramsScreen({super.key});

  Future<void> _useToday(BuildContext context, WorkoutTemplate workout) async {
    try {
      await LocalStateService().setTodayOverride(workout);
      if (!context.mounted) return;
      await context.push('/workout');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Finish your active workout before changing today.')));
      }
    }
  }

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
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
              children: <Widget>[
                Text('8-WEEK TRAINING BLOCK', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                Text(program.name, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -1.0)),
                const SizedBox(height: 6),
                Text('${program.environmentLabel} · ${program.split} · ${program.workouts.length} rotating workouts', style: const TextStyle(color: Colors.white60)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withValues(alpha: .08)),
                    gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary.withValues(alpha: .12), const Color(0xFF101410)]),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('YOUR TRAINING SETUP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .7)),
                    const SizedBox(height: 7),
                    Text(program.equipmentLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text('Week ${program.deloadWeeks.first} is a prescribed recovery/deload week. Planned recovery still counts toward consistency.', style: const TextStyle(color: Colors.white70)),
                  ]),
                ),
                const SizedBox(height: 20),
                const Text('THIS WEEK', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .7)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 86,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: program.week.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final day = program.week[index];
                      final today = day.weekday == DateTime.now().weekday;
                      return Container(
                        width: 92,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: today ? Theme.of(context).colorScheme.primary.withValues(alpha: .10) : const Color(0xFF111511),
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(color: today ? Theme.of(context).colorScheme.primary.withValues(alpha: .35) : Colors.white.withValues(alpha: .06)),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_weekday(day.weekday).substring(0,3).toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: today ? Theme.of(context).colorScheme.primary : Colors.white54)),
                          const Spacer(),
                          Icon(day.kind == ProgramDayKind.training ? Icons.fitness_center_rounded : Icons.self_improvement_rounded, size: 18),
                          const SizedBox(height: 3),
                          Text(day.kind == ProgramDayKind.training ? 'Train' : 'Recover', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                        ]),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 22),
                Row(children: [
                  const Expanded(child: Text('WORKOUT LIBRARY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .7))),
                  Text('${program.workouts.length} routines', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ]),
                const SizedBox(height: 10),
                for (final workout in program.workouts) ...[
                  _RoutineCard(workout: workout, equipment: program.environmentLabel, onUseToday: () => _useToday(context, workout)),
                  const SizedBox(height: 12),
                ],
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

class _RoutineCard extends StatefulWidget {
  const _RoutineCard({required this.workout, required this.equipment, required this.onUseToday});
  final WorkoutTemplate workout;
  final String equipment;
  final VoidCallback onUseToday;
  @override
  State<_RoutineCard> createState() => _RoutineCardState();
}

class _RoutineCardState extends State<_RoutineCard> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) {
    final totalSets = widget.workout.exercises.fold<int>(0, (sum, exercise) => sum + exercise.sets);
    return Card(child: Padding(
      padding: const EdgeInsets.all(17),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.workout.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('${widget.workout.estimatedMinutes} min · ${widget.workout.exercises.length} exercises · $totalSets sets', style: const TextStyle(color: Colors.white60)),
          ])),
          IconButton(onPressed: () => setState(() => expanded = !expanded), tooltip: expanded ? 'Collapse routine' : 'Expand routine', icon: Icon(expanded ? Icons.expand_less : Icons.expand_more)),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 7, runSpacing: 7, children: [
          _Tag(widget.equipment),
          _Tag(widget.workout.kind.name.toUpperCase()),
        ]),
        if (expanded) ...[
          const SizedBox(height: 14),
          for (final exercise in widget.workout.exercises)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Container(width: 30, height: 30, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.primary.withValues(alpha: .09)), child: Text('${widget.workout.exercises.indexOf(exercise)+1}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900))),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(exercise.isTimed ? '${exercise.sets} timed sets · ${exercise.restSeconds}s rest' : '${exercise.sets} × ${exercise.repMin}–${exercise.repMax} · ${exercise.restSeconds}s rest', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ])),
              ]),
            ),
        ],
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => setState(() => expanded = !expanded), child: Text(expanded ? 'Hide exercises' : 'Preview'))),
          const SizedBox(width: 8),
          Expanded(child: FilledButton(onPressed: widget.onUseToday, child: const Text('Use today'))),
        ]),
      ]),
    ));
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .05), borderRadius: BorderRadius.circular(99)),
    child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.white60, fontWeight: FontWeight.w700)),
  );
}
