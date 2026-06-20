import 'package:flutter/material.dart';

import 'custom_app_bar.dart';
import 'custom_drawer.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.title,
    required this.selectedPath,
    required this.child,
    this.actions,
    this.floatingActionButton,
    this.onRefresh,
  });

  final String title;
  final String selectedPath;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final body = onRefresh == null
        ? child
        : RefreshIndicator(onRefresh: onRefresh!, child: child);

    return Scaffold(
      key: scaffoldKey,
      drawer: CustomDrawer(currentPath: selectedPath),
      appBar: CustomAppBar(
        title: title,
        drawerKey: scaffoldKey,
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }
}
