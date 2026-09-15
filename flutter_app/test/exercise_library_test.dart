import 'package:flutter_test/flutter_test.dart';
import 'package:consistifit/models/models.dart';
import 'package:consistifit/services/exercise_library.dart';
import 'package:consistifit/services/program_generator.dart';

void main() {
  const generator = ProgramGenerator();
  const library = ExerciseLibrary();

  final preferences = <ProgramPreferences>[
    ProgramPreferences.homeDefault,
    const ProgramPreferences(
      goal: TrainingGoal.muscle,
      experience: ExperienceLevel.intermediate,
      environment: TrainingEnvironment.homeFreeWeights,
      daysPerWeek: 4,
      sessionMinutes: 60,
    ),
    const ProgramPreferences(
      goal: TrainingGoal.muscle,
      experience: ExperienceLevel.beginner,
      environment: TrainingEnvironment.gymMachines,
      daysPerWeek: 3,
      sessionMinutes: 45,
    ),
    const ProgramPreferences(
      goal: TrainingGoal.strength,
      experience: ExperienceLevel.intermediate,
      environment: TrainingEnvironment.gymMachines,
      daysPerWeek: 4,
      sessionMinutes: 60,
    ),
    const ProgramPreferences(
      goal: TrainingGoal.muscle,
      experience: ExperienceLevel.beginner,
      environment: TrainingEnvironment.custom,
      daysPerWeek: 3,
      sessionMinutes: 45,
      customEquipment: <EquipmentType>{
        EquipmentType.dumbbells,
        EquipmentType.bench,
        EquipmentType.barbell,
        EquipmentType.squatRack,
        EquipmentType.cableMachine,
        EquipmentType.legPress,
        EquipmentType.legCurl,
        EquipmentType.latPulldownMachine,
      },
    ),
    const ProgramPreferences(
      goal: TrainingGoal.habit,
      experience: ExperienceLevel.beginner,
      environment: TrainingEnvironment.custom,
      daysPerWeek: 2,
      sessionMinutes: 30,
    ),
    const ProgramPreferences(
      goal: TrainingGoal.cardio,
      experience: ExperienceLevel.beginner,
      environment: TrainingEnvironment.gymMachines,
      daysPerWeek: 3,
      sessionMinutes: 45,
    ),
  ];

  test('every generated exercise receives a complete guide and demo', () {
    for (final preference in preferences) {
      final program = generator.generate(preference);
      for (final workout in program.workouts) {
        for (final exercise in workout.exercises) {
          final guide = library.forExercise(exercise);
          expect(guide.name, exercise.name);
          expect(guide.overview.trim(), isNotEmpty,
              reason: 'Missing overview for ${exercise.name}');
          expect(guide.steps.length, greaterThanOrEqualTo(4),
              reason: 'Missing detailed steps for ${exercise.name}');
          expect(guide.mistakes, isNotEmpty,
              reason: 'Missing mistakes for ${exercise.name}');
          expect(guide.cues, isNotEmpty,
              reason: 'Missing coaching cues for ${exercise.name}');
          expect(guide.demoPhases.length, 3,
              reason: 'Missing 3-phase demo for ${exercise.name}');
          expect(guide.substitution.trim(), isNotEmpty,
              reason: 'Missing substitute for ${exercise.name}');
          expect(guide.safetyNote.trim(), isNotEmpty,
              reason: 'Missing safety note for ${exercise.name}');
        }
      }
    }
  });

  test('unknown movements still receive the safe general guide', () {
    const exercise = ExercisePrescription(
      name: 'Future Exercise',
      muscleGroup: 'General',
      sets: 3,
      repMin: 8,
      repMax: 12,
      restSeconds: 60,
    );
    final guide = library.forExercise(exercise);
    expect(guide.motion, ExerciseMotion.general);
    expect(guide.steps.length, greaterThanOrEqualTo(4));
    expect(guide.demoPhases.length, 3);
  });
}
