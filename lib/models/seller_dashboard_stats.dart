class SellerDashboardStats {
  final int totalProducts;
  final int activeProducts;
  final int pendingApprovalProducts;
  final int archivedProducts;
  final int lowStockProducts;
  final int totalOrders;
  final double totalRevenue;
  final double avgOrderValue;
  final double totalEarnings;
  final int topProductId;
  final String? topProductName;
  final int topProductSales;
  final List<DailyRevenue> revenueLastSevenDays;

  SellerDashboardStats({
    required this.totalProducts,
    required this.activeProducts,
    required this.pendingApprovalProducts,
    required this.archivedProducts,
    required this.lowStockProducts,
    required this.totalOrders,
    required this.totalRevenue,
    required this.avgOrderValue,
    required this.totalEarnings,
    required this.topProductId,
    this.topProductName,
    required this.topProductSales,
    required this.revenueLastSevenDays,
  });

  factory SellerDashboardStats.empty() => SellerDashboardStats(
    totalProducts: 0,
    activeProducts: 0,
    pendingApprovalProducts: 0,
    archivedProducts: 0,
    lowStockProducts: 0,
    totalOrders: 0,
    totalRevenue: 0.0,
    avgOrderValue: 0.0,
    totalEarnings: 0.0,
    topProductId: 0,
    topProductName: null,
    topProductSales: 0,
    revenueLastSevenDays: [],
  );
}

class DailyRevenue {
  final String date;
  final double amount;
  final int orderCount;

  DailyRevenue({
    required this.date,
    required this.amount,
    required this.orderCount,
  });

  factory DailyRevenue.fromJson(Map<String, dynamic> json) {
    return DailyRevenue(
      date: json['date'] as String? ?? '',
      amount: (json['sales_amount'] as num?)?.toDouble() ?? 0.0,
      orderCount: json['orders_count'] as int? ?? 0,
    );
  }
}
