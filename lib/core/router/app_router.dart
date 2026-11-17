import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/content/game_content.dart';
import '../../features/games/game_host.dart';
import '../../features/games/games_hub_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/library/library_screen.dart';
import '../../features/map/map_screen.dart';
import '../../features/onboarding/create_explorer_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/place/place_screen.dart';
import '../../features/profile/store_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/qr/qr_codes_screen.dart';
import '../../features/qr/scan_qr_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../state/explorer_controller.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

abstract final class Routes {
  static const welcome = '/';
  static const create = '/crear';
  static const home = '/inicio';
  static const library = '/inicio/biblioteca';
  static const map = '/mapa';
  static const games = '/juegos';
  static const profile = '/perfil';
  static const store = '/perfil/tienda';
  static const qrCodes = '/codigos';

  static String place(String id) => '/mapa/lugar/$id';
  static String scan({String? placeId}) =>
      placeId == null ? '/escanear' : '/escanear?lugar=$placeId';
  static String game(GameId id) => '/juego/${id.name}';
}

final routerProvider = Provider<GoRouter>((ref) {
  // Puente Riverpod → go_router: el redirect se reevalúa cuando aparece o
  // desaparece el perfil (crear explorador / reiniciar aventura).
  final hasProfile = ValueNotifier<bool>(
    ref.read(explorerProvider).profile != null,
  );
  ref.listen(
    explorerProvider.select((s) => s.profile != null),
    (_, next) => hasProfile.value = next,
  );

  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.welcome,
    refreshListenable: hasProfile,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final onboarding = loc == Routes.welcome || loc == Routes.create;
      if (!hasProfile.value && !onboarding) return Routes.welcome;
      return null;
    },
    routes: [
      GoRoute(path: Routes.welcome, builder: (_, _) => const WelcomeScreen()),
      GoRoute(
        path: Routes.create,
        builder: (_, _) => const CreateExplorerScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (_, _) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'biblioteca',
                    builder: (_, _) => const LibraryScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.map,
                builder: (_, state) =>
                    MapScreen(focusPlaceId: state.uri.queryParameters['lugar']),
                routes: [
                  GoRoute(
                    path: 'lugar/:id',
                    builder: (_, state) =>
                        PlaceScreen(placeId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.games,
                builder: (_, _) => const GamesHubScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (_, _) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'tienda',
                    builder: (_, _) => const StoreScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // Pantallas a pantalla completa (sin barra inferior).
      GoRoute(
        path: '/escanear',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            ScanQrScreen(expectedPlaceId: state.uri.queryParameters['lugar']),
      ),
      GoRoute(
        path: '/juego/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => GameHost(gameName: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.qrCodes,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const QrCodesScreen(),
      ),
    ],
  );
  ref.onDispose(() {
    hasProfile.dispose();
    router.dispose();
  });
  return router;
});
