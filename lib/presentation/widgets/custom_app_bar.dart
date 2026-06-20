import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.drawerKey,
    this.actions,
  });

  final String title;
  final GlobalKey<ScaffoldState>? drawerKey;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: drawerKey == null
          ? null
          : IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => drawerKey?.currentState?.openDrawer(),
            ),
      title: Text(title),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
