enum ExperienceLevel { beginner, intermediate, advanced }
enum TrainingGoal { muscle, strength, cardio, habit }
enum EquipmentLevel { bodyweight, dumbbells, fullGym }
enum SessionDifficulty { tooEasy, good, hard, tooHard }
enum ConsistencyRank { iron, bronze, silver, gold, platinum, diamond, master, grandmaster }
enum WorkoutKind { strength, cardio, recovery }
enum ProgramDayKind { training, recovery }

class ProgramPreferences {
  const ProgramPreferences({
    required this.goal,
    required this.experience,
    required this.equipment,
    required this.daysPerWeek,
    required this.sessionMinutes,
  });

  final TrainingGoal goal;
  final ExperienceLevel experience;
  final EquipmentLevel equipment;
  final int daysPerWeek;
  final int sessionMinutes;
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
    this.deloadWeeks = const <int>[8],
  });

  final String name;
  final String split;
  final int weeks;
  final List<WorkoutTemplate> workouts;
  final List<ProgramDay> week;
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
