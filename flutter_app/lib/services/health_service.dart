import 'package:health/health.dart';
import 'supabase_service.dart';

class HealthService {
  final Health _health = Health();

  static const readTypes = <HealthDataType>[
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.HEART_RATE,
    HealthDataType.WORKOUT,
    HealthDataType.SLEEP_ASLEEP,
  ];

  Future<void> configure() => _health.configure();

  Future<bool> requestReadAccess() => _health.requestAuthorization(readTypes);

  Future<List<HealthDataPoint>> today() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final points = await _health.getHealthDataFromTypes(types: readTypes, startTime: start, endTime: now);
    return _health.removeDuplicates(points);
  }

  Future<HealthSyncSummary> syncToday(SupabaseService backend) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final points = await today();
    final steps = await _health.getTotalStepsInInterval(start, now);
    var calories = 0.0;
    var sleepMinutes = 0;
    for (final point in points) {
      if (point.type == HealthDataType.ACTIVE_ENERGY_BURNED && point.value is NumericHealthValue) {
        calories += (point.value as NumericHealthValue).numericValue.toDouble();
      }
      if (point.type == HealthDataType.SLEEP_ASLEEP) {
        sleepMinutes += point.dateTo.difference(point.dateFrom).inMinutes;
      }
    }
    final source = points.isEmpty ? 'health' : points.first.sourcePlatform.name;
    await backend.saveHealthSnapshot(
      day: start,
      steps: steps,
      activeCalories: calories,
      sleepMinutes: sleepMinutes,
      source: source,
    );
    return HealthSyncSummary(steps: steps ?? 0, activeCalories: calories, sleepMinutes: sleepMinutes, dataPoints: points.length);
  }
}

class HealthSyncSummary {
  const HealthSyncSummary({required this.steps, required this.activeCalories, required this.sleepMinutes, required this.dataPoints});
  final int steps;
  final double activeCalories;
  final int sleepMinutes;
  final int dataPoints;
}
