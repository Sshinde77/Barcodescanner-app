import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../data/api/api_models.dart';
import '../../../data/api/api_provider.dart';
import '../../../data/mock/mock_barcodes.dart';
import '../../widgets/admin_shell.dart';
import '../../widgets/app_card.dart';
import '../../widgets/barcode_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/responsive_layout.dart';

class BarcodeListScreen extends StatefulWidget {
  const BarcodeListScreen({super.key});

  @override
  State<BarcodeListScreen> createState() => _BarcodeListScreenState();
}

class _BarcodeListScreenState extends State<BarcodeListScreen> {
  final _searchController = TextEditingController();
  final List<MockBarcodeItem> _items = [];
  bool _showEmpty = false;
  bool _loading = false;
  bool _loadingMore = false;
  int _start = 0;
  int _length = 10;
  int _recordsTotal = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  BarcodeFormatOption _formatFromApi(String? format) {
    switch (format?.toLowerCase()) {
      case 'qrcode':
      case 'qr':
        return BarcodeFormatOption.qr;
      case 'code39':
        return BarcodeFormatOption.code39;
      case 'ean13':
        return BarcodeFormatOption.ean13;
      case 'upc':
      case 'upca':
        return BarcodeFormatOption.upc;
      case 'code128':
      default:
        return BarcodeFormatOption.code128;
    }
  }

  MockBarcodeItem _toMockItem(BarcodeSummaryItem item) {
    return MockBarcodeItem(
      apiId: item.id?.toString(),
      id:
          item.id?.toString() ??
          item.uniqueCode ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      code: item.uniqueCode ?? item.barcodeData ?? '',
      productName: item.customLabel ?? item.productName ?? 'Barcode',
      customLabel: item.customLabel,
      format: _formatFromApi(item.barcodeFormat),
      createdAt: item.createdAt ?? '',
      status: 'Active',
      scannedCount: 0,
    );
  }

  Future<void> _load({bool append = false}) async {
    if (append) {
      setState(() => _loadingMore = true);
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final response = await ApiScope.of(context).fetchBarcodes(
        start: _start,
        length: _length,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _recordsTotal = response.recordsTotal ?? response.items.length;
        final mapped = response.items.map(_toMockItem).toList();
        if (append) {
          _items.addAll(mapped);
        } else {
          _items
            ..clear()
            ..addAll(mapped);
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_items.length >= _recordsTotal) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No more barcodes to load')));
      return;
    }

    setState(() {
      _start += _length;
    });
    await _load(append: true);
  }

  Future<void> _editBarcode(MockBarcodeItem item) async {
    final controller = TextEditingController(
      text: item.customLabel ?? item.productName ?? item.code,
    );
    final barcodeId = item.apiId ?? item.id;
    if (barcodeId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Barcode id is missing.')));
      return;
    }
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Custom Label'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Custom Label',
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result == null || result.isEmpty) {
      return;
    }

    try {
      await ApiScope.of(
        context,
      ).updateBarcode(id: barcodeId, customLabel: result);
      if (!mounted) return;
      await _load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Custom label updated successfully')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  void _confirmDelete(MockBarcodeItem item) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete barcode?'),
        content: Text('Delete ${item.code} from the live API?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final barcodeId = item.apiId ?? item.id;
                await ApiScope.of(context).deleteBarcode(barcodeId);
                if (!mounted) return;
                setState(
                  () => _items.removeWhere((entry) => entry.id == item.id),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Barcode deleted')),
                );
              } catch (error) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      error.toString().replaceFirst('Exception: ', ''),
                    ),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTiny = screenWidth < 380;
    final searchFontSize = isTiny ? 13.0 : 14.0;
    final iconSize = isTiny ? 18.0 : 20.0;
    final fabLabelSize = isTiny ? 12.0 : 14.0;
    final filtered = _items
        .where(
          (item) =>
              item.productName.toLowerCase().contains(
                _searchController.text.toLowerCase(),
              ) ||
              item.code.toLowerCase().contains(
                _searchController.text.toLowerCase(),
              ),
        )
        .toList();

    return AdminShell(
      title: 'Barcode List',
      selectedPath: '/barcode-list',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/generate-barcode'),
        icon: Icon(Icons.add_rounded, size: isTiny ? 18 : 20),
        label: Text(
          isTiny ? 'Generate' : 'Generate New Barcode',
          style: TextStyle(fontSize: fabLabelSize),
        ),
      ),
      child: ListView(
        padding: AppResponsive.pagePadding(context),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 360;
              final searchField = TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontSize: searchFontSize),
                decoration: InputDecoration(
                  hintText: 'Search barcodes',
                  prefixIcon: Icon(Icons.search_rounded, size: iconSize),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              );
              final filterButton = IconButton.filledTonal(
                onPressed: () => setState(() => _showEmpty = !_showEmpty),
                icon: Icon(Icons.filter_alt_rounded, size: iconSize),
              );
              return stacked
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        searchField,
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: filterButton,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: searchField),
                        const SizedBox(width: 10),
                        filterButton,
                      ],
                    );
            },
          ),
          const SizedBox(height: 12),
          if (_error != null)
            AppCard(
              child: ListTile(
                leading: const Icon(Icons.error_outline_rounded),
                title: const Text('API load failed'),
                subtitle: Text(_error!),
              ),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_showEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 28),
              child: EmptyStateWidget(
                title: 'No barcodes to show',
                message:
                    'This empty state can be toggled on for demo purposes.',
              ),
            )
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 760 ? 2 : 1;
                final cardWidth = crossAxisCount == 2
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final entry in filtered.asMap().entries)
                      SizedBox(
                        width: cardWidth,
                        child:
                            BarcodeCard(
                                  item: entry.value,
                                  onView: () => context.go(
                                    '/barcode-detail/${entry.value.apiId ?? entry.value.id}',
                                  ),
                                  onEdit: () => _editBarcode(entry.value),
                                  onDelete: () => _confirmDelete(entry.value),
                                )
                                .animate()
                                .fadeIn(delay: (entry.key * 70).ms)
                                .slideY(begin: 0.04, end: 0),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            CustomButton(
              label: 'Load More',
              loading: _loadingMore,
              onPressed: _loadMore,
            ),
            const SizedBox(height: 80),
          ],
        ],
      ),
    );
  }
}
