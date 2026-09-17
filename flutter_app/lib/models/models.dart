enum ExperienceLevel { beginner, intermediate, advanced }
enum TrainingGoal { muscle, strength, cardio, habit }
enum TrainingEnvironment { homeFreeWeights, gymMachines, custom }
enum EquipmentType {
  bodyweight,
  dumbbells,
  bench,
  barbell,
  squatRack,
  kettlebell,
  resistanceBands,
  pullUpBar,
  cableMachine,
  legPress,
  legExtension,
  legCurl,
  chestPressMachine,
  shoulderPressMachine,
  seatedRowMachine,
  latPulldownMachine,
  pecDeck,
  hipAbductionMachine,
  calfRaiseMachine,
  cardioMachine,
}
enum SessionDifficulty { tooEasy, good, hard, tooHard }
enum ConsistencyRank { iron, bronze, silver, gold, platinum, diamond, master, grandmaster }
enum WorkoutKind { strength, cardio, recovery }
enum ProgramDayKind { training, recovery }

class ProgramPreferences {
  const ProgramPreferences({
    required this.goal,
    required this.experience,
    required this.environment,
    required this.daysPerWeek,
    required this.sessionMinutes,
    this.customEquipment = const <EquipmentType>{},
  });

  final TrainingGoal goal;
  final ExperienceLevel experience;
  final TrainingEnvironment environment;
  final int daysPerWeek;
  final int sessionMinutes;
  final Set<EquipmentType> customEquipment;

  static const homeDefault = ProgramPreferences(
    goal: TrainingGoal.muscle,
    experience: ExperienceLevel.beginner,
    environment: TrainingEnvironment.homeFreeWeights,
    daysPerWeek: 3,
    sessionMinutes: 45,
  );

  Set<EquipmentType> get availableEquipment => switch (environment) {
        TrainingEnvironment.homeFreeWeights => const <EquipmentType>{
            EquipmentType.bodyweight,
            EquipmentType.dumbbells,
            EquipmentType.bench,
          },
        TrainingEnvironment.gymMachines => const <EquipmentType>{
            EquipmentType.bodyweight,
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
          },
        TrainingEnvironment.custom => <EquipmentType>{
            EquipmentType.bodyweight,
            ...customEquipment,
          },
      };

  Map<String, dynamic> toJson() => <String, dynamic>{
        'goal': goal.name,
        'experience': experience.name,
        'environment': environment.name,
        'daysPerWeek': daysPerWeek,
        'sessionMinutes': sessionMinutes,
        'customEquipment': customEquipment.map((item) => item.name).toList(growable: false),
      };

  factory ProgramPreferences.fromJson(Map<String, dynamic> json) {
    T enumValue<T extends Enum>(List<T> values, String? name, T fallback) {
      for (final value in values) {
        if (value.name == name) return value;
      }
      return fallback;
    }

    final equipmentNames = (json['customEquipment'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<String>()
        .toSet();
    return ProgramPreferences(
      goal: enumValue(TrainingGoal.values, json['goal'] as String?, TrainingGoal.muscle),
      experience: enumValue(ExperienceLevel.values, json['experience'] as String?, ExperienceLevel.beginner),
      environment: enumValue(
        TrainingEnvironment.values,
        json['environment'] as String?,
        TrainingEnvironment.homeFreeWeights,
      ),
      daysPerWeek: (json['daysPerWeek'] as num? ?? 3).toInt().clamp(2, 6),
      sessionMinutes: (json['sessionMinutes'] as num? ?? 45).toInt().clamp(30, 75),
      customEquipment: EquipmentType.values.where((item) => equipmentNames.contains(item.name)).toSet(),
    );
  }
}

class ExercisePrescription {
  const ExercisePrescription({
    required this.name,
    required this.muscleGroup,
    required this.sets,
    required this.repMin,
    required this.repMax,
    required this.restSeconds,
    this.loadIncrement = 5,
  });

  final String name;
  final String muscleGroup;
  final int sets;
  final int? repMin;
  final int? repMax;
  final int restSeconds;
  final double loadIncrement;

  bool get isTimed => repMin == null || repMax == null;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name, 'muscleGroup': muscleGroup, 'sets': sets,
    'repMin': repMin, 'repMax': repMax, 'restSeconds': restSeconds,
    'loadIncrement': loadIncrement,
  };

  factory ExercisePrescription.fromJson(Map<String, dynamic> json) => ExercisePrescription(
    name: json['name'] as String, muscleGroup: json['muscleGroup'] as String,
    sets: (json['sets'] as num).toInt(), repMin: (json['repMin'] as num?)?.toInt(),
    repMax: (json['repMax'] as num?)?.toInt(),
    restSeconds: (json['restSeconds'] as num).toInt(),
    loadIncrement: (json['loadIncrement'] as num? ?? 5).toDouble(),
  );

  ExercisePrescription copyWith({
    int? sets,
    int? repMin,
    int? repMax,
    int? restSeconds,
    double? loadIncrement,
  }) =>
      ExercisePrescription(
        name: name,
        muscleGroup: muscleGroup,
        sets: sets ?? this.sets,
        repMin: repMin ?? this.repMin,
        repMax: repMax ?? this.repMax,
        restSeconds: restSeconds ?? this.restSeconds,
        loadIncrement: loadIncrement ?? this.loadIncrement,
      );
}

class WorkoutTemplate {
  const WorkoutTemplate({
    required this.name,
    required this.exercises,
    required this.estimatedMinutes,
    this.kind = WorkoutKind.strength,
  });

