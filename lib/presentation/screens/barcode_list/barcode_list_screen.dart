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
      id: item.id?.toString() ?? item.uniqueCode ?? DateTime.now().microsecondsSinceEpoch.toString(),
      code: item.uniqueCode ?? item.barcodeData ?? '',
      productName: item.productName ?? item.customLabel ?? 'Barcode',
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No more barcodes to load')),
      );
      return;
    }

    setState(() {
      _start += _length;
    });
    await _load(append: true);
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
                await ApiScope.of(context).deleteBarcode(item.id);
                if (!mounted) return;
                setState(() => _items.removeWhere((entry) => entry.id == item.id));
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
        icon: const Icon(Icons.add_rounded),
        label: const Text('Generate New Barcode'),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search barcodes',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: () => setState(() => _showEmpty = !_showEmpty),
                icon: const Icon(Icons.filter_alt_rounded),
              ),
            ],
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
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: crossAxisCount == 1 ? 1.65 : 1.35,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return BarcodeCard(
                          item: item,
                          onView: () => context.go('/barcode-detail/${item.id}'),
                          onEdit: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Edit is live on detail screen')),
                          ),
                          onDelete: () => _confirmDelete(item),
                        )
                        .animate()
                        .fadeIn(delay: (index * 70).ms)
                        .slideY(begin: 0.04, end: 0);
                  },
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
