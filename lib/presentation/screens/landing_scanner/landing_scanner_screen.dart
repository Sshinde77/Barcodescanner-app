import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/mock/mock_scan_history.dart';
import '../../widgets/app_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/empty_state_widget.dart';

class LandingScannerScreen extends StatefulWidget {
  const LandingScannerScreen({super.key});

  @override
  State<LandingScannerScreen> createState() => _LandingScannerScreenState();
}

class _LandingScannerScreenState extends State<LandingScannerScreen> {
  final TextEditingController _manualController = TextEditingController();
  final List<MockScanHistoryItem> _history = List.of(mockScanHistory);
  bool _loadingScan = false;

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _fakeScan() async {
    setState(() => _loadingScan = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _loadingScan = false);
    _showResultSheet(
      code: 'SBM-2026-001',
      product: 'Premium Thermal Label Pack',
      location: 'Warehouse A',
    );
  }

  void _showResultSheet({
    required String code,
    required String product,
    required String location,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scan Result',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(code),
                  const SizedBox(height: 10),
                  Text('Location: $location'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code copied')),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded),
                      ),
                      const Spacer(),
                      CustomButton(
                        label: 'Open Detail',
                        onPressed: () => context.go('/barcode-detail/001'),
                        fullWidth: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _manualSearch() {
    final value = _manualController.text.trim();
    if (value.isEmpty || value.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid barcode format'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    _showResultSheet(
      code: value,
      product: 'Manual Lookup Result',
      location: 'Public Scanner',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.lg,
        title: Row(
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.qr_code_rounded, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Expanded(child: Text('Smart Barcode Manager')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Login'),
          ),
          TextButton(
            onPressed: () => context.go('/register'),
            child: const Text('Register'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AppCard(
              gradient: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkHeroGradient
                  : AppColors.primaryGradient,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scan, preview, and manage barcodes',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Public scanner with local mock result cards and scan history.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1.25,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.12),
                                Theme.of(
                                  context,
                                ).colorScheme.secondary.withOpacity(0.10),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 330,
                          height: 330,
                          child: Padding(
                            padding: EdgeInsets.zero,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Lottie.asset(
                                'assets/lottie/qrscanner.json',
                                fit: BoxFit.contain,
                                repeat: true,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.document_scanner_rounded,
                                  size: 112,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        _ScanFrameOverlay(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  CustomButton(
                    label: 'Scan Barcode',
                    icon: Icons.camera_alt_rounded,
                    loading: _loadingScan,
                    onPressed: _fakeScan,
                  ),
                  const SizedBox(height: 10),
                  CustomButton(
                    label: 'Upload Image to Scan',
                    icon: Icons.upload_rounded,
                    variant: CustomButtonVariant.outline,
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Upload flow is UI only')),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _manualController,
                      label: 'Manual barcode input',
                      hint: 'Enter barcode manually',
                      prefixIcon: Icons.confirmation_number_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: _manualSearch,
                    icon: const Icon(Icons.search_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Scan History',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (_history.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: EmptyStateWidget(
                  title: 'No scans yet',
                  message:
                      'Your scan history will appear here after the first scan.',
                ),
              )
            else
              ..._history.asMap().entries.map(
                (entry) => Dismissible(
                  key: ValueKey(entry.value.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {
                    setState(() => _history.removeAt(entry.key));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('History item removed')),
                    );
                  },
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.delete_rounded,
                      color: AppColors.danger,
                    ),
                  ),
                  child: AppCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.receipt_long_rounded),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.value.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 3),
                              Text(entry.value.subtitle),
                              const SizedBox(height: 6),
                              Text(
                                '${entry.value.code} � ${entry.value.time}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: entry.value.code),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Code copied')),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 250.ms).slideX(begin: 0.06, end: 0),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScanFrameOverlay extends StatelessWidget {
  const _ScanFrameOverlay({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 28,
            left: 28,
            child: _CornerBracket(color: color, top: true, left: true),
          ),
          Positioned(
            top: 28,
            right: 28,
            child: _CornerBracket(color: color, top: true, left: false),
          ),
          Positioned(
            bottom: 28,
            left: 28,
            child: _CornerBracket(color: color, top: false, left: true),
          ),
          Positioned(
            bottom: 28,
            right: 28,
            child: _CornerBracket(color: color, top: false, left: false),
          ),
        ],
      ),
    );
  }
}

class _CornerBracket extends StatelessWidget {
  const _CornerBracket({
    required this.color,
    required this.top,
    required this.left,
  });

  final Color color;
  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 26,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: top ? BorderSide(color: color, width: 3) : BorderSide.none,
            bottom: top ? BorderSide.none : BorderSide(color: color, width: 3),
            left: left ? BorderSide(color: color, width: 3) : BorderSide.none,
            right: left ? BorderSide.none : BorderSide(color: color, width: 3),
          ),
          borderRadius: BorderRadius.only(
            topLeft: left && top ? const Radius.circular(6) : Radius.zero,
            topRight: !left && top ? const Radius.circular(6) : Radius.zero,
            bottomLeft: left && !top ? const Radius.circular(6) : Radius.zero,
            bottomRight: !left && !top ? const Radius.circular(6) : Radius.zero,
          ),
        ),
      ),
    );
  }
}
