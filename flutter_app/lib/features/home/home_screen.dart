import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../services/local_state_service.dart';
import '../../services/program_generator.dart';
import '../../services/workout_engine.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = LocalStateService();
    return SafeArea(
      child: FutureBuilder<List<Object>>(
        future: Future.wait<Object>(<Future<Object>>[state.profile(), state.programPreferences()]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final profile = snapshot.data![0] as ProfileSnapshot;
          final preferences = snapshot.data![1] as ProgramPreferences;
          final program = const ProgramGenerator().generate(preferences);
          final today = program.week[DateTime.now().weekday - 1];
          final nextRank = const WorkoutEngine().nextRank(profile.rankPoints);
          final remaining = nextRank == null ? 0 : nextRank.minimumRp - profile.rankPoints;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Text('TODAY', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
              Text(today.label, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
              Text(
                today.kind == ProgramDayKind.training
                    ? '${today.workout!.estimatedMinutes} min · ${today.workout!.exercises.length} exercises · ${program.environmentLabel}'
                    : 'Recovery is part of ${program.name} — no catch-up workout required.',
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 14),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.route_outlined),
                  title: Text(program.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${program.split} · ${program.equipmentLabel}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/program'),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(profile.currentRank, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                      Text('${profile.rankPoints} RP${nextRank == null ? '' : ' · $remaining RP to ${nextRank.label}'}'),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: nextRank == null ? 1 : (1 - remaining / (nextRank.minimumRp == 0 ? 1 : nextRank.minimumRp)).clamp(0, 1)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(child: _Metric(label: 'STREAK', value: '${profile.streakDays} days')),
                  const SizedBox(width: 10),
                  Expanded(child: _Metric(label: 'CONSISTENCY', value: '${profile.consistencyPercent.toStringAsFixed(0)}%')),
                  const SizedBox(width: 10),
                  Expanded(child: _Metric(label: 'LEVEL', value: '${profile.accountLevel}')),
                ],
              ),
              const SizedBox(height: 24),
              const Text('THIS WEEK', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              for (final day in program.week)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(day.kind == ProgramDayKind.training ? Icons.fitness_center : Icons.self_improvement),
                  title: Text(day.label),
                  subtitle: Text(_weekday(day.weekday)),
                  trailing: day.weekday == DateTime.now().weekday ? const Chip(label: Text('Today')) : null,
                ),
            ],
          );
        },
      ),
    );
  }

  String _weekday(int weekday) => const <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: <Widget>[
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.white60)),
            ],
          ),
        ),
      );
}
