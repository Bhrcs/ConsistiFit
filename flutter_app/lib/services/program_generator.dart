import '../models/models.dart';

class ProgramGenerator {
  const ProgramGenerator();

  GeneratedProgram generate(ProgramPreferences p) {
    final raw = _workoutsFor(p);
    final workouts = raw
        .map((workout) => WorkoutTemplate(
              name: workout.name,
              kind: workout.kind,
              estimatedMinutes: p.sessionMinutes,
              exercises: _fitSession(
                workout.exercises.map((exercise) => _tuneForGoal(exercise, p)).toList(growable: false),
                p.sessionMinutes,
              ),
            ))
        .toList(growable: false);

    return GeneratedProgram(
      name: _programName(p),
      split: _splitFor(p),
      weeks: 8,
      workouts: workouts,
      week: _buildWeek(workouts, p.daysPerWeek),
      environmentLabel: _environmentLabel(p.environment),
      equipmentLabel: _equipmentLabel(p),
      deloadWeeks: const <int>[8],
    );
  }

  String _splitFor(ProgramPreferences p) {
    if (p.goal == TrainingGoal.cardio) return 'Cardio base + intervals + recovery';
    if (p.goal == TrainingGoal.habit) return 'Short full body';
    if (p.daysPerWeek >= 4 && p.experience != ExperienceLevel.beginner) return 'Upper / Lower';
    return 'Full body';
  }

  String _programName(ProgramPreferences p) {
    if (p.goal == TrainingGoal.cardio) return 'ConsistiFit Cardio Foundation';
    final goal = switch (p.goal) {
      TrainingGoal.strength => 'Strength',
      TrainingGoal.habit => 'Habit',
      _ => 'Muscle',
    };
    return switch (p.environment) {
      TrainingEnvironment.homeFreeWeights => 'ConsistiFit Home $goal',
      TrainingEnvironment.gymMachines => 'ConsistiFit Machine $goal',
      TrainingEnvironment.custom => 'ConsistiFit Custom $goal',
    };
  }

  String _environmentLabel(TrainingEnvironment environment) => switch (environment) {
        TrainingEnvironment.homeFreeWeights => 'At Home',
        TrainingEnvironment.gymMachines => 'Gym Machines',
        TrainingEnvironment.custom => 'Custom Equipment',
      };

  String _equipmentLabel(ProgramPreferences p) {
    if (p.environment == TrainingEnvironment.homeFreeWeights) return 'Dumbbells + adjustable bench + bodyweight';
    if (p.environment == TrainingEnvironment.gymMachines) return 'Machines + cables + cardio equipment';
    final selected = p.customEquipment.toList(growable: false)
      ..sort((a, b) => a.index.compareTo(b.index));
    if (selected.isEmpty) return 'Bodyweight only';
    return selected.map(equipmentName).join(' · ');
  }

  String equipmentName(EquipmentType type) => switch (type) {
        EquipmentType.bodyweight => 'Bodyweight',
        EquipmentType.dumbbells => 'Dumbbells',
        EquipmentType.bench => 'Bench',
        EquipmentType.barbell => 'Barbell + plates',
        EquipmentType.squatRack => 'Squat rack',
        EquipmentType.kettlebell => 'Kettlebell',
        EquipmentType.resistanceBands => 'Resistance bands',
        EquipmentType.pullUpBar => 'Pull-up bar',
        EquipmentType.cableMachine => 'Cable station',
        EquipmentType.legPress => 'Leg press',
        EquipmentType.legExtension => 'Leg extension',
        EquipmentType.legCurl => 'Leg curl',
        EquipmentType.chestPressMachine => 'Chest press machine',
        EquipmentType.shoulderPressMachine => 'Shoulder press machine',
        EquipmentType.seatedRowMachine => 'Seated row machine',
        EquipmentType.latPulldownMachine => 'Lat pulldown',
        EquipmentType.pecDeck => 'Pec deck / rear delt',
        EquipmentType.hipAbductionMachine => 'Hip abduction machine',
        EquipmentType.calfRaiseMachine => 'Calf raise machine',
        EquipmentType.cardioMachine => 'Cardio machine',
      };

  List<WorkoutTemplate> _workoutsFor(ProgramPreferences p) {
    if (p.goal == TrainingGoal.cardio) return _cardioPlan(p);

    final upperLower = p.daysPerWeek >= 4 && p.experience != ExperienceLevel.beginner;
    final base = switch (p.environment) {
      TrainingEnvironment.homeFreeWeights => upperLower ? _homeUpperLower() : _homeFullBody(),
      TrainingEnvironment.gymMachines => upperLower ? _gymUpperLower() : _gymFullBody(),
      TrainingEnvironment.custom => upperLower ? _customUpperLower(p.availableEquipment) : _customFullBody(p.availableEquipment),
    };

    if (p.goal != TrainingGoal.habit) return base;
    return base.take(2).map((workout) {
      final shortExercises = workout.exercises
          .take(4)
          .map((exercise) => exercise.copyWith(sets: 2, restSeconds: exercise.restSeconds.clamp(45, 75)))
          .toList(growable: false);
      return WorkoutTemplate(
        name: workout.name.replaceAll('Full Body', 'Habit').replaceAll('Upper', 'Habit'),
        estimatedMinutes: 30,
        exercises: shortExercises,
      );
    }).toList(growable: false);
  }

  ExercisePrescription _tuneForGoal(ExercisePrescription exercise, ProgramPreferences p) {
    if (exercise.isTimed || p.goal == TrainingGoal.habit || p.goal == TrainingGoal.cardio) return exercise;
    if (p.goal == TrainingGoal.strength && exercise.restSeconds >= 90) {
      return exercise.copyWith(
        sets: p.experience == ExperienceLevel.beginner ? 3 : 4,
        repMin: 5,
        repMax: 8,
        restSeconds: exercise.restSeconds.clamp(120, 180),
      );
    }
    if (p.goal == TrainingGoal.muscle && exercise.restSeconds >= 90) {
      return exercise.copyWith(sets: p.experience == ExperienceLevel.beginner ? 3 : 4, repMin: 8, repMax: 12);
    }
    return exercise;
  }

