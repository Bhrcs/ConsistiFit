import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../services/local_state_service.dart';
import '../../services/program_generator.dart';
import '../../services/workout_engine.dart';
import '../progress/weekly_recap_card.dart';
import '../workouts/workout_override_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _local = LocalStateService();
  late Future<_TodayData> _data;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _data = _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<_TodayData> _load() async {
    final preferences = await _local.programPreferences();
    return _TodayData(
      profile: await _local.profile(),
      program: const ProgramGenerator().generate(preferences),
      workout: await _local.todayWorkout(),
      override: await _local.todayOverride(),
      completed: await _local.completedMissionCodesToday(),
      history: await _local.workoutHistory(),
      recap: await _local.weeklyRecap(),
      adaptation: await _local.adaptationSuggestion(),
    );
  }

  Future<void> _refresh() async {
    final next = _load();
    if (mounted) setState(() => _data = next);
    await next;
  }

  Future<void> _action(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      await _refresh();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save this change. Please try again.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeWorkout() async {
    if (await showWorkoutOverrideSheet(context) == true && mounted) await _refresh();
  }

  Future<void> _preview() async {
    await context.push('/workout');
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) => SafeArea(child: FutureBuilder<_TodayData>(
    future: _data,
    builder: (context, snapshot) {
      if (snapshot.hasError) return Center(child: FilledButton(onPressed: _refresh, child: const Text('Reload today')));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final data = snapshot.data!;
      final workout = data.workout;
      final done = data.completed.contains('primary');
      final scheduled = data.program.week[DateTime.now().weekday - 1];
      final nextDay = data.program.week[DateTime.now().weekday % 7];
      final nextRank = const WorkoutEngine().nextRank(data.profile.rankPoints);
      final last = data.history.where((entry) => workout != null && entry.name == workout.name).toList()
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
      final milestones = [3, 7, 14, 30, 60, 100];
      final nextMilestone = milestones.where((day) => day > data.profile.streakDays).firstOrNull;
      return RefreshIndicator(onRefresh: _refresh, child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Text('TODAY', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
          Text(workout?.name ?? 'Recovery day', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          if (workout != null)
            Text('${workout.estimatedMinutes} min · ${workout.exercises.fold<int>(0, (total, exercise) => total + exercise.sets)} sets · ${data.program.environmentLabel}', style: const TextStyle(color: Colors.white70))
          else
            const Text('Recovery is today’s plan. Giving yourself time to recover keeps the habit going.', style: TextStyle(color: Colors.white70)),
          if (data.override != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Today only · replaces ${scheduled.label}', style: TextStyle(color: Theme.of(context).colorScheme.primary))),
          const SizedBox(height: 16),
          Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(done ? Icons.check_circle : workout == null ? Icons.self_improvement : Icons.fitness_center),
              const SizedBox(width: 10),
              Expanded(child: Text(done ? 'Today’s primary mission complete' : workout == null ? 'Planned recovery · +30 RP' : 'Complete today’s workout · +${data.completed.contains('checkin') ? 30 : 35} RP', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
            ]),
            const SizedBox(height: 8),
            Text(done ? 'You showed up. Extra activity stays in your history without another primary reward.' : 'One primary mission, one reward today. An approved workout change counts toward the same day.'),
            if (!done && workout != null) const Text('Training includes the +5 RP check-in. A check-in logged earlier is not awarded again.', style: TextStyle(color: Colors.white70)),
            if (workout != null) ...[
              const SizedBox(height: 12),
              Text(last.isEmpty ? 'Your first time with this workout. Start with a comfortable load.' : 'Last time: ${last.first.completedAt.month}/${last.first.completedAt.day} · ${last.first.sets.length} sets logged'),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _preview, icon: const Icon(Icons.play_arrow), label: Text(done ? 'Preview another session' : 'Preview workout'))),
            ] else ...[
              const SizedBox(height: 12),
              const Text('YOUR RECOVERY RESET', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('• Choose an easy walk if it feels good.\n• Spend a few minutes on comfortable mobility.\n• Check in with your energy and make space for rest.\n\nNo catch-up session is needed. You can also take a full rest day.'),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: FilledButton.icon(
                onPressed: done || _busy ? null : () => _action(() async { await _local.completeDailyMission('recovery'); }),
                icon: const Icon(Icons.self_improvement),
                label: Text(done ? 'Recovery logged' : 'Log planned recovery'),
              )),
            ],
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton.icon(onPressed: _busy ? null : _changeWorkout, icon: const Icon(Icons.swap_horiz), label: const Text('Change today’s workout')),
              if (data.override != null) TextButton(onPressed: _busy ? null : () => _action(_local.clearTodayOverride), child: const Text('Restore scheduled day')),
            ]),
          ]))),
          const SizedBox(height: 12),
          Text('Tomorrow: ${nextDay.label}', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 20),
          if (data.adaptation case final suggestion?) ...[
            Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('A SUGGESTION FOR TODAY', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(suggestion.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(suggestion.explanation),
              const SizedBox(height: 8),
              Text('${suggestion.workout.name} · ${suggestion.workout.exercises.fold<int>(0, (sum, e) => sum + e.sets)} sets'),
              const Text('Only applied when you choose it. Your future schedule stays the same.', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, children: [
                FilledButton(onPressed: _busy ? null : () => _action(() => _local.acceptAdaptation(suggestion.id)), child: const Text('Apply for today')),
                TextButton(onPressed: _busy ? null : () => _action(() => _local.dismissAdaptation(suggestion.id)), child: const Text('Keep my plan')),
              ]),
            ]))),
            const SizedBox(height: 16),
          ],
          Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${data.profile.streakDays} days of consistency', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
            Text(milestones.contains(data.profile.streakDays) ? 'Milestone reached — ${data.profile.streakDays} days. Keep making room for recovery.' : nextMilestone == null ? 'Keep showing up at your own pace.' : '${nextMilestone - data.profile.streakDays} more planned days to your $nextMilestone-day milestone.'),
            const SizedBox(height: 8),
            const Text('A missed day is a chance to resume, not a reason to double up.', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 14),
            Text('${data.profile.currentRank} · ${data.profile.rankPoints} RP · Level ${data.profile.accountLevel}'),
            if (nextRank != null) Text('${nextRank.minimumRp - data.profile.rankPoints} RP to ${nextRank.label}', style: const TextStyle(color: Colors.white70)),
          ]))),
          const SizedBox(height: 16),
          WeeklyRecapCard(recap: data.recap),
          const SizedBox(height: 16),
          Card(child: ListTile(leading: const Icon(Icons.route_outlined), title: Text(data.program.name), subtitle: Text('${data.program.split} · ${data.program.equipmentLabel}'), trailing: const Icon(Icons.chevron_right), onTap: () async { await context.push('/program'); if (mounted) await _refresh(); })),
          const SizedBox(height: 20),
          const Text('THIS WEEK’S SCHEDULE', style: TextStyle(fontWeight: FontWeight.w900)),
          for (final day in data.program.week) ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(day.kind == ProgramDayKind.training ? Icons.fitness_center : Icons.self_improvement),
            title: Text(day.weekday == DateTime.now().weekday && data.override != null ? workout!.name : day.label),
            subtitle: Text('${const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][day.weekday - 1]}${day.weekday == DateTime.now().weekday ? ' · Today${done ? ' · Complete' : ''}' : ''}'),
          ),
        ],
      ));
    },
  ));
}

class _TodayData {
  const _TodayData({required this.profile, required this.program, required this.workout, required this.override, required this.completed, required this.history, required this.recap, required this.adaptation});
  final ProfileSnapshot profile;
  final GeneratedProgram program;
  final WorkoutTemplate? workout;
  final WorkoutTemplate? override;
  final Set<String> completed;
  final List<WorkoutHistoryEntry> history;
  final WeeklyRecap recap;
  final PlanAdaptationSuggestion? adaptation;
}
