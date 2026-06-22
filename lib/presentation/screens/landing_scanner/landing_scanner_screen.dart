import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/api/api_provider.dart';
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
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final List<MockScanHistoryItem> _history = List.of(mockScanHistory);
  bool _isScanning = false;
  bool _isRequestingCameraPermission = false;
  bool _isRequestingImagePermission = false;
  String? _pickedImageName;

  @override
  void dispose() {
    _manualController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) {
      return true;
    }

    final status = await Permission.camera.request();
    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (!mounted) {
      return false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Camera permission is required to scan barcodes.'),
      ),
    );
    return false;
  }

  Future<bool> _requestImagePermission() async {
    if (kIsWeb) {
      return true;
    }

    final statuses = await Future.wait([
      Permission.storage.request(),
      Permission.photos.request(),
    ]);

    final granted = statuses.any(
      (status) => status.isGranted || status.isLimited,
    );
    if (granted) {
      return true;
    }

    if (!mounted) {
      return false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Storage permission is required to pick images.'),
      ),
    );
    return false;
  }

  Future<void> _startCameraScan() async {
    setState(() => _isRequestingCameraPermission = true);
    final granted = await _requestCameraPermission();
    if (!mounted) {
      return;
    }
    setState(() => _isRequestingCameraPermission = false);
    if (!granted) {
      return;
    }

    setState(() => _isScanning = true);
    await _scannerController.start();
  }

  Future<void> _stopCameraScan() async {
    await _scannerController.stop();
    if (!mounted) {
      return;
    }
    setState(() => _isScanning = false);
  }

  Future<void> _pickBarcodeImage() async {
    setState(() => _isRequestingImagePermission = true);
    final granted = await _requestImagePermission();
    if (!mounted) {
      return;
    }
    setState(() => _isRequestingImagePermission = false);
    if (!granted) {
      return;
    }

    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (!mounted) {
      return;
    }

    if (result == null || result.files.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No image selected.')));
      return;
    }

    final file = result.files.single;
    setState(() => _pickedImageName = file.name);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Selected image: ${file.name}')));
  }

  void _addHistoryItem({
    required String code,
    required String title,
    required String subtitle,
  }) {
    setState(() {
      _history.insert(
        0,
        MockScanHistoryItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: title,
          code: code,
          time: 'Just now',
          subtitle: subtitle,
        ),
      );
      if (_history.length > 10) {
        _history.removeRange(10, _history.length);
      }
    });
  }

  void _handleBarcodeDetection(BarcodeCapture capture) {
    String? code;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.isNotEmpty) {
        code = value;
        break;
      }
    }

    if (code == null || !_isScanning) {
      return;
    }

    _stopCameraScan();
    _scanBarcode(code, source: 'Camera Scanner');
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

  Future<void> _scanBarcode(String code, {required String source}) async {
    try {
      final result = await ApiScope.of(context).scanBarcode(code);
      if (!mounted) return;

      _addHistoryItem(
        code: result.uniqueCode ?? code,
        title: result.productName ?? result.customLabel ?? 'Scanned Barcode',
        subtitle: source,
      );
      _showResultSheet(
        code: result.uniqueCode ?? code,
        product: result.productName ?? result.customLabel ?? 'Scanned Barcode',
        location: source,
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

  Widget _buildScannerPreview(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.10),
              ],
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: _isScanning
              ? MobileScanner(
                  controller: _scannerController,
                  fit: BoxFit.cover,
                  onDetect: _handleBarcodeDetection,
                  errorBuilder: (context, error) => Container(
                    color: Theme.of(context).colorScheme.surface,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.no_photography_rounded,
                          size: 72,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 12),
                        const Text('Camera unavailable'),
                      ],
                    ),
                  ),
                )
              : SizedBox(
                  width: 320,
                  height: 320,
                  child: Lottie.asset(
                    'assets/lottie/qrscanner.json',
                    fit: BoxFit.contain,
                    repeat: true,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.document_scanner_rounded,
                      size: 112,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
        ),
        _ScanFrameOverlay(color: Theme.of(context).colorScheme.primary),
        if (_isScanning)
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.black.withValues(alpha: 0.45),
              shape: const CircleBorder(),
              child: IconButton(
                onPressed: _stopCameraScan,
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ),
      ],
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

    _scanBarcode(value, source: 'Public Scanner');
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
            child: const Text('Login to Dashboard'),
          ),
          // TextButton(
          //   onPressed: () => context.go('/register'),
          //   child: const Text('Register'),
          // ),
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
                      color: Colors.white.withValues(alpha: 0.9),
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
                    child: _buildScannerPreview(context),
                  ),
                  const SizedBox(height: 14),
                  CustomButton(
                    label: 'Scan Barcode',
                    iconAssetPath: 'assets/images/camera.png',
                    loading: _isRequestingCameraPermission,
                    onPressed: _isScanning ? _stopCameraScan : _startCameraScan,
                  ),
                  const SizedBox(height: 10),
                  CustomButton(
                    label: 'Upload Image to Scan',
                    iconAssetPath: 'assets/images/file.png',
                    variant: CustomButtonVariant.outline,
                    loading: _isRequestingImagePermission,
                    onPressed: _pickBarcodeImage,
                  ),
                  if (_pickedImageName != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Selected image: $_pickedImageName',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
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
                      prefixAssetPath: 'assets/images/keyboard1.png',
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: _manualSearch,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(54, 54),
                    ),
                    icon: SizedBox(
                      width: 38,
                      height: 38,
                      child: Transform.scale(
                        scale: 5.35,
                        child: Lottie.asset(
                          'assets/lottie/search.json',
                          fit: BoxFit.contain,
                          repeat: true,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.search_rounded),
                        ),
                      ),
                    ),
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
              ..._history.asMap().entries.map((entry) {
                final item = entry.value;
                return Dismissible(
                  key: ValueKey(item.id),
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
                      color: AppColors.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.delete_rounded,
                      color: AppColors.danger,
                    ),
                  ),
                  child:
                      AppCard(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  height: 52,
                                  width: 52,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.receipt_long_rounded),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(item.subtitle),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${item.code} - ${item.time}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
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
                                      ClipboardData(text: item.code),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Code copied'),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.copy_rounded),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 250.ms)
                          .slideX(begin: 0.06, end: 0),
                );
              }),
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
