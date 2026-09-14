enum ExperienceLevel { beginner, intermediate, advanced }
enum TrainingGoal { muscle, strength, cardio, habit }
enum EquipmentLevel { bodyweight, dumbbells, fullGym }
enum SessionDifficulty { tooEasy, good, hard, tooHard }
enum ConsistencyRank { iron, bronze, silver, gold, platinum, diamond, master, grandmaster }
class ProgramPreferences {
  const ProgramPreferences({required this.goal, required this.experience, required this.equipment, required this.daysPerWeek, required this.sessionMinutes});
  final TrainingGoal goal; final ExperienceLevel experience; final EquipmentLevel equipment; final int daysPerWeek; final int sessionMinutes;
}
class WorkoutTemplate { const WorkoutTemplate(this.name, this.exercises); final String name; final List<String> exercises; }
class GeneratedProgram { const GeneratedProgram({required this.name, required this.split, required this.weeks, required this.workouts}); final String name; final String split; final int weeks; final List<WorkoutTemplate> workouts; }
class RewardResult { const RewardResult({required this.rp, required this.xp, required this.coins}); final int rp; final int xp; final int coins; }
