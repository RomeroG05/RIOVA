import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'state/explorer_controller.dart';
import 'state/settings_controller.dart';

class RiovaApp extends ConsumerStatefulWidget {
  const RiovaApp({super.key});

  @override
  ConsumerState<RiovaApp> createState() => _RiovaAppState();
}

class _RiovaAppState extends ConsumerState<RiovaApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver a la app un día nuevo, la racha se actualiza.
    if (state == AppLifecycleState.resumed) _touchStreak();
  }

  @override
  void didChangePlatformBrightness() {
    // "Seguir al sistema": el tema cambia junto con el del teléfono.
    if (ref.read(settingsProvider).themeMode == ThemeMode.system) {
      setState(() {});
    }
  }

  bool _isDark(ThemeMode mode) => switch (mode) {
    ThemeMode.dark => true,
    ThemeMode.light => false,
    ThemeMode.system =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark,
  };

  void _touchStreak() {
    if (ref.read(explorerProvider).profile != null) {
      ref.read(explorerProvider.notifier).markActiveToday();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);
    final dark = _isDark(settings.themeMode);
    // La paleta se fija antes de construir cualquier pantalla.
    AppColors.dark = dark;
    return MaterialApp.router(
      title: 'RÍOVA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      routerConfig: router,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) {
        // Tamaño de letra: escala del sistema × la elegida en Ajustes, con
        // un tope para que las tarjetas no se rompan.
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: _TimesScaler(
              mq.textScaler,
              settings.textSize.scale,
            ).clamp(minScaleFactor: 0.85, maxScaleFactor: 1.4),
            disableAnimations: mq.disableAnimations || settings.reduceMotion,
          ),
          child: PaletteScope(dark: dark, child: child!),
        );
      },
    );
  }
}

/// Al cambiar entre claro y oscuro reconstruye todas las pantallas abiertas
/// (también las que están debajo en la pila) para que lean la nueva paleta
/// de [AppColors], sin perder la navegación ni el estado.
class PaletteScope extends StatefulWidget {
  const PaletteScope({super.key, required this.dark, required this.child});

  final bool dark;
  final Widget child;

  @override
  State<PaletteScope> createState() => _PaletteScopeState();
}

class _PaletteScopeState extends State<PaletteScope> {
  @override
  void didUpdateWidget(PaletteScope old) {
    super.didUpdateWidget(old);
    if (old.dark != widget.dark) {
      void rebuild(Element e) {
        e.markNeedsBuild();
        // Los dibujos (CustomPainter) también leen la paleta al pintar.
        if (e is RenderObjectElement) e.renderObject.markNeedsPaint();
        e.visitChildren(rebuild);
      }

      (context as Element).visitChildren(rebuild);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Multiplica la escala de letra del sistema (que en Android 14+ es no
/// lineal: los títulos crecen menos que el texto) por la elegida en Ajustes.
@immutable
class _TimesScaler extends TextScaler {
  const _TimesScaler(this.base, this.factor);

  final TextScaler base;
  final double factor;

  @override
  double scale(double fontSize) => base.scale(fontSize) * factor;

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => base.textScaleFactor * factor;

  @override
  bool operator ==(Object other) =>
      other is _TimesScaler && other.base == base && other.factor == factor;

  @override
  int get hashCode => Object.hash(base, factor);
}