  List<WorkoutTemplate> _cardioPlan(ProgramPreferences p) {
    final machine = p.availableEquipment.contains(EquipmentType.cardioMachine);
    final easy = machine ? 'Easy Bike / Treadmill / Elliptical' : 'Brisk Walk / Easy Run';
    final intervals = machine ? 'Machine Intervals' : 'Walk / Run Intervals';
    return <WorkoutTemplate>[
      WorkoutTemplate(name: 'Easy Cardio', estimatedMinutes: 45, kind: WorkoutKind.cardio, exercises: <ExercisePrescription>[
        const ExercisePrescription(name: 'Warm-up', muscleGroup: 'Cardio', sets: 1, repMin: null, repMax: null, restSeconds: 0),
        ExercisePrescription(name: easy, muscleGroup: 'Cardio', sets: 1, repMin: null, repMax: null, restSeconds: 0),
        const ExercisePrescription(name: 'Cooldown + Mobility', muscleGroup: 'Recovery', sets: 1, repMin: null, repMax: null, restSeconds: 0),
      ]),
      WorkoutTemplate(name: 'Intervals', estimatedMinutes: 45, kind: WorkoutKind.cardio, exercises: <ExercisePrescription>[
        const ExercisePrescription(name: 'Warm-up', muscleGroup: 'Cardio', sets: 1, repMin: null, repMax: null, restSeconds: 0),
        ExercisePrescription(name: intervals, muscleGroup: 'Cardio', sets: 6, repMin: null, repMax: null, restSeconds: 90),
        const ExercisePrescription(name: 'Cooldown', muscleGroup: 'Recovery', sets: 1, repMin: null, repMax: null, restSeconds: 0),
      ]),
      WorkoutTemplate(name: 'Long Easy Session', estimatedMinutes: 60, kind: WorkoutKind.cardio, exercises: <ExercisePrescription>[
        ExercisePrescription(name: easy, muscleGroup: 'Cardio', sets: 1, repMin: null, repMax: null, restSeconds: 0),
        const ExercisePrescription(name: 'Mobility Reset', muscleGroup: 'Recovery', sets: 1, repMin: null, repMax: null, restSeconds: 0),
      ]),
    ];
  }

