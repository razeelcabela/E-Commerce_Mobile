import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../services/rider_auth_service.dart';

class RiderAvailableOrdersScreen extends StatefulWidget {
  const RiderAvailableOrdersScreen({super.key});

  @override
  State<RiderAvailableOrdersScreen> createState() =>
      _RiderAvailableOrdersScreenState();
}

class _RiderAvailableOrdersScreenState
    extends State<RiderAvailableOrdersScreen> {
  List<Order> _orders = [];
  bool _loading = true;
  final Set<String> _accepting = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final orders = await OrderService.getAvailableForRider();
    if (!mounted) return;
    setState(() {
      _orders = orders;
      _loading = false;
    });
  }

  Future<void> _accept(Order order) async {
    final email = await RiderAuthService.getCurrentRiderEmail();
    if (email == null) return;

    setState(() => _accepting.add(order.id));
    await OrderService.acceptOrder(order.id, email);
    if (!mounted) return;

    setState(() => _accepting.remove(order.id));
    _snack('Order accepted — check My Active Deliveries');
    _load();
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios,
              size: 16, color: Colors.white),
        ),
        title: const Text(
          'AVAILABLE ORDERS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF0A0A0A), strokeWidth: 2))
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFF0A0A0A),
              child: _orders.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, i) => _orderCard(_orders[i]),
                    ),
            ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: const [
        SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined,
                  size: 48, color: Color(0xFFCCCCCC)),
              SizedBox(height: 16),
              Text(
                'No orders available',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFFAAAAAA),
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Pull to refresh or check back later',
                style:
                    TextStyle(fontSize: 11, color: Color(0xFFCCCCCC)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _orderCard(Order order) {
    final isAccepting = _accepting.contains(order.id);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product + commission
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                color: const Color(0xFFF0F0F0),
                child: const Icon(Icons.shopping_bag_outlined,
                    size: 20, color: Color(0xFF888888)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.productName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0A0A0A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Qty: ${order.quantity}  ·  ₱${order.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF888888)),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₱${order.commission.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
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
          const SizedBox(height: 14),
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          const SizedBox(height: 12),

          // Delivery address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: Color(0xFF888888)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.deliveryAddress,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF555555), height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Accept button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: isAccepting ? null : () => _accept(order),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A0A0A),
                disabledBackgroundColor: const Color(0xFFCCCCCC),
                elevation: 0,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero),
              ),
              child: isAccepting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'ACCEPT ORDER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
