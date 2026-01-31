import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/pages/calendar_page.dart';
import '../presentation/pages/configuracio_page.dart';
import '../presentation/pages/dashboard_page.dart';
import '../presentation/pages/daily_notes_page.dart';
import '../presentation/pages/grups_page.dart';
import '../presentation/pages/moduls_page.dart';
import '../presentation/pages/placeholder_page.dart';
import '../presentation/pages/ra_config_page.dart';
import '../presentation/pages/setup_curriculum_page.dart';
import '../presentation/shell/app_shell.dart';

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (_, state, child) {
          return AppShell(currentRoute: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (_, state) =>
                MaterialPage(key: state.pageKey, child: const DashboardPage()),
          ),
          GoRoute(
            path: '/calendar',
            pageBuilder: (_, state) =>
                MaterialPage(key: state.pageKey, child: const CalendarPage()),
          ),
          GoRoute(
            path: '/moduls',
            pageBuilder: (_, state) =>
                MaterialPage(key: state.pageKey, child: const ModulsListPage()),
            routes: [
              GoRoute(
                path: 'edit/:id',
                pageBuilder: (_, state) {
                  final id = state.pathParameters['id']!;
                  return MaterialPage(
                    key: state.pageKey,
                    child: ModulFormPage(modulId: id),
                  );
                },
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (_, state) {
                  final id = state.pathParameters['id']!;
                  return MaterialPage(
                    key: state.pageKey,
                    child: ModulDetailPage(modulId: id),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'ra-config',
                    pageBuilder: (_, state) {
                      final id = state.pathParameters['id']!;
                      return MaterialPage(
                        key: state.pageKey,
                        child: RaConfigPage(modulId: id),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'ra/new',
                    pageBuilder: (_, state) {
                      final modulId = state.pathParameters['id']!;
                      return MaterialPage(
                        key: state.pageKey,
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
                        key: state.pageKey,
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
            pageBuilder: (_, state) =>
                MaterialPage(key: state.pageKey, child: const GrupsListPage()),
            routes: [
              GoRoute(
                path: 'new',
                pageBuilder: (_, state) => MaterialPage(
                  key: state.pageKey,
                  child: const GroupFormPage(),
                ),
              ),
              GoRoute(
                path: 'edit/:id',
                pageBuilder: (_, state) {
                  final id = state.pathParameters['id']!;
                  return MaterialPage(
                    key: state.pageKey,
                    child: GroupFormPage(groupId: id),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/tasques',
            pageBuilder: (_, state) => MaterialPage(
              key: state.pageKey,
              child: const PlaceholderPage(title: 'Tasques'),
            ),
          ),
          GoRoute(
            path: '/informes',
            pageBuilder: (_, state) => MaterialPage(
              key: state.pageKey,
              child: const PlaceholderPage(title: 'Informes'),
            ),
          ),
          GoRoute(
            path: '/arxiu',
            pageBuilder: (_, state) => MaterialPage(
              key: state.pageKey,
              child: const PlaceholderPage(title: 'Arxiu'),
            ),
          ),
          GoRoute(
            path: '/configuracio',
            pageBuilder: (_, state) => MaterialPage(
              key: state.pageKey,
              child: const ConfiguracioPage(),
            ),
          ),
          GoRoute(
            path: '/setup-curriculum',
            pageBuilder: (_, state) => MaterialPage(
              key: state.pageKey,
              child: const SetupCurriculumPage(),
            ),
          ),
          GoRoute(
            path: '/daily-notes',
            pageBuilder: (_, state) =>
                MaterialPage(key: state.pageKey, child: const DailyNotesPage()),
          ),
        ],
      ),
    ],
  );
}
