import 'package:flutter/material.dart';
import '../../core/config/env.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final backend = SupabaseService();
  late Future<List<Map<String, dynamic>>> items;
  late Future<ProfileSnapshot?> profile;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    items = backend.shopItems();
    profile = backend.profile();
  }

  Future<void> _buy(String code) async {
    if (!Env.hasSupabase) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connect Supabase to make server-validated Coin purchases.')));
      return;
    }
    try {
      final remaining = await backend.purchaseShopItem(code);
      if (!mounted) return;
      setState(_refresh);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Purchased · ${remaining ?? 0} Coins remaining')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Rewards')),
        body: RefreshIndicator(
          onRefresh: () async => setState(_refresh),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Text('COIN SHOP', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
              FutureBuilder<ProfileSnapshot?>(
                future: profile,
                builder: (context, snapshot) => Text('${(snapshot.data ?? ProfileSnapshot.demo).coins} Coins', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
              ),
              const Text('Coins can unlock cosmetics and utilities. RP and rank are never for sale.', style: TextStyle(color: Colors.white60)),
              const SizedBox(height: 20),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: items,
                builder: (context, snapshot) {
                  final rows = snapshot.data ?? const <Map<String, dynamic>>[];
                  if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
                  if (rows.isEmpty) {
                    return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Connect the backend to load the live store catalog.')));
                  }
                  return Column(
                    children: <Widget>[
                      for (final item in rows)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.redeem),
                            title: Text(item['name'] as String? ?? 'Reward', style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text(item['description'] as String? ?? ''),
                            trailing: FilledButton(
                              onPressed: () => _buy(item['code'] as String),
                              child: Text('${item['coin_price']}'),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );
}
