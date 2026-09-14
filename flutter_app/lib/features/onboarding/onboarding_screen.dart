import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/program_generator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  TrainingGoal goal = TrainingGoal.muscle;
  ExperienceLevel experience = ExperienceLevel.beginner;
  EquipmentLevel equipment = EquipmentLevel.fullGym;
  int days = 3;
  int minutes = 45;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Build your plan')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField<TrainingGoal>(
              initialValue: goal,
              decoration: const InputDecoration(labelText: 'Goal'),
              items: TrainingGoal.values
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.name),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => goal = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExperienceLevel>(
              initialValue: experience,
              decoration: const InputDecoration(labelText: 'Experience'),
              items: ExperienceLevel.values
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.name),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => experience = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<EquipmentLevel>(
              initialValue: equipment,
              decoration: const InputDecoration(labelText: 'Equipment'),
              items: EquipmentLevel.values
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.name),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => equipment = value);
              },
            ),
            const SizedBox(height: 24),
            Text('Training days: $days'),
            Slider(
              value: days.toDouble(),
              min: 2,
              max: 6,
              divisions: 4,
              label: '$days days',
              onChanged: (value) => setState(() => days = value.round()),
            ),
            Text('Session length: $minutes minutes'),
            Slider(
              value: minutes.toDouble(),
              min: 30,
              max: 75,
              divisions: 3,
              label: '$minutes min',
              onChanged: (value) => setState(() => minutes = value.round()),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                final plan = const ProgramGenerator().generate(
                  ProgramPreferences(
                    goal: goal,
                    experience: experience,
                    equipment: equipment,
                    daysPerWeek: days,
                    sessionMinutes: minutes,
                  ),
                );
                showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(plan.name),
                    content: Text(
                      '${plan.split} · ${plan.weeks} weeks · ${plan.workouts.length} rotating workouts',
                    ),
                  ),
                );
              },
              child: const Text('Generate My Plan'),
            ),
          ],
        ),
      );
}
