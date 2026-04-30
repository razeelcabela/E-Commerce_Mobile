import 'dart:convert';

class SellerApplication {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';

  final String id;
  final String userEmail;
  final String fullName;
  final String address;
  final String phoneNumber;
  final String? businessName;
  final String? validIdNote;
  final String status;
  final String createdAt;

  const SellerApplication({
    required this.id,
    required this.userEmail,
    required this.fullName,
    required this.address,
    required this.phoneNumber,
    this.businessName,
    this.validIdNote,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userEmail': userEmail,
        'fullName': fullName,
        'address': address,
        'phoneNumber': phoneNumber,
        'businessName': businessName,
        'validIdNote': validIdNote,
        'status': status,
        'createdAt': createdAt,
      };

  factory SellerApplication.fromJson(Map<String, dynamic> json) =>
      SellerApplication(
        id: json['id'] as String,
        userEmail: json['userEmail'] as String,
        fullName: json['fullName'] as String,
        address: json['address'] as String,
        phoneNumber: json['phoneNumber'] as String,
        businessName: json['businessName'] as String?,
        validIdNote: json['validIdNote'] as String?,
        status: json['status'] as String,
        createdAt: json['createdAt'] as String,
      );

  static List<SellerApplication> listFromJson(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => SellerApplication.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJson(List<SellerApplication> apps) =>
      jsonEncode(apps.map((a) => a.toJson()).toList());
}
