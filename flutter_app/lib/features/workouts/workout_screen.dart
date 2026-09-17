import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/models.dart';
import '../../services/local_state_service.dart';
import '../../services/program_generator.dart';
import '../../services/workout_engine.dart';
import 'exercise_guide_sheet.dart';
import 'workout_override_sheet.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key, this.localState});
  final LocalStateService? localState;
  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  late final _state = widget.localState ?? LocalStateService();
  final _engine = const WorkoutEngine();
  WorkoutTemplate? workout;
  ActiveWorkoutSession? session;
  List<WorkoutHistoryEntry> history = [];
  List<LoggedSet> sets = [];
  int activeExercise = 0;
  DateTime? restEndsAt;
  Timer? restTimer;
  bool submitting = false;
  bool loading = true;
  bool primaryDone = false;
  bool saved = false;
  bool _allowLeave = false;
  bool _leaving = false;
  String? error;
  String feedback = '';

  @override
  void initState() { super.initState(); _loadWorkout(); }

  Future<void> _loadWorkout() async {
    try {
      final selected = await _state.todayWorkout();
      final previous = await _state.workoutHistory();
      final completed = await _state.completedMissionCodesToday();
      if (!mounted) return;
      setState(() {
        workout = selected;
        history = previous..sort((a, b) => b.completedAt.compareTo(a.completedAt));
        primaryDone = completed.contains('primary');
        loading = false;
        error = null;
      });
    } catch (_) {
      if (mounted) setState(() { loading = false; error = 'Could not load today’s workout. Please try again.'; });
    }
  }

  Future<void> _changeWorkout() async {
    if (await showWorkoutOverrideSheet(context, localState: _state) == true && mounted) await _loadWorkout();
  }

  Future<void> _start() async {
    if (submitting) return;
    setState(() => submitting = true);
    try {
      final active = await _state.startWorkout();
      final generated = <LoggedSet>[
        for (final exercise in active.template.exercises)
          for (var i = 1; i <= exercise.sets; i++)
            LoggedSet(exerciseName: exercise.name, setNumber: i, weight: _lastSet(exercise.name, i)?.weight ?? 0, reps: exercise.isTimed ? 0 : _lastSet(exercise.name, i)?.reps ?? exercise.repMin ?? 0, completed: false),
      ];
      if (!mounted) return;
      setState(() { session = active; workout = active.template; sets = generated; activeExercise = 0; });
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Today’s workout changed. Review your plan and try again.')));
      await _loadWorkout();
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  LoggedSet? _lastSet(String exerciseName, int setNumber) {
    for (final entry in history) {
      for (final set in entry.sets) {
        if (set.exerciseName == exerciseName && set.setNumber == setNumber && set.completed) return set;
      }
    }
    return null;
  }

  String _historyLabel(ExercisePrescription exercise) {
    for (final entry in history) {
      final previous = entry.sets.where((set) => set.exerciseName == exercise.name && set.completed).toList();
      if (previous.isNotEmpty) {
        return exercise.isTimed
            ? 'Last time: ${previous.length} sets logged'
            : 'Last time: ${previous.first.weight.toStringAsFixed(0)} lb × ${previous.first.reps} · ${previous.length} sets';
      }
    }
    return 'First session with this exercise';
  }

  @override
  void dispose() { restTimer?.cancel(); super.dispose(); }

  ExercisePrescription get exercise => workout!.exercises[activeExercise];
  int get restSeconds => restEndsAt == null ? 0 : ((restEndsAt!.difference(DateTime.now()).inMilliseconds / 1000).ceil()).clamp(0, 3600).toInt();
  List<int> get activeSetIndexes => [for (var i = 0; i < sets.length; i++) if (sets[i].exerciseName == exercise.name) i];

  void _changeWeight(int index, double delta) {
    final current = sets[index];
    setState(() => sets[index] = current.copyWith(weight: (current.weight + delta).clamp(0, 2000).toDouble()));
  }

  void _changeReps(int index, int delta) {
    final current = sets[index];
    setState(() => sets[index] = current.copyWith(reps: (current.reps + delta).clamp(0, 100).toInt()));
  }

  void _toggleSet(int index) {
    final current = sets[index];
    final completed = !current.completed;
    if (completed && !exercise.isTimed && current.reps == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter your completed reps before checking off this set.')));
      return;
    }
    final prior = history.expand((entry) => entry.sets).where((set) => set.exerciseName == current.exerciseName && set.completed).toList();
    final record = !exercise.isTimed && prior.isNotEmpty && prior.every((set) => current.weight > set.weight || (current.weight == set.weight && current.reps > set.reps));
    final last = _lastSet(current.exerciseName, current.setNumber);
    final extraReps = last != null && current.weight == last.weight ? current.reps - last.reps : 0;
    setState(() {
      sets[index] = current.copyWith(completed: completed);
      feedback = completed ? record ? 'Set complete · new best load / reps' : extraReps > 0 ? 'Set complete · +$extraReps reps at the same weight' : 'Set complete · nice work' : 'Set marked incomplete';
    });
    if (completed) {
      HapticFeedback.selectionClick();
      if (exercise.restSeconds > 0) _startRest(exercise.restSeconds);
    }
  }

  void _startRest(int seconds) {
    restTimer?.cancel();
    setState(() => restEndsAt = DateTime.now().add(Duration(seconds: seconds)));
    restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (restSeconds == 0) {
        timer.cancel();
        setState(() { restEndsAt = null; feedback = 'Rest complete. Begin when you feel ready.'; });
      } else {
        setState(() {});
      }
    });
  }

  Future<void> _confirmLeave() async {
    if (_leaving || submitting) return;
    _leaving = true;
    final leave = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Leave this workout?'),
      content: const Text('These sets have not been saved. Finish the workout to keep a partial session, or leave and discard them.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep training')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Leave workout')),
      ],
    ));
    if (leave == true && session != null) {
      try {
        await _state.discardWorkout(session!.id);
        if (!mounted) return;
        setState(() => _allowLeave = true);
        WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) Navigator.pop(context); });
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not leave the session yet. Please try again.')));
      }
    }
    _leaving = false;
  }

  Future<void> _finish() async {
    final active = session;
    final activeWorkout = workout;
    if (active == null || activeWorkout == null || submitting || saved) return;
    if (!sets.any((set) => set.completed)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Log at least one set before finishing.')));
      return;
    }
    setState(() => submitting = true);
    final difficulty = await showModalBottomSheet<SessionDifficulty>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(child: Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('How did today feel?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Text('${sets.where((set) => set.completed).length} / ${sets.length} sets complete. ${sets.every((set) => set.completed) ? 'Your check-in helps plan next time.' : 'You can save a partial session. The primary workout mission requires all planned sets.'}'),
        const SizedBox(height: 8),
        for (final item in const <(SessionDifficulty, String)>[(SessionDifficulty.tooEasy, 'Too easy'), (SessionDifficulty.good, 'Good'), (SessionDifficulty.hard, 'Hard'), (SessionDifficulty.tooHard, 'Too hard')])
          ListTile(contentPadding: EdgeInsets.zero, title: Text(item.$2), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.pop(context, item.$1)),
      ]))),
    );
    if (!mounted) return;
    if (difficulty == null) { setState(() => submitting = false); return; }
    try {
      final recommendations = await _state.nextTimeRecommendations(activeWorkout, sets, difficulty);
      final reward = await _state.recordWorkout(workoutName: activeWorkout.name, sets: sets, difficulty: difficulty, durationSeconds: DateTime.now().difference(active.startedAt).inSeconds, sessionId: active.id);
      if (!mounted) return;
      restTimer?.cancel();
      setState(() { saved = true; submitting = false; restEndsAt = null; });
      await showDialog<void>(context: context, barrierDismissible: false, builder: (context) => AlertDialog(
        title: const Text('Workout saved'),
        content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('Saved on this device · +${reward.rp} RP · +${reward.xp} XP · +${reward.coins} Coins'),
          const SizedBox(height: 8),
          Text(reward.rp > 0 ? 'The primary mission for ${active.dayKey} is complete.' : primaryDone ? 'This session day’s primary reward was already earned. This session is in your history.' : 'Your partial session is saved. Complete the full day’s plan to earn its primary reward.'),
          const SizedBox(height: 8),
          Text('Volume: ${_engine.sessionVolume(sets).toStringAsFixed(0)} lb'),
          const SizedBox(height: 18),
          const Text('NEXT TIME', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          for (final recommendation in recommendations) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(recommendation)),
          const Text('Use these as targets when your form feels controlled. You can keep the same load.', style: TextStyle(color: Colors.white70)),
        ])),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
      ));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(saved ? 'Your workout is saved. Return to Today to see your progress.' : 'Could not save yet. Your sets are still here; please try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (error != null) return Scaffold(appBar: AppBar(title: const Text('Today’s workout')), body: Center(child: FilledButton(onPressed: _loadWorkout, child: Text(error!))));
    final activeWorkout = workout;
    if (activeWorkout == null) return Scaffold(appBar: AppBar(title: const Text('Planned recovery')), body: ListView(padding: const EdgeInsets.all(20), children: [
      const Icon(Icons.self_improvement, size: 48),
      const SizedBox(height: 16),
      const Text('Recovery is today’s plan', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      const Text('An easy walk, gentle mobility, or full rest can fit today. Return to Today to log your planned recovery.'),
      const SizedBox(height: 20),
      OutlinedButton(onPressed: _changeWorkout, child: const Text('Choose a workout for today')),
    ]));
    if (session == null) return _preview(activeWorkout);
    final completed = sets.where((set) => set.completed).length;
    return PopScope(
      canPop: saved || _allowLeave,
      onPopInvokedWithResult: (didPop, result) { if (!didPop) _confirmLeave(); },
      child: Scaffold(
      appBar: AppBar(title: Text(activeWorkout.name)),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
        Text('EXERCISE ${activeExercise + 1} / ${activeWorkout.exercises.length}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
        Text(exercise.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        Text('${exercise.muscleGroup} · ${exercise.sets} sets · ${exercise.isTimed ? 'Timed / controlled' : '${exercise.repMin}–${exercise.repMax} reps'}', style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        Text(_historyLabel(exercise)),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: () => showExerciseGuide(context, exercise), icon: const Icon(Icons.play_circle_outline_rounded), label: const Text('How to perform + demo')),
        const SizedBox(height: 12),
        if (feedback.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 12), child: Semantics(liveRegion: true, child: Text(feedback, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)))),
        if (restSeconds > 0) Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Rest ${restSeconds ~/ 60}:${(restSeconds % 60).toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          Wrap(spacing: 8, children: [
            TextButton(onPressed: () => _startRest(restSeconds + 15), child: const Text('+15 seconds')),
            TextButton(onPressed: () { restTimer?.cancel(); setState(() => restEndsAt = null); }, child: const Text('Skip rest')),
          ]),
        ]))),
        const SizedBox(height: 10),
        for (final index in activeSetIndexes) _setCard(index),
        const SizedBox(height: 16),
        Text('$completed / ${sets.length} working sets logged', style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: sets.isEmpty ? 0 : completed / sets.length, semanticsLabel: 'Workout sets completed'),
        const SizedBox(height: 20),
        const Text('WORKOUT ORDER', style: TextStyle(fontWeight: FontWeight.w900)),
        for (var i = 0; i < activeWorkout.exercises.length; i++) ListTile(
          selected: i == activeExercise,
          contentPadding: EdgeInsets.zero,
          leading: Icon(sets.where((set) => set.exerciseName == activeWorkout.exercises[i].name).every((set) => set.completed) ? Icons.check_circle : Icons.fitness_center),
          title: Text(activeWorkout.exercises[i].name),
          subtitle: Text('${activeWorkout.exercises[i].sets} sets · tap to select'),
          onTap: () => setState(() { activeExercise = i; feedback = ''; }),
          trailing: IconButton(tooltip: 'Guide for ${activeWorkout.exercises[i].name}', icon: const Icon(Icons.info_outline), onPressed: () => showExerciseGuide(context, activeWorkout.exercises[i])),
        ),
      ]),
      bottomNavigationBar: SafeArea(minimum: const EdgeInsets.all(16), child: FilledButton(onPressed: submitting || saved ? null : _finish, child: Text(submitting ? 'Saving…' : 'Finish workout'))),
    ));
  }

  Widget _preview(WorkoutTemplate selected) {
    final equipment = const ProgramGenerator().requiredEquipment(selected).map(const ProgramGenerator().equipmentName).join(' · ');
    return Scaffold(
      appBar: AppBar(title: const Text('Workout preview')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text(selected.name, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('${selected.estimatedMinutes} min · ${selected.exercises.length} exercises · ${selected.exercises.fold<int>(0, (total, e) => total + e.sets)} sets'),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('WHAT YOU’LL NEED', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(equipment.isEmpty ? 'Bodyweight' : equipment),
          const SizedBox(height: 8),
          Text(primaryDone ? 'Today’s primary reward is already complete. You can still log a session.' : 'Complete the prescribed sets and check in to satisfy today’s primary mission once.'),
        ]))),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: submitting ? null : _changeWorkout, icon: const Icon(Icons.swap_horiz), label: const Text('Change today’s workout')),
        const SizedBox(height: 20),
        const Text('YOUR EXERCISES', style: TextStyle(fontWeight: FontWeight.w900)),
        for (final exercise in selected.exercises) ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text('${exercise.sets} sets · ${exercise.isTimed ? 'Timed / controlled' : '${exercise.repMin}–${exercise.repMax} reps'} · ${exercise.restSeconds}s rest\n${_historyLabel(exercise)}'),
          trailing: const Icon(Icons.info_outline),
          onTap: () => showExerciseGuide(context, exercise),
        ),
        const SizedBox(height: 12),
        const Text('Review the exercise guides and substitutions before you begin. Your session timer starts when you press Start.', style: TextStyle(color: Colors.white70)),
      ]),
      bottomNavigationBar: SafeArea(minimum: const EdgeInsets.all(16), child: FilledButton.icon(onPressed: submitting ? null : _start, icon: const Icon(Icons.play_arrow), label: Text(submitting ? 'Starting…' : 'Start workout'))),
    );
  }

  Widget _setCard(int index) {
    final set = sets[index];
    final enabled = !set.completed && !submitting && !saved;
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 180),
      decoration: BoxDecoration(color: set.completed ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.10) : Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: set.completed ? Theme.of(context).colorScheme.primary : Colors.white12)),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('SET ${set.setNumber}${set.completed ? ' · Complete' : ''}', style: const TextStyle(fontWeight: FontWeight.w800))),
          Semantics(label: '${set.completed ? 'Mark incomplete' : 'Complete'} ${exercise.name} set ${set.setNumber}', child: Checkbox(value: set.completed, onChanged: submitting || saved ? null : (_) => _toggleSet(index))),
        ]),
        if (exercise.isTimed) const Text('Complete the timed or controlled effort, then check off this set.')
        else Wrap(spacing: 20, runSpacing: 12, children: [
          _Stepper(label: '${set.weight.toStringAsFixed(0)} lb', field: '${exercise.name} set ${set.setNumber} weight', onMinus: enabled ? () => _changeWeight(index, -exercise.loadIncrement) : null, onPlus: enabled ? () => _changeWeight(index, exercise.loadIncrement) : null),
          _Stepper(label: '${set.reps} reps', field: '${exercise.name} set ${set.setNumber} reps', onMinus: enabled ? () => _changeReps(index, -1) : null, onPlus: enabled ? () => _changeReps(index, 1) : null),
        ]),
      ]),
    ));
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.field, required this.onMinus, required this.onPlus});
  final String label;
  final String field;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(onPressed: onMinus, tooltip: 'Decrease $field', icon: const Icon(Icons.remove)),
      IconButton(onPressed: onPlus, tooltip: 'Increase $field', icon: const Icon(Icons.add)),
    ]),
  ]);
}
