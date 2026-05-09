import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
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
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();

  bool _saving = false;

  // Image state
  Uint8List? _pickedBytes;
  String _pickedExt = 'jpg';
  String _existingImageUrl = '';

  // Category state (loaded from DB)
  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryId;
  String _selectedCategoryName = '';

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
    }
    _loadCategories();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final cats = await SellerProductService.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      if (_selectedCategoryId == null && cats.isNotEmpty) {
        _selectedCategoryId = cats.first['id'] as int;
        _selectedCategoryName = cats.first['name'] as String;
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last.toLowerCase();
    setState(() {
      _pickedBytes = bytes;
      _pickedExt = ext.isEmpty ? 'jpg' : ext;
    });
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
      p.price = price;
      p.stock = stock;
      p.categoryId = _selectedCategoryId;
      p.category = _selectedCategoryName;
      await SellerProductService.update(p);
      if (_pickedBytes != null) {
        await SellerProductService.uploadImage(p.id, _pickedBytes!, _pickedExt);
      }
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
      );
      final newId = await SellerProductService.add(product);
      if (newId != null && _pickedBytes != null) {
        await SellerProductService.uploadImage(newId, _pickedBytes!, _pickedExt);
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
                        child: _field('Stock', _stockCtrl,
                            inputType: TextInputType.number),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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

  // ── Sections ──────────────────────────────────────────────────────────────

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          Text(
            'Tap to pick an image',
            style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFFBBBBBB)),
          ),
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
        _categories.isEmpty
            ? Text('Loading...',
                style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFFAAAAAA)))
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final id = cat['id'] as int;
                  final name = cat['name'] as String;
                  final selected = _selectedCategoryId == id;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedCategoryId = id;
                      _selectedCategoryName = name;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF0A0A0A)
                            : const Color(0xFFF5F4F2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF555555),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

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
          borderSide: const BorderSide(color: Color(0xFF0A0A0A), width: 1.5),
        ),
      ),
    );
  }
}
