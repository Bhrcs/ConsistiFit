import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/local_state_service.dart';
import '../../services/program_generator.dart';

Future<bool?> showWorkoutOverrideSheet(BuildContext context, {LocalStateService? localState}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => FractionallySizedBox(heightFactor: 0.92, child: _WorkoutOverrideSheet(localState: localState)),
);

class _WorkoutOverrideSheet extends StatefulWidget {
  const _WorkoutOverrideSheet({this.localState});
  final LocalStateService? localState;
  @override
  State<_WorkoutOverrideSheet> createState() => _WorkoutOverrideSheetState();
}

class _WorkoutOverrideSheetState extends State<_WorkoutOverrideSheet> {
  late final _local = widget.localState ?? LocalStateService();
  final _generator = const ProgramGenerator();
  ProgramPreferences? _preferences;
  List<WorkoutTemplate> _program = [];
  List<WorkoutTemplate> _saved = [];
  WorkoutTemplate? _selected;
  String? _focus;
  String? _error;
  bool _save = false;
  bool _busy = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final preferences = await _local.programPreferences();
      final saved = await _local.savedWorkouts();
      if (!mounted) return;
      setState(() {
        _preferences = preferences;
        _program = _generator.generate(preferences).workouts.where((workout) => _generator.isCompatible(workout, preferences)).toList();
        _saved = saved;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load workouts. Close this sheet and try again.');
    }
  }

  void _generate(String focus) {
    try {
      final workout = _generator.generateFocused(_preferences!, focus);
      setState(() { _selected = workout; _focus = focus; _error = null; });
    } catch (_) {
      setState(() {
        _selected = null;
        _focus = focus;
        _error = 'No compatible workout is available for this focus. Choose another focus or update your equipment.';
      });
    }
  }

  Future<void> _apply() async {
    final selected = _selected;
    if (selected == null || _busy) return;
    setState(() => _busy = true);
    try {
      await _local.setTodayOverride(selected, saveTemplate: _save);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() {
        _busy = false;
        _error = error is StateError ? error.message.toString() : 'This workout could not be applied. Check your current equipment and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_preferences == null && _error == null) return const Center(child: CircularProgressIndicator());
    return ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 28), children: [
      const Text('Change today’s workout', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      const Text('Choose a workout that fits your day. Your weekly schedule stays the same. Completing today’s choice can satisfy the primary mission once.'),
      if (_preferences != null) ...[
        const SizedBox(height: 20),
        const Text('CHOOSE A MUSCLE FOCUS', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, children: [
          for (final focus in const ['Back', 'Chest', 'Legs', 'Shoulders', 'Arms', 'Core', 'Full Body'])
            ChoiceChip(label: Text(focus), selected: _focus == focus, onSelected: _busy ? null : (_) => _generate(focus)),
        ]),
        const SizedBox(height: 6),
        const Text('Built from the exercise library using only your selected equipment.', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 20),
        const Text('PROGRAM WORKOUTS', style: TextStyle(fontWeight: FontWeight.w900)),
        for (final item in _program) _choice(item),
        const SizedBox(height: 16),
        const Text('SAVED WORKOUTS', style: TextStyle(fontWeight: FontWeight.w900)),
        if (_saved.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No saved workouts match your current equipment yet.', style: TextStyle(color: Colors.white70))),
        for (final item in _saved) _choice(item),
      ],
      if (_selected case final selected?) ...[
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(selected.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          Text('${selected.estimatedMinutes} min · ${selected.exercises.fold<int>(0, (sum, e) => sum + e.sets)} sets'),
          const SizedBox(height: 8),
          for (final exercise in selected.exercises) Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text('${exercise.name} · ${exercise.sets} ${exercise.isTimed ? 'sets · timed / controlled' : '× ${exercise.repMin}–${exercise.repMax}'}')),
        ]))),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _save,
          onChanged: _busy ? null : (value) => setState(() => _save = value ?? false),
          title: const Text('Also save to my workouts'),
          subtitle: const Text('Keep a reusable copy on this device. This does not change future scheduled days.'),
        ),
      ],
      if (_error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Semantics(liveRegion: true, child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)))),
      const SizedBox(height: 12),
      FilledButton(onPressed: _selected == null || _busy ? null : _apply, child: Text(_busy ? 'Saving…' : 'Use for today')),
    ]);
  }

  Widget _choice(WorkoutTemplate item) => ListTile(
    contentPadding: EdgeInsets.zero,
    selected: identical(item, _selected),
    leading: Icon(identical(item, _selected) ? Icons.radio_button_checked : Icons.radio_button_unchecked),
    title: Text(item.name),
    subtitle: Text('${item.estimatedMinutes} min · ${item.exercises.length} exercises'),
    onTap: _busy ? null : () => setState(() { _selected = item; _focus = null; _error = null; }),
  );
}
