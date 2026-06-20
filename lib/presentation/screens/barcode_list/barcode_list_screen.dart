import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../data/mock/mock_barcodes.dart';
import '../../widgets/admin_shell.dart';
import '../../widgets/app_card.dart';
import '../../widgets/barcode_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/shimmer_loader.dart';

class BarcodeListScreen extends StatefulWidget {
  const BarcodeListScreen({super.key});

  @override
  State<BarcodeListScreen> createState() => _BarcodeListScreenState();
}

class _BarcodeListScreenState extends State<BarcodeListScreen> {
  final _searchController = TextEditingController();
  bool _showEmpty = false;
  bool _loading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _confirmDelete(MockBarcodeItem item) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete barcode?'),
        content: Text('Remove ${item.code} from the local mock list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = mockBarcodes
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
          if (_showEmpty)
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
                          onView: () =>
                              context.go('/barcode-detail/${item.id}'),
                          onEdit: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Edit is mock-only'),
                                ),
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
              loading: _loading,
              onPressed: _loadMore,
            ),
            const SizedBox(height: 80),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/generate-barcode'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Generate New Barcode'),
      ),
    );
  }
}
