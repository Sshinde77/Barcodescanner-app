import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/mock/mock_barcodes.dart';
import '../../widgets/admin_shell.dart';
import '../../widgets/app_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class GenerateBarcodeScreen extends StatefulWidget {
  const GenerateBarcodeScreen({super.key});

  @override
  State<GenerateBarcodeScreen> createState() => _GenerateBarcodeScreenState();
}

class _GenerateBarcodeScreenState extends State<GenerateBarcodeScreen> {
  final _controller = TextEditingController(
    text: 'Premium Thermal Label Pack | SKU 7821',
  );
  BarcodeFormatOption _format = BarcodeFormatOption.code128;
  bool _showDuplicateWarning = true;
  bool _generated = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _generatedCode {
    switch (_format) {
      case BarcodeFormatOption.code128:
        return 'SBM-${DateTime.now().year}-001';
      case BarcodeFormatOption.qr:
        return _controller.text.trim().isEmpty
            ? 'https://smartbarcode.local/mock'
            : _controller.text.trim();
      case BarcodeFormatOption.ean13:
        return '8901234567895';
      case BarcodeFormatOption.upc:
        return '123456789012';
    }
  }

  Barcode get _barcode {
    switch (_format) {
      case BarcodeFormatOption.code128:
        return Barcode.code128();
      case BarcodeFormatOption.qr:
        return Barcode.qrCode();
      case BarcodeFormatOption.ean13:
        return Barcode.ean13();
      case BarcodeFormatOption.upc:
        return Barcode.upcA();
    }
  }

  Future<void> _generate() async {
    setState(() => _generated = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Barcode generated locally')));
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Generate Barcode',
      selectedPath: '/generate-barcode',
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product Data',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _controller,
                  label: 'Product Data',
                  hint: 'Enter product name, SKU, or encoded payload',
                  maxLines: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Barcode Format',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: BarcodeFormatOption.values.map((option) {
              final selected = _format == option;
              return ChoiceChip(
                selected: selected,
                onSelected: (_) => setState(() => _format = option),
                avatar: Icon(option.icon, size: 18),
                label: Text(option.label),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          CustomButton(
            label: 'Generate Barcode',
            icon: Icons.qr_code_2_rounded,
            onPressed: _generate,
          ),
          const SizedBox(height: 16),
          if (_showDuplicateWarning)
            Dismissible(
              key: const ValueKey('duplicate-warning'),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => setState(() => _showDuplicateWarning = false),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.close_rounded),
              ),
              child: AppCard(
                margin: const EdgeInsets.only(bottom: 16),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Duplicate code warning enabled for demo state.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          AppCard(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: BarcodeWidget(
                    barcode: _barcode,
                    data: _generatedCode,
                    width: 280,
                    height: 120,
                    drawText: false,
                    errorBuilder: (_, error) => SizedBox(
                      height: 120,
                      child: Center(child: Text(error.toString())),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _generatedCode,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Live preview updates locally based on the selected format.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Downloaded')),
                        );
                      },
                      icon: const Icon(Icons.download_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04, end: 0),
          const SizedBox(height: 10),
          if (_generated)
            Text(
              'Generated status set locally. No persistence or backend calls are used.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
