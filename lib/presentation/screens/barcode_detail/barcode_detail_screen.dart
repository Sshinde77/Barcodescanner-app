import 'package:barcode/barcode.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/mock/mock_barcodes.dart';
import '../../widgets/admin_shell.dart';
import '../../widgets/app_card.dart';
import '../../widgets/custom_button.dart';

class BarcodeDetailScreen extends StatelessWidget {
  const BarcodeDetailScreen({super.key, required this.barcodeId});

  final String barcodeId;

  MockBarcodeItem get _item {
    return mockBarcodes.firstWhere(
      (item) => item.id == barcodeId,
      orElse: () => mockBarcodes.first,
    );
  }

  Barcode get _barcode {
    switch (_item.format) {
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

  @override
  Widget build(BuildContext context) {
    final item = _item;
    return AdminShell(
      title: 'Barcode Detail',
      selectedPath: '/barcode-list',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              children: [
                BarcodeWidget(
                  barcode: _barcode,
                  data: item.code,
                  width: 320,
                  height: 140,
                  drawText: false,
                  errorBuilder: (_, error) => Text(error.toString()),
                ),
                const SizedBox(height: 12),
                Text(
                  item.code,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                _detailRow(context, 'Product Name', item.productName),
                const Divider(),
                _detailRow(context, 'Code', item.code),
                const Divider(),
                _detailRow(context, 'Format', item.format.label),
                const Divider(),
                _detailRow(context, 'Created Date', item.createdAt),
                const Divider(),
                _detailRow(context, 'Status', item.status),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: 'Update',
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Update is mock-only')),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  label: 'Delete',
                  variant: CustomButtonVariant.outline,
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete barcode?'),
                        content: Text(
                          'Delete ${item.code} from the mock dataset?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(context);
                              context.go('/barcode-list');
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
