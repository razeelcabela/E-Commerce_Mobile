import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductStatusBadge extends StatelessWidget {
  final String approvalStatus; // 'pending', 'approved', 'rejected'
  final bool isActive;
  final String archiveStatus; // 'active', 'archived'
  final int stock;
  final bool compact;

  const ProductStatusBadge({
    super.key,
    required this.approvalStatus,
    required this.isActive,
    required this.archiveStatus,
    required this.stock,
    this.compact = false,
  });

  Color _getStatusColor() {
    if (archiveStatus == 'archived') return Colors.grey;
    if (!isActive) return Colors.orange;
    
    switch (approvalStatus) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel() {
    if (archiveStatus == 'archived') return 'Archived';
    if (!isActive) return 'Inactive';
    
    switch (approvalStatus) {
      case 'approved':
        return stock <= 0 ? 'Out of Stock' : 'Active';
      case 'pending':
        return 'Pending Review';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  IconData _getStatusIcon() {
    if (archiveStatus == 'archived') return Icons.archive;
    if (!isActive) return Icons.pause_circle_outline;
    
    switch (approvalStatus) {
      case 'approved':
        return stock <= 0 ? Icons.inventory_2_outlined : Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    final label = _getStatusLabel();
    final icon = _getStatusIcon();

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.white),
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      backgroundColor: color,
      side: BorderSide.none,
    );
  }
}

/// Displays stock status with color coding
class StockStatusBadge extends StatelessWidget {
  final int stock;
  final int? lowStockThreshold;
  final bool compact;

  const StockStatusBadge({
    super.key,
    required this.stock,
    this.lowStockThreshold = 10,
    this.compact = false,
  });

  Color _getColor() {
    if (stock == 0) return Colors.red;
    if (stock < (lowStockThreshold ?? 10)) return Colors.orange;
    return Colors.green;
  }

  String _getLabel() {
    if (stock == 0) return 'Out of Stock';
    if (stock < (lowStockThreshold ?? 10)) return 'Low Stock';
    return 'In Stock';
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          '$stock ${_getLabel()}',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      );
    }

    return Chip(
      label: Text(
        '${_getLabel()} ($stock)',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      backgroundColor: color,
      side: BorderSide.none,
    );
  }
}