  final String name;
  final List<ExercisePrescription> exercises;
  final int estimatedMinutes;
  final WorkoutKind kind;

  int get totalSets => exercises.fold(0, (total, exercise) => total + exercise.sets);
  int get requiredCompletedSets => (totalSets * 0.7).ceil();

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name, 'estimatedMinutes': estimatedMinutes, 'kind': kind.name,
    'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
  };

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) => WorkoutTemplate(
    name: json['name'] as String,
    estimatedMinutes: (json['estimatedMinutes'] as num).toInt(),
    kind: WorkoutKind.values.firstWhere((kind) => kind.name == json['kind'], orElse: () => WorkoutKind.strength),
    exercises: (json['exercises'] as List<dynamic>)
      .map((row) => ExercisePrescription.fromJson(Map<String, dynamic>.from(row as Map))).toList(),
  );
}

class ProgramDay {
  const ProgramDay({
    required this.weekday,
    required this.kind,
    required this.label,
    this.workout,
  });

  final int weekday;
  final ProgramDayKind kind;
  final String label;
  final WorkoutTemplate? workout;
}

class GeneratedProgram {
  const GeneratedProgram({
    required this.name,
    required this.split,
    required this.weeks,
    required this.workouts,
    required this.week,
    required this.environmentLabel,
    required this.equipmentLabel,
    this.deloadWeeks = const <int>[8],
  });

  final String name;
  final String split;
  final int weeks;
  final List<WorkoutTemplate> workouts;
  final List<ProgramDay> week;
  final String environmentLabel;
  final String equipmentLabel;
  final List<int> deloadWeeks;
}

class LoggedSet {
  const LoggedSet({
    required this.exerciseName,
    required this.setNumber,
    required this.weight,
    required this.reps,
    required this.completed,
  });

  final String exerciseName;
  final int setNumber;
  final double weight;
  /// Repetitions for resistance sets; logged seconds for timed prescriptions.
  final int reps;
  final bool completed;

  LoggedSet copyWith({double? weight, int? reps, bool? completed}) => LoggedSet(
        exerciseName: exerciseName,
        setNumber: setNumber,
        weight: weight ?? this.weight,
        reps: reps ?? this.reps,
        completed: completed ?? this.completed,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'exerciseName': exerciseName,
        'setNumber': setNumber,
        'weight': weight,
        'reps': reps,
        'completed': completed,
      };

  factory LoggedSet.fromJson(Map<String, dynamic> json) => LoggedSet(
        exerciseName: json['exerciseName'] as String,
        setNumber: json['setNumber'] as int,
        weight: (json['weight'] as num).toDouble(),
        reps: json['reps'] as int,
        completed: json['completed'] as bool,
      );
}

class ProfileSnapshot {
  const ProfileSnapshot({
    required this.displayName,
    required this.accountXp,
    required this.accountLevel,
    required this.coins,
    required this.rankPoints,
    required this.currentRank,
    required this.streakDays,
    required this.longestStreak,
    required this.consistencyPercent,
  });

  final String displayName;
  final int accountXp;
  final int accountLevel;
  final int coins;
  final int rankPoints;
  final String currentRank;
  final int streakDays;
  final int longestStreak;
  final double consistencyPercent;

  static const demo = ProfileSnapshot(
    displayName: 'Athlete',
    accountXp: 4240,
    accountLevel: 5,
    coins: 1280,
    rankPoints: 1742,
    currentRank: 'Gold II',
    streakDays: 14,
    longestStreak: 22,
    consistencyPercent: 89,
  );

  factory ProfileSnapshot.fromJson(Map<String, dynamic> json) => ProfileSnapshot(
        displayName: json['display_name'] as String? ?? 'Athlete',
        accountXp: json['account_xp'] as int? ?? 0,
        accountLevel: json['account_level'] as int? ?? 1,
        coins: json['coins'] as int? ?? 0,
        rankPoints: json['rank_points'] as int? ?? 0,
        currentRank: json['current_rank'] as String? ?? 'Iron III',
        streakDays: json['streak_days'] as int? ?? 0,
        longestStreak: json['longest_streak'] as int? ?? 0,
        consistencyPercent: (json['consistency_percent'] as num? ?? 0).toDouble(),
      );
}

