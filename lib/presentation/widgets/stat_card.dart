import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_spacing.dart';
import 'app_card.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 170;
        final padding = EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md);
        final badgeSize = compact ? 28.0 : 34.0;
        final valueStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
          height: 1,
        );
        final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          height: 1.1,
        );

        return AppCard(
          padding: padding,
          child: Stack(
            children: [
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  height: badgeSize,
                  width: badgeSize,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(compact ? 10 : 12),
                  ),
                  child: Icon(icon, color: tint, size: compact ? 16 : 18),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: compact ? 30 : 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 10),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: value),
                    duration: const Duration(milliseconds: 900),
                    builder: (context, value, _) => Text(
                      '$value',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: valueStyle,
                    ),
                  ),
                  SizedBox(height: compact ? 4 : 6),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle,
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0);
      },
    );
  }
}
