import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/mascot/rio_mascot.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/chunky_button.dart';
import '../../data/content/game_content.dart';
import '../../state/explorer_controller.dart';
import 'camino/water_path_game.dart';
import 'detective/flood_detective_game.dart';
import 'guardianes/nature_memory_game.dart';
import 'mitos/myths_game.dart';
import 'palabras/word_search_game.dart';
import 'quiz/loja_quiz_game.dart';
import 'recicla/recycle_game.dart';
import 'rescata/rescue_river_game.dart';
import 'rompecabezas/river_puzzle_game.dart';

/// Resuelve `/juego/:id` al minijuego correspondiente. Si el juego todavía
/// está bloqueado, explica cómo desbloquearlo.
class GameHost extends ConsumerWidget {
  const GameHost({super.key, required this.gameName});

  final String gameName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = gameIdFromName(gameName);
    if (id == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Este juego no existe.')),
      );
    }
    final game = gameById(id);
    final progress = ref.watch(explorerProvider.select((s) => s.progress));
    if (!game.unlockedFor(progress)) return _LockedGame(game: game);
    return switch (id) {
      GameId.rescata => const RescueRiverGame(),
      GameId.quiz => const LojaQuizGame(),
      GameId.detective => const FloodDetectiveGame(),
      GameId.palabras => const WordSearchGame(),
      GameId.camino => const WaterPathGame(),
      GameId.guardianes => const NatureMemoryGame(),
      GameId.mitos => const MythsGame(),
      GameId.recicla => const RecycleGame(),
      GameId.rompecabezas => const RiverPuzzleGame(),
    };
  }
}

class _LockedGame extends StatelessWidget {
  const _LockedGame({required this.game});

  final GameInfo game;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const RioMascot(size: 110, mood: MascotMood.thinking),
            const SizedBox(height: 16),
            Text(
              game.title,
              style: t.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '🔒 ${game.unlock.label} para desbloquear este minijuego.',
              style: t.bodyLarge?.copyWith(color: AppColors.inkSoft),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ChunkyButton(
              label: 'Volver a los juegos',
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}
