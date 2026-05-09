import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../services/unified_auth_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: IndexedStack(
        index: _tab,
        children: const [
          _OverviewTab(),
          _UsersTab(),
          _OrdersTab(),
          _ProductsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0A0A0A),
        unselectedItemColor: const Color(0xFFAAAAAA),
        selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'Products'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const _AdminAppBar({required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF0A0A0A),
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('VARÓN ADMIN', style: TextStyle(color: Color(0xFF888888), fontSize: 9, letterSpacing: 3)),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Color(0xFF888888), size: 20),
          onPressed: () async {
            await UnifiedAuthService.logout();
            if (context.mounted) Navigator.of(context).pushReplacementNamed('/login');
          },
        ),
      ],
    );
  }
}

Widget _statusBadge(String label, Color bg, Color fg) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
    child: Text(label, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w700)),
  );
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'approved': case 'active': case 'completed': case 'delivered': return const Color(0xFF16A34A);
    case 'pending': case 'topay': case 'toship': return const Color(0xFFF59E0B);
    case 'suspended': case 'banned': case 'rejected': case 'cancelled': return const Color(0xFFDC2626);
    default: return const Color(0xFF6B7280);
  }
}

void _snack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: error ? const Color(0xFFDC2626) : const Color(0xFF0A0A0A),
    behavior: SnackBarBehavior.floating,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    margin: const EdgeInsets.all(16),
  ));
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — Overview
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewTab extends StatefulWidget {
  const _OverviewTab();
  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final stats = await AdminService.getPlatformStats();
    if (mounted) setState(() { _stats = stats; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: const _AdminAppBar(title: 'Overview'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A0A0A), strokeWidth: 2))
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFF0A0A0A),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Revenue card
                  _revenueCard(),
                  const SizedBox(height: 20),

                  _sectionLabel('USERS'),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _statCard('Total Users', '${_stats['total_users'] ?? 0}', Icons.people, const Color(0xFF3B82F6))),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard('Buyers', '${_stats['total_buyers'] ?? 0}', Icons.shopping_bag_outlined, const Color(0xFF8B5CF6))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _statCard('Sellers', '${_stats['active_sellers'] ?? 0}', Icons.store_outlined, const Color(0xFF10B981))),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard('Riders', '${_stats['total_riders'] ?? 0}', Icons.delivery_dining_outlined, const Color(0xFFF59E0B))),
                  ]),
                  const SizedBox(height: 20),

                  _sectionLabel('ORDERS'),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _statCard('Total Orders', '${_stats['total_orders'] ?? 0}', Icons.receipt_long_outlined, const Color(0xFF0A0A0A))),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard('Completed', '${_stats['completed_orders'] ?? 0}', Icons.check_circle_outline, const Color(0xFF16A34A))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _statCard('In Progress', '${_stats['pending_orders'] ?? 0}', Icons.hourglass_empty_outlined, const Color(0xFFF59E0B))),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard('Products', '${_stats['approved_products'] ?? 0}', Icons.inventory_2_outlined, const Color(0xFF3B82F6))),
                  ]),
                  const SizedBox(height: 20),

                  // Pending approvals
                  if ((_stats['pending_sellers'] ?? 0) > 0 || (_stats['pending_riders'] ?? 0) > 0 || (_stats['pending_products'] ?? 0) > 0) ...[
                    _sectionLabel('PENDING APPROVALS'),
                    const SizedBox(height: 10),
                    _pendingCard('Seller Applications', _stats['pending_sellers'] ?? 0, Icons.store_outlined),
                    const SizedBox(height: 8),
                    _pendingCard('Rider Applications', _stats['pending_riders'] ?? 0, Icons.delivery_dining_outlined),
                    const SizedBox(height: 8),
                    _pendingCard('Products', _stats['pending_products'] ?? 0, Icons.inventory_2_outlined),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _revenueCard() {
    final revenue = (_stats['total_revenue'] as num?)?.toDouble() ?? 0.0;
    return Container(
      padding: const EdgeInsets.all(24),
      color: const Color(0xFF0A0A0A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TOTAL PLATFORM REVENUE', style: TextStyle(color: Color(0xFF888888), fontSize: 9, letterSpacing: 2.5)),
          const SizedBox(height: 8),
          Text('₱${revenue.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w300, letterSpacing: 1)),
          const SizedBox(height: 4),
          const Text('from completed orders', style: TextStyle(color: Color(0xFF555555), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha:0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0A0A0A))),
                Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pendingCard(String label, int count, IconData icon) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFFFF7ED),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            color: const Color(0xFFF59E0B),
            child: Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 3, color: Color(0xFF888888)));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — Users
// ─────────────────────────────────────────────────────────────────────────────

class _UsersTab extends StatefulWidget {
  const _UsersTab();
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _roleFilters = [null, 'buyer', 'seller', 'rider'];
  final _roleLabels  = ['All', 'Buyers', 'Sellers', 'Riders'];

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _sellers = [];
  List<Map<String, dynamic>> _riders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(() { if (_tabs.indexIsChanging) _load(); });
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final i = _tabs.index;
    if (i == 2) {
      _sellers = await AdminService.getSellers();
    } else if (i == 3) {
      _riders = await AdminService.getRiders();
    } else {
      _users = await AdminService.getAllUsers(roleFilter: _roleFilters[i]);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('VARÓN ADMIN', style: TextStyle(color: Color(0xFF888888), fontSize: 9, letterSpacing: 3)),
            Text('User Management', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          indicatorWeight: 2,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF666666),
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
          tabs: _roleLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A0A0A), strokeWidth: 2))
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFF0A0A0A),
              child: TabBarView(
                controller: _tabs,
                children: [
                  _userList(_users),
                  _userList(_users),
                  _sellerList(),
                  _riderList(),
                ],
              ),
            ),
    );
  }

  Widget _userList(List<Map<String, dynamic>> users) {
    if (users.isEmpty) return const Center(child: Text('No users found.', style: TextStyle(color: Color(0xFF888888))));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final u = users[i];
        final name = '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim();
        final status = u['account_status'] as String? ?? 'active';
        return Container(
          color: Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFF0F0F0),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: Color(0xFF0A0A0A), fontWeight: FontWeight.w700),
              ),
            ),
            title: Text(name.isNotEmpty ? name : u['email'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            subtitle: Text(u['email'] ?? '', style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _statusBadge(status.toUpperCase(), _statusColor(status).withValues(alpha:0.12), _statusColor(status)),
                const SizedBox(height: 4),
                Text(u['role'] ?? '', style: const TextStyle(color: Color(0xFF888888), fontSize: 10)),
              ],
            ),
            onTap: () => _showUserActions(u),
          ),
        );
      },
    );
  }

  Widget _sellerList() {
    if (_sellers.isEmpty) return const Center(child: Text('No sellers found.', style: TextStyle(color: Color(0xFF888888))));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _sellers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final s = _sellers[i];
        final user = s['users'] as Map<String, dynamic>?;
        final status = s['status'] as String? ?? 'pending';
        return Container(
          color: Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 40, height: 40,
              color: const Color(0xFFF0F0F0),
              child: const Icon(Icons.store_outlined, color: Color(0xFF0A0A0A), size: 20),
            ),
            title: Text(s['store_name'] ?? 'Unknown Store', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            subtitle: Text(user?['email'] ?? s['contact_email'] ?? '', style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
            trailing: _statusBadge(status.toUpperCase(), _statusColor(status).withValues(alpha:0.12), _statusColor(status)),
            onTap: () => _showSellerActions(s),
          ),
        );
      },
    );
  }

  Widget _riderList() {
    if (_riders.isEmpty) return const Center(child: Text('No riders found.', style: TextStyle(color: Color(0xFF888888))));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _riders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final r = _riders[i];
        final user = r['users'] as Map<String, dynamic>?;
        final status = r['status'] as String? ?? 'pending';
        return Container(
          color: Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 40, height: 40,
              color: const Color(0xFFF0F0F0),
              child: const Icon(Icons.delivery_dining_outlined, color: Color(0xFF0A0A0A), size: 20),
            ),
            title: Text(
              '${user?['first_name'] ?? ''} ${user?['last_name'] ?? ''}'.trim().isNotEmpty
                  ? '${user?['first_name'] ?? ''} ${user?['last_name'] ?? ''}'.trim()
                  : user?['email'] ?? 'Rider',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            subtitle: Text('${r['vehicle_type'] ?? 'motorcycle'} · ${r['license_number'] ?? ''}',
                style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
            trailing: _statusBadge(status.toUpperCase(), _statusColor(status).withValues(alpha:0.12), _statusColor(status)),
            onTap: () => _showRiderActions(r),
          ),
        );
      },
    );
  }

  void _showUserActions(Map<String, dynamic> user) {
    final status = user['account_status'] as String? ?? 'active';
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim(), style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(user['email'] ?? ''),
            ),
            const Divider(height: 1),
            if (status != 'active')
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A)),
                title: const Text('Activate Account'),
                onTap: () async { Navigator.pop(context); await _updateUserStatus(user['id'], 'active'); },
              ),
            if (status != 'suspended')
              ListTile(
                leading: const Icon(Icons.block, color: Color(0xFFDC2626)),
                title: const Text('Suspend Account'),
                onTap: () async { Navigator.pop(context); await _updateUserStatus(user['id'], 'suspended'); },
              ),
            if (status != 'banned')
              ListTile(
                leading: const Icon(Icons.gavel, color: Color(0xFFDC2626)),
                title: const Text('Ban Account'),
                onTap: () async { Navigator.pop(context); await _updateUserStatus(user['id'], 'banned'); },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateUserStatus(int id, String status) async {
    final err = await AdminService.setUserStatus(id, status);
    if (mounted) {
      if (err != null) {
        _snack(context, 'Error: $err', error: true);
      } else {
        _snack(context, 'Account status updated to $status');
        _load();
      }
    }
  }

  void _showSellerActions(Map<String, dynamic> seller) {
    final status = seller['status'] as String? ?? 'pending';
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.store_outlined),
              title: Text(seller['store_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(seller['contact_email'] ?? ''),
            ),
            const Divider(height: 1),
            if (status != 'approved')
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A)),
                title: const Text('Approve Seller'),
                onTap: () async { Navigator.pop(context); await _updateSellerStatus(seller['id'], 'approved'); },
              ),
            if (status != 'suspended')
              ListTile(
                leading: const Icon(Icons.block, color: Color(0xFFDC2626)),
                title: const Text('Suspend Seller'),
                onTap: () async { Navigator.pop(context); await _updateSellerStatus(seller['id'], 'suspended'); },
              ),
            if (status != 'rejected')
              ListTile(
                leading: const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626)),
                title: const Text('Reject Application'),
                onTap: () async { Navigator.pop(context); await _updateSellerStatus(seller['id'], 'rejected'); },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateSellerStatus(int id, String status) async {
    final err = await AdminService.setSellerStatus(id, status);
    if (mounted) {
      if (err != null) {
        _snack(context, 'Error: $err', error: true);
      } else {
        _snack(context, 'Seller status updated to $status');
        _load();
      }
    }
  }

  void _showRiderActions(Map<String, dynamic> rider) {
    final status = rider['status'] as String? ?? 'pending';
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delivery_dining_outlined),
              title: Text('${(rider['users'] as Map?)?.tryGet('first_name') ?? ''} ${(rider['users'] as Map?)?.tryGet('last_name') ?? ''}'.trim(),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(rider['license_number'] ?? ''),
            ),
            const Divider(height: 1),
            if (status != 'approved')
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A)),
                title: const Text('Approve Rider'),
                onTap: () async { Navigator.pop(context); await _updateRiderStatus(rider['id'], 'approved'); },
              ),
            if (status != 'suspended')
              ListTile(
                leading: const Icon(Icons.block, color: Color(0xFFDC2626)),
                title: const Text('Suspend Rider'),
                onTap: () async { Navigator.pop(context); await _updateRiderStatus(rider['id'], 'suspended'); },
              ),
            if (status != 'rejected')
              ListTile(
                leading: const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626)),
                title: const Text('Reject Application'),
                onTap: () async { Navigator.pop(context); await _updateRiderStatus(rider['id'], 'rejected'); },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateRiderStatus(int id, String status) async {
    final err = await AdminService.setRiderStatus(id, status);
    if (mounted) {
      if (err != null) {
        _snack(context, 'Error: $err', error: true);
      } else {
        _snack(context, 'Rider status updated to $status');
        _load();
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 — Orders
// ─────────────────────────────────────────────────────────────────────────────

class _OrdersTab extends StatefulWidget {
  const _OrdersTab();
  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _filter;

  final _filterOptions = ['All', 'toPay', 'toShip', 'shipped', 'toReceive', 'completed', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _orders = await AdminService.getAllOrders(statusFilter: _filter == 'All' ? null : _filter);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: const _AdminAppBar(title: 'All Orders'),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: Colors.white,
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _filterOptions[i];
                final selected = (_filter ?? 'All') == f;
                return GestureDetector(
                  onTap: () { setState(() => _filter = f == 'All' ? null : f); _load(); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF0A0A0A) : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(f, style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF444444),
                      fontSize: 11, fontWeight: FontWeight.w600,
                    )),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A0A0A), strokeWidth: 2))
                : _orders.isEmpty
                    ? const Center(child: Text('No orders found.', style: TextStyle(color: Color(0xFF888888))))
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: const Color(0xFF0A0A0A),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _orders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final o = _orders[i];
                            final buyer = o['users'] as Map<String, dynamic>?;
                            final seller = o['sellers'] as Map<String, dynamic>?;
                            final status = o['status'] as String? ?? '';
                            final buyerName = buyer != null
                                ? '${buyer['first_name'] ?? ''} ${buyer['last_name'] ?? ''}'.trim()
                                : 'Unknown Buyer';
                            return Container(
                              color: Colors.white,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                title: Row(
                                  children: [
                                    Text('Order #${o['id']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    const Spacer(),
                                    _statusBadge(
                                      status.toUpperCase(),
                                      _statusColor(status).withValues(alpha:0.1),
                                      _statusColor(status),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Buyer: $buyerName', style: const TextStyle(fontSize: 12)),
                                    if (seller != null)
                                      Text('Store: ${seller['store_name'] ?? ''}',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                                  ],
                                ),
                                onTap: () => _showOrderActions(o),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showOrderActions(Map<String, dynamic> order) {
    final statuses = ['toPay', 'toShip', 'shipped', 'toReceive', 'completed', 'cancelled'];
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Order #${order['id']}', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Change status to:'),
            ),
            const Divider(height: 1),
            ...statuses.map((s) => ListTile(
              leading: Icon(Icons.circle, color: _statusColor(s), size: 10),
              title: Text(s),
              onTap: () async {
                Navigator.pop(context);
                final err = await AdminService.setOrderStatus(order['id'] as int, s);
                if (mounted) {
                  if (err != null) {
                    _snack(context, 'Error: $err', error: true);
                  } else {
                    _snack(context, 'Order #${order['id']} → $s');
                    _load();
                  }
                }
              },
            )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 4 — Products
// ─────────────────────────────────────────────────────────────────────────────

class _ProductsTab extends StatefulWidget {
  const _ProductsTab();
  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  String? _filter;

  final _filterOptions = ['All', 'pending', 'approved', 'rejected'];

  @override
  void initState() {
    super.initState();
    _filter = 'pending';
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _products = await AdminService.getProducts(approvalFilter: _filter == 'All' ? null : _filter);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: const _AdminAppBar(title: 'Products'),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: Colors.white,
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _filterOptions[i];
                final selected = (_filter ?? 'pending') == f;
                return GestureDetector(
                  onTap: () { setState(() => _filter = f); _load(); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF0A0A0A) : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(f.toUpperCase(), style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF444444),
                      fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5,
                    )),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A0A0A), strokeWidth: 2))
                : _products.isEmpty
                    ? Center(child: Text('No ${_filter ?? ''} products.', style: const TextStyle(color: Color(0xFF888888))))
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: const Color(0xFF0A0A0A),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _products.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final p = _products[i];
                            final seller = p['sellers'] as Map<String, dynamic>?;
                            final status = p['approval_status'] as String? ?? 'pending';
                            return Container(
                              color: Colors.white,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                leading: Container(
                                  width: 44, height: 44,
                                  color: const Color(0xFFF0F0F0),
                                  child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF888888), size: 20),
                                ),
                                title: Text(p['name'] ?? 'Unknown Product',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (seller != null)
                                      Text('${seller['store_name'] ?? ''}',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                                    Text('₱${((p['price'] as num?)?.toStringAsFixed(2)) ?? '0.00'}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                trailing: _statusBadge(
                                  status.toUpperCase(),
                                  _statusColor(status).withValues(alpha:0.12),
                                  _statusColor(status),
                                ),
                                onTap: () => _showProductActions(p),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showProductActions(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(product['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Choose action:'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A)),
              title: const Text('Approve Product'),
              onTap: () async {
                Navigator.pop(context);
                await _setApproval(product['id'] as int, 'approved');
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626)),
              title: const Text('Reject Product'),
              onTap: () async {
                Navigator.pop(context);
                await _setApproval(product['id'] as int, 'rejected');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setApproval(int id, String status) async {
    final err = await AdminService.setProductApproval(id, status);
    if (mounted) {
      if (err != null) {
        _snack(context, 'Error: $err', error: true);
      } else {
        _snack(context, 'Product $status');
        _load();
      }
    }
  }
}

// Extension for safe map access
extension _MapExt on Map {
  dynamic tryGet(String key) {
    try { return this[key]; } catch (_) { return null; }
  }
}
