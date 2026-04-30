import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../services/seller_auth_service.dart';
import '../../services/seller_product_service.dart';
import 'seller_orders_screen.dart';
import 'seller_products_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  String? _email;
  String? _storeName;
  int _productCount = 0;
  Map<String, int> _statusCounts = {};
  double _revenue = 0;
  List<Order> _recentOrders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final email = await SellerAuthService.getCurrentSellerEmail();
    if (email == null) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/seller/login');
      return;
    }
    final storeName = await SellerAuthService.getStoreName(email);
    final products = await SellerProductService.getByEmail(email);
    final statusCounts = await OrderService.sellerStatusCounts(email);
    final revenue = await OrderService.sellerRevenue(email);
    final orders = await OrderService.getBySeller(email);

    if (!mounted) return;
    setState(() {
      _email = email;
      _storeName = storeName;
      _productCount = products.length;
      _statusCounts = statusCounts;
      _revenue = revenue;
      _recentOrders = orders.take(5).toList();
      _loading = false;
    });
  }

  Future<void> _logout() async {
    await SellerAuthService.logout();
    if (mounted) Navigator.of(context).pushReplacementNamed('/seller/login');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VARÓN',
              style: TextStyle(
                color: Color(0xFF0A0A0A),
                fontSize: 16,
                fontWeight: FontWeight.w300,
                letterSpacing: 6,
              ),
            ),
            Text(
              'SELLER PORTAL',
              style: TextStyle(
                color: Color(0xFF999999),
                fontSize: 8,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'logout') _logout();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'logout', child: Text('Sign Out')),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(Icons.account_circle_outlined,
                      color: Color(0xFF0A0A0A), size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Color(0xFF0A0A0A),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFF0A0A0A),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 48,
                  vertical: isMobile ? 24 : 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store header
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            color: const Color(0xFF0A0A0A),
                            child: Center(
                              child: Text(
                                (_storeName ?? '?')
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _storeName ?? '—',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0A0A0A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _email ?? '',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF888888),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats row
                    Row(
                      children: [
                        _statCard('PRODUCTS', '$_productCount', isMobile),
                        const SizedBox(width: 12),
                        _statCard(
                          'REVENUE',
                          '₱${_revenue.toStringAsFixed(0)}',
                          isMobile,
                        ),
                        const SizedBox(width: 12),
                        _statCard(
                          'TO SHIP',
                          '${_statusCounts[Order.toShip] ?? 0}',
                          isMobile,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Order status overview
                    _sectionHeader('ORDER STATUS'),
                    const SizedBox(height: 16),
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        children: [
                          _orderStatusTile(
                            Icons.credit_card_outlined,
                            'TO PAY',
                            _statusCounts[Order.toPay] ?? 0,
                          ),
                          _orderStatusTile(
                            Icons.inventory_2_outlined,
                            'TO SHIP',
                            _statusCounts[Order.toShip] ?? 0,
                          ),
                          _orderStatusTile(
                            Icons.local_shipping_outlined,
                            'SHIPPED',
                            _statusCounts[Order.shipped] ?? 0,
                          ),
                          _orderStatusTile(
                            Icons.move_to_inbox_outlined,
                            'TO RECEIVE',
                            _statusCounts[Order.toReceive] ?? 0,
                          ),
                          _orderStatusTile(
                            Icons.check_circle_outline,
                            'COMPLETED',
                            _statusCounts[Order.completed] ?? 0,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick actions
                    _sectionHeader('MANAGE'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _actionCard(
                            Icons.inventory_outlined,
                            'PRODUCTS',
                            'Add, edit & manage listings',
                            () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const SellerProductsScreen(),
                            )).then((_) => _load()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _actionCard(
                            Icons.receipt_long_outlined,
                            'ORDERS',
                            'View & update order status',
                            () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const SellerOrdersScreen(),
                            )).then((_) => _load()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Recent orders
                    if (_recentOrders.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _sectionHeader('RECENT ORDERS'),
                          GestureDetector(
                            onTap: () => Navigator.of(context)
                                .push(MaterialPageRoute(
                                  builder: (_) => const SellerOrdersScreen(),
                                ))
                                .then((_) => _load()),
                            child: const Text(
                              'SEE ALL',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF888888),
                                letterSpacing: 1.5,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        color: Colors.white,
                        child: Column(
                          children: _recentOrders
                              .map((o) => _orderRow(o))
                              .toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statCard(String label, String value, bool isMobile) {
    return Expanded(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w300,
                color: Color(0xFF0A0A0A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: Color(0xFF999999),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderStatusTile(IconData icon, String label, int count) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w300,
              color: Color(0xFF0A0A0A),
            ),
          ),
          const SizedBox(height: 8),
          Icon(icon, size: 18, color: const Color(0xFF0A0A0A)),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 7,
              fontWeight: FontWeight.w600,
              color: Color(0xFF888888),
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _actionCard(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF0A0A0A)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0A0A0A),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 12, color: Color(0xFFAAAAAA)),
          ],
        ),
      ),
    );
  }

  Widget _orderRow(Order order) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.productName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0A0A0A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  order.buyerEmail,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF999999),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₱${order.total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0A0A0A),
                ),
              ),
              const SizedBox(height: 4),
              _statusBadge(order.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      color: status == Order.completed
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF0F0F0),
      child: Text(
        Order.statusLabel(status).toUpperCase(),
        style: TextStyle(
          fontSize: 7,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: status == Order.completed
              ? Colors.white
              : const Color(0xFF555555),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0A0A0A),
        letterSpacing: 3,
      ),
    );
  }
}
