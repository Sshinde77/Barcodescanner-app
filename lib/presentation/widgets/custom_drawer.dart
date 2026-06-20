import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key, required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final items = <_DrawerItem>[
      const _DrawerItem(Icons.dashboard_rounded, 'Dashboard', '/dashboard'),
      const _DrawerItem(
        Icons.qr_code_2_rounded,
        'Generate Barcode',
        '/generate-barcode',
      ),
      const _DrawerItem(
        Icons.document_scanner_rounded,
        'Scanner',
        '/admin-scanner',
      ),
      const _DrawerItem(
        Icons.list_alt_rounded,
        'Barcode List',
        '/barcode-list',
      ),
    ];

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(
                      Icons.qr_code_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Smart Barcode Manager',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Admin workspace',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  ...items.map(
                    (item) => _DrawerTile(
                      icon: item.icon,
                      label: item.label,
                      selected: currentPath == item.path,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go(item.path);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  _DrawerTile(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    selected: false,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/landing');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem {
  const _DrawerItem(this.icon, this.label, this.path);

  final IconData icon;
  final String label;
  final String path;
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        selected: selected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon, color: color),
        title: Text(label),
        onTap: onTap,
      ),
    );
  }
}
