import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late CartService cartService;

  // Tracks which items currently have a stock-validation error.
  final Map<String, bool> _itemErrors = {};

  bool get _hasErrors => _itemErrors.values.any((e) => e);

  @override
  void initState() {
    super.initState();
    cartService = CartService();
  }

  void _removeItem(String variantKey) {
    setState(() {
      cartService.removeByVariantKey(variantKey);
      _itemErrors.remove(variantKey);
    });
  }

  void _onItemError(String variantKey, bool hasError) {
    setState(() => _itemErrors[variantKey] = hasError);
  }

  void _onQuantityChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final cartItems = cartService.getCartItems();
    final totalPrice = cartService.getTotalPrice();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF0A0A0A), size: 16),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'SHOPPING CART',
          style: GoogleFonts.commissioner(
            color: const Color(0xFF0A0A0A),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFEEEEEE), height: 1),
        ),
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 72, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  Text(
                    'YOUR CART IS EMPTY',
                    style: GoogleFonts.commissioner(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                      color: const Color(0xFFAAAAAA),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Browse the shop and add items to get started.',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: const Color(0xFFBBBBBB)),
                  ),
                  const SizedBox(height: 28),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0A0A0A)),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                    ),
                    child: Text(
                      'CONTINUE SHOPPING',
                      style: GoogleFonts.commissioner(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: const Color(0xFF0A0A0A),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // ── Item list ─────────────────────────────────────────────
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 40,
                      vertical: 20,
                    ),
                    itemCount: cartItems.length,
                    separatorBuilder: (_, __) => Divider(
                      color: Colors.grey[200],
                      height: 28,
                    ),
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return _CartItemRow(
                        key: ValueKey(item.variantKey),
                        item: item,
                        isMobile: isMobile,
                        onRemove: () => _removeItem(item.variantKey),
                        onErrorChanged: _onItemError,
                        onQuantityChanged: _onQuantityChanged,
                      );
                    },
                  ),
                ),

                // ── Summary + checkout ────────────────────────────────────
                Container(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 40,
                    20,
                    isMobile ? 16 : 40,
                    28,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        top: BorderSide(color: Color(0xFFEEEEEE))),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Error banner
                      if (_hasErrors) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          color: const Color(0xFFFFF3F3),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 14, color: Color(0xFFCC0000)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Please fix quantity errors before checking out.',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFFCC0000),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Item count + total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${cartService.getCartCount()} item${cartService.getCartCount() == 1 ? '' : 's'}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF888888),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'TOTAL',
                                style: GoogleFonts.commissioner(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                  color: const Color(0xFF888888),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₱${totalPrice.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0A0A0A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Checkout button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _hasErrors
                              ? null
                              : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const CheckoutScreen(),
                                    ),
                                  ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A0A0A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            disabledBackgroundColor:
                                const Color(0xFFCCCCCC),
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero),
                          ),
                          child: Text(
                            _hasErrors
                                ? 'FIX QUANTITIES TO CHECKOUT'
                                : 'PROCEED TO CHECKOUT',
                            style: GoogleFonts.commissioner(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cart item row — owns its own TextEditingController and error state
// ─────────────────────────────────────────────────────────────────────────────

class _CartItemRow extends StatefulWidget {
  final CartItem item;
  final bool isMobile;
  final VoidCallback onRemove;
  final void Function(String variantKey, bool hasError) onErrorChanged;
  final VoidCallback onQuantityChanged;

  const _CartItemRow({
    super.key,
    required this.item,
    required this.isMobile,
    required this.onRemove,
    required this.onErrorChanged,
    required this.onQuantityChanged,
  });

  @override
  State<_CartItemRow> createState() => _CartItemRowState();
}

class _CartItemRowState extends State<_CartItemRow> {
  late final TextEditingController _ctrl;
  String? _error;

  int get _stock => widget.item.product.stock;
  int get _qty => widget.item.quantity;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '$_qty');
  }

  @override
  void dispose() {
    // Clear any error tied to this item when it's removed from the tree.
    widget.onErrorChanged(widget.item.variantKey, false);
    _ctrl.dispose();
    super.dispose();
  }

  // Apply a new quantity from +/- buttons (always valid range).
  void _stepQty(int newQty) {
    newQty = newQty.clamp(1, _stock);
    widget.item.quantity = newQty;
    _ctrl.value = TextEditingValue(
      text: '$newQty',
      selection:
          TextSelection.fromPosition(TextPosition(offset: '$newQty'.length)),
    );
    setState(() => _error = null);
    widget.onErrorChanged(widget.item.variantKey, false);
    widget.onQuantityChanged();
  }

  // Validate and apply a quantity from keyboard input.
  void _applyQtyFromText(int qty) {
    final stock = _stock;
    if (qty > stock) {
      setState(() => _error = 'Quantity exceeds available stock.');
      widget.onErrorChanged(widget.item.variantKey, true);
      // Don't update cart item — leave it at last valid value.
    } else {
      final clamped = qty.clamp(1, stock);
      widget.item.quantity = clamped;
      setState(() => _error = null);
      widget.onErrorChanged(widget.item.variantKey, false);
      widget.onQuantityChanged();
    }
  }

  void _onTextChanged(String val) {
    if (val.isEmpty) {
      setState(() => _error = null);
      return;
    }
    final n = int.tryParse(val);
    if (n == null) return;
    _applyQtyFromText(n);
  }

  // On focus-out or submit: clamp to valid range and sync field.
  void _commitText() {
    final n = int.tryParse(_ctrl.text) ?? 1;
    final clamped = n.clamp(1, _stock);
    widget.item.quantity = clamped;
    _ctrl.value = TextEditingValue(
      text: '$clamped',
      selection: TextSelection.fromPosition(
          TextPosition(offset: '$clamped'.length)),
    );
    setState(() => _error = null);
    widget.onErrorChanged(widget.item.variantKey, false);
    widget.onQuantityChanged();
  }

  @override
  Widget build(BuildContext context) {
    final imgSize = widget.isMobile ? 80.0 : 96.0;
    final subtotal = widget.item.getTotal();
    final hasError = _error != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Product image ───────────────────────────────────────
            Container(
              width: imgSize,
              height: imgSize,
              color: const Color(0xFFF2F2F2),
              child: widget.item.product.imageUrl.isNotEmpty
                  ? Image.network(
                      widget.item.product.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, p) =>
                          p == null ? child : const _ImgLoader(),
                      errorBuilder: (_, __, ___) => const _ImgPlaceholder(),
                    )
                  : const _ImgPlaceholder(),
            ),
            const SizedBox(width: 14),

            // ── Details ─────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + subtotal
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.item.product.name,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0A0A0A),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₱${subtotal.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0A0A0A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Unit price
                  Text(
                    '₱${widget.item.product.price.toStringAsFixed(0)} each',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF888888),
                    ),
                  ),

                  // Variant label
                  if (widget.item.selectedSize != null ||
                      widget.item.selectedColor != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (widget.item.selectedSize != null)
                          'Size: ${widget.item.selectedSize}',
                        if (widget.item.selectedColor != null)
                          widget.item.selectedColor!,
                      ].join(' · '),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF888888),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // ── Quantity control row ─────────────────────────
                  Row(
                    children: [
                      // Stepper + editable field
                      Container(
                        height: 34,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: hasError
                                ? const Color(0xFFCC0000)
                                : const Color(0xFFDDDDDD),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Minus
                            _StepButton(
                              icon: Icons.remove,
                              enabled: _qty > 1,
                              onTap: () => _stepQty(_qty - 1),
                            ),

                            // Editable quantity field
                            SizedBox(
                              width: 44,
                              child: TextField(
                                controller: _ctrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: hasError
                                      ? const Color(0xFFCC0000)
                                      : const Color(0xFF0A0A0A),
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: _onTextChanged,
                                onSubmitted: (_) => _commitText(),
                                onTapOutside: (_) => _commitText(),
                              ),
                            ),

                            // Plus
                            _StepButton(
                              icon: Icons.add,
                              enabled: _qty < _stock,
                              onTap: () => _stepQty(_qty + 1),
                            ),
                          ],
                        ),
                      ),

                      // Stock indicator
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          '$_stock in stock',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: _stock <= 5
                                ? const Color(0xFFCC0000)
                                : const Color(0xFFAAAAAA),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Remove button
                      GestureDetector(
                        onTap: widget.onRemove,
                        child: Text(
                          'Remove',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF888888),
                            decoration: TextDecoration.underline,
                            decorationColor: const Color(0xFF888888),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── Validation error ──────────────────────────────
                  if (hasError) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 13, color: Color(0xFFCC0000)),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _error!,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFFCC0000),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small helpers
// ─────────────────────────────────────────────────────────────────────────────

class _StepButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 34,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Icon(
            icon,
            size: 15,
            color: enabled
                ? const Color(0xFF0A0A0A)
                : const Color(0xFFCCCCCC),
          ),
        ),
      ),
    );
  }
}

class _ImgLoader extends StatelessWidget {
  const _ImgLoader();

  @override
  Widget build(BuildContext context) => const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
              strokeWidth: 1.5, color: Color(0xFF0A0A0A)),
        ),
      );
}

class _ImgPlaceholder extends StatelessWidget {
  const _ImgPlaceholder();

  @override
  Widget build(BuildContext context) => const Center(
        child: Icon(Icons.image_outlined, size: 28, color: Color(0xFFCCCCCC)),
      );
}
