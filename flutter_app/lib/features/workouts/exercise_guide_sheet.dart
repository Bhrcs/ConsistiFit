import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/exercise_library.dart';

Future<void> showExerciseGuide(
  BuildContext context,
  ExercisePrescription exercise,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.92,
      child: ExerciseGuideSheet(exercise: exercise),
    ),
  );
}

class ExerciseGuideSheet extends StatefulWidget {
  const ExerciseGuideSheet({super.key, required this.exercise});

  final ExercisePrescription exercise;

  @override
  State<ExerciseGuideSheet> createState() => _ExerciseGuideSheetState();
}

class _ExerciseGuideSheetState extends State<ExerciseGuideSheet> {
  late final ExerciseGuide guide;
  Timer? timer;
  int phaseIndex = 0;

  @override
  void initState() {
    super.initState();
    guide = const ExerciseLibrary().forExercise(widget.exercise);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    timer?.cancel();
    if (MediaQuery.disableAnimationsOf(context)) return;
    timer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (!mounted) return;
      setState(() => phaseIndex = (phaseIndex + 1) % guide.demoPhases.length);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = guide.demoPhases[phaseIndex];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: <Widget>[
        Text(
          'EXERCISE GUIDE',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          guide.name,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        Text(
          '${guide.muscleGroup} · ${guide.equipment}',
          style: const TextStyle(color: Colors.white60),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'What this movement should feel like',
          child: Text(
            guide.overview,
            style: const TextStyle(height: 1.45, color: Colors.white70),
          ),
        ),
        const SizedBox(height: 20),
        const _SectionLabel('DEMONSTRATION'),
        const SizedBox(height: 8),
        _MotionPreview(
          motion: guide.motion,
          phaseIndex: phaseIndex,
          phase: phase,
          phaseCount: guide.demoPhases.length,
          onPhaseTap: (value) => setState(() => phaseIndex = value),
          phases: guide.demoPhases,
        ),
        const SizedBox(height: 22),
        const _SectionLabel('HOW TO DO IT'),
        const SizedBox(height: 8),
        for (var i = 0; i < guide.steps.length; i++)
          _StepRow(number: i + 1, text: guide.steps[i]),
        const SizedBox(height: 18),
        const _SectionLabel('COACHING CUES'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final cue in guide.cues)
              Chip(
                label: Text(cue),
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withValues(alpha: .08),
                side: BorderSide(
                  color:
                      Theme.of(context).colorScheme.primary.withValues(alpha: .25),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        const _SectionLabel('COMMON MISTAKES'),
        const SizedBox(height: 8),
        _SectionCard(
          child: Column(
            children: <Widget>[
              for (final mistake in guide.mistakes)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Colors.orangeAccent,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          mistake,
                          style: const TextStyle(height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _SectionLabel('IF YOU NEED A SUBSTITUTE'),
        const SizedBox(height: 8),
        _SectionCard(
          child: Text(
            guide.substitution,
            style: const TextStyle(height: 1.45, color: Colors.white70),
          ),
        ),
        const SizedBox(height: 14),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: .06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.amber.withValues(alpha: .18)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.health_and_safety_outlined,
                  size: 19,
                  color: Colors.amberAccent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    guide.safetyNote,
                    style: const TextStyle(
                      height: 1.4,
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back to workout'),
        ),
      ],
    );
  }
}

class _MotionPreview extends StatelessWidget {
  const _MotionPreview({
    required this.motion,
    required this.phaseIndex,
    required this.phase,
    required this.phaseCount,
    required this.onPhaseTap,
    required this.phases,
  });

  final ExerciseMotion motion;
  final int phaseIndex;
  final DemoPhase phase;
  final int phaseCount;
  final ValueChanged<int> onPhaseTap;
  final List<DemoPhase> phases;

  @override
  Widget build(BuildContext context) {
    final transform = _transform(motion, phaseIndex);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 142,
              child: Center(
                child: AnimatedSlide(
                  duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 550),
                  curve: Curves.easeInOut,
                  offset: Offset(transform.dx / 100, transform.dy / 100),
                  child: AnimatedRotation(
                    duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 550),
                    curve: Curves.easeInOut,
                    turns: transform.angle / (2 * math.pi),
                    child: AnimatedScale(
                      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 550),
                      curve: Curves.easeInOut,
                      scale: transform.scale,
                      child: Icon(
                        Icons.accessibility_new_rounded,
                        size: 92,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 250),
              child: Column(
                key: ValueKey<int>(phaseIndex),
                children: <Widget>[
                  Text(
                    '${phaseIndex + 1}. ${phase.title}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    phase.instruction,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      height: 1.4,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (var i = 0; i < phaseCount; i++)
                  TextButton(
                    onPressed: () => onPhaseTap(i),
                    child: Semantics(
                      label: 'Show ${phases[i].title}',
                      selected: i == phaseIndex,
                      child: AnimatedContainer(
                      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200),
                      width: i == phaseIndex ? 26 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i == phaseIndex
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white24,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Motion preview · use the written steps for the full technique.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }

  _MotionTransform _transform(ExerciseMotion motion, int phase) {
    if (phase != 1) return const _MotionTransform();

    return switch (motion) {
      ExerciseMotion.squat ||
      ExerciseMotion.kneeFlexion => const _MotionTransform(dy: 18, scale: .95),
      ExerciseMotion.hinge => const _MotionTransform(dy: 4, angle: .32),
      ExerciseMotion.bridge ||
      ExerciseMotion.calf => const _MotionTransform(dy: -12, scale: 1.03),
      ExerciseMotion.press ||
      ExerciseMotion.verticalPress => const _MotionTransform(dy: -15, scale: 1.06),
      ExerciseMotion.row ||
      ExerciseMotion.verticalPull => const _MotionTransform(dx: -14, scale: 1.02),
      ExerciseMotion.raise ||
      ExerciseMotion.abduction => const _MotionTransform(scale: 1.13),
      ExerciseMotion.curl ||
      ExerciseMotion.triceps => const _MotionTransform(angle: -.18, scale: 1.04),
      ExerciseMotion.kneeExtension => const _MotionTransform(dy: -5, angle: -.1),
      ExerciseMotion.core ||
      ExerciseMotion.plank => _MotionTransform(angle: math.pi / 2, scale: .92),
      ExerciseMotion.cardio => const _MotionTransform(dx: 14, dy: -4),
      ExerciseMotion.general => const _MotionTransform(scale: 1.06),
    };
  }
}

class _MotionTransform {
  const _MotionTransform({
    this.dx = 0,
    this.dy = 0,
    this.angle = 0,
    this.scale = 1,
  });

  final double dx;
  final double dy;
  final double angle;
  final double scale;
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: .8,
        ),
      );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({this.title, required this.child});
  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (title != null) ...<Widget>[
                Text(title!, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 7),
              ],
              child,
            ],
          ),
        ),
      );
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text});
  final int number;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(child: Text(text, style: const TextStyle(height: 1.45))),
          ],
        ),
      );
}
