import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../services/local_state_service.dart';
import '../../services/program_generator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _state = LocalStateService();
  final _generator = const ProgramGenerator();

  TrainingGoal goal = TrainingGoal.muscle;
  ExperienceLevel experience = ExperienceLevel.beginner;
  TrainingEnvironment environment = TrainingEnvironment.homeFreeWeights;
  Set<EquipmentType> customEquipment = <EquipmentType>{EquipmentType.dumbbells, EquipmentType.bench};
  int days = 3;
  int minutes = 45;
  bool loading = true;
  bool saving = false;

  static const customChoices = <EquipmentType>[
    EquipmentType.dumbbells,
    EquipmentType.bench,
    EquipmentType.barbell,
    EquipmentType.squatRack,
    EquipmentType.kettlebell,
    EquipmentType.resistanceBands,
    EquipmentType.pullUpBar,
    EquipmentType.cableMachine,
    EquipmentType.legPress,
    EquipmentType.legExtension,
    EquipmentType.legCurl,
    EquipmentType.chestPressMachine,
    EquipmentType.shoulderPressMachine,
    EquipmentType.seatedRowMachine,
    EquipmentType.latPulldownMachine,
    EquipmentType.pecDeck,
    EquipmentType.hipAbductionMachine,
    EquipmentType.calfRaiseMachine,
    EquipmentType.cardioMachine,
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final saved = await _state.programPreferences();
    if (!mounted) return;
    setState(() {
      goal = saved.goal;
      experience = saved.experience;
      environment = saved.environment;
      customEquipment = saved.customEquipment.toSet();
      days = saved.daysPerWeek;
      minutes = saved.sessionMinutes;
      loading = false;
    });
  }

  ProgramPreferences get preferences => ProgramPreferences(
        goal: goal,
        experience: experience,
        environment: environment,
        daysPerWeek: days,
        sessionMinutes: minutes,
        customEquipment: customEquipment,
      );

  Future<void> _save() async {
    setState(() => saving = true);
    final prefs = preferences;
    await _state.saveProgramPreferences(prefs);
    final plan = _generator.generate(prefs);
    if (!mounted) return;
    setState(() => saving = false);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(plan.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('${plan.environmentLabel} · ${plan.split} · ${plan.weeks} weeks'),
              const SizedBox(height: 8),
              Text(plan.equipmentLabel, style: const TextStyle(color: Colors.white60)),
              const SizedBox(height: 14),
              for (final workout in plan.workouts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• ${workout.name} · ${workout.exercises.length} exercises'),
                ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Keep editing')),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.go('/program');
            },
            child: const Text('View program'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Build your plan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: <Widget>[
          Text('TRAINING SETUP', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
          const Text('Where are you training?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Pick the setup you actually have. ConsistiFit will only program exercises that fit that environment.', style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 18),
          _EnvironmentCard(
            selected: environment == TrainingEnvironment.homeFreeWeights,
            icon: Icons.home_outlined,
            title: 'At Home',
            subtitle: 'Dumbbells, an adjustable bench and bodyweight only. No machines required.',
            onTap: () => setState(() => environment = TrainingEnvironment.homeFreeWeights),
          ),
          _EnvironmentCard(
            selected: environment == TrainingEnvironment.gymMachines,
            icon: Icons.fitness_center,
            title: 'Gym Machines',
            subtitle: 'Machine-forward workouts using common commercial-gym equipment and cables.',
            onTap: () => setState(() => environment = TrainingEnvironment.gymMachines),
          ),
          _EnvironmentCard(
            selected: environment == TrainingEnvironment.custom,
            icon: Icons.tune,
            title: 'Choose My Equipment',
            subtitle: 'Select exactly what you own or have access to and let ConsistiFit build around it.',
            onTap: () => setState(() => environment = TrainingEnvironment.custom),
          ),
          if (environment == TrainingEnvironment.custom) ...<Widget>[
            const SizedBox(height: 16),
            const Text('YOUR EQUIPMENT', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const Text('Bodyweight movements are always available as a fallback. Select every piece of equipment you can actually use.', style: TextStyle(color: Colors.white60)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final item in customChoices)
                  FilterChip(
                    selected: customEquipment.contains(item),
                    label: Text(_generator.equipmentName(item)),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        customEquipment.add(item);
                      } else {
                        customEquipment.remove(item);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('You still choose the actual working weight for every set during the workout.', style: TextStyle(color: Colors.white60, fontSize: 12)),
          ],
          const SizedBox(height: 26),
          DropdownButtonFormField<TrainingGoal>(
            initialValue: goal,
            decoration: const InputDecoration(labelText: 'Goal'),
            items: const <DropdownMenuItem<TrainingGoal>>[
              DropdownMenuItem(value: TrainingGoal.muscle, child: Text('Build muscle')),
              DropdownMenuItem(value: TrainingGoal.strength, child: Text('Get stronger')),
              DropdownMenuItem(value: TrainingGoal.cardio, child: Text('Improve cardio')),
              DropdownMenuItem(value: TrainingGoal.habit, child: Text('Build the habit')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => goal = value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ExperienceLevel>(
            initialValue: experience,
            decoration: const InputDecoration(labelText: 'Experience'),
            items: const <DropdownMenuItem<ExperienceLevel>>[
              DropdownMenuItem(value: ExperienceLevel.beginner, child: Text('Beginner')),
              DropdownMenuItem(value: ExperienceLevel.intermediate, child: Text('Intermediate')),
              DropdownMenuItem(value: ExperienceLevel.advanced, child: Text('Advanced')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => experience = value);
            },
          ),
          const SizedBox(height: 24),
          Text('Training days: $days', style: const TextStyle(fontWeight: FontWeight.w800)),
          Slider(
            value: days.toDouble(),
            min: 2,
            max: 6,
            divisions: 4,
            label: '$days days',
            onChanged: (value) => setState(() => days = value.round()),
          ),
          Text('Session length: $minutes minutes', style: const TextStyle(fontWeight: FontWeight.w800)),
          Slider(
            value: minutes.toDouble(),
            min: 30,
            max: 75,
            divisions: 3,
            label: '$minutes min',
            onChanged: (value) => setState(() => minutes = value.round()),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                days >= 4 && experience != ExperienceLevel.beginner
                    ? 'Your schedule supports an Upper / Lower split. Recovery days remain part of the plan.'
                    : 'Your schedule will use rotating full-body sessions so each major muscle group is trained regularly.',
              ),
            ),
          ),
        ],
      ),
      bottomSheet: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: saving ? null : _save,
            child: Text(saving ? 'Saving…' : 'Build & Save My Plan'),
          ),
        ),
      ),
    );
  }
}

class _EnvironmentCard extends StatelessWidget {
  const _EnvironmentCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  backgroundColor: selected ? Theme.of(context).colorScheme.primary : Colors.white12,
                  foregroundColor: selected ? Colors.black : Colors.white,
                  child: Icon(icon),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(color: Colors.white60)),
                    ],
                  ),
                ),
                Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked, color: selected ? Theme.of(context).colorScheme.primary : Colors.white38),
              ],
            ),
          ),
        ),
      );
}
