import 'package:flutter_test/flutter_test.dart';
import 'package:consistifit/models/models.dart';
import 'package:consistifit/services/workout_engine.dart';

void main() {
  const engine = WorkoutEngine();

  test('double progression only adds load after all sets hit top reps', () {
    expect(engine.recommendedLoad(currentLoad: 50, completedReps: const <int>[12, 12, 12], repMax: 12, formControlled: true), 55);
    expect(engine.recommendedLoad(currentLoad: 50, completedReps: const <int>[12, 11, 12], repMax: 12, formControlled: true), 50);
    expect(engine.recommendedLoad(currentLoad: 50, completedReps: const <int>[12, 12, 12], repMax: 12, formControlled: false), 50);
  });

  test('too hard session reduces accessory volume and increases rest', () {
    const prescription = ExercisePrescription(name: 'Lateral Raise', muscleGroup: 'Shoulders', sets: 3, repMin: 12, repMax: 15, restSeconds: 60);
    final adapted = engine.adaptPrescription(prescription, SessionDifficulty.tooHard);
    expect(adapted.sets, 2);
    expect(adapted.restSeconds, 75);
  });

  test('rank thresholds and weekly consistency behave as designed', () {
    expect(engine.rankFromRp(1742), 'Gold II');
    expect(engine.nextRank(1742)?.label, 'Gold I');
    expect(engine.weeklyRankAdjustment(100), 50);
    expect(engine.weeklyRankAdjustment(85), 0);
    expect(engine.weeklyRankAdjustment(70), -25);
    expect(engine.weeklyRankAdjustment(40), -50);
  });

  test('account level is permanent xp based', () {
    expect(engine.accountLevel(0), 1);
    expect(engine.accountLevel(999), 1);
    expect(engine.accountLevel(1000), 2);
    expect(engine.accountLevel(4240), 5);
  });
}
