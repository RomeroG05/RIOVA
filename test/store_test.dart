import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riova/core/theme/app_theme.dart';
import 'package:riova/core/widgets/hat.dart';
import 'package:riova/data/content/game_content.dart';
import 'package:riova/data/content/hat_content.dart';
import 'package:riova/data/models/explorer.dart';
import 'package:riova/data/repositories/progress_repository.dart';
import 'package:riova/features/profile/hat_store_screen.dart';
import 'package:riova/state/explorer_controller.dart';

ProviderContainer _container(ProgressRepository repo) {
  final c = ProviderContainer(
    overrides: [progressRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('comprar gasta gotitas disponibles pero no baja el nivel', () {
    final repo = InMemoryProgressRepository(
      progress: const ExplorerProgress(gotitas: 210),
    );
    final c = _container(repo);
    final ctrl = c.read(explorerProvider.notifier);
    final levelBefore = c.read(explorerProvider).level.level; // 210 → Nivel 3

    expect(ctrl.buyHat(hatById('paja_toquilla')!), HatPurchase.bought); // 200
    final p = c.read(explorerProvider).progress;
    expect(p.wallet, 10);
    expect(p.gotitas, 210);
    expect(c.read(explorerProvider).level.level, levelBefore);
    expect(p.equippedHat, 'paja_toquilla');

    expect(ctrl.buyHat(hatById('gorra_explorador')!), HatPurchase.notEnough);
    expect(ctrl.buyHat(hatById('paja_toquilla')!), HatPurchase.alreadyOwned);

    // Se guarda y se recupera (también es lo que se sube a Firebase).
    final restored = repo.loadProgress();
    expect(restored.spent, 200);
    expect(restored.ownedHats, {'paja_toquilla'});
    expect(restored.equippedHat, 'paja_toquilla');
  });

  test('ponerse y quitarse un sombrero; no se puede poner uno no comprado', () {
    final c = _container(
      InMemoryProgressRepository(
        progress: const ExplorerProgress(
          gotitas: 500,
          ownedHats: {'chullo'},
          spent: 80,
        ),
      ),
    );
    final ctrl = c.read(explorerProvider.notifier);
    ctrl.equipHat('corona_gotitas');
    expect(c.read(explorerProvider).progress.equippedHat, isNull);
    ctrl.equipHat('chullo');
    expect(c.read(explorerProvider).progress.equippedHat, 'chullo');
    ctrl.equipHat(null);
    expect(c.read(explorerProvider).progress.equippedHat, isNull);
  });

  test('los sombreros de nivel alto no se compran antes de tiempo', () {
    // 450 gotitas = Nivel 4: alcanza para la Corona (400) pero pide Nivel 6.
    final c = _container(
      InMemoryProgressRepository(
        progress: const ExplorerProgress(gotitas: 450),
      ),
    );
    final ctrl = c.read(explorerProvider.notifier);
    expect(c.read(explorerProvider).level.level, 4);
    expect(ctrl.buyHat(hatById('corona_gotitas')!), HatPurchase.levelLocked);
    expect(ctrl.buyHat(hatById('colibri')!), HatPurchase.levelLocked);
    expect(ctrl.buyHat(hatById('boina_musical')!), HatPurchase.bought);
    expect(c.read(explorerProvider).progress.wallet, 200);
  });

  test('subir de nivel avisa los sombreros nuevos de la tienda', () {
    final c = _container(
      InMemoryProgressRepository(progress: const ExplorerProgress(gotitas: 60)),
    );
    final out = c
        .read(explorerProvider.notifier)
        .completeGame(GameId.quiz, won: true); // +30 → 90 = Nivel 2
    expect(out.levelUp?.level, 2);
    expect(out.newHats.map((h) => h.id), ['guardaparques', 'detective']);
  });

  test('10 sombreros con id único y precios crecientes', () {
    expect(hats, hasLength(10));
    expect(hats.map((h) => h.id).toSet(), hasLength(10));
    for (var i = 1; i < hats.length; i++) {
      expect(hats[i].price, greaterThan(hats[i - 1].price));
    }
  });

  testWidgets('la tienda se dibuja completa en un teléfono angosto', (
    tester,
  ) async {
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
                name: 'Thony',
                avatar: ExplorerAvatar.oso,
                age: 8,
              ),
              progress: const ExplorerProgress(gotitas: 300),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const HatStoreScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));
    expect(
      find.byType(WithHat),
      findsWidgets,
    ); // vista previa y botón de perfil
    // Recorre la lista y prueba cada sombrero en la vista previa.
    for (final h in hats) {
      await tester.scrollUntilVisible(find.text(h.name).last, 200);
      await tester.tap(find.text(h.name).last);
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.pumpWidget(const SizedBox());
  });
}
