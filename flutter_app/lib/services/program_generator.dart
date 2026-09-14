import '../models/models.dart';

class ProgramGenerator {
  const ProgramGenerator();

  GeneratedProgram generate(ProgramPreferences p) {
    final workouts = _workoutsFor(p)
        .map((w) => WorkoutTemplate(
              name: w.name,
              kind: w.kind,
              estimatedMinutes: p.sessionMinutes,
              exercises: _fitSession(w.exercises, p.sessionMinutes),
            ))
        .toList(growable: false);

    final split = switch ((p.goal, p.daysPerWeek)) {
      (TrainingGoal.cardio, _) => 'Cardio base + intervals + recovery',
      (TrainingGoal.habit, _) => 'Short full-body habit sessions',
      (_, >= 4) when p.experience != ExperienceLevel.beginner => 'Upper / Lower',
      _ => 'Full body',
    };

    final name = _programName(p);
    return GeneratedProgram(
      name: name,
      split: split,
      weeks: 8,
      workouts: workouts,
      week: _buildWeek(workouts, p.daysPerWeek),
      deloadWeeks: const <int>[8],
    );
  }

  String _programName(ProgramPreferences p) {
    if (p.goal == TrainingGoal.cardio) return 'ConsistiFit Cardio Foundation';
    if (p.goal == TrainingGoal.habit) return 'ConsistiFit Habit Builder';
    if (p.equipment == EquipmentLevel.bodyweight) return 'ConsistiFit Home Foundation';
    if (p.equipment == EquipmentLevel.dumbbells) return 'ConsistiFit Dumbbell Foundation';
    if (p.goal == TrainingGoal.strength) return 'ConsistiFit Strength Foundation';
    if (p.experience != ExperienceLevel.beginner && p.daysPerWeek >= 4) {
      return 'ConsistiFit Muscle Builder';
    }
    return 'ConsistiFit Foundation';
  }

