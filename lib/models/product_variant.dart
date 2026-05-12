class ProductVariant {
  final dynamic id;
  final String? color;
  final String? size;
  int stock;

  ProductVariant({
    this.id,
    this.color,
    this.size,
    required this.stock,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'],
      color: json['color'] as String?,
      size: json['size'] as String?,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toInsert(dynamic productId) => {
        'product_id': productId,
        if (color != null) 'color': color,
        if (size != null) 'size': size,
        'stock': stock,
      };

  String get label {
    if (color != null && size != null) return '$color / $size';
    if (color != null) return color!;
    if (size != null) return size!;
    return 'Default';
  }

  String get variantKey => keyFor(color: color, size: size);

  static String keyFor({String? color, String? size}) =>
      '${color ?? ''}_${size ?? ''}';
}
