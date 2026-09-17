import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/local_state_service.dart';
import '../../services/workout_engine.dart';

class RankScreen extends StatelessWidget {
  const RankScreen({super.key});

  Future<_RankData> _load() async {
    final local = LocalStateService();
    return _RankData(profile: await local.profile(), recap: await local.weeklyRecap());
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: FutureBuilder<_RankData>(
          future: _load(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final data = snapshot.data!;
            final profile = data.profile;
            final engine = const WorkoutEngine();
            final next = engine.nextRank(profile.rankPoints);
            final currentBand = WorkoutEngine.rankBands.lastWhere(
              (band) => band.minimumRp <= profile.rankPoints,
              orElse: () => WorkoutEngine.rankBands.first,
            );
            final nextRemaining = next == null ? 0 : next.minimumRp - profile.rankPoints;
            final progress = next == null
                ? 1.0
                : ((profile.rankPoints - currentBand.minimumRp) /
                        (next.minimumRp - currentBand.minimumRp))
                    .clamp(0.0, 1.0);
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              children: <Widget>[
                Text('CONSISTENCY RANK', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
                const Text('Show up. Move up.', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -1.1)),
                const SizedBox(height: 6),
                const Text('Rank rewards following your plan—including recovery—not doing the most workouts.', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 20),
                _RankHero(
                  label: profile.currentRank,
                  rp: profile.rankPoints,
                  nextLabel: next?.label,
                  remaining: nextRemaining,
                  progress: progress,
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _Metric(value: data.recap.plannedDays == 0 ? '—' : '${((data.recap.completedDays / data.recap.plannedDays) * 100).round()}%', label: 'THIS WEEK')),
                  const SizedBox(width: 10),
                  Expanded(child: _Metric(value: '${profile.streakDays}', label: 'DAY STREAK')),
                  const SizedBox(width: 10),
                  Expanded(child: _Metric(value: 'Lv.${profile.accountLevel}', label: 'ACCOUNT')),
                ]),
                const SizedBox(height: 20),
                const Text('YOUR MOMENTUM', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .7)),
                const SizedBox(height: 10),
                Card(child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.trending_up_rounded, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('Weekly consistency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
                      Text('${data.recap.completedDays}/${data.recap.plannedDays}', style: const TextStyle(fontWeight: FontWeight.w900)),
                    ]),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: data.recap.plannedDays == 0 ? 0 : data.recap.completedDays / data.recap.plannedDays,
                      minHeight: 9,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    const SizedBox(height: 10),
                    const Text('Training and planned recovery count equally toward consistency.', style: TextStyle(color: Colors.white70)),
                  ]),
                )),
                const SizedBox(height: 20),
                const Text('RANK LADDER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .7)),
                const SizedBox(height: 10),
                Card(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Column(children: [
                    for (final band in WorkoutEngine.rankBands.reversed)
                      Container(
                        decoration: BoxDecoration(
                          color: profile.currentRank == band.label ? Theme.of(context).colorScheme.primary.withValues(alpha: .08) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          leading: Icon(
                            profile.currentRank == band.label ? Icons.diamond_rounded : Icons.circle_outlined,
                            size: profile.currentRank == band.label ? 22 : 14,
                            color: profile.currentRank == band.label ? Theme.of(context).colorScheme.primary : Colors.white24,
                          ),
                          title: Text(band.label, style: TextStyle(fontWeight: profile.currentRank == band.label ? FontWeight.w900 : FontWeight.w600)),
                          trailing: Text('${band.minimumRp} RP', style: const TextStyle(color: Colors.white60)),
                        ),
                      ),
                  ]),
                )),
                const SizedBox(height: 14),
                const Card(child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Follow the plan, not the leaderboard.', style: TextStyle(fontWeight: FontWeight.w900)),
                    SizedBox(height: 6),
                    Text('A 3-day plan and a 6-day plan can both build rank through consistency. Extra unscheduled workouts do not create extra primary RP.', style: TextStyle(color: Colors.white70)),
                  ]),
                )),
              ],
            );
          },
        ),
      );
}

class _RankHero extends StatelessWidget {
  const _RankHero({required this.label, required this.rp, required this.nextLabel, required this.remaining, required this.progress});
  final String label;
  final int rp;
  final String? nextLabel;
  final int remaining;
  final double progress;

  Color _tierColor() {
    final text = label.toLowerCase();
    if (text.contains('grandmaster')) return const Color(0xFFFF8D6F);
    if (text.contains('master')) return const Color(0xFFD39AFF);
    if (text.contains('diamond')) return const Color(0xFF8CC8FF);
    if (text.contains('platinum')) return const Color(0xFF8EF0DF);
    if (text.contains('gold')) return const Color(0xFFFFD86A);
    if (text.contains('silver')) return const Color(0xFFD5DCE3);
    if (text.contains('bronze')) return const Color(0xFFC98B52);
    return const Color(0xFF9AA49D);
  }

  @override
  Widget build(BuildContext context) {
    final tier = _tierColor();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: .09)),
        gradient: LinearGradient(colors: [tier.withValues(alpha: .16), const Color(0xFF0C0F0C)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      child: Column(children: [
        Container(
          width: 118,
          height: 118,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [tier.withValues(alpha: .24), Colors.transparent]),
          ),
          child: Center(
            child: Transform.rotate(
              angle: .785398,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(colors: [tier, tier.withValues(alpha: .42)]),
                  boxShadow: [BoxShadow(color: tier.withValues(alpha: .28), blurRadius: 28)],
                ),
                child: Transform.rotate(angle: -.785398, child: const Icon(Icons.bolt_rounded, color: Color(0xFF090B09), size: 38)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1.1)),
        Text('$rp RP', style: const TextStyle(color: Colors.white60)),
        const SizedBox(height: 18),
        LinearProgressIndicator(value: progress, minHeight: 10, borderRadius: BorderRadius.circular(99)),
        const SizedBox(height: 8),
        Text(nextLabel == null ? 'Highest rank reached' : '$remaining RP to $nextLabel', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
    decoration: BoxDecoration(color: const Color(0xFF111511), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withValues(alpha: .07))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.w800, letterSpacing: .5)),
    ]),
  );
}

class _RankData {
  const _RankData({required this.profile, required this.recap});
  final ProfileSnapshot profile;
  final WeeklyRecap recap;
}
