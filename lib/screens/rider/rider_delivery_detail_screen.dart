import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';

class RiderDeliveryDetailScreen extends StatefulWidget {
  final Order order;
  const RiderDeliveryDetailScreen({super.key, required this.order});

  @override
  State<RiderDeliveryDetailScreen> createState() =>
      _RiderDeliveryDetailScreenState();
}

class _RiderDeliveryDetailScreenState
    extends State<RiderDeliveryDetailScreen> {
  late Order _order;
  bool _updating = false;

  // Ordered progression of rider delivery statuses
  static const List<String> _flow = [
    Order.riderAccepted,
    Order.pickedUp,
    Order.inTransit,
    Order.nearLocation,
    Order.delivered,
  ];

  static const Map<String, String> _stepLabels = {
    Order.riderAccepted: 'ORDER ACCEPTED',
    Order.pickedUp: 'PICKED UP',
    Order.inTransit: 'IN TRANSIT',
    Order.nearLocation: 'NEAR LOCATION',
    Order.delivered: 'DELIVERED',
  };

  static const Map<String, String> _stepDescriptions = {
    Order.riderAccepted: 'Head to the seller\'s location to pick up the order.',
    Order.pickedUp: 'You have the package. Head to the delivery address.',
    Order.inTransit: 'You are on your way to the buyer.',
    Order.nearLocation: 'You are near the delivery location.',
    Order.delivered: 'Package successfully delivered to the buyer.',
  };

  static const Map<String, String> _nextActionLabel = {
    Order.riderAccepted: 'MARK AS PICKED UP',
    Order.pickedUp: 'MARK AS IN TRANSIT',
    Order.inTransit: 'MARK AS NEAR LOCATION',
    Order.nearLocation: 'MARK AS DELIVERED',
  };

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  String? get _nextStatus {
    final idx = _flow.indexOf(_order.status);
    if (idx == -1 || idx >= _flow.length - 1) return null;
    return _flow[idx + 1];
  }

  Future<void> _advanceStatus() async {
    final next = _nextStatus;
    if (next == null) return;

    setState(() => _updating = true);
    await OrderService.updateStatus(_order.id, next);
    if (!mounted) return;
    setState(() {
      _order.status = next;
      _updating = false;
    });

    if (next == Order.delivered) {
      _snack('Delivery completed! Commission: ₱${_order.commission.toStringAsFixed(2)}');
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios,
              size: 16, color: Colors.white),
        ),
        title: const Text(
          'DELIVERY DETAIL',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderCard(),
            const SizedBox(height: 16),
            _buildDeliveryTimeline(),
            const SizedBox(height: 16),
            _buildAddressCard(),
            const SizedBox(height: 24),
            if (_order.status != Order.delivered) _buildActionButton(),
            if (_order.status == Order.delivered) _buildCompletedBanner(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ORDER DETAILS',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
              color: Color(0xFF0A0A0A),
            ),
          ),
          const SizedBox(height: 8),
          Container(width: 24, height: 1, color: const Color(0xFF0A0A0A)),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                color: const Color(0xFFF0F0F0),
                child: const Icon(Icons.shopping_bag_outlined,
                    size: 22, color: Color(0xFF888888)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _order.productName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Qty: ${_order.quantity}  ·  ₱${_order.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF888888)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'YOUR COMMISSION',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: Color(0xFF888888),
                ),
              ),
              Text(
                '₱${_order.commission.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFF0A0A0A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTimeline() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DELIVERY PROGRESS',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
              color: Color(0xFF0A0A0A),
            ),
          ),
          const SizedBox(height: 8),
          Container(width: 24, height: 1, color: const Color(0xFF0A0A0A)),
          const SizedBox(height: 20),
          ..._flow.asMap().entries.map((entry) {
            final idx = entry.key;
            final step = entry.value;
            final currentIdx = _flow.indexOf(_order.status);
            final isDone = idx < currentIdx;
            final isActive = idx == currentIdx;
            final isPending = idx > currentIdx;
            final isLast = idx == _flow.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline indicator
                Column(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isDone
                            ? const Color(0xFF0A0A0A)
                            : isActive
                                ? const Color(0xFF0A0A0A)
                                : Colors.transparent,
                        border: Border.all(
                          color: isPending
                              ? const Color(0xFFDDDDDD)
                              : const Color(0xFF0A0A0A),
                          width: 1.5,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDone
                            ? Icons.check
                            : isActive
                                ? Icons.radio_button_checked
                                : Icons.circle_outlined,
                        size: 12,
                        color: isDone || isActive
                            ? Colors.white
                            : const Color(0xFFDDDDDD),
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 1.5,
                        height: 36,
                        color: isDone
                            ? const Color(0xFF0A0A0A)
                            : const Color(0xFFEEEEEE),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _stepLabels[step] ?? step,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isPending
                                ? const Color(0xFFCCCCCC)
                                : const Color(0xFF0A0A0A),
                            letterSpacing: 1,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(height: 4),
                          Text(
                            _stepDescriptions[step] ?? '',
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF888888),
                                height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DELIVERY ADDRESS',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
              color: Color(0xFF0A0A0A),
            ),
          ),
          const SizedBox(height: 8),
          Container(width: 24, height: 1, color: const Color(0xFF0A0A0A)),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: Color(0xFF888888)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _order.deliveryAddress,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF0A0A0A), height: 1.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final label = _nextActionLabel[_order.status] ?? 'UPDATE STATUS';
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _updating ? null : _advanceStatus,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0A0A0A),
          disabledBackgroundColor: const Color(0xFFCCCCCC),
          elevation: 0,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero),
        ),
        child: _updating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildCompletedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: const Color(0xFFF1F8E9),
      child: Row(
        children: [
          const Icon(Icons.check_circle,
              color: Color(0xFF2E7D32), size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DELIVERY COMPLETED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Commission earned: ₱${_order.commission.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF555555)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
