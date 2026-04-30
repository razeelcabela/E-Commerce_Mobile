import 'package:flutter/material.dart';
import '../../models/seller_product.dart';
import '../../services/seller_product_service.dart';

class SellerAddProductScreen extends StatefulWidget {
  final String sellerEmail;
  final SellerProduct? existing;

  const SellerAddProductScreen({
    super.key,
    required this.sellerEmail,
    this.existing,
  });

  @override
  State<SellerAddProductScreen> createState() => _SellerAddProductScreenState();
}

class _SellerAddProductScreenState extends State<SellerAddProductScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  String _category = 'Shirts';
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  static const _categories = [
    'Shirts', 'Pants', 'T-Shirts', 'Accessories', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final p = widget.existing!;
      _nameCtrl.text = p.name;
      _descCtrl.text = p.description;
      _imageCtrl.text = p.imageUrl;
      _priceCtrl.text = p.price.toStringAsFixed(0);
      _stockCtrl.text = '${p.stock}';
      _category = p.category;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _imageCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _priceCtrl.text.trim().isEmpty ||
        _stockCtrl.text.trim().isEmpty) {
      _snack('Name, price, and stock are required');
      return;
    }
    final price = double.tryParse(_priceCtrl.text.trim());
    final stock = int.tryParse(_stockCtrl.text.trim());
    if (price == null || price < 0) {
      _snack('Enter a valid price');
      return;
    }
    if (stock == null || stock < 0) {
      _snack('Enter a valid stock quantity');
      return;
    }

    setState(() => _saving = true);

    if (_isEdit) {
      final p = widget.existing!;
      p.name = _nameCtrl.text.trim();
      p.description = _descCtrl.text.trim();
      p.imageUrl = _imageCtrl.text.trim();
      p.price = price;
      p.stock = stock;
      p.category = _category;
      await SellerProductService.update(p);
    } else {
      final product = SellerProduct(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sellerEmail: widget.sellerEmail,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        imageUrl: _imageCtrl.text.trim(),
        price: price,
        stock: stock,
        category: _category,
        createdAt: DateTime.now(),
      );
      await SellerProductService.add(product);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF0A0A0A),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF0A0A0A), size: 16),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEdit ? 'EDIT PRODUCT' : 'NEW PRODUCT',
          style: const TextStyle(
            color: Color(0xFF0A0A0A),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 48,
          vertical: isMobile ? 24 : 40,
        ),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field('Product name *', _nameCtrl),
              const SizedBox(height: 24),
              _field('Description', _descCtrl, maxLines: 3),
              const SizedBox(height: 24),
              _field('Image URL', _imageCtrl,
                  hint: 'https://...'),
              const SizedBox(height: 24),

              // Preview
              if (_imageCtrl.text.isNotEmpty) ...[
                const Text(
                  'IMAGE PREVIEW',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF888888),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 160,
                  color: const Color(0xFFF2F2F2),
                  child: Image.network(
                    _imageCtrl.text,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: Color(0xFFCCCCCC), size: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              Row(
                children: [
                  Expanded(child: _field('Price (₱) *', _priceCtrl,
                      inputType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _field('Stock *', _stockCtrl,
                      inputType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 24),

              // Category dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CATEGORY',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF888888),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFDDDDDD), width: 1),
                      ),
                    ),
                    child: DropdownButton<String>(
                      value: _category,
                      isExpanded: true,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.keyboard_arrow_down,
                          size: 16, color: Color(0xFF888888)),
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF0A0A0A)),
                      items: _categories
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _category = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A0A0A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    disabledBackgroundColor: const Color(0xFF888888),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                  ),
                  child: Text(
                    _saving
                        ? 'SAVING...'
                        : (_isEdit ? 'SAVE CHANGES' : 'PUBLISH PRODUCT'),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
    String? hint,
    TextInputType? inputType,
  }) {
    return StatefulBuilder(
      builder: (context, localSet) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Color(0xFF888888),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: inputType,
            style: const TextStyle(fontSize: 14, color: Color(0xFF0A0A0A)),
            onChanged: (_) => localSet(() {}),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: const TextStyle(
                  fontSize: 13, color: Color(0xFFCCCCCC)),
              contentPadding: const EdgeInsets.only(bottom: 8),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFDDDDDD), width: 1),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF0A0A0A), width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
