import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/local_state_service.dart';
import '../../services/program_generator.dart';
import '../../services/workout_engine.dart';
import 'exercise_guide_sheet.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});
  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final _state = LocalStateService();
  final _engine = const WorkoutEngine();
  WorkoutTemplate? workout;
  late final DateTime startedAt;
  List<LoggedSet> sets = <LoggedSet>[];
  int activeExercise = 0;
  int restSeconds = 0;
  Timer? restTimer;
  bool submitting = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    startedAt = DateTime.now();
    _loadWorkout();
  }

  Future<void> _loadWorkout() async {
    final preferences = await _state.programPreferences();
    final program = const ProgramGenerator().generate(preferences);
    final today = program.week[DateTime.now().weekday - 1];
    final selected = today.kind == ProgramDayKind.training && today.workout != null
        ? today.workout!
        : program.workouts.first;
    final generatedSets = <LoggedSet>[
      for (final exercise in selected.exercises)
        for (var i = 1; i <= exercise.sets; i++)
          LoggedSet(
            exerciseName: exercise.name,
            setNumber: i,
            weight: 0,
            reps: exercise.repMin ?? 0,
            completed: false,
          ),
    ];
    if (!mounted) return;
    setState(() {
      workout = selected;
      sets = generatedSets;
      loading = false;
    });
  }

  @override
  void dispose() {
    restTimer?.cancel();
    super.dispose();
  }

  ExercisePrescription get exercise => workout!.exercises[activeExercise];
  List<int> get activeSetIndexes => <int>[
        for (var i = 0; i < sets.length; i++)
          if (sets[i].exerciseName == exercise.name) i,
      ];

  void _changeWeight(int index, double delta) {
    final current = sets[index];
    setState(() => sets[index] = current.copyWith(
          weight: (current.weight + delta).clamp(0, 2000).toDouble(),
        ));
  }

  void _changeReps(int index, int delta) {
    final current = sets[index];
    setState(() => sets[index] = current.copyWith(
          reps: (current.reps + delta).clamp(0, 100).toInt(),
        ));
  }

  void _toggleSet(int index) {
    final current = sets[index];
    final completed = !current.completed;
    setState(() => sets[index] = current.copyWith(completed: completed));
    if (completed && exercise.restSeconds > 0) _startRest(exercise.restSeconds);
  }

  void _startRest(int seconds) {
    restTimer?.cancel();
    setState(() => restSeconds = seconds);
    restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (restSeconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => restSeconds = 0);
      } else if (mounted) {
        setState(() => restSeconds--);
      }
    });
  }

  Future<void> _finish() async {
    final activeWorkout = workout;
    if (activeWorkout == null) return;
    if (!sets.any((set) => set.completed)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Log at least one set before finishing.')),
      );
      return;
    }
    final difficulty = await showModalBottomSheet<SessionDifficulty>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'How hard was today?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ),
            for (final item in const <(SessionDifficulty, String)>[
              (SessionDifficulty.tooEasy, 'Too easy'),
              (SessionDifficulty.good, 'Good'),
              (SessionDifficulty.hard, 'Hard'),
              (SessionDifficulty.tooHard, 'Too hard'),
            ])
              ListTile(
                title: Text(item.$2),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(context, item.$1),
              ),
          ],
        ),
      ),
    );
    if (difficulty == null || !mounted) return;
    setState(() => submitting = true);
    final duration = DateTime.now().difference(startedAt).inSeconds;
    final reward = await _state.recordWorkout(
      workoutName: activeWorkout.name,
      sets: sets,
      difficulty: difficulty,
      durationSeconds: duration,
    );
    if (!mounted) return;
    setState(() => submitting = false);
    final volume = _engine.sessionVolume(sets);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Workout saved'),
        content: Text(
          'Saved on this device: +${reward.rp} RP · +${reward.xp} XP · +${reward.coins} Coins\n\n${reward.newRank} · ${reward.newRankPoints} RP\nVolume: ${volume.toStringAsFixed(0)} lb',
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (loading || workout == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final activeWorkout = workout!;
    final setIndexes = activeSetIndexes;
    final completed = sets.where((set) => set.completed).length;
    final repLabel = exercise.isTimed
        ? 'Timed / controlled'
        : '${exercise.repMin}–${exercise.repMax} reps';

    return Scaffold(
      appBar: AppBar(title: Text(activeWorkout.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: <Widget>[
          Text(
            'EXERCISE ${activeExercise + 1} / ${activeWorkout.exercises.length}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            exercise.name,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          Text(
            '${exercise.muscleGroup} · ${exercise.sets} sets · $repLabel',
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => showExerciseGuide(context, exercise),
            icon: const Icon(Icons.play_circle_outline_rounded),
            label: const Text('How to perform + demo'),
          ),
          const SizedBox(height: 12),
          if (restSeconds > 0)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Rest ${restSeconds ~/ 60}:${(restSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          for (final index in setIndexes)
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 42,
                      child: Text(
                        'SET ${sets[index].setNumber}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Expanded(
                      child: _Stepper(
                        label: '${sets[index].weight.toStringAsFixed(0)} lb',
                        onMinus: () => _changeWeight(index, -5),
                        onPlus: () => _changeWeight(index, 5),
                      ),
                    ),
                    Expanded(
                      child: _Stepper(
                        label: '${sets[index].reps} reps',
                        onMinus: () => _changeReps(index, -1),
                        onPlus: () => _changeReps(index, 1),
                      ),
                    ),
                    Checkbox(
                      value: sets[index].completed,
                      onChanged: (_) => _toggleSet(index),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          const Text(
            'WORKOUT ORDER',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          for (var i = 0; i < activeWorkout.exercises.length; i++)
            ListTile(
              selected: i == activeExercise,
              contentPadding: EdgeInsets.zero,
              title: Text(activeWorkout.exercises[i].name),
              subtitle: Text(
                '${activeWorkout.exercises[i].sets} sets · tap row to select',
              ),
              trailing: IconButton(
                tooltip: 'How to perform',
                icon: const Icon(Icons.chevron_right),
                onPressed: () => showExerciseGuide(
                  context,
                  activeWorkout.exercises[i],
                ),
              ),
              onTap: () => setState(() => activeExercise = i),
            ),
          Text(
            '$completed / ${sets.length} working sets logged',
            style: const TextStyle(color: Colors.white60),
          ),
        ],
      ),
      bottomSheet: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: submitting ? null : _finish,
            child: Text(submitting ? 'Saving…' : 'Finish Workout'),
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.onMinus, required this.onPlus});
  final String label;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton(
                onPressed: onMinus,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.remove, size: 17),
              ),
              IconButton(
                onPressed: onPlus,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add, size: 17),
              ),
            ],
          ),
        ],
      );
}
