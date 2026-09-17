import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/local_state_service.dart';
import 'weekly_recap_card.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(child: FutureBuilder<WeeklyRecap>(
    future: LocalStateService().weeklyRecap(),
    builder: (context, snapshot) {
      if (snapshot.hasError) return const Center(child: Text('Your recap could not be loaded. Please reopen Progress.'));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      return ListView(padding: const EdgeInsets.all(20), children: [
        Text('PROGRESS', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
        const Text('Every planned day counts', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('Workouts and intentional recovery build the same habit. Your recap uses activity saved on this device.', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 20),
        WeeklyRecapCard(recap: snapshot.data!, showSchedule: true),
      ]);
    },
  ));
}
