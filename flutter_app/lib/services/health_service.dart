import 'package:health/health.dart';
class HealthService {
  final Health _health=Health();
  static const readTypes=<HealthDataType>[HealthDataType.STEPS,HealthDataType.ACTIVE_ENERGY_BURNED,HealthDataType.HEART_RATE,HealthDataType.WORKOUT,HealthDataType.SLEEP_ASLEEP];
  Future<void> configure()=>_health.configure();
  Future<bool> requestReadAccess()=>_health.requestAuthorization(readTypes);
  Future<List<HealthDataPoint>> today() async { final now=DateTime.now(); final start=DateTime(now.year,now.month,now.day); return _health.getHealthDataFromTypes(types:readTypes,startTime:start,endTime:now); }
}
