import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enums & value types
// ─────────────────────────────────────────────────────────────────────────────

/// Which sizing system a product category belongs to.
enum ProductSizeType { tops, bottoms, footwear, none }

/// A single selectable size option used by the variant picker.
class SizeOption {
  final String label;
  final bool outOfStock;
  const SizeOption(this.label, {this.outOfStock = false});
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal guide-table models (package-private)
// ─────────────────────────────────────────────────────────────────────────────

class _SizeRow {
  final List<String> cells;
  const _SizeRow(this.cells);
}

class _GuideConfig {
  final String categoryLabel;
  final String measureNote;
  final List<String> columns;
  final List<_SizeRow> rows;
  final List<String> howToMeasure;

  const _GuideConfig({
    required this.categoryLabel,
    required this.measureNote,
    required this.columns,
    required this.rows,
    required this.howToMeasure,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SizeGuide — canonical static utility
// ─────────────────────────────────────────────────────────────────────────────

/// Single source of truth for all size-guide logic.
/// Import this class anywhere a size guide is needed.
class SizeGuide {
  SizeGuide._();

  // ── Category classification sets ──────────────────────────────────────────

  static const Set<String> _tops = {
    'tops', 'barong', 'suits & blazers', 'casual shirts', 'polo shirts',
    'outerwear & jackets', 'activewear & fitness tops',
    'shirt', 'shirts', 'polo shirt',
  };

  static const Set<String> _bottoms = {
    'bottoms', 'jeans & denim', 'chinos & trousers', 'shorts',
    'joggers & sweatpants', 'formal pants', 'pants', 'jeans',
    'activewear & fitness bottoms',
  };

  static const Set<String> _footwear = {
    'footwear', 'sneakers', 'loafers & dress shoes', 'sandals & slides',
    'boots', 'athletic shoes', 'shoe', 'shoes', 'sneaker', 'sandals',
  };

  // Accessories & grooming explicitly opt out of size guides.
  static const Set<String> _noGuide = {
    'accessories', 'grooming', 'grooming products', 'grooming & skincare',
    'watches', 'bags', 'belts', 'hats', 'caps', 'jewellery', 'jewelry',
    'fragrances', 'skincare',
  };

  // ── Selectable size lists (used by VariantPickerSheet) ────────────────────

  static const List<SizeOption> topSizes = [
    SizeOption('XS'), SizeOption('S'), SizeOption('M'),
    SizeOption('L'),  SizeOption('XL'), SizeOption('XXL'),
  ];

  static const List<SizeOption> bottomSizes = [
    SizeOption('28'), SizeOption('30'), SizeOption('32'),
    SizeOption('34'), SizeOption('36'), SizeOption('38'),
  ];

  static const List<SizeOption> footwearSizes = [
    SizeOption('39'), SizeOption('40'), SizeOption('41'),
    SizeOption('42'), SizeOption('43'), SizeOption('44'), SizeOption('45'),
  ];

  // ── Guide table data ──────────────────────────────────────────────────────

  static const Map<ProductSizeType, _GuideConfig> _configs = {
    ProductSizeType.tops: _GuideConfig(
      categoryLabel: 'Tops & Shirts',
      measureNote: 'All measurements in inches (in)',
      columns: ['SIZE', 'CHEST', 'SHOULDER', 'LENGTH'],
      rows: [
        _SizeRow(['XS',  '32–34', '15', '26']),
        _SizeRow(['S',   '34–36', '16', '27']),
        _SizeRow(['M',   '37–39', '17', '28']),
        _SizeRow(['L',   '40–42', '18', '29']),
        _SizeRow(['XL',  '43–45', '19', '30']),
        _SizeRow(['XXL', '46–48', '20', '31']),
      ],
      howToMeasure: [
        'Chest — Wrap the tape around the fullest part of your chest, keeping it horizontal.',
        'Shoulder — Measure across the back from shoulder seam to shoulder seam.',
        'Length — From the highest shoulder point straight down to the hem.',
      ],
    ),
    ProductSizeType.bottoms: _GuideConfig(
      categoryLabel: 'Pants & Bottoms',
      measureNote: 'All measurements in inches (in)',
      columns: ['SIZE', 'WAIST', 'HIPS', 'INSEAM'],
      rows: [
        _SizeRow(['28', '28', '36', '30']),
        _SizeRow(['30', '30', '38', '30']),
        _SizeRow(['32', '32', '40', '30.5']),
        _SizeRow(['34', '34', '42', '31']),
        _SizeRow(['36', '36', '44', '31.5']),
        _SizeRow(['38', '38', '46', '32']),
      ],
      howToMeasure: [
        'Waist — Measure around your natural waist, about 1 inch above your navel.',
        'Hips — Measure around the fullest part of your hips, roughly 8 inches below the waist.',
        'Inseam — From the crotch seam down to the bottom of the leg.',
      ],
    ),
    ProductSizeType.footwear: _GuideConfig(
      categoryLabel: 'Footwear',
      measureNote: 'International shoe size conversion chart',
      columns: ['EU', 'US', 'UK', 'CM'],
      rows: [
        _SizeRow(['39', '6.5', '6',    '24.5']),
        _SizeRow(['40', '7',   '6.5',  '25']),
        _SizeRow(['41', '7.5', '7',    '25.5']),
        _SizeRow(['42', '8.5', '8',    '26.5']),
        _SizeRow(['43', '9',   '8.5',  '27']),
        _SizeRow(['44', '10',  '9.5',  '28']),
        _SizeRow(['45', '11',  '10.5', '29']),
      ],
      howToMeasure: [
        'Stand on paper and trace your foot outline.',
        'Measure heel-to-toe length in centimetres.',
        'Use the CM column to find the matching EU / US / UK size.',
      ],
    ),
  };

  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns the [ProductSizeType] for [category].
  static ProductSizeType typeFor(String category) {
    final c = category.toLowerCase().trim();
    if (_noGuide.contains(c)) return ProductSizeType.none;
    if (_tops.contains(c))     return ProductSizeType.tops;
    if (_bottoms.contains(c))  return ProductSizeType.bottoms;
    if (_footwear.contains(c)) return ProductSizeType.footwear;
    return ProductSizeType.none;
  }

  /// `true` when [category] should display a size guide.
  static bool hasSizeGuide(String category) =>
      typeFor(category) != ProductSizeType.none;

  /// Selectable size options for [category] (used by VariantPickerSheet).
  static List<SizeOption> sizesFor(String category) {
    switch (typeFor(category)) {
      case ProductSizeType.tops:     return topSizes;
      case ProductSizeType.bottoms:  return bottomSizes;
      case ProductSizeType.footwear: return footwearSizes;
      case ProductSizeType.none:     return topSizes; // fallback
    }
  }

  /// Opens the size guide bottom sheet for [category].
  /// No-op if the category has no size guide.
  static void showModal(BuildContext context, String category) {
    final type = typeFor(category);
    if (type == ProductSizeType.none) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      isScrollControlled: true,
      builder: (_) => SizeGuideSheet(sizeType: type),
    );
  }

  // Internal accessor for table config.
  static _GuideConfig? _configFor(ProductSizeType type) => _configs[type];
}

// ─────────────────────────────────────────────────────────────────────────────
// SizeGuideButton
// Compact tap target for product cards and detail screens.
// ─────────────────────────────────────────────────────────────────────────────

/// Renders a "📏 Size Guide" link. Returns [SizedBox.shrink] for categories
/// that have no size guide (Accessories, Grooming, etc.).
class SizeGuideButton extends StatelessWidget {
  final String category;

  /// When `true` only the ruler icon is shown (tight layouts).
  final bool iconOnly;

  const SizeGuideButton({
    super.key,
    required this.category,
    this.iconOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!SizeGuide.hasSizeGuide(category)) return const SizedBox.shrink();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => SizeGuide.showModal(context, category),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.straighten_rounded,
              size: 11,
              color: Color(0xFF888888),
            ),
            if (!iconOnly) ...[
              const SizedBox(width: 4),
              Text(
                'Size Guide',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: const Color(0xFF888888),
                  decoration: TextDecoration.underline,
                  decorationColor: const Color(0xFFCCCCCC),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SizeGuideSheet
// Full bottom-sheet content widget. Reusable on any screen.
// ─────────────────────────────────────────────────────────────────────────────

class SizeGuideSheet extends StatelessWidget {
  final ProductSizeType sizeType;

  const SizeGuideSheet({super.key, required this.sizeType});

  @override
  Widget build(BuildContext context) {
    final config = SizeGuide._configFor(sizeType);
    if (config == null) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 3,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title block
            Text(
              'SIZE GUIDE',
              style: GoogleFonts.commissioner(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: const Color(0xFF0A0A0A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              config.categoryLabel,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              config.measureNote,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFFAAAAAA),
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 16),

            // Size table
            _buildTable(config),

            const SizedBox(height: 24),

            // How to measure tips
            if (config.howToMeasure.isNotEmpty) _buildHowToMeasure(config),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(_GuideConfig config) {
    return Column(
      children: [
        _tableRow(config.columns, isHeader: true),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Divider(height: 1, color: Color(0xFFF0F0F0)),
        ),
        ...config.rows.map(
          (row) => _tableRow(row.cells, isHeader: false),
        ),
      ],
    );
  }

  Widget _tableRow(List<String> cells, {required bool isHeader}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: List.generate(cells.length, (i) {
          final isFirst = i == 0;
          final isLast  = i == cells.length - 1;
          return Expanded(
            child: Text(
              cells[i],
              textAlign: isFirst
                  ? TextAlign.left
                  : isLast
                      ? TextAlign.right
                      : TextAlign.center,
              style: isHeader
                  ? GoogleFonts.commissioner(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF888888),
                      letterSpacing: 1.5,
                    )
                  : GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF0A0A0A),
                    ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHowToMeasure(_GuideConfig config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        const SizedBox(height: 20),
        Text(
          'HOW TO MEASURE',
          style: GoogleFonts.commissioner(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: const Color(0xFF888888),
          ),
        ),
        const SizedBox(height: 14),
        ...config.howToMeasure.map(
          (tip) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(top: 6, right: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A0A0A),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    tip,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF555555),
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
