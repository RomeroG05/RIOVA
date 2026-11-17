import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riova/app.dart';
import 'package:riova/core/theme/app_colors.dart';
import 'package:riova/core/theme/app_theme.dart';
import 'package:riova/data/models/explorer.dart';
import 'package:riova/data/repositories/progress_repository.dart';
import 'package:riova/features/profile/profile_screen.dart';
import 'package:riova/features/profile/settings_screen.dart';
import 'package:riova/features/profile/store_screen.dart';
import 'package:riova/state/explorer_controller.dart';
import 'package:riova/state/settings_controller.dart';

const _profile = ExplorerProfile(
  name: 'Thony',
  avatar: ExplorerAvatar.oso,
  age: 8,
);

/// Teléfono angosto (360 dp) con la letra más grande permitida.
Future<void> _pumpNarrow(
  WidgetTester tester,
  Widget screen, {
  required bool dark,
}) async {
  tester.view.physicalSize = const Size(1080, 2220);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  AppColors.dark = dark;
  addTearDown(() => AppColors.dark = false);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        progressRepositoryProvider.overrideWithValue(
          InMemoryProgressRepository(
            profile: _profile,
            progress: const ExplorerProgress(gotitas: 300),
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.build(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.4)),
          child: child!,
        ),
        home: screen,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 900));
}

void main() {
  test('los ajustes se guardan y toleran valores desconocidos', () {
    const s = AppSettings(
      themeMode: ThemeMode.dark,
      textSize: TextSize.huge,
      reduceMotion: true,
      voiceSpeed: VoiceSpeed.slow,
    );
    expect(AppSettings.fromJson(s.toJson()), s);
    final odd = AppSettings.fromJson({'themeMode': 'neon', 'textSize': 42});
    expect(odd, const AppSettings());
  });

  test('el controlador persiste cada cambio', () {
    final repo = InMemorySettingsRepository();
    final c = ProviderContainer(
      overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    c.read(settingsProvider.notifier)
      ..setThemeMode(ThemeMode.dark)
      ..setTextSize(TextSize.large)
      ..setReduceMotion(true)
      ..setVoiceSpeed(VoiceSpeed.fast);
    expect(
      repo.load(),
      const AppSettings(
        themeMode: ThemeMode.dark,
        textSize: TextSize.large,
        reduceMotion: true,
        voiceSpeed: VoiceSpeed.fast,
      ),
    );
  });

  test('la paleta oscura cambia superficies y tinta', () {
    AppColors.dark = false;
    final lightInk = AppColors.ink;
    final lightSurface = AppColors.surface;
    AppColors.dark = true;
    addTearDown(() => AppColors.dark = false);
    expect(AppColors.ink, isNot(lightInk));
    expect(AppColors.surface, isNot(lightSurface));
    expect(AppTheme.build().brightness, Brightness.dark);
    // Tinta clara sobre superficie oscura.
    expect(
      AppColors.ink.computeLuminance(),
      greaterThan(AppColors.surface.computeLuminance()),
    );
  });

  for (final dark in [false, true]) {
    final mode = dark ? 'oscuro' : 'claro';
    testWidgets('Ajustes cabe en pantalla angosta con letra grande ($mode)', (
      tester,
    ) async {
      await _pumpNarrow(tester, const SettingsScreen(), dark: dark);
      await tester.scrollUntilVisible(find.text('Reiniciar aventura'), 300);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Perfil con Tienda y Ajustes en la tarjeta ($mode)', (
      tester,
    ) async {
      await _pumpNarrow(
        tester,
        const Scaffold(body: ProfileScreen()),
        dark: dark,
      );
      expect(find.byIcon(Icons.storefront_rounded), findsOneWidget);
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Tienda con letra grande ($mode)', (tester) async {
      await _pumpNarrow(tester, const StoreScreen(), dark: dark);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('cambiar a modo oscuro desde Ajustes repinta la app', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(() => AppColors.dark = false);
    final settings = InMemorySettingsRepository(
      const AppSettings(themeMode: ThemeMode.light),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          progressRepositoryProvider.overrideWithValue(
            InMemoryProgressRepository(profile: _profile),
          ),
          settingsRepositoryProvider.overrideWithValue(settings),
        ],
        child: const RiovaApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    final context = tester.element(find.byType(Navigator).first);
    context.go('/perfil/ajustes');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Apariencia'), findsOneWidget);

    await tester.tap(find.text('Oscuro'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(AppColors.dark, isTrue);
    expect(settings.load().themeMode, ThemeMode.dark);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
    expect(scaffold, isNotNull);
    expect(
      Theme.of(tester.element(find.text('Apariencia'))).brightness,
      Brightness.dark,
    );

    await tester.tap(find.text('Claro'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(AppColors.dark, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
