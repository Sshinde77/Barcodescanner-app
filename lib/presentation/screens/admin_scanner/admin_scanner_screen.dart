import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_assets.dart';
import '../../../data/api/api_models.dart';
import '../../../data/api/api_provider.dart';
import '../../widgets/admin_shell.dart';
import '../../widgets/app_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

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
  final List<ScanHistorySnapshot> _history = [];
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
      final response = await ApiScope.of(context).fetchScanHistory(perPage: 10);
      if (!mounted) return;
      setState(() {
        _history
          ..clear()
          ..addAll(response.items);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected.')),
      );
      return;
    }

    final file = result.files.single;
    setState(() => _pickedImageName = file.name);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected image: ${file.name}')),
    );
  }

  void _prependHistory(ScanHistorySnapshot item) {
    setState(() {
      _history.insert(0, item);
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
    _processScannedCode(code);
  }

  Future<void> _processScannedCode(String code) async {
    try {
      final result = await ApiScope.of(context).scanBarcode(code);
      if (!mounted) return;

      _prependHistory(
        ScanHistorySnapshot(
          uniqueCode: result.uniqueCode,
          scanResult: 'success',
          createdAt: DateTime.now(),
          productDataSnapshot: ScanProductDataSnapshot(
            uniqueCode: result.uniqueCode,
            barcodeFormat: result.barcodeFormat,
            customLabel: result.customLabel,
            product: result.product,
          ),
        ),
      );
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

  void _showResult({
    required String code,
    required ScanResultData result,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              AppAssets.successAnimation,
              height: 140,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.verified_rounded, size: 72),
            ),
            const SizedBox(height: 12),
            Text('Scanned code: $code'),
            if (result.productName != null) ...[
              const SizedBox(height: 6),
              Text(result.productName!),
            ],
          ],
        ),
      ),
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
                  width: 320,
                  height: 320,
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

  String _historyLabel(ScanHistorySnapshot item) {
    final snapshot = item.productDataSnapshot;
    return snapshot?.customLabel ?? snapshot?.product?.name ?? item.uniqueCode ?? 'Scanned Barcode';
  }

  String _historySubtitle(ScanHistorySnapshot item) {
    final scanResult = item.scanResult ?? 'success';
    final createdAt = item.createdAt;
    if (createdAt == null) {
      return scanResult;
    }
    return '$scanResult - ${createdAt.toLocal().toString().split('.').first}';
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Admin Scanner',
      selectedPath: '/admin-scanner',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Selected image: $_pickedImageName',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Recent Scans',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          if (_loadingHistory)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_history.isEmpty)
            AppCard(
              child: ListTile(
                leading: const Icon(Icons.history_rounded),
                title: const Text('No recent scans'),
                subtitle: const Text(
                  'Scanned barcodes will appear here after the first scan.',
                ),
              ),
            )
          else
            ..._history.map(
              (item) => AppCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.10),
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(_historySubtitle(item)),
                          const SizedBox(height: 6),
                          Text(
                            item.uniqueCode ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: item.uniqueCode ?? ''),
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
          const SizedBox(height: 16),
          AppCard(
            child: Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _controller,
                    label: 'Manual scan input',
                    prefixAssetPath: 'assets/images/keyboard1.png',
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _controller.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Manual input copied')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('Admin shell active'),
              subtitle: const Text(
                'This scanner lives inside the dashboard scaffold.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
