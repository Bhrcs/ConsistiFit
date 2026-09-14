import 'package:flutter_test/flutter_test.dart';
import 'package:consistifit/models/models.dart';
import 'package:consistifit/services/program_generator.dart';

void main() {
  const generator = ProgramGenerator();

  test('beginner muscle defaults to three-day foundation', () {
    final program = generator.generate(const ProgramPreferences(
      goal: TrainingGoal.muscle,
      experience: ExperienceLevel.beginner,
      equipment: EquipmentLevel.fullGym,
      daysPerWeek: 3,
      sessionMinutes: 45,
    ));
    expect(program.name, 'ConsistiFit Foundation');
    expect(program.workouts.length, 3);
    expect(program.week.where((day) => day.kind == ProgramDayKind.training).length, 3);
    expect(program.week.where((day) => day.kind == ProgramDayKind.recovery).length, 4);
    expect(program.workouts.first.exercises.first.sets, 3);
    expect(program.deloadWeeks, contains(8));
  });

  test('intermediate four-day muscle plan becomes upper lower', () {
    final program = generator.generate(const ProgramPreferences(
      goal: TrainingGoal.muscle,
      experience: ExperienceLevel.intermediate,
      equipment: EquipmentLevel.fullGym,
      daysPerWeek: 4,
      sessionMinutes: 60,
    ));
    expect(program.name, 'ConsistiFit Muscle Builder');
    expect(program.split, 'Upper / Lower');
    expect(program.workouts.length, 4);
  });

  test('short sessions reduce exercise count', () {
    final program = generator.generate(const ProgramPreferences(
      goal: TrainingGoal.muscle,
      experience: ExperienceLevel.beginner,
      equipment: EquipmentLevel.fullGym,
      daysPerWeek: 3,
      sessionMinutes: 30,
    ));
    expect(program.workouts.first.exercises.length, 4);
  });
}
