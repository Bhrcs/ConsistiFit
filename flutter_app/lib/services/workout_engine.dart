import '../models/models.dart';
class WorkoutEngine {
  const WorkoutEngine();
  int nextLoad({required int currentLoad,required int achievedReps,required int repMax,required bool formControlled}) { if(!formControlled||achievedReps<repMax)return currentLoad; return currentLoad+(currentLoad<50?5:10); }
  int adjustedAccessorySets(SessionDifficulty difficulty,int plannedSets)=>difficulty==SessionDifficulty.tooHard?(plannedSets>1?plannedSets-1:1):plannedSets;
  List<String> reflowAfterMiss({required List<String> remainingWorkouts,required int missedCount}) { if(missedCount<=1)return remainingWorkouts; return remainingWorkouts.take(3).toList(); }
}
