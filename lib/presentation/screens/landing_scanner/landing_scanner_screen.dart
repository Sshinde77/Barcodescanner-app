import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

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
import '../../../data/api/api_models.dart';
import '../../../data/api/api_provider.dart';
import '../../../data/api/api_service.dart';
import '../../../data/cache/scan_history_cache.dart';
import '../../../data/mock/mock_scan_history.dart';
import '../shared/barcode_image_decoder.dart';
import '../shared/barcode_path_exists_stub.dart'
    if (dart.library.io) '../shared/barcode_path_exists_io.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/responsive_layout.dart';

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
  final List<MockScanHistoryItem> _history = [];
  bool _isScanning = false;
  bool _isRequestingCameraPermission = false;
  bool _isRequestingImagePermission = false;
  bool _isScanningUploadedImage = false;
  PlatformFile? _pickedImageFile;
  String? _pickedImageName;

  void _log(String message) {
    debugPrint('[LandingScanner] $message');
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadHistory());
  }

  @override
  void dispose() {
    _manualController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await ScanHistoryCache.load();
    if (!mounted) {
      return;
    }

    setState(() {
      _history
        ..clear()
        ..addAll(history);
    });
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
    _log('Camera scan button clicked');
    setState(() => _isRequestingCameraPermission = true);
    _log('Requesting camera permission');
    final granted = await _requestCameraPermission();
    _log('Camera permission result: $granted');
    if (!mounted) {
      _log('Widget unmounted after camera permission request');
      return;
    }
    setState(() => _isRequestingCameraPermission = false);
    if (!granted) {
      _log('Camera scan cancelled because permission was denied');
      return;
    }

    _log('Starting camera scanner');
    setState(() => _isScanning = true);
    await _scannerController.start();
    _log('Camera scanner started');
  }

  Future<void> _stopCameraScan() async {
    _log('Camera stop button clicked');
    await _scannerController.stop();
    _log('Camera scanner stopped');
    if (!mounted) {
      _log('Widget unmounted after stopping camera scan');
      return;
    }
    setState(() => _isScanning = false);
  }

  Future<void> _pickBarcodeImage() async {
    _log('Upload Image button clicked');
    setState(() => _isRequestingImagePermission = true);
    _log('Requesting image permission');
    final granted = await _requestImagePermission();
    _log('Image permission result: $granted');
    if (!mounted) {
      _log('Widget unmounted after image permission request');
      return;
    }
    setState(() => _isRequestingImagePermission = false);
    if (!granted) {
      _log('Image pick cancelled because permission was denied');
      return;
    }

    _log('Opening file picker for uploaded barcode image');
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    _log('File picker returned: ${result == null ? 'null' : 'result'}');

    if (!mounted) {
      _log('Widget unmounted after file picker returned');
      return;
    }

    if (result == null || result.files.isEmpty) {
      _log('No image selected');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No image selected.')));
      return;
    }

    final file = result.files.single;
    _log(
      'Picked image file: name=${file.name}, size=${file.size}, hasBytes=${file.bytes != null}',
    );
    setState(() {
      _pickedImageFile = file;
      _pickedImageName = file.name;
    });
    _log('Uploaded image stored for scan button');
  }

  Future<void> _scanPickedBarcodeImage() async {
    _log('Scan uploaded image button clicked');
    final file = _pickedImageFile;
    if (file == null || file.name.isEmpty) {
      _log('Scan aborted because no uploaded image is selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick an image before scanning.')),
      );
      return;
    }

    _log('Reading bytes from uploaded image: ${file.name}');
    final bytes = await file.xFile.readAsBytes();
    _log('Read ${bytes.length} bytes from uploaded image');
    final imageName = _pickedImageName ?? file.name;
    final decodedCode = await _decodeBarcodeFromUploadedImage(file, bytes);
    _log('Decoded barcode from uploaded image: ${decodedCode ?? '-'}');
    if (bytes.isEmpty || imageName.isEmpty) {
      _log('Scan aborted because uploaded image bytes are empty or name missing');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected image could not be read.')),
      );
      return;
    }

    if (decodedCode == null || decodedCode.isEmpty) {
      _log('Scan aborted because no barcode was detected in the uploaded image');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No barcode found in the uploaded image.')),
      );
      return;
    }

    _log('Sending uploaded image to API: code=$decodedCode, name=$imageName');
    setState(() => _isScanningUploadedImage = true);
    try {
      await _scanBarcode(
        code: decodedCode,
        imageBytes: bytes,
        imageName: imageName,
        source: 'Image Upload',
      );
      _log('Uploaded image scan finished');
    } finally {
      if (mounted) {
        setState(() => _isScanningUploadedImage = false);
        _log('Upload scan loading state cleared');
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
      _log('Uploaded image path is null or empty');
      return null;
    }

    try {
      _log(
        'Analyzing uploaded image path: $path, exists=${barcodePathExists(path)}',
      );
      final capture = await _scannerController.analyzeImage(path);
      if (capture == null) {
        _log('Capture result: NULL');
        return null;
      }

      _log('Capture result: barcodes=${capture.barcodes.length}');

      for (final barcode in capture.barcodes) {
        final value = barcode.rawValue;
        if (value != null && value.isNotEmpty) {
          _log('Decoded barcode from image path: $value');
          return value;
        }
      }

      _log('Capture had no rawValue entries');
    } catch (error) {
      _log('Image analysis failed: $error');
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

  void _addHistoryItem({
    required String code,
    required String title,
    required String subtitle,
    required ScanResultData result,
  }) {
    setState(() {
      _history.insert(
        0,
        MockScanHistoryItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: title,
          code: code,
          time:
              result.scannedAt?.toLocal().toString().split('.').first ??
              'Just now',
          subtitle: subtitle,
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
        ),
      );
      if (_history.length > 10) {
        _history.removeRange(10, _history.length);
      }
    });
    unawaited(ScanHistoryCache.save(_history));
  }

  void _handleBarcodeDetection(BarcodeCapture capture) {
    _log('Camera detection callback fired with ${capture.barcodes.length} barcode(s)');
    String? code;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.isNotEmpty) {
        code = value;
        _log('Detected camera barcode value: $value');
        break;
      }
    }

    if (code == null || !_isScanning) {
      _log('Ignoring camera detection. code=$code, isScanning=$_isScanning');
      return;
    }

    _log('Camera code accepted, stopping scanner and processing result');
    setState(() => _isScanning = false);
    unawaited(_scannerController.stop());
    _scanBarcode(code: code, source: 'Camera Scanner');
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return '-';
    }

    return value.toLocal().toString().split('.').first;
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

  Map<String, String> _scanResultDetails({
    required ScanResultData result,
  }) {
    return {
      'Unique Code': result.uniqueCode ?? '-',
      'Barcode Format': result.barcodeFormat ?? '-',
      'Barcode Data': result.barcodeData ?? result.customLabel ?? '-',
      'Public Link': result.publicLink ?? result.barcodeImageUrl ?? '-',
      'Product Name': result.productName ?? result.product?.name ?? '-',
      'Scanned At': _formatDateTime(result.scannedAt),
    };
  }

  Map<String, String> _historyDetails(MockScanHistoryItem item) {
    return {
      'Unique Code': item.code,
      'Barcode Format': item.barcodeFormat ?? '-',
      'Barcode Data': item.customLabel ?? '-',
      'Public Link': item.barcodeImageUrl ?? '-',
      'Product Name': item.productName ?? '-',
      'Scanned At': item.scannedAt == null ? item.time : _formatDateTime(item.scannedAt),
    };
  }

  Future<void> _showDetailsPopup({
    required String title,
    required String code,
    required Map<String, String> details,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: AppCard(
            padding: const EdgeInsets.all(18),
            child: SingleChildScrollView(
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
                  const SizedBox(height: 14),
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
      ),
    );
  }

  Future<void> _scanBarcode({
    String? code,
    Uint8List? imageBytes,
    String? imageName,
    required String source,
  }) async {
    _log(
      'API scan started. source=$source, code=${code ?? '-'}, imageName=${imageName ?? '-'}, imageBytes=${imageBytes?.length ?? 0}',
    );
    try {
      final result = await ApiScope.of(context).scanBarcode(
        uniqueCode: code,
        barcodeImageBytes: imageBytes,
        barcodeImageName: imageName,
      );
      final responseLog = {
        'valid': result.valid,
        'unique_code': result.uniqueCode,
        'barcode_format': result.barcodeFormat,
        'custom_label': result.customLabel,
        'barcode_image_url': result.barcodeImageUrl,
        'product_name': result.productName,
        'scanned_at': result.scannedAt?.toIso8601String(),
        'product': result.product == null
            ? null
            : {
                'id': result.product!.id,
                'name': result.product!.name,
                'sku': result.product!.sku,
                'description': result.product!.description,
                'price': result.product!.price,
                'brand': result.product!.brand,
                'category': result.product!.category,
                'unit': result.product!.unit,
                'stock_quantity': result.product!.stockQuantity,
                'raw': result.product!.raw,
              },
      };
      _log(
        'API scan success. valid=${result.valid}, uniqueCode=${result.uniqueCode ?? '-'}, format=${result.barcodeFormat ?? '-'}',
      );
      _log('API response: ${const JsonEncoder.withIndent('  ').convert(responseLog)}');
      if (!mounted) return;

      final resolvedCode =
          result.uniqueCode ?? code ?? imageName ?? 'Scanned Barcode';
      final resolvedTitle =
          result.productName ?? result.customLabel ?? 'Scanned Barcode';

      _addHistoryItem(
        code: resolvedCode,
        title: resolvedTitle,
        subtitle: source,
        result: result,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        _log('Opening scan result dialog');
        unawaited(
          _showDetailsPopup(
            title: 'Scan Result',
            code: resolvedCode,
            details: _scanResultDetails(result: result),
          ),
        );
      });
    } catch (error) {
      if (error is ApiException) {
        _log(
          'API scan failed. statusCode=${error.statusCode}, message=${error.message}',
        );
        _log(
          'API error payload: ${const JsonEncoder.withIndent('  ').convert({
            'message': error.message,
            'status_code': error.statusCode,
            'validation_errors': error.validationErrors
                ?.map(
                  (item) => {
                    'field': item.field,
                    'messages': item.messages,
                  },
                )
                .toList(),
          })}',
        );
      } else {
        _log('API scan failed: $error');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _showHistoryDetails(MockScanHistoryItem item) async {
    await _showDetailsPopup(
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
    _log('Manual search button clicked');
    final value = _manualController.text.trim();
    _log('Manual barcode input value: "$value"');
    if (value.isEmpty) {
      _log('Manual search aborted because input is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter barcode data first'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    _log('Sending manual barcode to API');
    _scanBarcode(code: value, source: 'Manual Entry');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.lg,
        title: Row(
          children: [
            const AppLogo(size: 38),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Smart Barcode Manager',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Builder(
            builder: (context) {
              final compact = AppResponsive.isCompact(context);
              if (compact) {
                return IconButton(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.login_rounded),
                  tooltip: 'Login to Dashboard',
                );
              }
              return TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Login to Dashboard'),
              );
            },
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
                    'API-backed scan results with local scan history.',
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
            const SizedBox(height: 18),
            AppCard(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final field = CustomTextField(
                    controller: _manualController,
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
                    unawaited(ScanHistoryCache.save(_history));
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
                            onTap: () => _showHistoryDetails(item),
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
