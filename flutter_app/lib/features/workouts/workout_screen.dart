import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/config/env.dart';
import '../../models/models.dart';
import '../../services/offline_workout_queue.dart';
import '../../services/program_generator.dart';
import '../../services/supabase_service.dart';
import '../../services/workout_engine.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final _backend = SupabaseService();
  final _queue = OfflineWorkoutQueue();
  final _engine = const WorkoutEngine();
  late final WorkoutTemplate workout;
  late final DateTime startedAt;
  late List<LoggedSet> sets;
  int activeExercise = 0;
  int restSeconds = 0;
  Timer? restTimer;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    startedAt = DateTime.now();
    workout = const ProgramGenerator()
        .generate(const ProgramPreferences(
          goal: TrainingGoal.muscle,
          experience: ExperienceLevel.beginner,
          equipment: EquipmentLevel.fullGym,
          daysPerWeek: 3,
          sessionMinutes: 45,
        ))
        .workouts
        .first;
    sets = <LoggedSet>[
      for (final exercise in workout.exercises)
        for (var i = 1; i <= exercise.sets; i++)
          LoggedSet(
            exerciseName: exercise.name,
            setNumber: i,
            weight: 0,
            reps: exercise.repMin ?? 0,
            completed: false,
          ),
    ];
    if (Env.hasSupabase) {
      Future<void>.microtask(() => _backend.syncPendingWorkouts(_queue));
    }
  }

  @override
  void dispose() {
    restTimer?.cancel();
    super.dispose();
  }

  ExercisePrescription get exercise => workout.exercises[activeExercise];
  List<int> get activeSetIndexes => <int>[
        for (var i = 0; i < sets.length; i++)
          if (sets[i].exerciseName == exercise.name) i,
      ];

  void _changeWeight(int index, double delta) {
    final current = sets[index];
    setState(() => sets[index] = current.copyWith(weight: (current.weight + delta).clamp(0, 2000)));
  }

  void _changeReps(int index, int delta) {
    final current = sets[index];
    setState(() => sets[index] = current.copyWith(reps: (current.reps + delta).clamp(0, 100)));
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

  void _adjustRest(int seconds) {
    setState(() => restSeconds = (restSeconds + seconds).clamp(0, 600));
    if (restSeconds == 0) restTimer?.cancel();
  }

  Future<void> _finish() async {
    final completed = sets.where((set) => set.completed).length;
    if (completed == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Log at least one set before finishing.')));
      return;
    }
    final difficulty = await showModalBottomSheet<SessionDifficulty>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text('How hard was today?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              for (final item in const <(SessionDifficulty, String, String)>[
                (SessionDifficulty.tooEasy, 'Too easy', 'Increase future difficulty slightly'),
                (SessionDifficulty.good, 'Good', 'Keep progression on track'),
                (SessionDifficulty.hard, 'Hard', 'Keep load and watch recovery'),
                (SessionDifficulty.tooHard, 'Too hard', 'Reduce accessory volume next time'),
              ])
                ListTile(
                  title: Text(item.$2),
                  subtitle: Text(item.$3),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(context, item.$1),
                ),
            ],
          ),
        ),
      ),
    );
    if (difficulty == null || !mounted) return;
    await _submit(difficulty);
  }

  Future<void> _submit(SessionDifficulty difficulty) async {
    setState(() => submitting = true);
    final duration = DateTime.now().difference(startedAt).inSeconds;
    RewardResult? reward;
    var queued = false;
    try {
      reward = await _backend.recordAndCompleteWorkout(
        workoutName: workout.name,
        sets: sets,
        difficulty: difficulty,
        startedAt: startedAt,
        durationSeconds: duration,
      );
      if (reward == null) {
        queued = true;
        await _queue.enqueue(_pendingEvent(difficulty, duration));
      }
    } catch (_) {
      queued = true;
      await _queue.enqueue(_pendingEvent(difficulty, duration));
    }
    if (!mounted) return;
    setState(() => submitting = false);
    final volume = _engine.sessionVolume(sets);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(queued ? 'Workout saved' : 'Workout complete'),
        content: Text(
          queued
              ? 'Your session is stored on this phone and will sync when the backend is available. Rank rewards stay pending until the server validates it.\n\nVolume: ${volume.toStringAsFixed(0)} lb'
              : 'Server verified: +${reward!.rp} RP · +${reward.xp} XP · +${reward.coins} Coins\n\n${reward.newRank ?? ''} · ${reward.newRankPoints ?? ''} RP\nVolume: ${volume.toStringAsFixed(0)} lb',
        ),
        actions: <Widget>[
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
        ],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  Map<String, dynamic> _pendingEvent(SessionDifficulty difficulty, int duration) => <String, dynamic>{
        'workoutName': workout.name,
        'difficulty': difficulty.name,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'durationSeconds': duration,
        'sets': sets.map((set) => set.toJson()).toList(growable: false),
      };

  @override
  Widget build(BuildContext context) {
    final setIndexes = activeSetIndexes;
    final completed = sets.where((set) => set.completed).length;
    final repLabel = exercise.isTimed ? 'Timed / controlled' : '${exercise.repMin}–${exercise.repMax} reps';
    return Scaffold(
      appBar: AppBar(title: Text(workout.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: <Widget>[
          Text('EXERCISE ${activeExercise + 1} / ${workout.exercises.length}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
          Text(exercise.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          Text('${exercise.muscleGroup} · ${exercise.sets} sets · $repLabel', style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 16),
          if (restSeconds > 0)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    Expanded(child: Text('Rest ${restSeconds ~/ 60}:${(restSeconds % 60).toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
                    IconButton(onPressed: () => _adjustRest(-15), icon: const Icon(Icons.remove)),
                    IconButton(onPressed: () => _adjustRest(15), icon: const Icon(Icons.add)),
                    TextButton(onPressed: () => _adjustRest(-restSeconds), child: const Text('Skip')),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          for (final index in setIndexes)
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: <Widget>[
                    SizedBox(width: 42, child: Text('SET ${sets[index].setNumber}', style: const TextStyle(fontWeight: FontWeight.w800))),
                    Expanded(
                      child: _Stepper(
                        label: '${sets[index].weight.toStringAsFixed(0)} lb',
                        onMinus: () => _changeWeight(index, -5),
                        onPlus: () => _changeWeight(index, 5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _Stepper(
                        label: '${sets[index].reps} reps',
                        onMinus: () => _changeReps(index, -1),
                        onPlus: () => _changeReps(index, 1),
                      ),
                    ),
                    Checkbox(value: sets[index].completed, onChanged: (_) => _toggleSet(index)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          const Text('WORKOUT ORDER', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          for (var i = 0; i < workout.exercises.length; i++)
            ListTile(
              selected: i == activeExercise,
              title: Text(workout.exercises[i].name),
              subtitle: Text('${workout.exercises[i].sets} sets'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() => activeExercise = i),
            ),
          const SizedBox(height: 12),
          Text('$completed / ${sets.length} working sets logged', style: const TextStyle(color: Colors.white60)),
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
              IconButton(onPressed: onMinus, visualDensity: VisualDensity.compact, icon: const Icon(Icons.remove, size: 17)),
              IconButton(onPressed: onPlus, visualDensity: VisualDensity.compact, icon: const Icon(Icons.add, size: 17)),
            ],
          ),
        ],
      );
}
