import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showResult() {
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
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.verified_rounded, size: 72),
            ),
            const SizedBox(height: 12),
            const Text('Admin scan completed'),
          ],
        ),
      ),
    );
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
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.10),
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
                          child: Lottie.asset(
                            'assets/lottie/qrscanner.json',
                            fit: BoxFit.contain,
                            repeat: true,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.document_scanner_rounded,
                              size: 96,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                CustomButton(
                  label: 'Scan Barcode',
                  icon: Icons.camera_alt_rounded,
                  onPressed: _showResult,
                ),
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
                    label: 'Manual scan input',
                    prefixIcon: Icons.confirmation_number_rounded,
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
