import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/notification_service.dart';

class SellerNotificationsScreen extends StatefulWidget {
  const SellerNotificationsScreen({super.key});

  @override
  State<SellerNotificationsScreen> createState() =>
      _SellerNotificationsScreenState();
}

class _SellerNotificationsScreenState
    extends State<SellerNotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _notifications = await NotificationService.getSellerNotifications();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _markAllRead() async {
    await NotificationService.markAllAsRead();
    _load();
  }

  Future<void> _markRead(Map<String, dynamic> n) async {
    if (n['is_read'] == true) return;
    await NotificationService.markAsRead(n['id'] as int);
    if (mounted) {
      setState(() => n['is_read'] = true);
    }
  }

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount =
        _notifications.where((n) => n['is_read'] == false).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F3F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 16),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'NOTIFICATIONS',
          style: GoogleFonts.commissioner(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
          ),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark all read',
                style: GoogleFonts.inter(
                    fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: Color(0xFF0A0A0A)))
          : _notifications.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: const Color(0xFF0A0A0A),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _notifCard(_notifications[i]),
                  ),
                ),
    );
  }

  Widget _notifCard(Map<String, dynamic> n) {
    final type = n['type'] as String? ?? 'info';
    final isRead = n['is_read'] as bool? ?? false;
    final isApproved = type == 'product_approved';
    final isRejected = type == 'product_rejected';

    final Color accentColor;
    final IconData icon;
    if (isApproved) {
      accentColor = const Color(0xFF10B981);
      icon = Icons.check_circle;
    } else if (isRejected) {
      accentColor = const Color(0xFFEF4444);
      icon = Icons.cancel;
    } else {
      accentColor = const Color(0xFF3B82F6);
      icon = Icons.notifications;
    }

    return GestureDetector(
      onTap: () => _markRead(n),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: !isRead
              ? Border.all(
                  color: accentColor.withValues(alpha: 0.4), width: 1.5)
              : null,
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n['title'] as String? ?? '',
                          style: GoogleFonts.commissioner(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0A0A0A),
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n['message'] as String? ?? '',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF555555),
                        height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _timeAgo(n['created_at'] as String?),
                    style: GoogleFonts.inter(
                        fontSize: 10, color: const Color(0xFFAAAAAA)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.notifications_none_outlined,
                size: 36, color: Color(0xFFCCCCCC)),
          ),
          const SizedBox(height: 20),
          Text(
            'NO NOTIFICATIONS',
            style: GoogleFonts.commissioner(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFAAAAAA),
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You\'ll be notified when your products are reviewed',
            style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFFBBBBBB)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
