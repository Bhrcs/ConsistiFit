import 'package:flutter/material.dart';
import '../../services/social_repository.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final repository = SocialRepository();
  late Future<List<Map<String, dynamic>>> feed;
  late Future<List<Map<String, dynamic>>> squads;
  late Future<List<Map<String, dynamic>>> challenges;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    feed = repository.activityFeed();
    squads = repository.squads();
    challenges = repository.challenges();
  }

  Future<void> _findPeople() async {
    final controller = TextEditingController();
    List<Map<String, dynamic>> results = const <Map<String, dynamic>>[];
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Find athletes'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: 'Display name'),
                  onSubmitted: (_) async {
                    final rows = await repository.searchProfiles(controller.text);
                    setDialogState(() => results = rows);
                  },
                ),
                const SizedBox(height: 12),
                if (results.isEmpty)
                  const Text('Enter at least two characters and search.', style: TextStyle(color: Colors.white60))
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: <Widget>[
                        for (final person in results)
                          ListTile(
                            title: Text(person['display_name'] as String? ?? 'Athlete'),
                            subtitle: Text('${person['current_rank'] ?? 'Iron III'} · ${person['streak_days'] ?? 0} day streak'),
                            trailing: IconButton(
                              icon: const Icon(Icons.person_add_alt_1),
                              onPressed: () async {
                                await repository.sendFriendRequest(person['user_id'] as String);
                                if (dialogContext.mounted) Navigator.pop(dialogContext);
                                if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Friend request sent.')));
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                final rows = await repository.searchProfiles(controller.text);
                setDialogState(() => results = rows);
              },
              child: const Text('Search'),
            ),
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  Future<void> _createSquad() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create squad'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Squad name')),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Create')),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    await repository.createSquad(name);
    if (mounted) setState(_refresh);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Friends & Squads'),
          actions: <Widget>[
            IconButton(onPressed: _findPeople, icon: const Icon(Icons.person_search), tooltip: 'Find athletes'),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async => setState(_refresh),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Text('SOCIAL', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
              const Text('Consistency is easier together.', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              const Text('Friends, squads and challenges never change ranked rewards directly.', style: TextStyle(color: Colors.white60)),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(child: OutlinedButton.icon(onPressed: _findPeople, icon: const Icon(Icons.person_add), label: const Text('Find friends'))),
                  const SizedBox(width: 10),
                  Expanded(child: FilledButton.icon(onPressed: _createSquad, icon: const Icon(Icons.groups), label: const Text('Create squad'))),
                ],
              ),
              const SizedBox(height: 24),
              const Text('SQUADS', style: TextStyle(fontWeight: FontWeight.w900)),
              _FutureRows(
                future: squads,
                emptyText: 'No squads yet.',
                builder: (row) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.groups)),
                  title: Text(row['name'] as String? ?? 'Squad'),
                  subtitle: Text(row['description'] as String? ?? 'Consistency squad'),
                  trailing: TextButton(onPressed: () => repository.joinSquad(row['id'] as String), child: const Text('Join')),
                ),
              ),
              const SizedBox(height: 20),
              const Text('ACTIVE CHALLENGES', style: TextStyle(fontWeight: FontWeight.w900)),
              _FutureRows(
                future: challenges,
                emptyText: 'No active challenges yet.',
                builder: (row) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.flag_outlined),
                  title: Text(row['name'] as String? ?? 'Challenge'),
                  subtitle: Text('${row['metric'] ?? 'consistency'} · target ${row['target'] ?? ''}'),
                  trailing: TextButton(onPressed: () => repository.joinChallenge(row['id'] as String), child: const Text('Join')),
                ),
              ),
              const SizedBox(height: 20),
              const Text('ACTIVITY', style: TextStyle(fontWeight: FontWeight.w900)),
              _FutureRows(
                future: feed,
                emptyText: 'Friend workout activity will appear here.',
                builder: (row) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.bolt),
                  title: Text((row['event_type'] as String? ?? 'activity').replaceAll('_', ' ')),
                  subtitle: Text('${row['payload'] ?? const <String, dynamic>{}}'),
                ),
              ),
            ],
          ),
        ),
      );
}

class _FutureRows extends StatelessWidget {
  const _FutureRows({required this.future, required this.emptyText, required this.builder});
  final Future<List<Map<String, dynamic>>> future;
  final String emptyText;
  final Widget Function(Map<String, dynamic>) builder;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
          if (snapshot.hasError) return Text('Connect the backend to load this section.', style: TextStyle(color: Theme.of(context).colorScheme.error));
          final rows = snapshot.data ?? const <Map<String, dynamic>>[];
          if (rows.isEmpty) return Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(emptyText, style: const TextStyle(color: Colors.white60)));
          return Column(children: rows.map(builder).toList(growable: false));
        },
      );
}
