import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:client/core/router/routes.dart';
import 'package:client/core/widgets/app_shell.dart';
import 'package:client/features/camera/camera_screen.dart';
import 'package:client/features/session_detail/presentation/session_detail_screen.dart';
import 'package:client/features/sessions/presentation/sessions_list_screen.dart';
import 'package:client/features/translation_result/translation_result_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) => _buildRouter());

final appRouter = _buildRouter();

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: Routes.sessions,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(
          navigationShell: navigationShell,
          child: navigationShell,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.sessions,
                builder: (context, state) => const SessionsListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => SessionDetailScreen(
                      id: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.scan,
                builder: (context, state) => const CameraScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.cards,
                builder: (context, state) => const CardsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.result,
        builder: (context, state) => const TranslationResultScreen(),
      ),
    ],
  );
}
