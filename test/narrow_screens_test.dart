import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riova/core/mascot/rio_mascot.dart';
import 'package:riova/core/theme/app_theme.dart';
import 'package:riova/data/content/game_content.dart';
import 'package:riova/data/models/explorer.dart';
import 'package:riova/data/repositories/progress_repository.dart';
import 'package:riova/features/games/game_host.dart';
import 'package:riova/features/games/games_hub_screen.dart';
import 'package:riova/features/home/home_screen.dart';
import 'package:riova/features/onboarding/create_explorer_screen.dart';
import 'package:riova/features/place/place_screen.dart';
import 'package:riova/features/profile/profile_screen.dart';
import 'package:riova/state/explorer_controller.dart';

/// Teléfono angosto (360 × 740 dp) con la fuente del sistema al 115 %:
/// el caso que produjo "OVERFLOWED BY 13 PIXELS" en un dispositivo real.
Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1080, 2220);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = 1.15;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        progressRepositoryProvider.overrideWithValue(
          InMemoryProgressRepository(
            profile: const ExplorerProfile(
              name: 'Exploradora',
              avatar: ExplorerAvatar.nutria,
              age: 7,
            ),
            // Nivel 8: todos los minijuegos extra desbloqueados.
            progress: const ExplorerProgress(gotitas: 1500),
          ),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: child),
    ),
  );
  await tester.pump(const Duration(milliseconds: 800));
}

void main() {
  for (final game in GameId.values) {
    testWidgets('${game.name}: partida y diálogo de salida sin desbordes', (
      tester,
    ) async {
      await _pump(tester, GameHost(gameName: game.name));

      // La pantalla de inicio del juego es una lista perezosa: hay que
      // desplazarse hasta que el botón se construya.
      await tester.scrollUntilVisible(find.text('¡Jugar!'), 300);
      await tester.tap(find.text('¡Jugar!'));
      await tester.pump(const Duration(milliseconds: 600));

      // Botón atrás de la barra → confirmación.
      await tester.tap(find.bySemanticsLabel('Salir del juego'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('¿Salir del juego?'), findsOneWidget);

      // La mascota del diálogo conserva su tamaño (64 dp), no el del diálogo.
      final mascot = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(RioMascot),
      );
      final box = find
          .descendant(of: mascot, matching: find.byType(SizedBox))
          .first;
      expect(tester.getSize(box).width, 64);

      await tester.tap(find.text('Seguir jugando'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('¿Salir del juego?'), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final (name, screen) in [
    ('Inicio', const Scaffold(body: HomeScreen())),
    ('Juegos', const Scaffold(body: GamesHubScreen())),
    ('Perfil', const Scaffold(body: ProfileScreen())),
    ('Crear perfil', const CreateExplorerScreen()),
    ('La Tebaida', const PlaceScreen(placeId: 'tebaida')),
  ]) {
    testWidgets('$name se ve completo en pantalla angosta', (tester) async {
      await _pump(tester, screen);
      // Recorre toda la pantalla para construir cada sección.
      for (var i = 0; i < 12; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
        await tester.pump(const Duration(milliseconds: 200));
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}