class RewardResult {
  const RewardResult({
    required this.rp,
    required this.xp,
    required this.coins,
    this.newRankPoints,
    this.newRank,
  });

  final int rp;
  final int xp;
  final int coins;
  final int? newRankPoints;
  final String? newRank;

  factory RewardResult.fromJson(Map<String, dynamic> json) => RewardResult(
        rp: json['rp_awarded'] as int? ?? 0,
        xp: json['xp_awarded'] as int? ?? 0,
        coins: json['coins_awarded'] as int? ?? 0,
        newRankPoints: json['new_rank_points'] as int?,
        newRank: json['new_rank'] as String?,
      );
}

class RankBand {
  const RankBand(this.label, this.minimumRp);
  final String label;
  final int minimumRp;
}

class ActiveWorkoutSession {
  const ActiveWorkoutSession({required this.id, required this.dayKey,
    required this.template, required this.startedAt, required this.plannedKind});
  final String id;
  final String dayKey;
  final WorkoutTemplate template;
  final DateTime startedAt;
  final ProgramDayKind plannedKind;
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id, 'dayKey': dayKey, 'template': template.toJson(),
    'startedAt': startedAt.toIso8601String(), 'plannedKind': plannedKind.name,
  };
  factory ActiveWorkoutSession.fromJson(Map<String, dynamic> json) => ActiveWorkoutSession(
    id: json['id'] as String, dayKey: json['dayKey'] as String,
    template: WorkoutTemplate.fromJson(Map<String, dynamic>.from(json['template'] as Map)),
    startedAt: DateTime.parse(json['startedAt'] as String),
    plannedKind: ProgramDayKind.values.byName(json['plannedKind'] as String),
  );
}

class WorkoutHistoryEntry {
  const WorkoutHistoryEntry({required this.id, required this.name, required this.dayKey,
    required this.completedAt, required this.sets, required this.difficulty,
    required this.durationSeconds, required this.rp, required this.primaryCompleted,
    this.personalRecords = 0, this.template});
  final String id;
  final String name;
  final String dayKey;
  final DateTime completedAt;
  final List<LoggedSet> sets;
  final SessionDifficulty difficulty;
  final int durationSeconds;
  final int rp;
  final bool primaryCompleted;
  final int personalRecords;
  final WorkoutTemplate? template;
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id, 'name': name, 'dayKey': dayKey, 'completedAt': completedAt.toIso8601String(),
    'sets': sets.map((set) => set.toJson()).toList(), 'difficulty': difficulty.name,
    'durationSeconds': durationSeconds, 'rp': rp, 'primaryCompleted': primaryCompleted,
    'personalRecords': personalRecords, 'template': template?.toJson(),
  };
  factory WorkoutHistoryEntry.fromJson(Map<String, dynamic> json) => WorkoutHistoryEntry(
    id: json['id'] as String, name: json['name'] as String, dayKey: json['dayKey'] as String,
    completedAt: DateTime.parse(json['completedAt'] as String),
    sets: (json['sets'] as List<dynamic>).map((set) => LoggedSet.fromJson(Map<String, dynamic>.from(set as Map))).toList(),
    difficulty: SessionDifficulty.values.byName(json['difficulty'] as String),
    durationSeconds: (json['durationSeconds'] as num).toInt(), rp: (json['rp'] as num? ?? 0).toInt(),
    primaryCompleted: json['primaryCompleted'] == true,
    personalRecords: (json['personalRecords'] as num? ?? 0).toInt(),
    template: json['template'] is Map ? WorkoutTemplate.fromJson(Map<String, dynamic>.from(json['template'] as Map)) : null,
  );
}

class WeeklyRecap {
  const WeeklyRecap({required this.plannedDays, required this.completedDays,
    required this.workouts, required this.recoveryDays, required this.rp,
    required this.personalRecords, required this.longestStreak, required this.nextWeek});
  final int plannedDays;
  final int completedDays;
  final int workouts;
  final int recoveryDays;
  final int rp;
  final int personalRecords;
  final int longestStreak;
  final List<ProgramDay> nextWeek;
  double get consistencyPercent => plannedDays == 0 ? 0 : 100 * completedDays / plannedDays;
}

class PlanAdaptationSuggestion {
  const PlanAdaptationSuggestion({required this.id, required this.title,
    required this.explanation, required this.workout});
  final String id;
  final String title;
  final String explanation;
  final WorkoutTemplate workout;
}
