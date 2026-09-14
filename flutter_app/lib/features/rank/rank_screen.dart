import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/local_state_service.dart';
import '../../services/workout_engine.dart';

class RankScreen extends StatelessWidget {
  const RankScreen({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: FutureBuilder<ProfileSnapshot>(
          future: LocalStateService().profile(),
          builder: (context, snapshot) {
            final profile = snapshot.data ?? ProfileSnapshot.demo;
            final engine = const WorkoutEngine();
            final next = engine.nextRank(profile.rankPoints);
            final nextRemaining = next == null ? 0 : next.minimumRp - profile.rankPoints;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                Text('CONSISTENCY RANK', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
                Text(profile.currentRank, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
                Text(
                  next == null ? '${profile.rankPoints} RP · Highest rank reached' : '${profile.rankPoints} RP · $nextRemaining RP to ${next.label}',
                  style: const TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 18),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Rank is local prototype data for now. Account XP stays permanent, while rank can still move with consistency rules. Extra unscheduled workouts do not farm ranked rewards.'),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('RANK LADDER', style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                for (final band in WorkoutEngine.rankBands.reversed)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      profile.currentRank == band.label ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: profile.currentRank == band.label ? Theme.of(context).colorScheme.primary : null,
                    ),
                    title: Text(band.label, style: TextStyle(fontWeight: profile.currentRank == band.label ? FontWeight.w900 : FontWeight.w600)),
                    trailing: Text('${band.minimumRp} RP', style: const TextStyle(color: Colors.white60)),
                  ),
              ],
            );
          },
        ),
      );
}
