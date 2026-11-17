import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mascot/rio_mascot.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/chunky_button.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/reward_dialog.dart';
import '../../../core/widgets/riova_header.dart';
import '../../../data/content/game_content.dart';
import '../../../state/explorer_controller.dart';

/// Estructura común de todos los minijuegos: barra "Minijuego Activo",
/// confirmación de salida con el Back del sistema y pantalla de inicio.
class GameScaffold extends StatelessWidget {
  const GameScaffold({
    super.key,
    required this.game,
    required this.body,
    this.inProgress = false,
    this.onPauseChanged,
  });

  final GameInfo game;
  final Widget body;

  /// Si es `true`, salir pide confirmación (no se pierde la partida por error).
  final bool inProgress;
  final ValueChanged<bool>? onPauseChanged;

  Future<bool> _confirmExit(BuildContext context) async {
    onPauseChanged?.call(true);
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const RioMascot(
          size: 64,
          mood: MascotMood.sad,
          interactive: false,
          idle: false,
        ),
        title: const Text('¿Salir del juego?'),
        content: const Text('Perderás el avance de esta partida.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir jugando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (leave != true) onPauseChanged?.call(false);
    return leave == true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !inProgress,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmExit(context)) navigator.pop();
      },
      child: Scaffold(
        appBar: RiovaBackBarMinimal(title: 'Minijuego Activo'),
        body: SafeArea(top: false, child: body),
      ),
    );
  }
}

/// Barra simple para juegos: atrás + título + avatar.
class RiovaBackBarMinimal extends StatelessWidget
    implements PreferredSizeWidget {
  const RiovaBackBarMinimal({super.key, required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 64,
      automaticallyImplyLeading: false,
      titleSpacing: 12,
      title: Row(
        children: [
          Pressable(
            semanticLabel: 'Salir del juego',
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.blueSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back_rounded, color: AppColors.blue),
            ),
          ),
          const SizedBox(width: 10),
          const RioMascot(size: 24, interactive: false, idle: false),
          const SizedBox(width: 8),
          Flexible(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
        ],
      ),
      actions: const [ProfileButton(), SizedBox(width: 10)],
    );
  }
}

/// Fila de indicadores: pausa, tiempo, vidas y progreso.
class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    this.onPause,
    this.paused = false,
    this.seconds,
    this.lives,
    this.maxLives = 3,
    this.progress,
    this.progressIcon = Icons.explore_outlined,
    this.countdown = true,
  });

  final VoidCallback? onPause;
  final bool paused;
  final int? seconds;
  final int? lives;
  final int maxLives;
  final String? progress;
  final IconData progressIcon;

  /// `false` para cronómetros que cuentan hacia arriba (sin alerta roja).
  final bool countdown;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final time = seconds == null
        ? null
        : '${(seconds! ~/ 60).toString().padLeft(2, '0')}:${(seconds! % 60).toString().padLeft(2, '0')}';
    final urgent = countdown && seconds != null && seconds! <= 10;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      radius: 22,
      child: Row(
        children: [
          if (onPause != null)
            Pressable(
              semanticLabel: paused ? 'Continuar' : 'Pausa',
              onTap: onPause,
              child: Container(
                width: 48,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.blueSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  color: AppColors.blue,
                ),
              ),
            ),
          if (time != null) ...[
            const SizedBox(width: 6),
            AnimatedContainer(
              duration: AppMotion.of(context, AppMotion.fast),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: urgent ? AppColors.redSoft : AppColors.blueSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: urgent ? AppColors.red : AppColors.teal,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    time,
                    style: t.titleSmall?.copyWith(
                      color: urgent ? AppColors.red : AppColors.teal,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // En pantallas angostas (o con fuente grande) el bloque derecho se
          // reduce en vez de desbordar la fila.
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (lives != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.redSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            for (var i = 0; i < maxLives; i++)
                              AnimatedScale(
                                scale: i < lives! ? 1 : 0.7,
                                duration: AppMotion.of(
                                  context,
                                  AppMotion.medium,
                                ),
                                curve: AppMotion.playful,
                                child: Icon(
                                  i < lives!
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: AppColors.heart,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (progress != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.blueSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            Icon(progressIcon, size: 17, color: AppColors.blue),
                            const SizedBox(width: 4),
                            Text(
                              progress!,
                              style: t.titleSmall?.copyWith(
                                color: AppColors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de inicio de un juego: instrucciones + botón Jugar.
class GameIntro extends StatelessWidget {
  const GameIntro({
    super.key,
    required this.game,
    required this.instructions,
    required this.onStart,
    this.accessory = MascotAccessory.none,
  });

  final GameInfo game;
  final List<String> instructions;
  final VoidCallback onStart;
  final MascotAccessory accessory;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: RioMascot(
            size: 120,
            mood: MascotMood.cheer,
            accessory: accessory,
          ),
        ),
        const SizedBox(height: 12),
        Text(game.title, style: t.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(
          game.description,
          style: t.bodyLarge?.copyWith(color: AppColors.inkSoft),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('¿Cómo se juega?', style: t.titleMedium),
              const SizedBox(height: 10),
              for (final (i, line) in instructions.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppColors.cyanSoft,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${i + 1}',
                          style: t.labelMedium?.copyWith(color: AppColors.teal),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          line,
                          style: t.bodyMedium?.copyWith(color: AppColors.ink),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ChunkyButton(
          label: '¡Jugar!',
          tone: game.tone == ChunkyTone.soft ? ChunkyTone.cyan : game.tone,
          leading: Icons.play_arrow_rounded,
          onPressed: onStart,
        ),
      ],
    );
  }
}

/// Registra el resultado y muestra la pantalla final.
/// Devuelve `true` si el jugador quiere jugar otra vez.
Future<bool> finishGame(
  BuildContext context,
  WidgetRef ref, {
  required GameInfo game,
  required bool won,
  required int score,
  required String summary,
}) async {
  final outcome = ref
      .read(explorerProvider.notifier)
      .completeGame(game.id, won: won, score: score);
  if (won) {
    HapticFeedback.heavyImpact();
    await showReward(
      context,
      outcome: outcome,
      title: '¡Misión cumplida!',
      message: summary,
      emptyMessage: summary,
      action: 'Continuar',
    );
  }
  if (!context.mounted) return false;
  final again = await showModalBottomSheet<bool>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    builder: (context) {
      final t = Theme.of(context).textTheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RioMascot(size: 90, mood: won ? MascotMood.cheer : MascotMood.sad),
            const SizedBox(height: 10),
            Text(
              won ? '¡Bien hecho, guardián!' : '¡Casi lo logras!',
              style: t.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(summary, style: t.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            ChunkyButton(
              label: 'Jugar otra vez',
              tone: ChunkyTone.cyan,
              leading: Icons.replay_rounded,
              onPressed: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 10),
            ChunkyButton(
              label: 'Volver a los juegos',
              tone: ChunkyTone.soft,
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      );
    },
  );
  return again == true;
}
