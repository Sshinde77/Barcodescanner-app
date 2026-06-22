import 'package:barcode/barcode.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../data/api/api_models.dart';
import '../../../data/api/api_provider.dart';
import '../../widgets/admin_shell.dart';
import '../../widgets/app_card.dart';
import '../../widgets/custom_button.dart';

class BarcodeDetailScreen extends StatefulWidget {
  const BarcodeDetailScreen({super.key, required this.barcodeId});

  final String barcodeId;

  @override
  State<BarcodeDetailScreen> createState() => _BarcodeDetailScreenState();
}

class _BarcodeDetailScreenState extends State<BarcodeDetailScreen> {
  BarcodeDetailItem? _item;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Barcode _barcodeFromFormat(String? format) {
    switch (format?.toLowerCase()) {
      case 'qrcode':
      case 'qr':
        return Barcode.qrCode();
      case 'code39':
        return Barcode.code39();
      case 'ean13':
        return Barcode.ean13();
      case 'upc':
      case 'upca':
        return Barcode.upcA();
      case 'code128':
      default:
        return Barcode.code128();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final item = await ApiScope.of(context).fetchBarcodeDetail(widget.barcodeId);
      if (!mounted) return;
      setState(() => _item = item);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _updateLabel() async {
    final item = _item;
    if (item == null) return;

    final controller = TextEditingController(text: item.customLabel ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update custom label'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Custom label',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty) return;

    setState(() => _saving = true);
    try {
      await ApiScope.of(context).updateBarcode(
        id: widget.barcodeId,
        customLabel: result,
      );
      if (!mounted) return;
      await _load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barcode updated successfully')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _deleteBarcode() async {
    final item = _item;
    if (item == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete barcode?'),
        content: Text('Delete ${item.uniqueCode ?? widget.barcodeId} from the API?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      await ApiScope.of(context).deleteBarcode(widget.barcodeId);
      if (!mounted) return;
      context.go('/barcode-list');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
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
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            AppCard(
              child: ListTile(
                leading: const Icon(Icons.error_outline_rounded),
                title: const Text('API load failed'),
                subtitle: Text(_error!),
              ),
            )
          else if (item != null) ...[
            AppCard(
              child: Column(
                children: [
                  if (item.barcodeSvg != null && item.barcodeSvg!.isNotEmpty)
                    SvgPicture.string(
                      item.barcodeSvg!,
                      width: 320,
                      height: 140,
                    )
                  else
                    BarcodeWidget(
                      barcode: _barcodeFromFormat(item.barcodeFormat),
                      data: item.uniqueCode ?? '',
                      width: 320,
                      height: 140,
                      drawText: false,
                      errorBuilder: (_, error) => Text(error.toString()),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    item.uniqueCode ?? widget.barcodeId,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                children: [
                  _detailRow(context, 'Product Name', item.product?.name ?? '-'),
                  const Divider(),
                  _detailRow(context, 'Code', item.uniqueCode ?? '-'),
                  const Divider(),
                  _detailRow(context, 'Format', item.barcodeFormat ?? '-'),
                  const Divider(),
                  _detailRow(context, 'Created Date', item.createdAt?.toIso8601String() ?? '-'),
                  const Divider(),
                  _detailRow(context, 'Scan Count', item.scanCount?.toString() ?? '-'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: 'Update',
                    loading: _saving,
                    onPressed: _updateLabel,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    label: 'Delete',
                    loading: _saving,
                    variant: CustomButtonVariant.outline,
                    onPressed: _deleteBarcode,
                  ),
                ),
              ],
            ),
          ],
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}
