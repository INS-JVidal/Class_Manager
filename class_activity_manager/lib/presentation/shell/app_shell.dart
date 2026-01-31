import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../widgets/sync_status_indicator.dart';

/// Navigation routes with icons (labels are localized).
const _navRoutes = [
  (route: '/', icon: Icons.dashboard),
  (route: '/calendar', icon: Icons.calendar_month),
  (route: '/moduls', icon: Icons.school),
  (route: '/daily-notes', icon: Icons.note),
  (route: '/grups', icon: Icons.groups),
  (route: '/tasques', icon: Icons.assignment),
  (route: '/informes', icon: Icons.assessment),
  (route: '/arxiu', icon: Icons.archive),
  (route: '/configuracio', icon: Icons.settings),
];

/// Get localized labels for navigation destinations.
List<String> _navLabels(AppLocalizations l10n) => [
  l10n.navDashboard,
  l10n.navCalendar,
  l10n.navModules,
  l10n.navDailyNotes,
  l10n.navGroups,
  l10n.navTasks,
  l10n.navReports,
  l10n.navArchive,
  l10n.navSettings,
];

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child, required this.currentRoute});

  final Widget child;
  final String currentRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final labels = _navLabels(l10n);

    // Listen for sync conflicts and show notification
    ref.listen(conflictStreamProvider, (_, next) {
      next.whenData((conflict) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              conflict.type.name == 'versionMismatch'
                  ? l10n.conflictVersionMismatch
                  : l10n.conflictDeleted,
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: l10n.understood,
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      });
    });

    return Scaffold(
      body: Row(
        children: [
          NavigationDrawer(
            selectedIndex: _selectedIndex(),
            onDestinationSelected: (index) {
              final route = _navRoutes[index].route;
              if (route != currentRoute) context.go(route);
            },
            children: [
              // Sync status indicator at top
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SyncStatusIndicator(),
              ),
              const Divider(),
              // Navigation destinations
              for (var i = 0; i < _navRoutes.length; i++)
                NavigationDrawerDestination(
                  icon: Icon(_navRoutes[i].icon),
                  label: Text(labels[i]),
                ),
            ],
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  int _selectedIndex() {
    // Match exact or prefix so /moduls/123 highlights Mòduls
    for (var i = _navRoutes.length - 1; i >= 0; i--) {
      final r = _navRoutes[i].route;
      if (currentRoute == r || (r != '/' && currentRoute.startsWith('$r/'))) {
        return i;
      }
    }
    return 0;
  }
}
