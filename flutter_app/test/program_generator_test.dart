import 'package:flutter_test/flutter_test.dart';
import 'package:consistifit/models/models.dart';
import 'package:consistifit/services/program_generator.dart';

void main() {
  const generator = ProgramGenerator();

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
