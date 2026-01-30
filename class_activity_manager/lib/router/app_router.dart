import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/pages/configuracio_page.dart';
import '../presentation/pages/dashboard_page.dart';
import '../presentation/pages/grups_page.dart';
import '../presentation/pages/moduls_page.dart';
import '../presentation/pages/placeholder_page.dart';
import '../presentation/shell/app_shell.dart';

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(
            currentRoute: state.uri.path,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (_, __) => const MaterialPage(
              child: DashboardPage(),
            ),
          ),
          GoRoute(
            path: '/calendar',
            pageBuilder: (_, __) => const MaterialPage(
              child: PlaceholderPage(title: 'Calendar'),
            ),
          ),
          GoRoute(
            path: '/moduls',
            pageBuilder: (_, __) => const MaterialPage(
              child: ModulsListPage(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                pageBuilder: (_, __) => const MaterialPage(
                  child: ModulFormPage(),
                ),
              ),
              GoRoute(
                path: 'edit/:id',
                pageBuilder: (_, state) {
                  final id = state.pathParameters['id']!;
                  return MaterialPage(
                    child: ModulFormPage(modulId: id),
                  );
                },
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (_, state) {
                  final id = state.pathParameters['id']!;
                  return MaterialPage(
                    child: ModulDetailPage(modulId: id),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'ra/new',
                    pageBuilder: (_, state) {
                      final modulId = state.pathParameters['id']!;
                      return MaterialPage(
                        child: RAFormPage(modulId: modulId),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'ra/edit/:raId',
                    pageBuilder: (_, state) {
                      final modulId = state.pathParameters['id']!;
                      final raId = state.pathParameters['raId']!;
                      return MaterialPage(
                        child: RAFormPage(modulId: modulId, raId: raId),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/grups',
            pageBuilder: (_, __) => const MaterialPage(
              child: GrupsListPage(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                pageBuilder: (_, __) => const MaterialPage(
                  child: GroupFormPage(),
                ),
              ),
              GoRoute(
                path: 'edit/:id',
                pageBuilder: (_, state) {
                  final id = state.pathParameters['id']!;
                  return MaterialPage(
                    child: GroupFormPage(groupId: id),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/tasques',
            pageBuilder: (_, __) => const MaterialPage(
              child: PlaceholderPage(title: 'Tasques'),
            ),
          ),
          GoRoute(
            path: '/informes',
            pageBuilder: (_, __) => const MaterialPage(
              child: PlaceholderPage(title: 'Informes'),
            ),
          ),
          GoRoute(
            path: '/arxiu',
            pageBuilder: (_, __) => const MaterialPage(
              child: PlaceholderPage(title: 'Arxiu'),
            ),
          ),
          GoRoute(
            path: '/configuracio',
            pageBuilder: (_, __) => const MaterialPage(
              child: ConfiguracioPage(),
            ),
          ),
        ],
      ),
    ],
  );
}
