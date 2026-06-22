import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/api/api_provider.dart';

class SmartBarcodeManagerApp extends StatelessWidget {
  const SmartBarcodeManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ApiScope(
      notifier: apiProvider,
      child: MaterialApp.router(
        title: 'Smart Barcode Manager',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
