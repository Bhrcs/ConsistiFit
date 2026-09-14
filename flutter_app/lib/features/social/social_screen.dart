import 'package:flutter/material.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});
  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final List<Map<String, String>> squads = <Map<String, String>>[
    <String, String>{'name': 'Weekend Warriors', 'description': 'Local preview squad'},
  ];
  final List<Map<String, String>> challenges = <Map<String, String>>[
    <String, String>{'name': '5-Day Consistency', 'description': 'Complete your planned days this week'},
  ];

  Future<void> _findPeople() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Friends coming later'),
        content: const Text('Online profiles and friend requests are intentionally disabled for now. This screen stays as a local feature preview until a backend is added.'),
        actions: <Widget>[TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _createSquad() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create local squad'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Squad name')),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Create')),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    setState(() => squads.add(<String, String>{'name': name, 'description': 'Local preview squad'}));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Friends & Squads')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Text('SOCIAL', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
            const Text('Consistency is easier together.', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const Text('This is a local-only preview. Online friends, squads and challenges can be connected later.', style: TextStyle(color: Colors.white60)),
            const SizedBox(height: 20),
            Row(children: <Widget>[
              Expanded(child: OutlinedButton.icon(onPressed: _findPeople, icon: const Icon(Icons.person_add), label: const Text('Find friends'))),
              const SizedBox(width: 10),
              Expanded(child: FilledButton.icon(onPressed: _createSquad, icon: const Icon(Icons.groups), label: const Text('Create squad'))),
            ]),
            const SizedBox(height: 24),
            const Text('SQUADS', style: TextStyle(fontWeight: FontWeight.w900)),
            for (final squad in squads)
              ListTile(contentPadding: EdgeInsets.zero, leading: const CircleAvatar(child: Icon(Icons.groups)), title: Text(squad['name']!), subtitle: Text(squad['description']!)),
            const SizedBox(height: 20),
            const Text('CHALLENGE PREVIEW', style: TextStyle(fontWeight: FontWeight.w900)),
            for (final challenge in challenges)
              ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.flag_outlined), title: Text(challenge['name']!), subtitle: Text(challenge['description']!)),
          ],
        ),
      );
}
