import 'package:flutter_test/flutter_test.dart';
import 'package:consistifit/models/models.dart';
import 'package:consistifit/services/program_generator.dart';

void main() {
  const generator = ProgramGenerator();

  test('every focus uses only known exercises compatible with equipment', () {
    for (final environment in TrainingEnvironment.values) {
      final preferences = ProgramPreferences(goal: TrainingGoal.muscle,
        experience: ExperienceLevel.beginner, environment: environment,
        daysPerWeek: 3, sessionMinutes: 45);
      for (final focus in ProgramGenerator.muscleFocuses) {
        final workout = generator.generateFocused(preferences, focus);
        expect(workout.exercises, isNotEmpty, reason: '$environment $focus');
        expect(generator.isCompatible(workout, preferences), isTrue, reason: '$environment $focus');
        expect(generator.requiredEquipment(workout).every(preferences.availableEquipment.contains), isTrue);
        expect(workout.exercises.map((exercise) => exercise.name).toSet().length, workout.exercises.length);
      }
    }
  });

  test('focus respects primary muscles instead of matching incidental secondary muscles', () {
    const bodyweight = ProgramPreferences(goal: TrainingGoal.muscle,
      experience: ExperienceLevel.beginner, environment: TrainingEnvironment.custom,
      daysPerWeek: 3, sessionMinutes: 45);
    final back = generator.generateFocused(bodyweight, 'Back');
    expect(back.exercises.every((exercise) => exercise.muscleGroup.contains('Back')), isTrue);
    expect(back.exercises.any((exercise) => exercise.name.contains('Push-up')), isFalse);
    expect(generator.generateFocused(bodyweight, 'Arms').exercises.every((exercise) =>
      exercise.muscleGroup.startsWith('Triceps') || exercise.muscleGroup.startsWith('Biceps') ||
      exercise.muscleGroup.startsWith('Arms')), isTrue);
    expect(() => generator.generateFocused(bodyweight, 'Unrecognized'), throwsArgumentError);
  });

  test('all generated plans have explicit catalog requirements and no duplicate exercises', () {
    for (final environment in TrainingEnvironment.values) {
      for (final goal in TrainingGoal.values) {
        for (final experience in ExperienceLevel.values) {
          final preferences = ProgramPreferences(goal: goal, experience: experience,
            environment: environment, daysPerWeek: 4, sessionMinutes: 75);
          for (final workout in generator.generate(preferences).workouts) {
            expect(generator.isCompatible(workout, preferences), isTrue,
              reason: '$environment $goal $experience ${workout.name}');
          }
        }
      }
    }
  });

  test('saved workouts cannot bypass equipment requirements using muscle labels', () {
    const bodyweight = ProgramPreferences(goal: TrainingGoal.muscle,
      experience: ExperienceLevel.beginner, environment: TrainingEnvironment.custom,
      daysPerWeek: 3, sessionMinutes: 45);
    const unknown = WorkoutTemplate(name: 'Unknown', estimatedMinutes: 15, exercises: [
      ExercisePrescription(name: 'Magic Row', muscleGroup: 'Back', sets: 3, repMin: 8, repMax: 12, restSeconds: 60),
    ]);
    final home = generator.generate(ProgramPreferences.homeDefault).workouts.first;
    expect(generator.isCompatible(unknown, bodyweight), isFalse);
    expect(generator.isCompatible(home, bodyweight), isFalse);
    expect(generator.isCompatible(const WorkoutTemplate(name: 'Empty', estimatedMinutes: 15, exercises: []), bodyweight), isFalse);
  });

  test('home plan uses dumbbells bench and bodyweight', () {
    final program = generator.generate(const ProgramPreferences(
      goal: TrainingGoal.muscle,
      experience: ExperienceLevel.beginner,
      environment: TrainingEnvironment.homeFreeWeights,
      daysPerWeek: 3,
      sessionMinutes: 45,
    ));
    expect(program.name, 'ConsistiFit Home Muscle');
    expect(program.environmentLabel, 'At Home');
    expect(program.workouts.length, 3);
    expect(program.week.where((day) => day.kind == ProgramDayKind.training).length, 3);
    expect(program.week.where((day) => day.kind == ProgramDayKind.recovery).length, 4);
    expect(program.workouts.first.exercises.first.name, contains('Dumbbell'));
    expect(program.workouts.expand((w) => w.exercises).any((e) => e.name.contains('Leg Press')), isFalse);
    expect(program.deloadWeeks, contains(8));
  });

  test('gym plan is machine forward', () {
    final program = generator.generate(const ProgramPreferences(
      goal: TrainingGoal.muscle,
      experience: ExperienceLevel.beginner,
      environment: TrainingEnvironment.gymMachines,
      daysPerWeek: 3,
      sessionMinutes: 45,
    ));
    final names = program.workouts.expand((workout) => workout.exercises).map((exercise) => exercise.name).join(' ');
    expect(program.name, 'ConsistiFit Machine Muscle');
    expect(names, contains('Leg Press'));
    expect(names, contains('Machine Chest Press'));
    expect(names, contains('Lat Pulldown'));
    expect(names, isNot(contains('Dumbbell Bench Press')));
  });

  test('intermediate four-day plan becomes upper lower', () {
    final program = generator.generate(const ProgramPreferences(
      goal: TrainingGoal.muscle,
      experience: ExperienceLevel.intermediate,
      environment: TrainingEnvironment.homeFreeWeights,
      daysPerWeek: 4,
      sessionMinutes: 60,
    ));
    expect(program.split, 'Upper / Lower');
    expect(program.workouts.length, 4);
    expect(program.workouts.first.name, contains('Upper'));
  });

  test('custom plan only chooses compatible weighted equipment before fallback', () {
    final program = generator.generate(const ProgramPreferences(
      goal: TrainingGoal.muscle,
      experience: ExperienceLevel.beginner,
      environment: TrainingEnvironment.custom,
      customEquipment: <EquipmentType>{EquipmentType.dumbbells, EquipmentType.bench},
      daysPerWeek: 3,
      sessionMinutes: 60,
    ));
    final names = program.workouts.expand((workout) => workout.exercises).map((exercise) => exercise.name).join(' | ');
    expect(program.name, 'ConsistiFit Custom Muscle');
    expect(program.equipmentLabel, contains('Dumbbells'));
    expect(names, contains('Dumbbell Bench Press'));
    expect(names, isNot(contains('Leg Press')));
    expect(names, isNot(contains('Cable')));
  });

  test('custom machine selections are used when available', () {
    final program = generator.generate(const ProgramPreferences(
      goal: TrainingGoal.muscle,
      experience: ExperienceLevel.beginner,
      environment: TrainingEnvironment.custom,
      customEquipment: <EquipmentType>{
        EquipmentType.legPress,
        EquipmentType.chestPressMachine,
        EquipmentType.seatedRowMachine,
        EquipmentType.legCurl,
        EquipmentType.shoulderPressMachine,
        EquipmentType.latPulldownMachine,
      },
      daysPerWeek: 3,
      sessionMinutes: 60,
    ));
    final first = program.workouts.first.exercises.map((exercise) => exercise.name).toList();
    expect(first, contains('Leg Press'));
    expect(first, contains('Machine Chest Press'));
    expect(first, contains('Seated Row Machine'));
  });

  test('short sessions reduce exercise count', () {
    final program = generator.generate(const ProgramPreferences(
      goal: TrainingGoal.muscle,
      experience: ExperienceLevel.beginner,
      environment: TrainingEnvironment.gymMachines,
      daysPerWeek: 3,
      sessionMinutes: 30,
    ));
    expect(program.workouts.first.exercises.length, 4);
  });

  test('program preferences round trip custom equipment', () {
    const original = ProgramPreferences(
      goal: TrainingGoal.strength,
      experience: ExperienceLevel.advanced,
      environment: TrainingEnvironment.custom,
      customEquipment: <EquipmentType>{EquipmentType.barbell, EquipmentType.squatRack, EquipmentType.bench},
      daysPerWeek: 5,
      sessionMinutes: 60,
    );
    final restored = ProgramPreferences.fromJson(original.toJson());
    expect(restored.goal, original.goal);
    expect(restored.environment, original.environment);
    expect(restored.daysPerWeek, 5);
    expect(restored.customEquipment, containsAll(original.customEquipment));
  });
}
