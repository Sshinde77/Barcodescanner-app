import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/api/api_models.dart';
import '../../../data/api/api_provider.dart';
import '../../../data/cache/scan_history_cache.dart';
import '../../../data/mock/mock_scan_history.dart';
import '../shared/barcode_image_decoder.dart';
import '../shared/barcode_path_exists_stub.dart'
    if (dart.library.io) '../shared/barcode_path_exists_io.dart';
import '../../widgets/admin_shell.dart';
import '../../widgets/app_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/responsive_layout.dart';

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
  bool _isScanningUploadedImage = false;
  bool _loadingHistory = false;
  PlatformFile? _pickedImageFile;
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
    return true;
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
      withData: true,
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
    setState(() {
      _pickedImageFile = file;
      _pickedImageName = file.name;
    });
  }

  Future<void> _scanPickedBarcodeImage() async {
    final file = _pickedImageFile;
    if (file == null || file.name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick an image before scanning.')),
      );
      return;
    }

    final bytes = await file.xFile.readAsBytes();
    final imageName = _pickedImageName ?? file.name;
    final decodedCode = await _decodeBarcodeFromUploadedImage(file, bytes);
    if (bytes.isEmpty || imageName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected image could not be read.')),
      );
      return;
    }

    if (decodedCode == null || decodedCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No barcode found in the uploaded image.')),
      );
      return;
    }

    setState(() => _isScanningUploadedImage = true);
    try {
      await _scanBarcode(
        code: decodedCode,
        imageBytes: bytes,
        imageName: imageName,
        source: 'Image Upload',
      );
    } finally {
      if (mounted) {
        setState(() => _isScanningUploadedImage = false);
      }
    }
  }

  Future<String?> _decodeBarcodeFromUploadedImage(
    PlatformFile file,
    Uint8List bytes,
  ) async {
    if (kIsWeb) {
      return decodeBarcodeFromImageBytes(
        bytes,
        mimeType: _mimeTypeFromFileName(file.name),
      );
    }

    final path = file.path;
    if (path == null || path.isEmpty) {
      debugPrint('[AdminScanner] Uploaded image path is null or empty');
      return null;
    }

    try {
      debugPrint(
        '[AdminScanner] Analyzing uploaded image path: $path, exists=${barcodePathExists(path)}',
      );
      final capture = await _scannerController.analyzeImage(path);
      if (capture == null) {
        debugPrint('[AdminScanner] Capture result: NULL');
        return null;
      }

      debugPrint(
        '[AdminScanner] Capture result: barcodes=${capture.barcodes.length}',
      );

      for (final barcode in capture.barcodes) {
        final value = barcode.rawValue;
        if (value != null && value.isNotEmpty) {
          debugPrint('[AdminScanner] Decoded barcode from image path: $value');
          return value;
        }
      }

      debugPrint('[AdminScanner] Capture had no rawValue entries');
    } catch (_) {
      return null;
    }

    return null;
  }

  String _mimeTypeFromFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/png';
  }

  Widget _buildUploadedScanButton({
    required bool loading,
    required VoidCallback? onPressed,
    required bool compact,
  }) {
    final button = OutlinedButton(
      onPressed: loading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: Size.fromHeight(compact ? 44 : 54),
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: loading
            ? SizedBox(
                key: const ValueKey('upload-scan-loading'),
                height: compact ? 28 : 40,
                width: compact ? 28 : 40,
                child: CircularProgressIndicator(
                  strokeWidth: compact ? 2.0 : 2.4,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : Row(
                key: const ValueKey('upload-scan-content'),
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: compact ? 16 : 26,
                    height: compact ? 16 : 26,
                    child: Lottie.asset(
                      'assets/lottie/barcode.json',
                      fit: BoxFit.contain,
                      repeat: true,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(
                            Icons.qr_code_rounded,
                            size: compact ? 15 : 18,
                          ),
                    ),
                  ),
                  SizedBox(width: compact ? 4 : 8),
                  Text(
                    'Scan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: compact
                        ? Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          )
                        : null,
                  ),
                ],
              ),
      ),
    );

    return SizedBox(width: double.infinity, child: button);
  }

  Widget _buildUploadActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 420;

        final uploadButton = CustomButton(
          label: 'Upload Image',
          iconAssetPath: 'assets/images/file.png',
          variant: CustomButtonVariant.outline,
          compact: isCompact,
          loading: _isRequestingImagePermission,
          onPressed: _pickBarcodeImage,
        );

        final scanButton = _buildUploadedScanButton(
          loading: _isScanningUploadedImage,
          compact: isCompact,
          onPressed: _pickedImageFile == null ? null : _scanPickedBarcodeImage,
        );

        return Row(
          children: [
            Expanded(child: uploadButton),
            SizedBox(width: isCompact ? 8 : 10),
            Expanded(child: scanButton),
          ],
        );
      },
    );
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

  Future<void> _scanBarcode({
    String? code,
    Uint8List? imageBytes,
    String? imageName,
    required String source,
  }) async {
    try {
      final result = await ApiScope.of(context).scanBarcode(
        uniqueCode: code,
        barcodeImageBytes: imageBytes,
        barcodeImageName: imageName,
      );
      if (!mounted) return;

      final resolvedCode = result.uniqueCode ?? code ?? imageName ?? 'Scanned Barcode';
      _addHistoryItem(
        code: resolvedCode,
        result: result,
        source: source,
      );
      _showResult(code: resolvedCode, result: result);
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
      time:
          result.scannedAt?.toLocal().toString().split('.').first ??
          DateTime.now().toLocal().toString().split('.').first,
      subtitle: source,
      isValid: result.valid,
      barcodeFormat: result.barcodeFormat,
      customLabel: result.customLabel,
      productName: result.productName ?? result.product?.name,
      barcodeImageUrl: result.barcodeImageUrl,
      publicLink: result.publicLink ?? result.barcodeImageUrl,
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
      'Unique Code': result.uniqueCode ?? '-',
      'Barcode Format': result.barcodeFormat ?? '-',
      'Barcode Data': result.barcodeData ?? result.customLabel ?? '-',
      'Public Link': result.publicLink ?? result.barcodeImageUrl ?? '-',
      'Product Name': result.productName ?? result.product?.name ?? '-',
      'Scanned At':
          result.scannedAt?.toLocal().toString().split('.').first ?? '-',
    };
  }

  Map<String, String> _historyDetails(MockScanHistoryItem item) {
    return {
      'Unique Code': item.code,
      'Barcode Format': item.barcodeFormat ?? '-',
      'Barcode Data': item.customLabel ?? '-',
      'Public Link': item.publicLink ?? item.barcodeImageUrl ?? '-',
      'Product Name': item.productName ?? '-',
      'Scanned At': item.scannedAt == null
          ? item.time
          : item.scannedAt!.toLocal().toString().split('.').first,
    };
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    final isLink = label == 'Public Link' && value.startsWith('http');
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
          child: isLink
              ? Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _openPublicLink(value),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      value,
                      textAlign: TextAlign.right,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                )
              : Text(
                  value,
                  textAlign: TextAlign.right,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
        ),
      ],
    );
  }

  Future<void> _openPublicLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the public link.')),
      );
    }
  }

  Future<void> _showDetailsPopup({
    required String title,
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 360;
                    final copyButton = CustomButton(
                      label: 'Copy Code',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('Code copied')),
                        );
                      },
                      fullWidth: false,
                    );
                    final closeButton = CustomButton(
                      label: 'Close',
                      variant: CustomButtonVariant.outline,
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      fullWidth: false,
                    );
                    return stacked
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              copyButton,
                              const SizedBox(height: 12),
                              closeButton,
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: copyButton),
                              const SizedBox(width: 12),
                              Expanded(child: closeButton),
                            ],
                          );
                  },
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
      code: code,
      details: _scanResultDetails(result),
    );
  }

  Future<void> _showHistoryDetails(MockScanHistoryItem item) {
    return _showDetailsPopup(
      title: 'Recent Scan',
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
        padding: AppResponsive.pagePadding(context, top: AppSpacing.lg),
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
                _buildUploadActions(),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final field = CustomTextField(
                  controller: _controller,
                  label: 'Manual barcode input',
                  hint: 'Enter barcode manually',
                  prefixAssetPath: 'assets/images/keyboard1.png',
                );
                final action = IconButton(
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
                  );
                return Row(
                  children: [
                    Expanded(child: field),
                    const SizedBox(width: 8),
                    action,
                  ],
                );
              },
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
                      child: Center(
                        child: Lottie.asset(
                          'assets/lottie/barcode.json',
                          width: 30,
                          height: 30,
                          fit: BoxFit.contain,
                        ),
                      ),
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
                        Clipboard.setData(ClipboardData(text: item.code));
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
