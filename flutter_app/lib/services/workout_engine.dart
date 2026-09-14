import '../models/models.dart';

class WorkoutEngine {
  const WorkoutEngine();

  static const rankBands = <RankBand>[
    RankBand('Iron III', 0),
    RankBand('Iron II', 50),
    RankBand('Iron I', 100),
    RankBand('Bronze III', 200),
    RankBand('Bronze II', 350),
    RankBand('Bronze I', 500),
    RankBand('Silver III', 700),
    RankBand('Silver II', 900),
    RankBand('Silver I', 1100),
    RankBand('Gold III', 1350),
    RankBand('Gold II', 1550),
    RankBand('Gold I', 1750),
    RankBand('Platinum III', 1900),
    RankBand('Platinum II', 2100),
    RankBand('Platinum I', 2300),
    RankBand('Diamond III', 2600),
    RankBand('Diamond II', 3000),
    RankBand('Diamond I', 3600),
    RankBand('Master', 4500),
    RankBand('Grandmaster', 6000),
  ];

  double recommendedLoad({
    required double currentLoad,
    required List<int> completedReps,
    required int repMax,
    required bool formControlled,
    double increment = 5,
  }) {
    if (!formControlled || completedReps.isEmpty) return currentLoad;
    final reachedTop = completedReps.every((reps) => reps >= repMax);
    return reachedTop ? currentLoad + increment : currentLoad;
  }

  ExercisePrescription adaptPrescription(
    ExercisePrescription planned,
    SessionDifficulty difficulty,
  ) {
    if (difficulty == SessionDifficulty.tooHard) {
      return planned.copyWith(
        sets: planned.sets > 1 ? planned.sets - 1 : 1,
        restSeconds: planned.restSeconds + 15,
      );
    }
    if (difficulty == SessionDifficulty.hard) {
      return planned.copyWith(restSeconds: planned.restSeconds + 15);
    }
    return planned;
  }

  int adjustedAccessorySets(SessionDifficulty difficulty, int plannedSets) {
    if (difficulty != SessionDifficulty.tooHard) return plannedSets;
    return plannedSets > 1 ? plannedSets - 1 : 1;
  }

  List<String> reflowAfterMiss({
    required List<String> remainingWorkouts,
    required int missedCount,
  }) {
    if (missedCount <= 1) return remainingWorkouts;
    return remainingWorkouts.take(3).toList(growable: false);
  }

  double sessionVolume(Iterable<LoggedSet> sets) => sets
      .where((set) => set.completed)
      .fold<double>(0, (total, set) => total + set.weight * set.reps);

  int accountLevel(int accountXp) => 1 + (accountXp ~/ 1000);

  String rankFromRp(int rp) {
    var current = rankBands.first.label;
    for (final band in rankBands) {
      if (rp < band.minimumRp) break;
      current = band.label;
    }
    return current;
  }

  RankBand? nextRank(int rp) {
    for (final band in rankBands) {
      if (band.minimumRp > rp) return band;
    }
    return null;
  }

  int weeklyRankAdjustment(double adherencePercent) {
    if (adherencePercent >= 100) return 50;
    if (adherencePercent >= 80) return 0;
    if (adherencePercent >= 60) return -25;
    return -50;
  }

  bool isDeloadWeek(int week) => week > 0 && week % 8 == 0;
}
