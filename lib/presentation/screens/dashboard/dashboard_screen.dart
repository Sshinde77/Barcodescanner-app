import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/api/api_models.dart';
import '../../../data/api/api_provider.dart';
import '../../widgets/admin_shell.dart';
import '../../widgets/app_card.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardStats? _stats;
  List<RecentBarcodeItem> _recentBarcodes = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ApiScope.of(context);
      final stats = await api.fetchDashboardStats();
      final recent = await api.fetchRecentBarcodes(perPage: 10);
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _recentBarcodes = recent.items;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _refresh() async {
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ApiScope.of(context).currentUser;
    return AdminShell(
      title: 'Dashboard',
      selectedPath: '/dashboard',
      onRefresh: _refresh,
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        const SizedBox(width: 6),
      ],
      child: ListView(
        padding: AppResponsive.pagePadding(context, top: AppSpacing.lg),
        children: [
          AppCard(
            gradient: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkHeroGradient
                : AppColors.primaryGradient,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 340;
                final greeting = Text(
                  'Hello, ${currentUser?.name ?? 'Admin'}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: stacked ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                );

                return stacked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.white24,
                            child: Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          greeting,
                        ],
                      )
                    : Row(
                        children: [
                          const CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.white24,
                            child: Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: greeting),
                        ],
                      );
              },
            ),
          ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.05, end: 0),
          const SizedBox(height: 18),
          if (_error != null)
            AppCard(
              child: ListTile(
                leading: const Icon(Icons.error_outline_rounded),
                title: const Text('API load failed'),
                subtitle: Text(_error!),
              ),
            ),
          if (_loading) ...[
            const SizedBox(height: 18),
            const Center(child: CircularProgressIndicator()),
          ] else ...[
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final stats = _stats;
                final crossAxisCount = AppResponsive.gridColumns(
                  constraints.maxWidth,
                );
                final spacing = 12.0;
                final cards = [
                  StatCard(
                    label: 'Total Barcodes Generated',
                    value: stats?.totalBarcodes ?? 0,
                    icon: Icons.qr_code_rounded,
                    tint: AppColors.primary,
                  ),
                  StatCard(
                    label: 'Total Scans Today',
                    value: stats?.scansToday ?? 0,
                    icon: Icons.document_scanner_rounded,
                    tint: AppColors.secondary,
                  ),
                  StatCard(
                    label: 'Unique Barcode Data',
                    value: stats?.uniqueBarcodeData ?? 0,
                    icon: Icons.inventory_2_outlined,
                    tint: AppColors.warning,
                  ),
                  StatCard(
                    label: 'Active Users',
                    value: stats?.activeUsers ?? 0,
                    icon: Icons.group_rounded,
                    tint: AppColors.info,
                  ),
                ];
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: crossAxisCount == 1
                      ? 3.4
                      : crossAxisCount == 2
                      ? constraints.maxWidth > 700
                            ? 2.8
                            : 2.15
                      : 2.2,
                  children: cards,
                );
              },
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 360;
                final title = Text(
                  'Recent Generated Barcodes',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                );
                final action = TextButton(
                  onPressed: () => context.go('/barcode-list'),
                  child: const Text('View all'),
                );
                return stacked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [title, action],
                      )
                    : Row(
                        children: [
                          Expanded(child: title),
                          action,
                        ],
                      );
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 176,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _recentBarcodes.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = _recentBarcodes[index];
                  final displayTitle =
                      item.productName ?? item.customLabel ?? 'Barcode';
                  return AppCard(
                        onTap: item.id == null
                            ? null
                            : () => context.go('/barcode-detail/${item.id}'),
                        padding: const EdgeInsets.all(14),
                        child: SizedBox(
                          width: 200,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 74,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.qr_code_2_rounded,
                                  color: Colors.white,
                                  size: 34,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                displayTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const Spacer(),
                              Text(item.uniqueCode ?? item.barcodeData ?? ''),
                            ],
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: (index * 90).ms)
                      .slideX(begin: 0.08, end: 0);
                },
              ),
            ),
            const SizedBox(height: 20),
            // AppCard(
            //   child: ListTile(
            //     contentPadding: EdgeInsets.zero,
            //     leading: const CircleAvatar(
            //       backgroundColor: Color(0xFFDCFCE7),
            //       child: Icon(Icons.refresh_rounded, color: AppColors.success),
            //     ),
            //     title: const Text('Pull-to-refresh is enabled'),
            //     subtitle: const Text(
            //       'The dashboard now loads live stats and recent barcodes from the API.',
            //     ),
            //   ),
            // ),
          ],
        ],
      ),
    );
  }
}
