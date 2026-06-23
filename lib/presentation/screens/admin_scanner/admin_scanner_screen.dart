import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/api/api_models.dart';
import '../../../data/api/api_provider.dart';
import '../../../data/cache/scan_history_cache.dart';
import '../../../data/mock/mock_scan_history.dart';
import '../../widgets/admin_shell.dart';
import '../../widgets/app_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/empty_state_widget.dart';

class AdminScannerScreen extends StatefulWidget {
  const AdminScannerScreen({super.key});

  @override
  State<AdminScannerScreen> createState() => _AdminScannerScreenState();
}

class _AdminScannerScreenState extends State<AdminScannerScreen> {
  final _controller = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final List<MockScanHistoryItem> _history = [];
  bool _isScanning = false;
  bool _isRequestingCameraPermission = false;
  bool _isRequestingImagePermission = false;
  bool _loadingHistory = false;
  String? _pickedImageName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final history = await ScanHistoryCache.load();
      if (!mounted) return;
      setState(() {
        _history
          ..clear()
          ..addAll(history);
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingHistory = false);
      }
    }
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
    _processScannedCode(code, source: 'Camera Scanner');
  }

  Future<void> _processScannedCode(
    String code, {
    required String source,
  }) async {
    try {
      final result = await ApiScope.of(context).scanBarcode(uniqueCode: code);
      if (!mounted) return;
      _addHistoryItem(code: code, result: result, source: source);
      _showResult(code: result.uniqueCode ?? code, result: result);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  void _addHistoryItem({
    required String code,
    required ScanResultData result,
    required String source,
  }) {
    final historyItem = MockScanHistoryItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: result.productName ?? result.customLabel ?? 'Scanned Barcode',
      code: result.uniqueCode ?? code,
      time: result.scannedAt?.toLocal().toString().split('.').first ??
          DateTime.now().toLocal().toString().split('.').first,
      subtitle: source,
      isValid: result.valid,
      barcodeFormat: result.barcodeFormat,
      customLabel: result.customLabel,
      productName: result.productName ?? result.product?.name,
      barcodeImageUrl: result.barcodeImageUrl,
      scannedAt: result.scannedAt,
      brand: result.product?.brand,
      category: result.product?.category,
      unit: result.product?.unit,
      stockQuantity: result.product?.stockQuantity,
    );

    setState(() {
      _history.insert(0, historyItem);
      if (_history.length > 10) {
        _history.removeRange(10, _history.length);
      }
    });

    unawaited(ScanHistoryCache.save(_history));
  }

  Map<String, String> _scanResultDetails(ScanResultData result) {
    return {
      'Status': result.valid ? 'Valid' : 'Invalid',
      'Unique Code': result.uniqueCode ?? '-',
      'Barcode Format': result.barcodeFormat ?? '-',
      'Custom Label': result.customLabel ?? '-',
      'Product Name': result.productName ?? result.product?.name ?? '-',
      'Scanned At': result.scannedAt?.toLocal().toString().split('.').first ??
          '-',
      'Barcode Image URL': result.barcodeImageUrl ?? '-',
      'SKU': result.product?.sku ?? '-',
      'Brand': result.product?.brand ?? '-',
      'Category': result.product?.category ?? '-',
      'Unit': result.product?.unit ?? '-',
      'Stock Quantity': result.product?.stockQuantity?.toString() ?? '-',
    };
  }

  Map<String, String> _historyDetails(MockScanHistoryItem item) {
    return {
      'Status': item.isValid == null
          ? '-'
          : (item.isValid == true ? 'Valid' : 'Invalid'),
      'Source': item.subtitle,
      'Unique Code': item.code,
      'Barcode Format': item.barcodeFormat ?? '-',
      'Custom Label': item.customLabel ?? '-',
      'Product Name': item.productName ?? '-',
      'Scanned At': item.scannedAt == null
          ? item.time
          : item.scannedAt!.toLocal().toString().split('.').first,
      'Barcode Image URL': item.barcodeImageUrl ?? '-',
      'Brand': item.brand ?? '-',
      'Category': item.category ?? '-',
      'Unit': item.unit ?? '-',
      'Stock Quantity': item.stockQuantity?.toString() ?? '-',
    };
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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

  Future<void> _showDetailsPopup({
    required String title,
    required String source,
    required String code,
    required Map<String, String> details,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(dialogContext).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  source,
                  style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                    color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      dialogContext,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SelectableText(
                    code,
                    style: Theme.of(dialogContext).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 14),
                for (final entry in details.entries) ...[
                  _detailRow(dialogContext, entry.key, entry.value),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        label: 'Copy Code',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(content: Text('Code copied')),
                          );
                        },
                        fullWidth: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        label: 'Close',
                        variant: CustomButtonVariant.outline,
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        fullWidth: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showResult({
    required String code,
    required ScanResultData result,
  }) {
    return _showDetailsPopup(
      title: 'Scan Result',
      source: 'API result',
      code: code,
      details: _scanResultDetails(result),
    );
  }

  Future<void> _showHistoryDetails(MockScanHistoryItem item) {
    return _showDetailsPopup(
      title: 'Recent Scan',
      source: item.subtitle,
      code: item.code,
      details: _historyDetails(item),
    );
  }

  Widget _buildScannerPreview(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
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
                  width: double.infinity,
                  height: double.infinity,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: 240,
                        height: 240,
                        child: Lottie.asset(
                          'assets/lottie/qrscanner.json',
                          fit: BoxFit.contain,
                          repeat: true,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.document_scanner_rounded,
                            size: 96,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
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
    final value = _controller.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter barcode data first'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    _processScannedCode(value, source: 'Manual Entry');
  }

  String _historyLabel(MockScanHistoryItem item) {
    if (item.title.isNotEmpty) {
      return item.title;
    }
    return item.customLabel ?? item.productName ?? item.code;
  }

  String _historySubtitle(MockScanHistoryItem item) {
    final scanResult = item.isValid == null
        ? 'Scan'
        : (item.isValid == true ? 'Valid scan' : 'Invalid scan');
    final time = item.scannedAt == null
        ? item.time
        : item.scannedAt!.toLocal().toString().split('.').first;
    return '$scanResult - ${item.subtitle} - $time';
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Admin Scanner',
      selectedPath: '/admin-scanner',
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
                  'Admin scanner with live API results and recent scan history.',
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
          const SizedBox(height: 16),
          AppCard(
            child: Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _controller,
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
          Builder(
            builder: (context) {
              final width = MediaQuery.sizeOf(context).width;
              final titleSize = width < 360 ? 18.0 : 22.0;
              return Text(
                'Recent Scans',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          if (_loadingHistory)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_history.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: EmptyStateWidget(
                title: 'No scans yet',
                message:
                    'Your cached scan history will appear here after the first scan.',
              ),
            )
          else
            ..._history.map(
              (item) => AppCard(
                onTap: () => _showHistoryDetails(item),
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.10),
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
                            _historyLabel(item),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(_historySubtitle(item)),
                          const SizedBox(height: 6),
                          Text(
                            item.code,
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
                          ClipboardData(text: item.code),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code copied')),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded),
                    ),
                  ],
                ),
              ),
            ),
          // AppCard(
          //   child: ListTile(
          //     leading: const Icon(Icons.info_outline_rounded),
          //     title: const Text('Admin shell active'),
          //     subtitle: const Text(
          //       'This scanner lives inside the dashboard scaffold.',
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
