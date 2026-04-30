import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';

class RiderEarningsScreen extends StatefulWidget {
  final String riderEmail;
  const RiderEarningsScreen({super.key, required this.riderEmail});

  @override
  State<RiderEarningsScreen> createState() => _RiderEarningsScreenState();
}

class _RiderEarningsScreenState extends State<RiderEarningsScreen> {
  List<Order> _delivered = [];
  double _totalEarnings = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await OrderService.getByRider(widget.riderEmail);
    final delivered =
        all.where((o) => o.status == Order.delivered).toList();
    final total = delivered.fold<double>(
        0.0, (sum, o) => sum + o.commission);
    if (!mounted) return;
    setState(() {
      _delivered = delivered;
      _totalEarnings = total;
      _loading = false;
    });
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
          'MY EARNINGS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF0A0A0A), strokeWidth: 2))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildSummaryCard()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DELIVERY HISTORY',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                            color: Color(0xFF0A0A0A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                            width: 24,
                            height: 1,
                            color: const Color(0xFF0A0A0A)),
                      ],
                    ),
                  ),
                ),
                if (_delivered.isEmpty)
                  const SliverFillRemaining(child: _EmptyEarnings())
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _earningCard(_delivered[i]),
                        ),
                        childCount: _delivered.length,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL EARNINGS',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 3,
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '₱${_totalEarnings.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w200,
              color: Color(0xFF0A0A0A),
            ),
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: const Color(0xFFEEEEEE)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  label: 'DELIVERIES',
                  value: '${_delivered.length}',
                  icon: Icons.check_circle_outline,
                ),
              ),
              Expanded(
                child: _summaryItem(
                  label: 'COMMISSION RATE',
                  value: '${(Order.commissionRate * 100).toInt()}%',
                  icon: Icons.percent,
                ),
              ),
              Expanded(
                child: _summaryItem(
                  label: 'AVG. PER ORDER',
                  value: _delivered.isEmpty
                      ? '₱0'
                      : '₱${(_totalEarnings / _delivered.length).toStringAsFixed(0)}',
                  icon: Icons.trending_up,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
      {required String label,
      required String value,
      required IconData icon}) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0A0A0A)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w300,
            color: Color(0xFF0A0A0A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.w600,
            color: Color(0xFF888888),
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _earningCard(Order order) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            color: const Color(0xFFF1F8E9),
            child: const Icon(Icons.check,
                size: 18, color: Color(0xFF2E7D32)),
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
                    fontWeight: FontWeight.w500,
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
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+ ₱${order.commission.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'of ₱${order.total.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 10, color: Color(0xFFAAAAAA)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyEarnings extends StatelessWidget {
  const _EmptyEarnings();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payments_outlined,
              size: 48, color: Color(0xFFCCCCCC)),
          SizedBox(height: 16),
          Text(
            'No earnings yet',
            style: TextStyle(
                fontSize: 13,
                color: Color(0xFFAAAAAA),
                letterSpacing: 1),
          ),
          SizedBox(height: 6),
          Text(
            'Complete deliveries to start earning',
            style: TextStyle(fontSize: 11, color: Color(0xFFCCCCCC)),
          ),
        ],
      ),
    );
  }
}
