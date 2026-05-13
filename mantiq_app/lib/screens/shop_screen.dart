import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ShopScreen extends StatefulWidget {
  final int userId;
  const ShopScreen({super.key, required this.userId});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<dynamic> _items     = [];
  List<dynamic> _inventory = [];
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await ApiService.getShopItems();
    final inv   = await ApiService.getInventory(widget.userId);
    final prof  = await ApiService.getUser(widget.userId);
    setState(() { _items = items; _inventory = inv; _profile = prof; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          if (_profile != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(children: [
                const Icon(Icons.monetization_on_rounded, color: AppColors.warning, size: 18),
                const SizedBox(width: 4),
                Text('${_profile!['coins']}',
                    style: const TextStyle(
                        color: AppColors.warning, fontWeight: FontWeight.w800, fontSize: 16)),
              ]),
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [Tab(text: 'Shop'), Tab(text: 'Inventar')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabs,
              children: [_buildShop(), _buildInventory()],
            ),
    );
  }

  Widget _buildShop() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final item = _items[i];
          final coins = _profile?['coins'] ?? 0;
          final kannKaufen = coins >= (item['cost'] as int);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              Text(_itemEmoji(item['itemType']),
                  style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['name'],
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.text, fontSize: 15)),
                const SizedBox(height: 4),
                Text(item['description'],
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.monetization_on_rounded, color: AppColors.warning, size: 15),
                  const SizedBox(width: 4),
                  Text('${item['cost']}',
                      style: const TextStyle(
                          color: AppColors.warning, fontWeight: FontWeight.w700)),
                ]),
              ])),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: kannKaufen
                    ? () => _buy(item['id'], item['name'])
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.surface2,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                child: const Text('Kaufen', style: TextStyle(fontSize: 13)),
              ),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildInventory() {
    if (_inventory.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('🎒', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('Inventar leer', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
          SizedBox(height: 6),
          Text('Kaufe Items im Shop',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _inventory.length,
      itemBuilder: (_, i) {
        final item = _inventory[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Text(_itemEmoji(item['itemType']), style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['name'],
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text)),
              Text('${item['quantity']}x vorhanden',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ])),
            ElevatedButton(
              onPressed: () => _use(item['itemId'], item['name']),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: const Text('Benutzen', style: TextStyle(fontSize: 13)),
            ),
          ]),
        );
      },
    );
  }

  Future<void> _buy(int itemId, String name) async {
    final res = await ApiService.buyItem(widget.userId, itemId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res['ok'] ? '✓ $name gekauft!' : res['data']['fehler'] ?? 'Fehler'),
      backgroundColor: res['ok'] ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
    if (res['ok']) _load();
  }

  Future<void> _use(int itemId, String name) async {
    final res = await ApiService.useItem(widget.userId, itemId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res['ok'] ? res['data']['nachricht'] ?? '✓ $name benutzt' : 'Fehler'),
      backgroundColor: res['ok'] ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
    if (res['ok']) _load();
  }

  String _itemEmoji(String type) {
    return switch (type) {
      'STREAK_FREEZE' => '🛡️',
      'DOUBLE_XP'     => '⚡',
      'COIN_BOOST'    => '💰',
      _               => '🎁',
    };
  }
}
