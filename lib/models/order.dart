import 'dart:developer' as developer;

class Order {
  final String id;
  final String sellerEmail;
  final String buyerEmail;
  final String productId;
  final String productName;
  final String productImageUrl;
  final double unitPrice;
  final int quantity;
  final String deliveryAddress;
  final DateTime createdAt;
  String status;
  String? riderEmail;

  // Original statuses
  static const String toPay = 'toPay';
  static const String toShip = 'toShip';
  static const String shipped = 'shipped';
  static const String toReceive = 'toReceive';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  // Rider delivery statuses
  static const String riderAccepted = 'riderAccepted';
  static const String pickedUp = 'pickedUp';
  static const String inTransit = 'inTransit';
  static const String nearLocation = 'nearLocation';
  static const String delivered = 'delivered';

  static const double commissionRate = 0.15;

  double get total => unitPrice * quantity;
  double get commission => total * commissionRate;

  static const List<String> riderStatuses = [
    riderAccepted,
    pickedUp,
    inTransit,
    nearLocation,
    delivered,
  ];

  Order({
    required this.id,
    required this.sellerEmail,
    required this.buyerEmail,
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.deliveryAddress,
    required this.createdAt,
    required this.status,
    this.riderEmail,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    try {
      final unitPrice = json['unitPrice'];
      final createdAtStr = json['createdAt'] as String?;
      
      return Order(
        id: json['id'] as String? ?? 'unknown',
        sellerEmail: json['sellerEmail'] as String? ?? '',
        buyerEmail: json['buyerEmail'] as String? ?? '',
        productId: json['productId'] as String? ?? '',
        productName: json['productName'] as String? ?? 'Unknown Product',
        productImageUrl: json['productImageUrl'] as String? ?? '',
        unitPrice: unitPrice is num ? unitPrice.toDouble() : 0.0,
        quantity: json['quantity'] as int? ?? 1,
        deliveryAddress: json['deliveryAddress'] as String? ?? '',
        createdAt: createdAtStr != null 
            ? DateTime.parse(createdAtStr) 
            : DateTime.now(),
        status: json['status'] as String? ?? 'unknown',
        riderEmail: json['riderEmail'] as String?,
      );
    } catch (e) {
      developer.log('[Order.fromJson] Parsing error: $e');
      developer.log('[Order.fromJson] JSON was: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sellerEmail': sellerEmail,
        'buyerEmail': buyerEmail,
        'productId': productId,
        'productName': productName,
        'productImageUrl': productImageUrl,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'deliveryAddress': deliveryAddress,
        'createdAt': createdAt.toIso8601String(),
        'status': status,
        'riderEmail': riderEmail,
      };

  static String statusLabel(String status) {
    switch (status) {
      case toPay:          return 'To Pay';
      case toShip:         return 'To Ship';
      case shipped:        return 'Shipped';
      case toReceive:      return 'To Receive';
      case completed:      return 'Completed';
      case cancelled:      return 'Cancelled';
      case riderAccepted:  return 'Rider Accepted';
      case pickedUp:       return 'Picked Up';
      case inTransit:      return 'In Transit';
      case nearLocation:   return 'Near Location';
      case delivered:      return 'Delivered';
      default:             return status;
    }
  }
}
