import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../services/rider_auth_service.dart';
import 'rider_available_orders_screen.dart';
import 'rider_delivery_detail_screen.dart';
import 'rider_earnings_screen.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  String? _email;
  String? _name;
  int _availableCount = 0;
  int _activeCount = 0;
  int _deliveredCount = 0;
  double _earnings = 0;
  List<Order> _activeDeliveries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final email = await RiderAuthService.getCurrentRiderEmail();
    if (email == null || !mounted) return;

    try {
      developer.log('[RIDER_DASHBOARD] Loading data for: $email');
      
      developer.log('[RIDER_DASHBOARD] Fetching full name...');
      final fullName = await RiderAuthService.getFullName(email);
      
      developer.log('[RIDER_DASHBOARD] Fetching available orders...');
      final availableOrders = await OrderService.getAvailableForRider();
      
      developer.log('[RIDER_DASHBOARD] Fetching active deliveries...');
      final activeOrders = await OrderService.getActiveDeliveriesByRider(email);
      
      developer.log('[RIDER_DASHBOARD] Fetching completed count...');
      final completedCount = await OrderService.riderCompletedCount(email);
      
      developer.log('[RIDER_DASHBOARD] Fetching earnings...');
      final earnings = await OrderService.riderEarnings(email);
      
      developer.log('[RIDER_DASHBOARD] All data fetched successfully');

      if (!mounted) return;
      setState(() {
        _email = email;
        _name = fullName;
        _availableCount = availableOrders.length;
        _activeDeliveries = activeOrders;
        _activeCount = activeOrders.length;
        _deliveredCount = completedCount;
        _earnings = earnings;
        _loading = false;
      });
      developer.log('[RIDER_DASHBOARD] State updated, loading complete');
    } catch (e, stackTrace) {
      developer.log('[RIDER_DASHBOARD] ERROR: $e');
      developer.log('[RIDER_DASHBOARD] STACK: $stackTrace');
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('Failed to load dashboard: $e');
    }
  }

  Future<void> _logout() async {
    await RiderAuthService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/rider/login');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF0A0A0A),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF0A0A0A), strokeWidth: 2))
            : RefreshIndicator(
                onRefresh: _load,
                color: const Color(0xFF0A0A0A),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(child: _buildStatsRow()),
                    SliverToBoxAdapter(child: _buildQuickActions()),
                    SliverToBoxAdapter(child: _buildActiveDeliveries()),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RIDER PORTAL',
                  style: TextStyle(
                    fontSize: 8,
                    color: Color(0xFF888888),
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _name ?? _email ?? 'Rider',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout,
                color: Color(0xFF888888), size: 20),
            tooltip: 'Sign out',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final stats = [
      {
        'label': 'AVAILABLE',
        'value': '$_availableCount',
        'icon': Icons.inbox_outlined,
      },
      {
        'label': 'ACTIVE',
        'value': '$_activeCount',
        'icon': Icons.delivery_dining,
      },
      {
        'label': 'DELIVERED',
        'value': '$_deliveredCount',
        'icon': Icons.check_circle_outline,
      },
      {
        'label': 'EARNINGS',
        'value': '₱${_earnings.toStringAsFixed(0)}',
        'icon': Icons.payments_outlined,
      },
    ];

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: stats.map((s) {
          return Expanded(
            child: Column(
              children: [
                Icon(s['icon'] as IconData,
                    size: 20, color: const Color(0xFF0A0A0A)),
                const SizedBox(height: 8),
                Text(
                  s['value'] as String,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s['label'] as String,
                  style: const TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF888888),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'QUICK ACTIONS',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: Color(0xFF0A0A0A),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _actionCard(
                  icon: Icons.inbox_outlined,
                  label: 'AVAILABLE\nORDERS',
                  badge: _availableCount,
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            const RiderAvailableOrdersScreen()));
                    _load();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionCard(
                  icon: Icons.payments_outlined,
                  label: 'MY\nEARNINGS',
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            RiderEarningsScreen(riderEmail: _email!)));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 22, color: const Color(0xFF0A0A0A)),
                if (badge > 0)
                  Positioned(
                    top: -6,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: Color(0xFF0A0A0A),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveDeliveries() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'MY ACTIVE DELIVERIES',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: Color(0xFF0A0A0A),
              ),
            ),
          ),
          if (_activeDeliveries.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: const Column(
                children: [
                  Icon(Icons.delivery_dining,
                      size: 32, color: Color(0xFFCCCCCC)),
                  SizedBox(height: 12),
                  Text(
                    'No active deliveries',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFAAAAAA),
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Accept an order to start delivering',
                    style:
                        TextStyle(fontSize: 11, color: Color(0xFFCCCCCC)),
                  ),
                ],
              ),
            )
          else
            ..._activeDeliveries
                .map((order) => _deliveryCard(order))
                .toList(),
        ],
      ),
    );
  }

  Widget _deliveryCard(Order order) {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => RiderDeliveryDetailScreen(order: order)));
        _load();
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              color: const Color(0xFFF0F0F0),
              child: const Icon(Icons.shopping_bag_outlined,
                  size: 18, color: Color(0xFF888888)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.productName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0A0A0A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.deliveryAddress,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF888888)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _statusChip(order.status),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₱${order.commission.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
                const Text(
                  'commission',
                  style: TextStyle(
                      fontSize: 9, color: Color(0xFFAAAAAA)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      color: color.withValues(alpha: 0.1),
      child: Text(
        Order.statusLabel(status).toUpperCase(),
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: color,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case Order.riderAccepted:
        return const Color(0xFF1565C0);
      case Order.pickedUp:
        return const Color(0xFF6A1B9A);
      case Order.inTransit:
        return const Color(0xFFE65100);
      case Order.nearLocation:
        return const Color(0xFF2E7D32);
      default:
        return const Color(0xFF555555);
    }
  }
}