  List<WorkoutTemplate> _homeFullBody() => const <WorkoutTemplate>[
        WorkoutTemplate(name: 'Home Full Body A', estimatedMinutes: 45, exercises: <ExercisePrescription>[
          ExercisePrescription(name: 'Dumbbell Goblet Squat', muscleGroup: 'Quads · Glutes', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Dumbbell Bench Press', muscleGroup: 'Chest · Triceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Bench-Supported Dumbbell Row', muscleGroup: 'Back · Biceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Dumbbell Romanian Deadlift', muscleGroup: 'Hamstrings · Glutes', sets: 3, repMin: 8, repMax: 12, restSeconds: 105),
          ExercisePrescription(name: 'Dumbbell Lateral Raise', muscleGroup: 'Shoulders', sets: 2, repMin: 12, repMax: 15, restSeconds: 60),
          ExercisePrescription(name: 'Plank', muscleGroup: 'Core', sets: 2, repMin: null, repMax: null, restSeconds: 45),
        ]),
        WorkoutTemplate(name: 'Home Full Body B', estimatedMinutes: 45, exercises: <ExercisePrescription>[
          ExercisePrescription(name: 'Dumbbell Reverse Lunge', muscleGroup: 'Quads · Glutes', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Incline Dumbbell Bench Press', muscleGroup: 'Chest · Triceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Chest-Supported Dumbbell Row', muscleGroup: 'Back · Biceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Dumbbell Hip Thrust on Bench', muscleGroup: 'Glutes · Hamstrings', sets: 3, repMin: 10, repMax: 15, restSeconds: 90),
          ExercisePrescription(name: 'Seated Dumbbell Shoulder Press', muscleGroup: 'Shoulders · Triceps', sets: 2, repMin: 8, repMax: 12, restSeconds: 75),
          ExercisePrescription(name: 'Dead Bug', muscleGroup: 'Core', sets: 2, repMin: 8, repMax: 12, restSeconds: 45),
        ]),
        WorkoutTemplate(name: 'Home Full Body C', estimatedMinutes: 45, exercises: <ExercisePrescription>[
          ExercisePrescription(name: 'Dumbbell Bulgarian Split Squat', muscleGroup: 'Quads · Glutes', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Dumbbell Floor Press', muscleGroup: 'Chest · Triceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'One-Arm Dumbbell Row', muscleGroup: 'Back · Biceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Single-Leg Dumbbell Romanian Deadlift', muscleGroup: 'Hamstrings · Glutes', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Dumbbell Curl + Overhead Triceps Extension', muscleGroup: 'Arms', sets: 2, repMin: 10, repMax: 15, restSeconds: 60),
          ExercisePrescription(name: 'Bench Leg Raise', muscleGroup: 'Core', sets: 2, repMin: 10, repMax: 15, restSeconds: 45),
        ]),
      ];

  List<WorkoutTemplate> _homeUpperLower() => const <WorkoutTemplate>[
        WorkoutTemplate(name: 'Home Upper A', estimatedMinutes: 60, exercises: <ExercisePrescription>[
          ExercisePrescription(name: 'Dumbbell Bench Press', muscleGroup: 'Chest · Triceps', sets: 4, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Bench-Supported Dumbbell Row', muscleGroup: 'Back · Biceps', sets: 4, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Seated Dumbbell Shoulder Press', muscleGroup: 'Shoulders · Triceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Dumbbell Pullover on Bench', muscleGroup: 'Lats · Chest', sets: 3, repMin: 10, repMax: 15, restSeconds: 75),
          ExercisePrescription(name: 'Dumbbell Lateral Raise', muscleGroup: 'Shoulders', sets: 2, repMin: 12, repMax: 15, restSeconds: 60),
          ExercisePrescription(name: 'Dumbbell Curl', muscleGroup: 'Biceps', sets: 2, repMin: 10, repMax: 15, restSeconds: 60),
        ]),
        WorkoutTemplate(name: 'Home Lower A', estimatedMinutes: 60, exercises: <ExercisePrescription>[
          ExercisePrescription(name: 'Dumbbell Goblet Squat', muscleGroup: 'Quads · Glutes', sets: 4, repMin: 8, repMax: 12, restSeconds: 105),
          ExercisePrescription(name: 'Dumbbell Romanian Deadlift', muscleGroup: 'Hamstrings · Glutes', sets: 4, repMin: 8, repMax: 12, restSeconds: 105),
          ExercisePrescription(name: 'Dumbbell Bulgarian Split Squat', muscleGroup: 'Quads · Glutes', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Dumbbell Hip Thrust on Bench', muscleGroup: 'Glutes', sets: 3, repMin: 10, repMax: 15, restSeconds: 90),
          ExercisePrescription(name: 'Standing Dumbbell Calf Raise', muscleGroup: 'Calves', sets: 3, repMin: 12, repMax: 20, restSeconds: 60),
        ]),
        WorkoutTemplate(name: 'Home Upper B', estimatedMinutes: 60, exercises: <ExercisePrescription>[
          ExercisePrescription(name: 'Incline Dumbbell Bench Press', muscleGroup: 'Chest · Triceps', sets: 4, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Chest-Supported Dumbbell Row', muscleGroup: 'Back · Biceps', sets: 4, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Arnold Press', muscleGroup: 'Shoulders · Triceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Dumbbell Pullover on Bench', muscleGroup: 'Lats · Chest', sets: 3, repMin: 10, repMax: 15, restSeconds: 75),
          ExercisePrescription(name: 'Rear Delt Dumbbell Raise', muscleGroup: 'Rear Delts', sets: 2, repMin: 12, repMax: 15, restSeconds: 60),
          ExercisePrescription(name: 'Overhead Dumbbell Triceps Extension', muscleGroup: 'Triceps', sets: 2, repMin: 10, repMax: 15, restSeconds: 60),
        ]),
        WorkoutTemplate(name: 'Home Lower B', estimatedMinutes: 60, exercises: <ExercisePrescription>[
          ExercisePrescription(name: 'Dumbbell Reverse Lunge', muscleGroup: 'Quads · Glutes', sets: 4, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Dumbbell Sumo Squat', muscleGroup: 'Quads · Glutes', sets: 3, repMin: 10, repMax: 15, restSeconds: 90),
          ExercisePrescription(name: 'Single-Leg Dumbbell Romanian Deadlift', muscleGroup: 'Hamstrings · Glutes', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Dumbbell Step-Up on Bench', muscleGroup: 'Quads · Glutes', sets: 3, repMin: 8, repMax: 12, restSeconds: 75),
          ExercisePrescription(name: 'Standing Dumbbell Calf Raise', muscleGroup: 'Calves', sets: 3, repMin: 12, repMax: 20, restSeconds: 60),
        ]),
      ];

  List<WorkoutTemplate> _gymFullBody() => const <WorkoutTemplate>[
        WorkoutTemplate(name: 'Machine Full Body A', estimatedMinutes: 45, exercises: <ExercisePrescription>[
          ExercisePrescription(name: 'Leg Press', muscleGroup: 'Quads · Glutes', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Machine Chest Press', muscleGroup: 'Chest · Triceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Seated Row Machine', muscleGroup: 'Back · Biceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Seated Leg Curl', muscleGroup: 'Hamstrings', sets: 3, repMin: 10, repMax: 15, restSeconds: 75),
          ExercisePrescription(name: 'Cable Lateral Raise', muscleGroup: 'Shoulders', sets: 2, repMin: 12, repMax: 15, restSeconds: 60),
          ExercisePrescription(name: 'Cable Crunch', muscleGroup: 'Core', sets: 2, repMin: 10, repMax: 15, restSeconds: 60),
        ]),
        WorkoutTemplate(name: 'Machine Full Body B', estimatedMinutes: 45, exercises: <ExercisePrescription>[
          ExercisePrescription(name: 'Leg Extension', muscleGroup: 'Quads', sets: 3, repMin: 10, repMax: 15, restSeconds: 75),
          ExercisePrescription(name: 'Lat Pulldown Machine', muscleGroup: 'Back · Biceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Shoulder Press Machine', muscleGroup: 'Shoulders · Triceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Leg Curl Machine', muscleGroup: 'Hamstrings', sets: 3, repMin: 10, repMax: 15, restSeconds: 75),
          ExercisePrescription(name: 'Pec Deck', muscleGroup: 'Chest', sets: 2, repMin: 10, repMax: 15, restSeconds: 60),
          ExercisePrescription(name: 'Cable Curl', muscleGroup: 'Biceps', sets: 2, repMin: 10, repMax: 15, restSeconds: 60),
        ]),
        WorkoutTemplate(name: 'Machine Full Body C', estimatedMinutes: 45, exercises: <ExercisePrescription>[
          ExercisePrescription(name: 'Leg Press', muscleGroup: 'Quads · Glutes', sets: 3, repMin: 10, repMax: 15, restSeconds: 90),
          ExercisePrescription(name: 'Machine Chest Press', muscleGroup: 'Chest · Triceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Seated Row Machine', muscleGroup: 'Back · Biceps', sets: 3, repMin: 10, repMax: 15, restSeconds: 90),
          ExercisePrescription(name: 'Hip Abduction Machine', muscleGroup: 'Glutes', sets: 3, repMin: 12, repMax: 20, restSeconds: 60),
          ExercisePrescription(name: 'Calf Raise Machine', muscleGroup: 'Calves', sets: 3, repMin: 12, repMax: 20, restSeconds: 60),
          ExercisePrescription(name: 'Cable Triceps Pressdown', muscleGroup: 'Triceps', sets: 2, repMin: 10, repMax: 15, restSeconds: 60),
        ]),
      ];

  List<WorkoutTemplate> _gymUpperLower() => const <WorkoutTemplate>[
        WorkoutTemplate(name: 'Machine Upper A', estimatedMinutes: 60, exercises: <ExercisePrescription>[
          ExercisePrescription(name: 'Machine Chest Press', muscleGroup: 'Chest · Triceps', sets: 4, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Seated Row Machine', muscleGroup: 'Back · Biceps', sets: 4, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Shoulder Press Machine', muscleGroup: 'Shoulders · Triceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Lat Pulldown Machine', muscleGroup: 'Back · Biceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Pec Deck', muscleGroup: 'Chest', sets: 2, repMin: 10, repMax: 15, restSeconds: 60),
          ExercisePrescription(name: 'Cable Curl', muscleGroup: 'Biceps', sets: 2, repMin: 10, repMax: 15, restSeconds: 60),
        ]),
        WorkoutTemplate(name: 'Machine Lower A', estimatedMinutes: 60, exercises: <ExercisePrescription>[
          ExercisePrescription(name: 'Leg Press', muscleGroup: 'Quads · Glutes', sets: 4, repMin: 8, repMax: 12, restSeconds: 105),
          ExercisePrescription(name: 'Leg Curl Machine', muscleGroup: 'Hamstrings', sets: 4, repMin: 10, repMax: 15, restSeconds: 75),
          ExercisePrescription(name: 'Leg Extension', muscleGroup: 'Quads', sets: 3, repMin: 10, repMax: 15, restSeconds: 75),
          ExercisePrescription(name: 'Hip Abduction Machine', muscleGroup: 'Glutes', sets: 3, repMin: 12, repMax: 20, restSeconds: 60),
          ExercisePrescription(name: 'Calf Raise Machine', muscleGroup: 'Calves', sets: 3, repMin: 12, repMax: 20, restSeconds: 60),
        ]),
        WorkoutTemplate(name: 'Machine Upper B', estimatedMinutes: 60, exercises: <ExercisePrescription>[
          ExercisePrescription(name: 'Machine Chest Press', muscleGroup: 'Chest · Triceps', sets: 4, repMin: 10, repMax: 15, restSeconds: 90),
          ExercisePrescription(name: 'Lat Pulldown Machine', muscleGroup: 'Back · Biceps', sets: 4, repMin: 8, repMax: 12, restSeconds: 90),
          ExercisePrescription(name: 'Seated Row Machine', muscleGroup: 'Back · Biceps', sets: 3, repMin: 10, repMax: 15, restSeconds: 90),
          ExercisePrescription(name: 'Reverse Pec Deck', muscleGroup: 'Rear Delts', sets: 3, repMin: 12, repMax: 15, restSeconds: 60),
          ExercisePrescription(name: 'Cable Lateral Raise', muscleGroup: 'Shoulders', sets: 2, repMin: 12, repMax: 15, restSeconds: 60),
          ExercisePrescription(name: 'Cable Triceps Pressdown', muscleGroup: 'Triceps', sets: 2, repMin: 10, repMax: 15, restSeconds: 60),
        ]),
        WorkoutTemplate(name: 'Machine Lower B', estimatedMinutes: 60, exercises: <ExercisePrescription>[
          ExercisePrescription(name: 'Leg Press', muscleGroup: 'Quads · Glutes', sets: 4, repMin: 10, repMax: 15, restSeconds: 105),
          ExercisePrescription(name: 'Leg Curl Machine', muscleGroup: 'Hamstrings', sets: 4, repMin: 8, repMax: 12, restSeconds: 75),
          ExercisePrescription(name: 'Leg Extension', muscleGroup: 'Quads', sets: 3, repMin: 12, repMax: 15, restSeconds: 75),
          ExercisePrescription(name: 'Hip Abduction Machine', muscleGroup: 'Glutes', sets: 3, repMin: 12, repMax: 20, restSeconds: 60),
          ExercisePrescription(name: 'Calf Raise Machine', muscleGroup: 'Calves', sets: 3, repMin: 12, repMax: 20, restSeconds: 60),
        ]),
      ];

  List<WorkoutTemplate> _customFullBody(Set<EquipmentType> equipment) => <WorkoutTemplate>[
        WorkoutTemplate(name: 'Custom Full Body A', estimatedMinutes: 45, exercises: <ExercisePrescription>[
          _pick(equipment, _squatA),
          _pick(equipment, _chestA),
          _pick(equipment, _rowA),
          _pick(equipment, _hingeA),
          _pick(equipment, _shoulderA),
          _pick(equipment, _coreA),
        ]),
        WorkoutTemplate(name: 'Custom Full Body B', estimatedMinutes: 45, exercises: <ExercisePrescription>[
          _pick(equipment, _squatB),
          _pick(equipment, _pullB),
          _pick(equipment, _chestB),
          _pick(equipment, _hingeB),
          _pick(equipment, _accessoryB),
          _pick(equipment, _coreB),
        ]),
        WorkoutTemplate(name: 'Custom Full Body C', estimatedMinutes: 45, exercises: <ExercisePrescription>[
          _pick(equipment, _singleLegC),
          _pick(equipment, _chestC),
          _pick(equipment, _rowC),
          _pick(equipment, _gluteC),
          _pick(equipment, _armsC),
          _pick(equipment, _calfCoreC),
        ]),
      ];

  List<WorkoutTemplate> _customUpperLower(Set<EquipmentType> equipment) {
    final full = _customFullBody(equipment);
    ExercisePrescription byMuscles(List<String> needles, List<_Candidate> backup) {
      for (final workout in full) {
        for (final exercise in workout.exercises) {
          if (needles.any((needle) => exercise.muscleGroup.contains(needle))) return exercise;
        }
      }
      return _pick(equipment, backup);
    }

    return <WorkoutTemplate>[
      WorkoutTemplate(name: 'Custom Upper A', estimatedMinutes: 60, exercises: <ExercisePrescription>[
        _pick(equipment, _chestA),
        _pick(equipment, _rowA),
        _pick(equipment, _shoulderA),
        _pick(equipment, _pullB),
        _pick(equipment, _accessoryB),
        _pick(equipment, _armsC),
      ]),
      WorkoutTemplate(name: 'Custom Lower A', estimatedMinutes: 60, exercises: <ExercisePrescription>[
        _pick(equipment, _squatA),
        _pick(equipment, _hingeA),
        _pick(equipment, _singleLegC),
        _pick(equipment, _gluteC),
        _pick(equipment, _calfCoreC),
      ]),
      WorkoutTemplate(name: 'Custom Upper B', estimatedMinutes: 60, exercises: <ExercisePrescription>[
        _pick(equipment, _chestB),
        _pick(equipment, _pullB),
        _pick(equipment, _rowC),
        _pick(equipment, _shoulderA),
        byMuscles(<String>['Shoulders'], _shoulderA),
        _pick(equipment, _armsC),
      ]),
      WorkoutTemplate(name: 'Custom Lower B', estimatedMinutes: 60, exercises: <ExercisePrescription>[
        _pick(equipment, _squatB),
        _pick(equipment, _hingeB),
        _pick(equipment, _singleLegC),
        _pick(equipment, _gluteC),
        _pick(equipment, _coreB),
      ]),
    ];
  }

  ExercisePrescription _pick(Set<EquipmentType> equipment, List<_Candidate> candidates) {
    for (final candidate in candidates) {
      if (candidate.requires.every(equipment.contains)) return candidate.exercise;
    }
    return candidates.last.exercise;
  }

  List<ExercisePrescription> _fitSession(List<ExercisePrescription> exercises, int minutes) {
    final maxExercises = switch (minutes) {
      <= 30 => 4,
      <= 45 => 5,
      <= 60 => 6,
      _ => 7,
    };
    return exercises.take(maxExercises).toList(growable: false);
  }

  List<ProgramDay> _buildWeek(List<WorkoutTemplate> workouts, int daysPerWeek) {
    final trainingDays = switch (daysPerWeek.clamp(2, 6)) {
      2 => const <int>[1, 4],
      3 => const <int>[1, 3, 5],
      4 => const <int>[1, 2, 4, 5],
      5 => const <int>[1, 2, 3, 5, 6],
      _ => const <int>[1, 2, 3, 4, 5, 6],
    };
    var workoutIndex = 0;
    return <ProgramDay>[
      for (var weekday = 1; weekday <= 7; weekday++)
        if (trainingDays.contains(weekday))
          ProgramDay(
            weekday: weekday,
            kind: ProgramDayKind.training,
            label: workouts[workoutIndex % workouts.length].name,
            workout: workouts[workoutIndex++ % workouts.length],
          )
        else
          ProgramDay(
            weekday: weekday,
            kind: ProgramDayKind.recovery,
            label: 'Recovery + Mobility',
          ),
    ];
  }

  static const _squatA = <_Candidate>[
    _Candidate({EquipmentType.barbell, EquipmentType.squatRack}, ExercisePrescription(name: 'Back Squat', muscleGroup: 'Quads · Glutes', sets: 3, repMin: 6, repMax: 10, restSeconds: 120)),
    _Candidate({EquipmentType.legPress}, ExercisePrescription(name: 'Leg Press', muscleGroup: 'Quads · Glutes', sets: 3, repMin: 8, repMax: 12, restSeconds: 90)),
    _Candidate({EquipmentType.dumbbells}, ExercisePrescription(name: 'Dumbbell Goblet Squat', muscleGroup: 'Quads · Glutes', sets: 3, repMin: 8, repMax: 12, restSeconds: 90)),
    _Candidate({EquipmentType.kettlebell}, ExercisePrescription(name: 'Kettlebell Goblet Squat', muscleGroup: 'Quads · Glutes', sets: 3, repMin: 8, repMax: 12, restSeconds: 90)),
    _Candidate({EquipmentType.resistanceBands}, ExercisePrescription(name: 'Band-Resisted Squat', muscleGroup: 'Quads · Glutes', sets: 3, repMin: 10, repMax: 15, restSeconds: 75)),
    _Candidate({}, ExercisePrescription(name: 'Tempo Bodyweight Squat', muscleGroup: 'Quads · Glutes', sets: 3, repMin: 12, repMax: 20, restSeconds: 60)),
  ];
  static const _chestA = <_Candidate>[
    _Candidate({EquipmentType.barbell, EquipmentType.bench, EquipmentType.squatRack}, ExercisePrescription(name: 'Barbell Bench Press', muscleGroup: 'Chest · Triceps', sets: 3, repMin: 6, repMax: 10, restSeconds: 120)),
    _Candidate({EquipmentType.dumbbells, EquipmentType.bench}, ExercisePrescription(name: 'Dumbbell Bench Press', muscleGroup: 'Chest · Triceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90)),
    _Candidate({EquipmentType.chestPressMachine}, ExercisePrescription(name: 'Machine Chest Press', muscleGroup: 'Chest · Triceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90)),
    _Candidate({EquipmentType.cableMachine}, ExercisePrescription(name: 'Standing Cable Chest Press', muscleGroup: 'Chest · Triceps', sets: 3, repMin: 10, repMax: 15, restSeconds: 75)),
    _Candidate({EquipmentType.dumbbells}, ExercisePrescription(name: 'Dumbbell Floor Press', muscleGroup: 'Chest · Triceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90)),
    _Candidate({}, ExercisePrescription(name: 'Push-up', muscleGroup: 'Chest · Triceps', sets: 3, repMin: 8, repMax: 20, restSeconds: 60)),
  ];
  static const _rowA = <_Candidate>[
    _Candidate({EquipmentType.seatedRowMachine}, ExercisePrescription(name: 'Seated Row Machine', muscleGroup: 'Back · Biceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90)),
    _Candidate({EquipmentType.cableMachine}, ExercisePrescription(name: 'Seated Cable Row', muscleGroup: 'Back · Biceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90)),
    _Candidate({EquipmentType.dumbbells}, ExercisePrescription(name: 'One-Arm Dumbbell Row', muscleGroup: 'Back · Biceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90)),
    _Candidate({EquipmentType.barbell}, ExercisePrescription(name: 'Barbell Row', muscleGroup: 'Back · Biceps', sets: 3, repMin: 6, repMax: 10, restSeconds: 105)),
    _Candidate({EquipmentType.resistanceBands}, ExercisePrescription(name: 'Resistance Band Row', muscleGroup: 'Back · Biceps', sets: 3, repMin: 10, repMax: 15, restSeconds: 75)),
    _Candidate({}, ExercisePrescription(name: 'Prone Reverse Snow Angel', muscleGroup: 'Upper Back', sets: 3, repMin: 10, repMax: 15, restSeconds: 60)),
  ];
  static const _hingeA = <_Candidate>[
    _Candidate({EquipmentType.barbell}, ExercisePrescription(name: 'Barbell Romanian Deadlift', muscleGroup: 'Hamstrings · Glutes', sets: 3, repMin: 6, repMax: 10, restSeconds: 120)),
    _Candidate({EquipmentType.dumbbells}, ExercisePrescription(name: 'Dumbbell Romanian Deadlift', muscleGroup: 'Hamstrings · Glutes', sets: 3, repMin: 8, repMax: 12, restSeconds: 105)),
    _Candidate({EquipmentType.kettlebell}, ExercisePrescription(name: 'Kettlebell Romanian Deadlift', muscleGroup: 'Hamstrings · Glutes', sets: 3, repMin: 8, repMax: 12, restSeconds: 90)),
    _Candidate({EquipmentType.legCurl}, ExercisePrescription(name: 'Leg Curl Machine', muscleGroup: 'Hamstrings', sets: 3, repMin: 10, repMax: 15, restSeconds: 75)),
    _Candidate({EquipmentType.resistanceBands}, ExercisePrescription(name: 'Band Good Morning', muscleGroup: 'Hamstrings · Glutes', sets: 3, repMin: 10, repMax: 15, restSeconds: 75)),
    _Candidate({}, ExercisePrescription(name: 'Glute Bridge', muscleGroup: 'Hamstrings · Glutes', sets: 3, repMin: 12, repMax: 20, restSeconds: 60)),
  ];
  static const _shoulderA = <_Candidate>[
    _Candidate({EquipmentType.dumbbells}, ExercisePrescription(name: 'Dumbbell Shoulder Press', muscleGroup: 'Shoulders · Triceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90)),
    _Candidate({EquipmentType.shoulderPressMachine}, ExercisePrescription(name: 'Shoulder Press Machine', muscleGroup: 'Shoulders · Triceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90)),
    _Candidate({EquipmentType.barbell}, ExercisePrescription(name: 'Barbell Overhead Press', muscleGroup: 'Shoulders · Triceps', sets: 3, repMin: 6, repMax: 10, restSeconds: 105)),
    _Candidate({EquipmentType.cableMachine}, ExercisePrescription(name: 'Cable Lateral Raise', muscleGroup: 'Shoulders', sets: 3, repMin: 12, repMax: 15, restSeconds: 60)),
    _Candidate({EquipmentType.resistanceBands}, ExercisePrescription(name: 'Band Shoulder Press', muscleGroup: 'Shoulders · Triceps', sets: 3, repMin: 10, repMax: 15, restSeconds: 75)),
    _Candidate({}, ExercisePrescription(name: 'Pike Push-up', muscleGroup: 'Shoulders · Triceps', sets: 3, repMin: 6, repMax: 12, restSeconds: 60)),
  ];
  static const _coreA = <_Candidate>[
    _Candidate({EquipmentType.cableMachine}, ExercisePrescription(name: 'Cable Crunch', muscleGroup: 'Core', sets: 2, repMin: 10, repMax: 15, restSeconds: 60)),
    _Candidate({}, ExercisePrescription(name: 'Plank', muscleGroup: 'Core', sets: 2, repMin: null, repMax: null, restSeconds: 45)),
  ];
  static const _squatB = <_Candidate>[
    _Candidate({EquipmentType.legExtension}, ExercisePrescription(name: 'Leg Extension', muscleGroup: 'Quads', sets: 3, repMin: 10, repMax: 15, restSeconds: 75)),
    _Candidate({EquipmentType.dumbbells}, ExercisePrescription(name: 'Dumbbell Reverse Lunge', muscleGroup: 'Quads · Glutes', sets: 3, repMin: 8, repMax: 12, restSeconds: 90)),
    _Candidate({EquipmentType.kettlebell}, ExercisePrescription(name: 'Kettlebell Reverse Lunge', muscleGroup: 'Quads · Glutes', sets: 3, repMin: 8, repMax: 12, restSeconds: 90)),
    _Candidate({EquipmentType.resistanceBands}, ExercisePrescription(name: 'Band Split Squat', muscleGroup: 'Quads · Glutes', sets: 3, repMin: 10, repMax: 15, restSeconds: 75)),
    _Candidate({}, ExercisePrescription(name: 'Reverse Lunge', muscleGroup: 'Quads · Glutes', sets: 3, repMin: 10, repMax: 15, restSeconds: 60)),
  ];
  static const _pullB = <_Candidate>[
    _Candidate({EquipmentType.latPulldownMachine}, ExercisePrescription(name: 'Lat Pulldown Machine', muscleGroup: 'Back · Biceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90)),
    _Candidate({EquipmentType.pullUpBar}, ExercisePrescription(name: 'Pull-up / Assisted Pull-up', muscleGroup: 'Back · Biceps', sets: 3, repMin: 5, repMax: 10, restSeconds: 105)),
    _Candidate({EquipmentType.cableMachine}, ExercisePrescription(name: 'Cable Lat Pulldown', muscleGroup: 'Back · Biceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90)),
    _Candidate({EquipmentType.dumbbells, EquipmentType.bench}, ExercisePrescription(name: 'Dumbbell Pullover on Bench', muscleGroup: 'Lats · Chest', sets: 3, repMin: 10, repMax: 15, restSeconds: 75)),
    _Candidate({EquipmentType.resistanceBands}, ExercisePrescription(name: 'Band Lat Pulldown', muscleGroup: 'Back · Biceps', sets: 3, repMin: 10, repMax: 15, restSeconds: 75)),
    _Candidate({}, ExercisePrescription(name: 'Prone Lat Sweep', muscleGroup: 'Back', sets: 3, repMin: 10, repMax: 15, restSeconds: 60)),
  ];
  static const _chestB = <_Candidate>[
    _Candidate({EquipmentType.dumbbells, EquipmentType.bench}, ExercisePrescription(name: 'Incline Dumbbell Bench Press', muscleGroup: 'Chest · Triceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90)),
    _Candidate({EquipmentType.chestPressMachine}, ExercisePrescription(name: 'Machine Chest Press', muscleGroup: 'Chest · Triceps', sets: 3, repMin: 10, repMax: 15, restSeconds: 90)),
    _Candidate({EquipmentType.pecDeck}, ExercisePrescription(name: 'Pec Deck', muscleGroup: 'Chest', sets: 3, repMin: 10, repMax: 15, restSeconds: 60)),
    _Candidate({EquipmentType.resistanceBands}, ExercisePrescription(name: 'Band Chest Press', muscleGroup: 'Chest · Triceps', sets: 3, repMin: 10, repMax: 15, restSeconds: 75)),
    _Candidate({}, ExercisePrescription(name: 'Push-up', muscleGroup: 'Chest · Triceps', sets: 3, repMin: 8, repMax: 20, restSeconds: 60)),
  ];
  static const _hingeB = <_Candidate>[
    _Candidate({EquipmentType.legCurl}, ExercisePrescription(name: 'Leg Curl Machine', muscleGroup: 'Hamstrings', sets: 3, repMin: 10, repMax: 15, restSeconds: 75)),
    _Candidate({EquipmentType.dumbbells}, ExercisePrescription(name: 'Dumbbell Romanian Deadlift', muscleGroup: 'Hamstrings · Glutes', sets: 3, repMin: 8, repMax: 12, restSeconds: 105)),
    _Candidate({EquipmentType.barbell}, ExercisePrescription(name: 'Barbell Romanian Deadlift', muscleGroup: 'Hamstrings · Glutes', sets: 3, repMin: 6, repMax: 10, restSeconds: 120)),
    _Candidate({EquipmentType.resistanceBands}, ExercisePrescription(name: 'Band Leg Curl', muscleGroup: 'Hamstrings', sets: 3, repMin: 12, repMax: 20, restSeconds: 60)),
    _Candidate({}, ExercisePrescription(name: 'Single-Leg Glute Bridge', muscleGroup: 'Hamstrings · Glutes', sets: 3, repMin: 10, repMax: 15, restSeconds: 60)),
  ];
  static const _accessoryB = <_Candidate>[
    _Candidate({EquipmentType.cableMachine}, ExercisePrescription(name: 'Cable Curl', muscleGroup: 'Biceps', sets: 2, repMin: 10, repMax: 15, restSeconds: 60)),
    _Candidate({EquipmentType.dumbbells}, ExercisePrescription(name: 'Dumbbell Curl', muscleGroup: 'Biceps', sets: 2, repMin: 10, repMax: 15, restSeconds: 60)),
    _Candidate({EquipmentType.barbell}, ExercisePrescription(name: 'Barbell Curl', muscleGroup: 'Biceps', sets: 2, repMin: 8, repMax: 12, restSeconds: 60)),
    _Candidate({EquipmentType.resistanceBands}, ExercisePrescription(name: 'Band Curl', muscleGroup: 'Biceps', sets: 2, repMin: 12, repMax: 20, restSeconds: 45)),
    _Candidate({}, ExercisePrescription(name: 'Side Plank', muscleGroup: 'Core', sets: 2, repMin: null, repMax: null, restSeconds: 45)),
  ];
  static const _coreB = <_Candidate>[
    _Candidate({}, ExercisePrescription(name: 'Dead Bug', muscleGroup: 'Core', sets: 2, repMin: 8, repMax: 12, restSeconds: 45)),
  ];
  static const _singleLegC = <_Candidate>[
    _Candidate({EquipmentType.dumbbells, EquipmentType.bench}, ExercisePrescription(name: 'Dumbbell Bulgarian Split Squat', muscleGroup: 'Quads · Glutes', sets: 3, repMin: 8, repMax: 12, restSeconds: 90)),
    _Candidate({EquipmentType.dumbbells}, ExercisePrescription(name: 'Dumbbell Split Squat', muscleGroup: 'Quads · Glutes', sets: 3, repMin: 8, repMax: 12, restSeconds: 90)),
    _Candidate({EquipmentType.kettlebell}, ExercisePrescription(name: 'Kettlebell Split Squat', muscleGroup: 'Quads · Glutes', sets: 3, repMin: 8, repMax: 12, restSeconds: 90)),
    _Candidate({EquipmentType.legPress}, ExercisePrescription(name: 'Single-Leg Press', muscleGroup: 'Quads · Glutes', sets: 3, repMin: 10, repMax: 15, restSeconds: 90)),
    _Candidate({}, ExercisePrescription(name: 'Bulgarian Split Squat', muscleGroup: 'Quads · Glutes', sets: 3, repMin: 8, repMax: 15, restSeconds: 60)),
  ];
  static const _chestC = <_Candidate>[
    _Candidate({EquipmentType.dumbbells}, ExercisePrescription(name: 'Dumbbell Floor Press', muscleGroup: 'Chest · Triceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90)),
    _Candidate({EquipmentType.chestPressMachine}, ExercisePrescription(name: 'Machine Chest Press', muscleGroup: 'Chest · Triceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90)),
    _Candidate({EquipmentType.cableMachine}, ExercisePrescription(name: 'Cable Fly', muscleGroup: 'Chest', sets: 3, repMin: 10, repMax: 15, restSeconds: 60)),
    _Candidate({}, ExercisePrescription(name: 'Close-Grip Push-up', muscleGroup: 'Chest · Triceps', sets: 3, repMin: 8, repMax: 20, restSeconds: 60)),
  ];
  static const _rowC = <_Candidate>[
    _Candidate({EquipmentType.dumbbells, EquipmentType.bench}, ExercisePrescription(name: 'Chest-Supported Dumbbell Row', muscleGroup: 'Back · Biceps', sets: 3, repMin: 8, repMax: 12, restSeconds: 90)),
    _Candidate({EquipmentType.seatedRowMachine}, ExercisePrescription(name: 'Seated Row Machine', muscleGroup: 'Back · Biceps', sets: 3, repMin: 10, repMax: 15, restSeconds: 90)),
    _Candidate({EquipmentType.cableMachine}, ExercisePrescription(name: 'Cable Row', muscleGroup: 'Back · Biceps', sets: 3, repMin: 10, repMax: 15, restSeconds: 90)),
    _Candidate({EquipmentType.resistanceBands}, ExercisePrescription(name: 'Resistance Band Row', muscleGroup: 'Back · Biceps', sets: 3, repMin: 12, repMax: 20, restSeconds: 60)),
    _Candidate({}, ExercisePrescription(name: 'Prone Reverse Snow Angel', muscleGroup: 'Upper Back', sets: 3, repMin: 10, repMax: 15, restSeconds: 60)),
  ];
  static const _gluteC = <_Candidate>[
    _Candidate({EquipmentType.dumbbells, EquipmentType.bench}, ExercisePrescription(name: 'Dumbbell Hip Thrust on Bench', muscleGroup: 'Glutes', sets: 3, repMin: 10, repMax: 15, restSeconds: 90)),
    _Candidate({EquipmentType.cableMachine}, ExercisePrescription(name: 'Cable Pull-Through', muscleGroup: 'Glutes · Hamstrings', sets: 3, repMin: 10, repMax: 15, restSeconds: 75)),
    _Candidate({EquipmentType.hipAbductionMachine}, ExercisePrescription(name: 'Hip Abduction Machine', muscleGroup: 'Glutes', sets: 3, repMin: 12, repMax: 20, restSeconds: 60)),
    _Candidate({EquipmentType.resistanceBands}, ExercisePrescription(name: 'Band Glute Bridge', muscleGroup: 'Glutes', sets: 3, repMin: 12, repMax: 20, restSeconds: 60)),
    _Candidate({}, ExercisePrescription(name: 'Glute Bridge', muscleGroup: 'Glutes', sets: 3, repMin: 12, repMax: 20, restSeconds: 60)),
  ];
  static const _armsC = <_Candidate>[
    _Candidate({EquipmentType.cableMachine}, ExercisePrescription(name: 'Cable Triceps Pressdown', muscleGroup: 'Triceps', sets: 2, repMin: 10, repMax: 15, restSeconds: 60)),
    _Candidate({EquipmentType.dumbbells}, ExercisePrescription(name: 'Dumbbell Curl + Overhead Triceps Extension', muscleGroup: 'Arms', sets: 2, repMin: 10, repMax: 15, restSeconds: 60)),
    _Candidate({EquipmentType.resistanceBands}, ExercisePrescription(name: 'Band Curl + Pressdown', muscleGroup: 'Arms', sets: 2, repMin: 12, repMax: 20, restSeconds: 45)),
    _Candidate({}, ExercisePrescription(name: 'Diamond Push-up', muscleGroup: 'Triceps · Chest', sets: 2, repMin: 6, repMax: 15, restSeconds: 60)),
  ];
  static const _calfCoreC = <_Candidate>[
    _Candidate({EquipmentType.calfRaiseMachine}, ExercisePrescription(name: 'Calf Raise Machine', muscleGroup: 'Calves', sets: 3, repMin: 12, repMax: 20, restSeconds: 60)),
    _Candidate({EquipmentType.dumbbells}, ExercisePrescription(name: 'Standing Dumbbell Calf Raise', muscleGroup: 'Calves', sets: 3, repMin: 12, repMax: 20, restSeconds: 60)),
    _Candidate({}, ExercisePrescription(name: 'Side Plank', muscleGroup: 'Core', sets: 2, repMin: null, repMax: null, restSeconds: 45)),
  ];
}

class _Candidate {
  const _Candidate(this.requires, this.exercise);
  final Set<EquipmentType> requires;
  final ExercisePrescription exercise;
}
