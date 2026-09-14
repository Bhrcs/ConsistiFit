import 'package:flutter_test/flutter_test.dart';
import 'package:consistifit/models/models.dart';
import 'package:consistifit/services/program_generator.dart';
void main(){test('beginner muscle defaults to foundation',(){final p=const ProgramGenerator().generate(const ProgramPreferences(goal:TrainingGoal.muscle,experience:ExperienceLevel.beginner,equipment:EquipmentLevel.fullGym,daysPerWeek:3,sessionMinutes:45));expect(p.name,'ConsistiFit Foundation');expect(p.workouts.length,3);});}
