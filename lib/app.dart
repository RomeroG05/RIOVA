import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'state/explorer_controller.dart';

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

  void _touchStreak() {
    if (ref.read(explorerProvider).profile != null) {
      ref.read(explorerProvider.notifier).markActiveToday();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'RÍOVA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) {
        // Evita que una escala de fuente extrema rompa las tarjetas sin
        // ignorar la preferencia del usuario.
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 1,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
