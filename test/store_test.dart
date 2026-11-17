import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riova/core/theme/app_theme.dart';
import 'package:riova/core/widgets/hat.dart';
import 'package:riova/core/widgets/profile_banner.dart';
import 'package:riova/data/content/banner_content.dart';
import 'package:riova/data/content/game_content.dart';
import 'package:riova/data/content/hat_content.dart';
import 'package:riova/data/models/explorer.dart';
import 'package:riova/data/repositories/progress_repository.dart';
import 'package:riova/features/profile/store_screen.dart';
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
      progress: const ExplorerProgress(gotitas: 300), // Nivel 3
    );
    final c = _container(repo);
    final ctrl = c.read(explorerProvider.notifier);
    final levelBefore = c.read(explorerProvider).level.level;
    expect(levelBefore, 3);

    expect(ctrl.buyHat(hatById('detective')!), Purchase.bought); // 200
    final p = c.read(explorerProvider).progress;
    expect(p.wallet, 100);
    expect(p.gotitas, 300);
    expect(c.read(explorerProvider).level.level, levelBefore);
    expect(p.equippedHat, 'detective');

    expect(ctrl.buyHat(hatById('chullo')!), Purchase.notEnough); // 120
    expect(ctrl.buyHat(hatById('detective')!), Purchase.alreadyOwned);

    // Se guarda y se recupera (también es lo que se sube a Firebase).
    final restored = repo.loadProgress();
    expect(restored.spent, 200);
    expect(restored.ownedHats, {'detective'});
    expect(restored.equippedHat, 'detective');
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
    // 700 gotitas = Nivel 4: alcanza para la Corona (650) pero pide Nivel 7.
    final c = _container(
      InMemoryProgressRepository(
        progress: const ExplorerProgress(gotitas: 700),
      ),
    );
    final ctrl = c.read(explorerProvider.notifier);
    expect(c.read(explorerProvider).level.level, 4);
    expect(ctrl.buyHat(hatById('corona_gotitas')!), Purchase.levelLocked);
    expect(ctrl.buyHat(hatById('colibri')!), Purchase.levelLocked);
    expect(ctrl.buyHat(hatById('paja_toquilla')!), Purchase.bought); // 330
    expect(c.read(explorerProvider).progress.wallet, 370);
  });

  test('subir de nivel avisa los sombreros nuevos de la tienda', () {
    final c = _container(
      InMemoryProgressRepository(progress: const ExplorerProgress(gotitas: 80)),
    );
    final out = c
        .read(explorerProvider.notifier)
        .completeGame(GameId.quiz, won: true); // +20 → 100 = Nivel 2
    expect(out.levelUp?.level, 2);
    expect(out.newHats.map((h) => h.id), ['chullo', 'guardaparques']);
    expect(out.newBanners.map((b) => b.id), ['bosque_sauces']);
  });

  test('10 sombreros con id único y precios crecientes', () {
    expect(hats, hasLength(10));
    expect(hats.map((h) => h.id).toSet(), hasLength(10));
    for (var i = 1; i < hats.length; i++) {
      expect(hats[i].price, greaterThan(hats[i - 1].price));
    }
  });

  group('Banners del perfil', () {
    test('se compran igual que los sombreros: nivel + gotitas', () {
      final repo = InMemoryProgressRepository(
        progress: const ExplorerProgress(gotitas: 300, spent: 60), // Nivel 3
      );
      final c = _container(repo);
      final ctrl = c.read(explorerProvider.notifier);
      expect(
        ctrl.buyBanner(bannerById('noche_estrellada')!), // pide Nivel 4
        Purchase.levelLocked,
      );
      expect(ctrl.buyBanner(bannerById('laguna_jipiro')!), Purchase.notEnough);
      expect(ctrl.buyBanner(bannerById('bosque_sauces')!), Purchase.bought);
      expect(
        ctrl.buyBanner(bannerById('bosque_sauces')!),
        Purchase.alreadyOwned,
      );
      final p = c.read(explorerProvider).progress;
      expect(p.wallet, 300 - 60 - 160);
      expect(p.gotitas, 300); // el nivel no baja
      expect(p.equippedBanner, 'bosque_sauces');

      final restored = repo.loadProgress();
      expect(restored.ownedBanners, {'bosque_sauces'});
      expect(restored.equippedBanner, 'bosque_sauces');
      expect(restored.spent, 220);
    });

    test('equipar y quitar; sombrero y banner son independientes', () {
      final c = _container(
        InMemoryProgressRepository(
          progress: const ExplorerProgress(
            gotitas: 500,
            ownedHats: {'chullo'},
            equippedHat: 'chullo',
            ownedBanners: {'cielo_andino'},
          ),
        ),
      );
      final ctrl = c.read(explorerProvider.notifier);
      ctrl.equipBanner('aurora_gotitas'); // no comprado
      expect(c.read(explorerProvider).progress.equippedBanner, isNull);
      ctrl.equipBanner('cielo_andino');
      expect(c.read(explorerProvider).progress.equippedBanner, 'cielo_andino');
      expect(c.read(explorerProvider).progress.equippedHat, 'chullo');
      ctrl.equipBanner(null);
      expect(c.read(explorerProvider).progress.equippedBanner, isNull);
      expect(c.read(explorerProvider).progress.equippedHat, 'chullo');
    });

    test('progreso antiguo sin banners se carga sin errores', () {
      final p = ExplorerProgress.fromJson({'gotitas': 120, 'spent': 60});
      expect(p.ownedBanners, isEmpty);
      expect(p.equippedBanner, isNull);
      final again = ExplorerProgress.fromJson(
        p
            .copyWith(
              ownedBanners: {'rio_malacatos'},
              equippedBanner: 'rio_malacatos',
            )
            .toJson(),
      );
      expect(again.ownedBanners, {'rio_malacatos'});
      expect(again.equippedBanner, 'rio_malacatos');
      expect(again.copyWith(equippedBanner: null).equippedBanner, isNull);
    });

    test('8 banners con id único, precios crecientes y niveles 1–7', () {
      expect(banners, hasLength(8));
      expect(banners.map((b) => b.id).toSet(), hasLength(8));
      for (var i = 1; i < banners.length; i++) {
        expect(banners[i].price, greaterThan(banners[i - 1].price));
        expect(
          banners[i].minLevel,
          greaterThanOrEqualTo(banners[i - 1].minLevel),
        );
      }
      expect(banners.first.minLevel, 1);
      expect(banners.last.minLevel, 7);
    });
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
        child: MaterialApp(theme: AppTheme.light(), home: const StoreScreen()),
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

    // Pestaña Banners: cada banner se dibuja en la vista previa.
    await tester.scrollUntilVisible(find.byType(StoreTabs), -300);
    await tester.tap(find.text('Banners'));
    await tester.pump(const Duration(milliseconds: 600));
    for (final b in banners) {
      await tester.scrollUntilVisible(find.text(b.name).last, 200);
      await tester.tap(find.text(b.name).last);
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.byType(BannerSwatch), findsWidgets);
    // Nivel 3 con 300 gotitas: el de nivel 7 sale bloqueado.
    await tester.scrollUntilVisible(
      find.text('Se desbloquea en el Nivel 7'),
      -300,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
