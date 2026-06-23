import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/mock/mock_barcodes.dart';
import 'app_card.dart';

class BarcodeCard extends StatelessWidget {
  const BarcodeCard({
    super.key,
    required this.item,
    this.onView,
    this.onEdit,
    this.onDelete,
  });

  final MockBarcodeItem item;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTiny = constraints.maxWidth <= 320;
        final tileSize = isTiny ? 56.0 : 68.0;
        final tileIconSize = isTiny ? 30.0 : 36.0;
        final titleSize = isTiny ? 14.0 : null;
        final codeSize = isTiny ? 11.0 : null;
        final metaSize = isTiny ? 11.0 : null;
        final chipSize = isTiny ? 10.0 : null;
        final actionIconSize = isTiny ? 18.0 : 20.0;
        final actionVisualDensity = isTiny
            ? const VisualDensity(horizontal: -4, vertical: -4)
            : VisualDensity.compact;

        return AppCard(
          padding: EdgeInsets.all(isTiny ? 12 : 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: tileSize,
                    width: tileSize,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(isTiny ? 16 : 18),
                    ),
                    child: Icon(
                      Icons.qr_code_rounded,
                      color: Colors.white,
                      size: tileIconSize,
                    ),
                  ),
                  SizedBox(width: isTiny ? 10 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: titleSize,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.code,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(fontSize: codeSize),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _chip(
                              context,
                              item.format.label,
                              fontSize: chipSize,
                            ),
                            _chip(
                              context,
                              item.status,
                              color: item.accentColor,
                              fontSize: chipSize,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isTiny ? 8 : 14),
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: isTiny ? 14 : 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.createdAt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontSize: metaSize),
                    ),
                  ),
                  IconButton(
                    onPressed: onView,
                    icon: Icon(Icons.visibility_rounded, size: actionIconSize),
                    visualDensity: actionVisualDensity,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 36,
                    ),
                  ),
                  IconButton(
                    onPressed: onEdit,
                    icon: Icon(Icons.edit_rounded, size: actionIconSize),
                    visualDensity: actionVisualDensity,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 36,
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: actionIconSize,
                    ),
                    visualDensity: actionVisualDensity,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 36,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(
    BuildContext context,
    String label, {
    Color? color,
    double? fontSize,
  }) {
    final tint = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: tint,
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
