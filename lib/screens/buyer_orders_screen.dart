import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';

class BuyerOrdersScreen extends StatefulWidget {
  const BuyerOrdersScreen({super.key});

  @override
  State<BuyerOrdersScreen> createState() => _BuyerOrdersScreenState();
}

class _BuyerOrdersScreenState extends State<BuyerOrdersScreen> {
  String _filter = 'all';
  List<Order> _orders = [];
  bool _loading = true;

  static const _filters = [
    ('all', 'ALL'),
    (Order.toPay, 'TO PAY'),
    (Order.toShip, 'TO SHIP'),
    (Order.shipped, 'SHIPPED'),
    (Order.toReceive, 'TO RECEIVE'),
    (Order.completed, 'COMPLETED'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final email = await AuthService.getUserEmail();
    if (email == null) return;
    final orders = await OrderService.getByBuyer(email);
    if (!mounted) return;
    setState(() {
      _orders = orders;
      _loading = false;
    });
  }

  List<Order> get _filtered => _filter == 'all'
      ? _orders
      : _orders.where((o) => o.status == _filter).toList();

  Future<void> _confirmReceipt(Order order) async {
    await OrderService.updateStatus(order.id, Order.completed);
    _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt confirmed — thank you for your order!'),
        backgroundColor: Color(0xFF0A0A0A),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF0A0A0A), size: 16),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'MY ORDERS',
          style: TextStyle(
            color: Color(0xFF0A0A0A),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Color(0xFF0A0A0A),
              ),
            )
          : Column(
              children: [
                // Filter tabs
                Container(
                  color: Colors.white,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: _filters.map((f) {
                        final active = _filter == f.$1;
                        return GestureDetector(
                          onTap: () => setState(() => _filter = f.$1),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: active
                                ? const BoxDecoration(
                                    color: Color(0xFF0A0A0A))
                                : BoxDecoration(
                                    color: Colors.transparent,
                                    border: Border.all(
                                        color: const Color(0xFFDDDDDD))),
                            child: Text(
                              f.$2,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: active
                                    ? Colors.white
                                    : const Color(0xFF555555),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Container(height: 1, color: const Color(0xFFEEEEEE)),

                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.receipt_long_outlined,
                                  size: 48, color: Color(0xFFCCCCCC)),
                              SizedBox(height: 20),
                              Text(
                                'NO ORDERS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFAAAAAA),
                                  letterSpacing: 3,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Your orders will appear here',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFFBBBBBB)),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: const Color(0xFF0A0A0A),
                          child: ListView.separated(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 16 : 48,
                              vertical: 20,
                            ),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) =>
                                _orderCard(_filtered[i], isMobile),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _orderCard(Order order, bool isMobile) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ORDER #${order.id.substring(order.id.length > 6 ? order.id.length - 6 : 0)}',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF888888),
                  letterSpacing: 2,
                ),
              ),
              _statusBadge(order.status),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              if (order.productImageUrl.isNotEmpty)
                Container(
                  width: 52,
                  height: 52,
                  color: const Color(0xFFF2F2F2),
                  margin: const EdgeInsets.only(right: 14),
                  child: Image.network(
                    order.productImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_outlined,
                        color: Color(0xFFCCCCCC),
                        size: 20),
                  ),
                ),
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
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Qty: ${order.quantity}  ·  ₱${order.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF777777)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          const SizedBox(height: 12),

          _infoRow('ADDRESS', order.deliveryAddress),
          const SizedBox(height: 6),
          _infoRow(
            'DATE',
            '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
          ),

          // Delivery progress indicator
          const SizedBox(height: 16),
          _progressBar(order.status),

          // Confirm receipt button — shown when seller has marked out for delivery
          if (order.status == Order.toReceive) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _confirmReceipt(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A0A0A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero),
                ),
                child: const Text(
                  'ORDER RECEIVED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],

          if (order.status == Order.completed) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF0A0A0A),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Colors.white, size: 14),
                  SizedBox(width: 8),
                  Text(
                    'DELIVERED — TRANSACTION COMPLETE',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _progressBar(String status) {
    final steps = [
      Order.toPay,
      Order.toShip,
      Order.shipped,
      Order.toReceive,
      Order.completed,
    ];
    final labels = ['PAID', 'TO SHIP', 'SHIPPED', 'DELIVERING', 'DONE'];
    final current = steps.indexOf(status);

    return Row(
      children: List.generate(steps.length, (i) {
        final done = i <= current;
        final isLast = i == steps.length - 1;
        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done
                          ? const Color(0xFF0A0A0A)
                          : const Color(0xFFDDDDDD),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 6,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: done
                          ? const Color(0xFF0A0A0A)
                          : const Color(0xFFCCCCCC),
                    ),
                  ),
                ],
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 1,
                    margin: const EdgeInsets.only(bottom: 16),
                    color: i < current
                        ? const Color(0xFF0A0A0A)
                        : const Color(0xFFDDDDDD),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _statusBadge(String status) {
    final isComplete = status == Order.completed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      color: isComplete ? const Color(0xFF0A0A0A) : const Color(0xFFF0F0F0),
      child: Text(
        Order.statusLabel(status).toUpperCase(),
        style: TextStyle(
          fontSize: 7,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: isComplete ? Colors.white : const Color(0xFF555555),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 68,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: Color(0xFFAAAAAA),
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 11, color: Color(0xFF555555)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
