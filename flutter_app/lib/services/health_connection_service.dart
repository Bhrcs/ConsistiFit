import '../models/models.dart';
import 'health_service.dart';
import 'local_state_service.dart';

class HealthConnectionResult {
  const HealthConnectionResult({
    required this.summary,
    required this.stepReward,
  });

  final HealthSyncSummary summary;
  final RewardResult? stepReward;
}

class HealthConnectionService {
  HealthConnectionService({HealthService? health, LocalStateService? state})
      : _health = health ?? HealthService(),
        _state = state ?? LocalStateService();

  final HealthService _health;
  final LocalStateService _state;

  Future<bool> isConnected() => _state.healthConnected();

  Future<HealthConnectionResult?> connect() async {
    await _health.configure();
    final granted = await _health.requestReadAccess();
    if (!granted) return null;
    await _state.setHealthConnected(true);
    return syncNow();
  }

  Future<void> disconnect() => _state.setHealthConnected(false);

  Future<HealthConnectionResult?> syncIfConnected() async {
    if (!await isConnected()) return null;
    return syncNow();
  }

  Future<HealthConnectionResult> syncNow() async {
    await _health.configure();
    final summary = await _health.syncToday();
    final reward = await _state.applyHealthProgress(
      steps: summary.steps,
      activeCalories: summary.activeCalories,
      sleepMinutes: summary.sleepMinutes,
    );
    return HealthConnectionResult(summary: summary, stepReward: reward);
  }
}
