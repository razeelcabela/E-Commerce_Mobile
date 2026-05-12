import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/seller_product.dart';
import '../../models/product_variant.dart';
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
  // ── Text controllers ───────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();

  // ── UI state ───────────────────────────────────────────────────────────────
  bool _saving = false;

  // ── Image state ────────────────────────────────────────────────────────────
  Uint8List? _pickedBytes;
  String _pickedExt = 'jpg';
  String _existingImageUrl = '';

  // ── Category state ─────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _categories = [];
  bool _categoriesLoaded = false;
  int? _selectedCategoryId;
  String _selectedCategoryName = '';

  // ── Fulfillment ────────────────────────────────────────────────────────────
  String _deliveryOptions = 'delivery';
  String _condition = 'new';

  // ── Variant state ──────────────────────────────────────────────────────────
  bool _hasVariants = false;
  bool _loadingVariants = false;
  List<String> _selectedColors = [];
  List<String> _selectedSizes = [];
  List<ProductVariant> _variants = [];
  List<TextEditingController> _variantStockCtrls = [];

  // ── Presets ────────────────────────────────────────────────────────────────
  static const _colorPresets = [
    'Black', 'White', 'Gray', 'Navy', 'Khaki', 'Olive',
    'Red', 'Blue', 'Brown', 'Beige', 'Pink', 'Yellow', 'Green', 'Orange', 'Purple',
  ];
  static const _sizePresets = [
    'XS', 'S', 'M', 'L', 'XL', 'XXL', '2XL', '3XL',
    '26', '28', '30', '32', '34', '36', '38', '40',
    '37', '38', '39', '40', '41', '42', '43', '44', '45',
  ];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final p = widget.existing!;
      _nameCtrl.text = p.name;
      _descCtrl.text = p.description;
      _priceCtrl.text = p.price.toStringAsFixed(0);
      _stockCtrl.text = '${p.stock}';
      _existingImageUrl = p.imageUrl;
      _selectedCategoryId = p.categoryId;
      _selectedCategoryName = p.category;
      _deliveryOptions = p.deliveryOptions;
      _condition = p.condition;
    }
    _loadCategories();
    if (_isEdit) _loadVariants();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    for (final c in _variantStockCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Data loaders ───────────────────────────────────────────────────────────

  Future<void> _loadCategories() async {
    setState(() => _categoriesLoaded = false);
    final cats = await SellerProductService.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _categoriesLoaded = true;
      if (_selectedCategoryId == null && cats.isNotEmpty) {
        _selectedCategoryId = (cats.first['id'] as num).toInt();
        _selectedCategoryName = cats.first['name'] as String;
      }
    });
  }

  Future<void> _loadVariants() async {
    if (!_isEdit) return;
    setState(() => _loadingVariants = true);
    final variants =
        await SellerProductService.getVariants(widget.existing!.id);
    if (!mounted) return;
    for (final c in _variantStockCtrls) {
      c.dispose();
    }
    _variantStockCtrls = [];
    if (variants.isNotEmpty) {
      _hasVariants = true;
      _variants = variants;
      _selectedColors = variants
          .map((v) => v.color)
          .whereType<String>()
          .toSet()
          .toList();
      _selectedSizes = variants
          .map((v) => v.size)
          .whereType<String>()
          .toSet()
          .toList();
      _variantStockCtrls =
          variants.map((v) => TextEditingController(text: '${v.stock}')).toList();
    }
    setState(() => _loadingVariants = false);
  }

  // ── Variant helpers ────────────────────────────────────────────────────────

  void _regenerateVariants() {
    // Preserve existing stock values keyed by variant key.
    final oldStock = <String, int>{};
    for (var i = 0; i < _variants.length; i++) {
      oldStock[_variants[i].variantKey] =
          int.tryParse(_variantStockCtrls[i].text) ?? _variants[i].stock;
    }
    for (final c in _variantStockCtrls) {
      c.dispose();
    }
    _variantStockCtrls = [];

    final List<ProductVariant> next = [];
    if (_selectedColors.isNotEmpty && _selectedSizes.isNotEmpty) {
      for (final color in _selectedColors) {
        for (final size in _selectedSizes) {
          final key = ProductVariant.keyFor(color: color, size: size);
          next.add(ProductVariant(color: color, size: size, stock: oldStock[key] ?? 0));
        }
      }
    } else if (_selectedColors.isNotEmpty) {
      for (final color in _selectedColors) {
        final key = ProductVariant.keyFor(color: color);
        next.add(ProductVariant(color: color, stock: oldStock[key] ?? 0));
      }
    } else if (_selectedSizes.isNotEmpty) {
      for (final size in _selectedSizes) {
        final key = ProductVariant.keyFor(size: size);
        next.add(ProductVariant(size: size, stock: oldStock[key] ?? 0));
      }
    }

    _variants = next;
    _variantStockCtrls =
        next.map((v) => TextEditingController(text: '${v.stock}')).toList();
  }

  // ── Image picker ───────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last.toLowerCase();
    setState(() {
      _pickedBytes = bytes;
      _pickedExt = ext.isEmpty ? 'jpg' : ext;
    });
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _priceCtrl.text.trim().isEmpty) {
      _snack('Name and price are required');
      return;
    }
    final price = double.tryParse(_priceCtrl.text.trim());
    if (price == null || price < 0) {
      _snack('Enter a valid price');
      return;
    }
    if (_selectedCategoryId == null) {
      _snack('Please select a category');
      return;
    }

    int stock;
    if (_hasVariants) {
      if (_variants.isEmpty) {
        _snack('Select at least one color or size to create variants');
        return;
      }
      for (var i = 0; i < _variants.length; i++) {
        _variants[i].stock =
            int.tryParse(_variantStockCtrls[i].text.trim()) ?? 0;
      }
      stock = _variants.fold(0, (sum, v) => sum + v.stock);
    } else {
      if (_stockCtrl.text.trim().isEmpty) {
        _snack('Stock is required');
        return;
      }
      final s = int.tryParse(_stockCtrl.text.trim());
      if (s == null || s < 0) {
        _snack('Enter a valid stock quantity');
        return;
      }
      stock = s;
    }

    setState(() => _saving = true);

    if (_isEdit) {
      final p = widget.existing!;
      p.name = _nameCtrl.text.trim();
      p.description = _descCtrl.text.trim();
      p.price = price;
      p.stock = stock;
      p.categoryId = _selectedCategoryId;
      p.category = _selectedCategoryName;
      await SellerProductService.update(p);
      if (_pickedBytes != null) {
        await SellerProductService.uploadImage(p.id, _pickedBytes!, _pickedExt);
      }
      await SellerProductService.saveVariants(
          p.id, _hasVariants ? _variants : []);
    } else {
      final product = SellerProduct(
        id: 0,
        sellerId: 0,
        sellerEmail: widget.sellerEmail,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        imageUrl: '',
        price: price,
        stock: stock,
        categoryId: _selectedCategoryId,
        category: _selectedCategoryName,
        createdAt: DateTime.now(),
        deliveryOptions: _deliveryOptions,
        condition: _condition,
      );
      final newId = await SellerProductService.add(product);
      if (!mounted) return;
      if (newId == null) {
        setState(() => _saving = false);
        _snack('Failed to submit product. Please check your connection.');
        return;
      }
      if (_pickedBytes != null) {
        await SellerProductService.uploadImage(newId, _pickedBytes!, _pickedExt);
      }
      if (_hasVariants && _variants.isNotEmpty) {
        await SellerProductService.saveVariants(newId, _variants);
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);
    _snack(_isEdit ? 'Product updated.' : 'Product submitted for review!');
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
        backgroundColor: const Color(0xFF0A0A0A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F3F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEdit ? 'EDIT PRODUCT' : 'NEW PRODUCT',
          style: GoogleFonts.commissioner(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _imageSection(),
            const SizedBox(height: 16),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('PRODUCT DETAILS'),
                  const SizedBox(height: 20),
                  _field('Product name', _nameCtrl),
                  const SizedBox(height: 16),
                  _field('Description', _descCtrl, maxLines: 3),
                  const SizedBox(height: 16),
                  _categoryPicker(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('FULFILLMENT'),
                  const SizedBox(height: 14),
                  _optionPicker(
                    label: 'DELIVERY OPTIONS',
                    options: const [
                      ('delivery', 'Delivery'),
                      ('pickup', 'Pickup'),
                      ('both', 'Delivery & Pickup'),
                    ],
                    selected: _deliveryOptions,
                    onSelect: (v) => setState(() => _deliveryOptions = v),
                  ),
                  const SizedBox(height: 16),
                  _optionPicker(
                    label: 'CONDITION',
                    options: const [
                      ('new', 'New'),
                      ('used', 'Used'),
                      ('refurbished', 'Refurbished'),
                    ],
                    selected: _condition,
                    onSelect: (v) => setState(() => _condition = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _pricingCard(),
            const SizedBox(height: 16),
            _variantsCard(),
            if (!_isEdit) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: Color(0xFFB45309)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'New products are reviewed by admin before appearing to buyers.',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: const Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A0A0A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  disabledBackgroundColor: const Color(0xFF555555),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _saving
                      ? const SizedBox(
                          key: ValueKey('spinner'),
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: Colors.white),
                        )
                      : Text(
                          key: ValueKey(_isEdit ? 'save' : 'publish'),
                          _isEdit ? 'SAVE CHANGES' : 'SUBMIT FOR REVIEW',
                          style: GoogleFonts.commissioner(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.5,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sections ───────────────────────────────────────────────────────────────

  Widget _imageSection() {
    final hasPickedImage = _pickedBytes != null;
    final hasExisting = _existingImageUrl.isNotEmpty;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionLabel('PRODUCT IMAGE'),
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library_outlined,
                    size: 15, color: Color(0xFF0A0A0A)),
                label: Text(
                  hasPickedImage || hasExisting ? 'CHANGE' : 'PICK IMAGE',
                  style: GoogleFonts.commissioner(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: const Color(0xFF0A0A0A),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  backgroundColor: const Color(0xFFF0F0F0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _pickImage,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: double.infinity,
                height: 180,
                child: hasPickedImage
                    ? Image.memory(_pickedBytes!, fit: BoxFit.cover)
                    : hasExisting
                        ? Image.network(
                            _existingImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imagePlaceholder(),
                          )
                        : _imagePlaceholder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFF5F4F2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_photo_alternate_outlined,
              color: Color(0xFFCCCCCC), size: 40),
          const SizedBox(height: 10),
          Text('Tap to pick an image',
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFFBBBBBB))),
        ],
      ),
    );
  }

  Widget _pricingCard() {
    final totalStock = _hasVariants && _variants.isNotEmpty
        ? _variants.fold(0, (sum, v) {
            final idx = _variants.indexOf(v);
            return sum +
                (int.tryParse(
                        idx < _variantStockCtrls.length
                            ? _variantStockCtrls[idx].text
                            : '0') ??
                    0);
          })
        : null;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('PRICING & STOCK'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _field('Price (₱)', _priceCtrl,
                    inputType: TextInputType.number, prefix: '₱'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _hasVariants
                    ? _readonlyStockDisplay(totalStock ?? 0)
                    : _field('Stock', _stockCtrl,
                        inputType: TextInputType.number),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _readonlyStockDisplay(int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TOTAL STOCK',
          style: GoogleFonts.commissioner(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF888888),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          decoration: BoxDecoration(
            color: const Color(0xFFEEEDEB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$total',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF555555),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Calculated from variants',
          style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFAAAAAA)),
        ),
      ],
    );
  }

  Widget _variantsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionLabel('VARIANTS'),
              if (_loadingVariants)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: Color(0xFF0A0A0A)),
                )
              else
                Switch(
                  value: _hasVariants,
                  activeThumbColor: const Color(0xFF0A0A0A),
                  onChanged: (v) {
                    setState(() {
                      _hasVariants = v;
                      if (!v) {
                        for (final c in _variantStockCtrls) c.dispose();
                        _variantStockCtrls = [];
                        _variants = [];
                        _selectedColors = [];
                        _selectedSizes = [];
                      }
                    });
                  },
                ),
            ],
          ),
          if (!_hasVariants)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Enable to add colors, sizes, and stock per combination.',
                style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFFAAAAAA)),
              ),
            ),
          if (_hasVariants) ...[
            const SizedBox(height: 20),
            _chipGroup(
              label: 'COLORS',
              options: _colorPresets,
              selected: _selectedColors,
              onToggle: (color) => setState(() {
                _selectedColors.contains(color)
                    ? _selectedColors.remove(color)
                    : _selectedColors.add(color);
                _regenerateVariants();
              }),
            ),
            const SizedBox(height: 20),
            _chipGroup(
              label: 'SIZES',
              options: _sizePresets,
              selected: _selectedSizes,
              onToggle: (size) => setState(() {
                _selectedSizes.contains(size)
                    ? _selectedSizes.remove(size)
                    : _selectedSizes.add(size);
                _regenerateVariants();
              }),
            ),
            if (_variants.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 20),
              _sectionLabel('STOCK PER VARIANT'),
              const SizedBox(height: 14),
              ...List.generate(_variants.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _variants[i].label,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF0A0A0A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: _variantStockCtrls[i],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF0A0A0A)),
                          decoration: InputDecoration(
                            labelText: 'Stock',
                            labelStyle: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF999999)),
                            filled: true,
                            fillColor: const Color(0xFFF7F6F4),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Color(0xFF0A0A0A), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            if (_variants.isEmpty &&
                (_selectedColors.isNotEmpty || _selectedSizes.isNotEmpty))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'No combinations available. Select at least one option above.',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFF999999)),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _categoryPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CATEGORY',
          style: GoogleFonts.commissioner(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF888888),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        if (!_categoriesLoaded)
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F6F4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: Color(0xFF0A0A0A)),
              ),
            ),
          )
        else if (_categories.isEmpty)
          Row(
            children: [
              Text('Failed to load categories',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: const Color(0xFFAAAAAA))),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _loadCategories,
                child: Text('Retry',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF0A0A0A),
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline)),
              ),
            ],
          )
        else
          DropdownButtonFormField<int>(
            initialValue: _selectedCategoryId,
            isExpanded: true,
            style: GoogleFonts.inter(
                fontSize: 15, color: const Color(0xFF0A0A0A)),
            dropdownColor: Colors.white,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF7F6F4),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFF0A0A0A), width: 1.5),
              ),
            ),
            hint: Text('Select a category',
                style: GoogleFonts.inter(
                    fontSize: 14, color: const Color(0xFF999999))),
            items: _categories.map((cat) {
              final id = (cat['id'] as num).toInt();
              final name = cat['name'] as String;
              return DropdownMenuItem<int>(
                value: id,
                child: Text(name,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: const Color(0xFF0A0A0A))),
              );
            }).toList(),
            onChanged: (val) {
              if (val == null) return;
              final cat =
                  _categories.firstWhere((c) => (c['id'] as num).toInt() == val);
              setState(() {
                _selectedCategoryId = val;
                _selectedCategoryName = cat['name'] as String;
              });
            },
          ),
      ],
    );
  }

  // ── Reusable widgets ───────────────────────────────────────────────────────

  Widget _optionPicker({
    required String label,
    required List<(String value, String display)> options,
    required String selected,
    required void Function(String) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.commissioner(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF888888),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isSelected = selected == opt.$1;
            return GestureDetector(
              onTap: () => onSelect(opt.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0A0A0A)
                      : const Color(0xFFF5F4F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  opt.$2,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.white : const Color(0xFF555555),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _chipGroup({
    required String label,
    required List<String> options,
    required List<String> selected,
    required void Function(String) onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.commissioner(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF888888),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.toSet().map((opt) {
            final isSelected = selected.contains(opt);
            return GestureDetector(
              onTap: () => onToggle(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0A0A0A)
                      : const Color(0xFFF5F4F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  opt,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.white : const Color(0xFF555555),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.commissioner(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF888888),
        letterSpacing: 2.5,
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
    String? hint,
    TextInputType? inputType,
    String? prefix,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: inputType,
      style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF0A0A0A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            GoogleFonts.inter(fontSize: 14, color: const Color(0xFF999999)),
        floatingLabelStyle: GoogleFonts.commissioner(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0A0A0A),
          letterSpacing: 1,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(fontSize: 13, color: const Color(0xFFCCCCCC)),
        prefixText: prefix,
        prefixStyle:
            GoogleFonts.inter(fontSize: 15, color: const Color(0xFF0A0A0A)),
        filled: true,
        fillColor: const Color(0xFFF7F6F4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0A0A0A), width: 1.5),
        ),
      ),
    );
  }
}
