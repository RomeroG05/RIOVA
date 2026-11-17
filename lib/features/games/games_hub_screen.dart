import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/illustrations/scene_painter.dart';
import '../../core/mascot/rio_mascot.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/chunky_button.dart';
import '../../core/widgets/motion_widgets.dart';
import '../../core/widgets/riova_header.dart';
import '../../data/content/game_content.dart';
import '../../state/explorer_controller.dart';
import '../../core/widgets/hat.dart';

/// Pantalla "Centro de aventuras": catálogo de minijuegos.
class GamesHubScreen extends ConsumerWidget {
  const GamesHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final progress = ref.watch(explorerProvider.select((s) => s.progress));
    final completed = progress.completedGames;
    final open = unlockedGames(progress).length;
    return CustomScrollView(
      slivers: [
        const RiovaSliverHeader(section: 'Juegos'),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          sliver: SliverList.list(
            children: [
              EntranceFade(
                child: AppCard(
                  gradient: LinearGradient(
                    colors: AppColors.dark
                        ? [AppColors.surfaceTint, AppColors.surfaceBlue]
                        : const [Color(0xFFEAF6FE), Color(0xFFDDEFFD)],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Pill(
                              label: 'Misiones de Loja',
                              icon: Icons.stars_rounded,
                              uppercase: true,
                              dense: true,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '¡Centro de Aventuras!',
                              style: t.headlineMedium?.copyWith(
                                color: AppColors.teal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text.rich(
                              TextSpan(
                                text: '¡Aprende, juega y gana gotitas para convertirte en un ',
                                children: [
                                  TextSpan(
                                    text: 'Guardián del Agua',
                                    style: TextStyle(
                                      color: AppColors.greenDeep,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  TextSpan(text: '!'),
                                ],
                              ),
                              style: t.bodyMedium?.copyWith(
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const RioMascot(
                        size: 80,
                        accessory: MascotAccessory.glasses,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const EntranceFade(index: 1, child: _PlayerCard()),
              const SizedBox(height: 24),
              EntranceFade(
                index: 2,
                child: SectionTitle(
                  title: '¡Elige tu próxima aventura!',
                  icon: Icons.sports_esports_outlined,
                  trailing: Pill(
                    label: '$open/${games.length}',
                    icon: Icons.lock_open_rounded,
                    dense: true,
                    color: AppColors.cyanSoft,
                  ),
                  subtitle: 'Sube de nivel o escanea los tótems QR para desbloquear minijuegos extra.',
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 12,
              mainAxisExtent: 336,
            ),
            itemCount: games.length,
            itemBuilder: (context, i) => EntranceFade(
              index: (3 + i).clamp(0, 6),
              child: GameCard(
                game: games[i],
                completed: completed.contains(games[i].id.name),
                locked: !games[i].unlockedFor(progress),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
          sliver: SliverToBoxAdapter(
            child: AppCard(
              color: AppColors.mintSoft,
              child: Row(
                children: [
                  IconBubble(
                    icon: Icons.shield_outlined,
                    color: AppColors.surface,
                    foreground: AppColors.greenDeep,
                    size: 54,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¡Cada gotita cuenta!',
                          style: t.titleLarge?.copyWith(
                            color: AppColors.greenDeep,
                          ),
                        ),
                        Text(
                          '¡Mientras más aprendes sobre los ríos de Loja, más crece tu poder como Guardián del Agua!',
                          style: t.bodyMedium?.copyWith(color: AppColors.ink),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerCard extends ConsumerWidget {
  const _PlayerCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final s = ref.watch(explorerProvider);
    final level = s.level;
    final white = t.bodyMedium?.copyWith(color: Colors.white);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16BDEB), Color(0xFF0B57B8)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x400B57B8),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  WithHat(
                    hatId: s.progress.equippedHat,
                    size: 62,
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        s.profile?.avatar.emoji ?? '💧',
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -6,
                    left: 8,
                    child: Pill(
                      label: 'Nv.${level.level}',
                      color: AppColors.mint,
                      foreground: AppColors.greenDeep,
                      dense: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.profile?.name ?? 'Explorador',
                      style: t.headlineSmall?.copyWith(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      level.current.title,
                      style: t.labelMedium?.copyWith(color: AppColors.mint),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.water_drop_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    CountUpText(
                      s.progress.wallet,
                      style: t.titleLarge?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x33062E5E),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        level.isMax
                            ? 'Nivel ${level.level} — ¡Nivel máximo!'
                            : 'Nivel ${level.level} — ${level.gotitas} / ${level.next!.threshold} XP',
                        style: t.titleSmall?.copyWith(color: Colors.white),
                      ),
                    ),
                    Pill(
                      label: '${(level.fraction * 100).round()}% LISTO',
                      color: const Color(0x33FFFFFF),
                      foreground: AppColors.mint,
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ProgressBar(
                  value: level.fraction,
                  height: 12,
                  colors: [AppColors.mint, AppColors.cyan],
                  track: const Color(0x55062E5E),
                  showKnob: true,
                ),
                if (!level.isMax) ...[
                  const SizedBox(height: 8),
                  Text(
                    '¡Te faltan ${level.remaining} gotitas para alcanzar el Nivel ${level.next!.level}!',
                    style: white,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.sports_esports_rounded,
                  text: '${s.progress.completedGames.length} Completos',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  icon: Icons.star_rounded,
                  text: 'Nivel ${level.level}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.yellow, size: 20),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.game,
    required this.completed,
    this.locked = false,
  });

  final GameInfo game;
  final bool completed;

  /// Minijuego extra aún no desbloqueado (por nivel o escaneando tótems).
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: game.cardBackground,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140B3B66),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Pill(
                  label: game.difficulty,
                  color: game.easy
                      ? (AppColors.dark
                            ? AppColors.greenDark
                            : AppColors.greenDeep)
                      : AppColors.blue,
                  foreground: Colors.white,
                  dense: true,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Pill(
                  label: '+${game.reward}',
                  icon: Icons.water_drop_rounded,
                  color: AppColors.cyan,
                  foreground: Colors.white,
                  dense: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 26,
            child: locked
                ? Pill(
                    label: 'Bloqueado',
                    icon: Icons.lock_outline_rounded,
                    color: AppColors.surfaceBlue,
                    foreground: AppColors.inkSoft,
                    dense: true,
                  )
                : completed
                ? Pill(
                    label: 'Completado ✓',
                    color: AppColors.mint,
                    foreground: AppColors.greenDeep,
                    dense: true,
                  )
                : game.isNew
                ? Pill(
                    label: '¡Nuevo!',
                    icon: Icons.auto_awesome_rounded,
                    color: AppColors.yellow,
                    foreground: AppColors.amberInk,
                    dense: true,
                  )
                : null,
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 86,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  SceneIllustration(spec: game.scene),
                  if (locked) const ColoredBox(color: Color(0x990B2236)),
                  Center(
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Color(0x260B2236), blurRadius: 8),
                        ],
                      ),
                      child: Icon(
                        locked ? Icons.lock_rounded : game.icon,
                        color: locked
                            ? AppColors.inkSoft
                            : game.tone == ChunkyTone.soft
                            ? AppColors.teal
                            : game.tone.face,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            game.title,
            style: t.titleLarge?.copyWith(fontSize: 18),
            maxLines: 2,
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Text(
              locked ? '🔒 ${game.unlock.label}.' : game.description,
              style: t.bodySmall?.copyWith(
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ChunkyButton(
            label: locked ? 'Bloqueado' : game.cta,
            tone: game.tone,
            leading: locked ? null : game.ctaIcon,
            height: 44,
            fontSize: 15,
            singleLine: true,
            onPressed: locked ? null : () => context.push(Routes.game(game.id)),
          ),
        ],
      ),
    );
  }
}
