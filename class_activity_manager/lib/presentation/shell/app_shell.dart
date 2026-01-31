import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Navigation destinations for the sidebar.
final navDestinations = [
  (route: '/', label: 'Dashboard', icon: Icons.dashboard),
  (route: '/calendar', label: 'Calendar', icon: Icons.calendar_month),
  (route: '/moduls', label: 'Mòduls', icon: Icons.school),
  (route: '/daily-notes', label: 'Notes diàries', icon: Icons.note),
  (route: '/grups', label: 'Grups', icon: Icons.groups),
  (route: '/tasques', label: 'Tasques', icon: Icons.assignment),
  (route: '/informes', label: 'Informes', icon: Icons.assessment),
  (route: '/arxiu', label: 'Arxiu', icon: Icons.archive),
  (route: '/configuracio', label: 'Configuració', icon: Icons.settings),
];

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, required this.currentRoute});

  final Widget child;
  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationDrawer(
            selectedIndex: _selectedIndex(),
            onDestinationSelected: (index) {
              final route = navDestinations[index].route;
              if (route != currentRoute) context.go(route);
            },
            children: navDestinations
                .map(
                  (d) => NavigationDrawerDestination(
                    icon: Icon(d.icon),
                    label: Text(d.label),
                  ),
                )
                .toList(),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  int _selectedIndex() {
    // Match exact or prefix so /moduls/123 highlights Mòduls
    for (var i = navDestinations.length - 1; i >= 0; i--) {
      final r = navDestinations[i].route;
      if (currentRoute == r || (r != '/' && currentRoute.startsWith('$r/'))) {
        return i;
      }
    }
    return 0;
  }
}