  List<WorkoutTemplate> _workoutsFor(ProgramPreferences p) {
    if (p.goal == TrainingGoal.cardio) {
      return const <WorkoutTemplate>[
        WorkoutTemplate(
          name: 'Easy Cardio',
          estimatedMinutes: 45,
          kind: WorkoutKind.cardio,
          exercises: <ExercisePrescription>[
            ExercisePrescription(name: 'Warm-up Walk', muscleGroup: 'Cardio', sets: 1, repMin: null, repMax: null, restSeconds: 0),
            ExercisePrescription(name: 'Easy Run / Bike', muscleGroup: 'Cardio', sets: 1, repMin: null, repMax: null, restSeconds: 0),
            ExercisePrescription(name: 'Cooldown Walk', muscleGroup: 'Recovery', sets: 1, repMin: null, repMax: null, restSeconds: 0),
          ],
        ),
        WorkoutTemplate(
          name: 'Intervals',
          estimatedMinutes: 45,
          kind: WorkoutKind.cardio,
          exercises: <ExercisePrescription>[
            ExercisePrescription(name: 'Warm-up', muscleGroup: 'Cardio', sets: 1, repMin: null, repMax: null, restSeconds: 0),
            ExercisePrescription(name: 'Run Intervals', muscleGroup: 'Cardio', sets: 6, repMin: null, repMax: null, restSeconds: 90),
            ExercisePrescription(name: 'Cooldown', muscleGroup: 'Recovery', sets: 1, repMin: null, repMax: null, restSeconds: 0),
          ],
        ),
        WorkoutTemplate(
          name: 'Long Easy Session',
          estimatedMinutes: 60,
          kind: WorkoutKind.cardio,
          exercises: <ExercisePrescription>[
            ExercisePrescription(name: 'Easy Continuous Cardio', muscleGroup: 'Cardio', sets: 1, repMin: null, repMax: null, restSeconds: 0),
            ExercisePrescription(name: 'Mobility Reset', muscleGroup: 'Recovery', sets: 1, repMin: null, repMax: null, restSeconds: 0),
          ],
        ),
      ];
    }

    if (p.goal == TrainingGoal.habit) {
      return const <WorkoutTemplate>[
        WorkoutTemplate(name: 'Habit A', estimatedMinutes: 30, exercises: <ExercisePrescription>[
          ExercisePrescription(name: 'Goblet Squat', muscleGroup: 'Quads · Glutes', sets: 2, repMin: 8, repMax: 12, restSeconds: 75),
          ExercisePrescription(name: 'Push-up', muscleGroup: 'Chest · Triceps', sets: 2, repMin: 6, repMax: 12, restSeconds: 60),
          ExercisePrescription(name: 'Dumbbell Row', muscleGroup: 'Back · Biceps', sets: 2, repMin: 8, repMax: 12, restSeconds: 60),
          ExercisePrescription(name: 'Plank', muscleGroup: 'Core', sets: 2, repMin: null, repMax: null, restSeconds: 45),
        ]),
        WorkoutTemplate(name: 'Habit B', estimatedMinutes: 30, exercises: <ExercisePrescription>[
          ExercisePrescription(name: 'Romanian Deadlift', muscleGroup: 'Hamstrings · Glutes', sets: 2, repMin: 8, repMax: 12, restSeconds: 75),
          ExercisePrescription(name: 'Dumbbell Shoulder Press', muscleGroup: 'Shoulders · Triceps', sets: 2, repMin: 8, repMax: 12, restSeconds: 60),
          ExercisePrescription(name: 'Lat Pulldown', muscleGroup: 'Back · Biceps', sets: 2, repMin: 8, repMax: 12, restSeconds: 60),
          ExercisePrescription(name: 'Dead Bug', muscleGroup: 'Core', sets: 2, repMin: 8, repMax: 12, restSeconds: 45),
        ]),
      ];
    }

    if (p.equipment == EquipmentLevel.bodyweight) {
      return const <WorkoutTemplate>[
        WorkoutTemplate(name: 'Home A', estimatedMinutes: 45, exercises: <ExercisePrescription>[
          ExercisePrescription(name: 'Tempo Squat', muscleGroup: 'Quads · Glutes', sets: 3, repMin: 10, repMax: 15, restSeconds: 75),
          ExercisePrescription(name: 'Push-up', muscleGroup: 'Chest · Triceps', sets: 3, repMin: 6, repMax: 15, restSeconds: 75),
          ExercisePrescription(name: 'Backpack Row', muscleGroup: 'Back · Biceps', sets: 3, repMin: 10, repMax: 15, restSeconds: 75),
          ExercisePrescription(name: 'Glute Bridge', muscleGroup: 'Glutes', sets: 2, repMin: 12, repMax: 20, restSeconds: 60),
          ExercisePrescription(name: 'Plank', muscleGroup: 'Core', sets: 2, repMin: null, repMax: null, restSeconds: 45),
        ]),
        WorkoutTemplate(name: 'Home B', estimatedMinutes: 45, exercises: <ExercisePrescription>[
          ExercisePrescription(name: 'Reverse Lunge', muscleGroup: 'Quads · Glutes', sets: 3, repMin: 8, repMax: 12, restSeconds: 75),
          ExercisePrescription(name: 'Pike Push-up', muscleGroup: 'Shoulders · Triceps', sets: 3, repMin: 6, repMax: 12, restSeconds: 75),
          ExercisePrescription(name: 'Doorway Row', muscleGroup: 'Back · Biceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 75),
          ExercisePrescription(name: 'Single-leg Hinge', muscleGroup: 'Hamstrings · Glutes', sets: 2, repMin: 8, repMax: 12, restSeconds: 60),
          ExercisePrescription(name: 'Dead Bug', muscleGroup: 'Core', sets: 2, repMin: 8, repMax: 12, restSeconds: 45),
        ]),
        WorkoutTemplate(name: 'Home C', estimatedMinutes: 45, exercises: <ExercisePrescription>[
          ExercisePrescription(name: 'Split Squat', muscleGroup: 'Quads · Glutes', sets: 3, repMin: 8, repMax: 12, restSeconds: 75),
          ExercisePrescription(name: 'Incline Push-up', muscleGroup: 'Chest · Triceps', sets: 3, repMin: 8, repMax: 15, restSeconds: 75),
          ExercisePrescription(name: 'Backpack Row', muscleGroup: 'Back · Biceps', sets: 3, repMin: 10, repMax: 15, restSeconds: 75),
          ExercisePrescription(name: 'Hip Bridge', muscleGroup: 'Glutes', sets: 2, repMin: 12, repMax: 20, restSeconds: 60),
          ExercisePrescription(name: 'Side Plank', muscleGroup: 'Core', sets: 2, repMin: null, repMax: null, restSeconds: 45),
        ]),
      ];
    }

    if (p.experience != ExperienceLevel.beginner && p.daysPerWeek >= 4) {
      return const <WorkoutTemplate>[
        WorkoutTemplate(name: 'Upper A', estimatedMinutes: 60, exercises: <ExercisePrescription>[
          ExercisePrescription(name: 'Bench Press', muscleGroup: 'Chest · Triceps', sets: 4, repMin: 6, repMax: 10, restSeconds: 120),
          ExercisePrescription(name: 'Seated Cable Row', muscleGroup: 'Back · Biceps', sets: 4, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Shoulder Press', muscleGroup: 'Shoulders · Triceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Lat Pulldown', muscleGroup: 'Back · Biceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Lateral Raise', muscleGroup: 'Shoulders', sets: 2, repMin: 12, repMax: 15, restSeconds: 60),
        ]),
        WorkoutTemplate(name: 'Lower A', estimatedMinutes: 60, exercises: <ExercisePrescription>[
          ExercisePrescription(name: 'Back Squat', muscleGroup: 'Quads · Glutes', sets: 4, repMin: 5, repMax: 8, restSeconds: 150),
          ExercisePrescription(name: 'Romanian Deadlift', muscleGroup: 'Hamstrings · Glutes', sets: 3, repMin: 6, repMax: 10, restSeconds: 120),
          ExercisePrescription(name: 'Leg Curl', muscleGroup: 'Hamstrings', sets: 3, repMin: 10, repMax: 15, restSeconds: 75),
          ExercisePrescription(name: 'Calf Raise', muscleGroup: 'Calves', sets: 3, repMin: 12, repMax: 20, restSeconds: 60),
        ]),
        WorkoutTemplate(name: 'Upper B', estimatedMinutes: 60, exercises: <ExercisePrescription>[
          ExercisePrescription(name: 'Incline Dumbbell Press', muscleGroup: 'Chest · Triceps', sets: 4, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Chest-supported Row', muscleGroup: 'Back · Biceps', sets: 4, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Lateral Raise', muscleGroup: 'Shoulders', sets: 3, repMin: 12, repMax: 15, restSeconds: 60),
          ExercisePrescription(name: 'Pull-up / Pulldown', muscleGroup: 'Back · Biceps', sets: 3, repMin: 6, repMax: 10, restSeconds: 90),
          ExercisePrescription(name: 'Arm Superset', muscleGroup: 'Biceps · Triceps', sets: 2, repMin: 10, repMax: 15, restSeconds: 60),
        ]),
        WorkoutTemplate(name: 'Lower B', estimatedMinutes: 60, exercises: <ExercisePrescription>[
          ExercisePrescription(name: 'Deadlift Pattern', muscleGroup: 'Posterior Chain', sets: 3, repMin: 4, repMax: 6, restSeconds: 180),
          ExercisePrescription(name: 'Split Squat', muscleGroup: 'Quads · Glutes', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Hip Thrust', muscleGroup: 'Glutes', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Leg Extension', muscleGroup: 'Quads', sets: 2, repMin: 12, repMax: 15, restSeconds: 60),
        ]),
      ];
    }

    return const <WorkoutTemplate>[
      WorkoutTemplate(name: 'Full Body A', estimatedMinutes: 45, exercises: <ExercisePrescription>[
        ExercisePrescription(name: 'Squat / Goblet Squat', muscleGroup: 'Quads · Glutes', sets: 3, repMin: 8, repMax: 10, restSeconds: 120),
        ExercisePrescription(name: 'Dumbbell Bench Press', muscleGroup: 'Chest · Triceps · Shoulders', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
        ExercisePrescription(name: 'Seated Cable Row', muscleGroup: 'Back · Biceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
        ExercisePrescription(name: 'Romanian Deadlift', muscleGroup: 'Hamstrings · Glutes', sets: 2, repMin: 8, repMax: 10, restSeconds: 120),
        ExercisePrescription(name: 'Lateral Raise', muscleGroup: 'Shoulders', sets: 2, repMin: 12, repMax: 15, restSeconds: 60),
        ExercisePrescription(name: 'Plank', muscleGroup: 'Core', sets: 2, repMin: null, repMax: null, restSeconds: 45),
      ]),
      WorkoutTemplate(name: 'Full Body B', estimatedMinutes: 45, exercises: <ExercisePrescription>[
        ExercisePrescription(name: 'Leg Press', muscleGroup: 'Quads · Glutes', sets: 3, repMin: 8, repMax: 12, restSeconds: 120),
        ExercisePrescription(name: 'Lat Pulldown', muscleGroup: 'Back · Biceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
        ExercisePrescription(name: 'Dumbbell Shoulder Press', muscleGroup: 'Shoulders · Triceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
        ExercisePrescription(name: 'Leg Curl', muscleGroup: 'Hamstrings', sets: 2, repMin: 10, repMax: 15, restSeconds: 75),
        ExercisePrescription(name: 'Dumbbell Curl', muscleGroup: 'Biceps', sets: 2, repMin: 10, repMax: 15, restSeconds: 60),
        ExercisePrescription(name: 'Dead Bug', muscleGroup: 'Core', sets: 2, repMin: 8, repMax: 12, restSeconds: 45),
      ]),
      WorkoutTemplate(name: 'Full Body C', estimatedMinutes: 45, exercises: <ExercisePrescription>[
        ExercisePrescription(name: 'Split Squat', muscleGroup: 'Quads · Glutes', sets: 3, repMin: 8, repMax: 10, restSeconds: 90),
        ExercisePrescription(name: 'Incline Dumbbell Press', muscleGroup: 'Chest · Triceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
        ExercisePrescription(name: 'Chest-supported Row', muscleGroup: 'Back · Biceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
        ExercisePrescription(name: 'Hip Thrust', muscleGroup: 'Glutes', sets: 2, repMin: 8, repMax: 12, restSeconds: 90),
        ExercisePrescription(name: 'Triceps Pressdown', muscleGroup: 'Triceps', sets: 2, repMin: 10, repMax: 15, restSeconds: 60),
        ExercisePrescription(name: 'Calf Raise', muscleGroup: 'Calves', sets: 2, repMin: 12, repMax: 20, restSeconds: 60),
      ]),
    ];
  }

  List<ExercisePrescription> _fitSession(List<ExercisePrescription> exercises, int minutes) {
    final maxExercises = minutes <= 30 ? 4 : (minutes <= 45 ? 6 : exercises.length);
    return exercises.take(maxExercises).toList(growable: false);
  }

  List<ProgramDay> _buildWeek(List<WorkoutTemplate> workouts, int daysPerWeek) {
    final trainingDays = switch (daysPerWeek) {
      <= 2 => const <int>[1, 4],
      3 => const <int>[1, 3, 5],
      4 => const <int>[1, 2, 4, 5],
      5 => const <int>[1, 2, 3, 5, 6],
      _ => const <int>[1, 2, 3, 4, 5, 6],
    };
    var workoutIndex = 0;
    return List<ProgramDay>.generate(7, (index) {
      final weekday = index + 1;
      if (trainingDays.contains(weekday)) {
        final workout = workouts[workoutIndex % workouts.length];
        workoutIndex++;
        return ProgramDay(weekday: weekday, kind: ProgramDayKind.training, label: workout.name, workout: workout);
      }
      return const ProgramDay(weekday: 0, kind: ProgramDayKind.recovery, label: 'Recovery / Rest');
    }).asMap().entries.map((entry) {
      final day = entry.value;
      if (day.weekday != 0) return day;
      return ProgramDay(weekday: entry.key + 1, kind: day.kind, label: day.label);
    }).toList(growable: false);
  }
}
