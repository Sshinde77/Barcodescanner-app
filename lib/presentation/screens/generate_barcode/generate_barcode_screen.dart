import 'package:barcode/barcode.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/api/api_models.dart';
import '../../../data/api/api_provider.dart';
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
  bool _showDuplicateWarning = false;
  bool _loading = false;
  BarcodeGenerateItem? _generatedResult;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _payload => _controller.text.trim();

  String get _generatedCode {
    switch (_format) {
      case BarcodeFormatOption.code128:
        return 'SBM-${DateTime.now().year}-001';
      case BarcodeFormatOption.qr:
        return _payload.isEmpty ? 'https://smartbarcode.local/mock' : _payload;
      case BarcodeFormatOption.code39:
        return _payload.isEmpty ? 'CODE39-SAMPLE' : _payload;
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
      case BarcodeFormatOption.code39:
        return Barcode.code39();
      case BarcodeFormatOption.ean13:
        return Barcode.ean13();
      case BarcodeFormatOption.upc:
        return Barcode.upcA();
    }
  }

  String _apiFormatValue(BarcodeFormatOption format) {
    switch (format) {
      case BarcodeFormatOption.code128:
        return 'code128';
      case BarcodeFormatOption.qr:
        return 'qrcode';
      case BarcodeFormatOption.code39:
        return 'code39';
      case BarcodeFormatOption.ean13:
        return 'ean13';
      case BarcodeFormatOption.upc:
        return 'upc';
    }
  }

  Future<void> _generate() async {
    if (_payload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter barcode data first')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final api = ApiScope.of(context);
      final duplicate = await api.checkDuplicate(_payload);
      if (!mounted) return;

      setState(() => _showDuplicateWarning = duplicate.exists);

      final label = _payload;
      final result = await api.generateBarcode(
        barcodeData: _payload,
        barcodeFormat: _apiFormatValue(_format),
        customLabel: label,
      );

      if (!mounted) return;
      setState(() => _generatedResult = result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            duplicate.exists
                ? 'Barcode generated. Duplicate data already exists.'
                : 'Barcode generated successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewSvg = _generatedResult?.barcodeSvg;
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
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
            loading: _loading,
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
                        'Duplicate barcode data detected by the API.',
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
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: previewSvg != null && previewSvg.isNotEmpty
                      ? SvgPicture.string(
                          previewSvg,
                          width: 280,
                          height: 120,
                          fit: BoxFit.contain,
                        )
                      : BarcodeWidget(
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
                  _generatedResult?.uniqueCode ?? _generatedCode,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _generatedResult?.barcodeImageUrl ??
                            'Live preview updates from the API and local format selection.',
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
          if (_generatedResult != null)
            Text(
              'Generated barcode via API.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
        ],
      ),
    );
  }
}
