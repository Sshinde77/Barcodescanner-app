import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:smart_barcode_manager/presentation/screens/admin_scanner/admin_scanner_screen.dart';
import 'package:smart_barcode_manager/presentation/screens/auth/forgot_password_screen.dart';
import 'package:smart_barcode_manager/presentation/screens/auth/login_screen.dart';
import 'package:smart_barcode_manager/presentation/screens/auth/register_screen.dart';
import 'package:smart_barcode_manager/presentation/screens/barcode_detail/barcode_detail_screen.dart';
import 'package:smart_barcode_manager/presentation/screens/barcode_list/barcode_list_screen.dart';
import 'package:smart_barcode_manager/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:smart_barcode_manager/presentation/screens/generate_barcode/generate_barcode_screen.dart';
import 'package:smart_barcode_manager/presentation/screens/landing_scanner/landing_scanner_screen.dart';

class AppRouter {
  static final _rootKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/landing',
    routes: [
      _page('/landing', 'landing', const LandingScannerScreen()),
      _page('/login', 'login', const LoginScreen()),
      _page('/register', 'register', const RegisterScreen()),
      _page(
        '/forgot-password',
        'forgot-password',
        const ForgotPasswordScreen(),
      ),
      _page('/dashboard', 'dashboard', const DashboardScreen()),
      _page(
        '/generate-barcode',
        'generate-barcode',
        const GenerateBarcodeScreen(),
      ),
      _page('/barcode-list', 'barcode-list', const BarcodeListScreen()),
      GoRoute(
        path: '/barcode-detail/:id',
        name: 'barcode-detail',
        pageBuilder: (context, state) => _transitionPage(
          state,
          BarcodeDetailScreen(barcodeId: state.pathParameters['id'] ?? '001'),
        ),
      ),
      _page('/admin-scanner', 'admin-scanner', const AdminScannerScreen()),
    ],
  );

  static GoRoute _page(String path, String name, Widget child) {
    return GoRoute(
      path: path,
      name: name,
      pageBuilder: (context, state) => _transitionPage(state, child),
    );
  }

  static CustomTransitionPage<void> _transitionPage(
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        final slide =
            Tween<Offset>(
              begin: const Offset(0.02, 0.03),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }
}
