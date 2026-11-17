import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/illustrations/scene_painter.dart';
import '../../core/mascot/rio_mascot.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/utils/day_key.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/chunky_button.dart';
import '../../core/widgets/motion_widgets.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/riova_header.dart';
import '../../data/content/game_content.dart';
import '../../state/explorer_controller.dart';

/// Pantalla "Inicio": panel principal.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final state = ref.watch(explorerProvider);
    final level = state.level;
    final name = state.profile?.name ?? 'Explorador';

    final features = [
      (
        Icons.explore_outlined,
        AppColors.cyanSoft,
        AppColors.teal,
        'Mapa Interactivo',
        'Recorre los puntos clave y secretos de los ríos de Loja.',
        Routes.map,
      ),
      (
        Icons.sports_esports_outlined,
        AppColors.blueSoft,
        AppColors.blue,
        'Minijuegos y Retos',
        'Limpia el río y salva a los animalitos locales jugando.',
        Routes.games,
      ),
      (
        Icons.menu_book_outlined,
        AppColors.mint,
        AppColors.greenDeep,
        'Biblioteca del Agua',
        'Descubre historias, cuentos y datos curiosos de nuestra fauna y flora.',
        Routes.library,
      ),
      (
        Icons.military_tech_outlined,
        AppColors.surfaceBlue,
        AppColors.teal,
        'Logros de Guardián',
        'Gana gotas de agua y medallas por cada misión superada.',
        Routes.profile,
      ),
    ];

    return CustomScrollView(
      slivers: [
        const RiovaSliverHeader(section: 'Inicio'),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          sliver: SliverList.list(
            children: [
              EntranceFade(child: _Hero(name: name)),
              const SizedBox(height: 16),
              EntranceFade(
                index: 1,
                child: Pressable(
                  onTap: () => context.go(Routes.profile),
                  semanticLabel: 'Nivel ${level.level}: ${level.current.title}',
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        const IconBubble(
                          icon: Icons.shield_rounded,
                          color: Color(0xFF5B8DEF),
                          foreground: Color(0xFF0B2E6B),
                          size: 46,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Nivel ${level.level}: ${level.current.title}',
                                      style: t.titleMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    level.isMax
                                        ? '${level.gotitas} XP'
                                        : '${level.gotitas} / ${level.next!.threshold} XP',
                                    style: t.labelMedium?.copyWith(
                                      color: AppColors.teal,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ProgressBar(value: level.fraction),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              EntranceFade(
                index: 2,
                child: Text(
                  '¿Qué descubrirás en RÍOVA?',
                  style: t.headlineSmall,
                ),
              ),
              const SizedBox(height: 12),
              for (final (i, f) in features.indexed) ...[
                EntranceFade(
                  index: 3 + i,
                  child: _FeatureTile(
                    icon: f.$1,
                    color: f.$2,
                    foreground: f.$3,
                    title: f.$4,
                    subtitle: f.$5,
                    onTap: () => f.$6 == Routes.library
                        ? context.push(f.$6)
                        : context.go(f.$6),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 14),
              const EntranceFade(index: 7, child: _MissionCard()),
            ],
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: DecoratedBox(
        decoration: BoxDecoration(color: AppColors.surface),
        child: Column(
          children: [
            SizedBox(
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const Opacity(
                    opacity: 0.6,
                    child: SceneIllustration(spec: SceneSpec.valley),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.surface.withValues(alpha: 0),
                          AppColors.surface,
                        ],
                        stops: [0.35, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    top: 14,
                    child: Pill(
                      label: 'Ríos de Loja',
                      icon: Icons.water_drop_rounded,
                      color: AppColors.surface,
                      uppercase: true,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: AppColors.cyanSoft,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A0B3B66),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const RioMascot(size: 58),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                children: [
                  Text(
                    '¡BIENVENIDO A RÍOVA!',
                    style: t.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hola, $name. ¿Listo para cuidar el río?',
                    style: t.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ChunkyButton(
                    label: 'Explorar el Mapa',
                    leading: Icons.explore_rounded,
                    onPressed: () => context.go(Routes.map),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.color,
    required this.foreground,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color foreground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Pressable(
      onTap: onTap,
      semanticLabel: title,
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconBubble(
              icon: icon,
              color: color,
              foreground: foreground,
              size: 54,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: t.bodyMedium),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
          ],
        ),
      ),
    );
  }
}

class _MissionCard extends ConsumerWidget {
  const _MissionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final progress = ref.watch(explorerProvider.select((s) => s.progress));
    final today = dayKey(DateTime.now());
    final mission = missionFor(DateTime.now(), progress);
    final accepted = progress.missionAccepted == today;
    final done = progress.missionCompleted == today;

    final (label, tone, icon) = done
        ? ('¡Misión completada!', ChunkyTone.green, Icons.verified_rounded)
        : accepted
        ? ('Ir a la misión', ChunkyTone.cyan, Icons.play_arrow_rounded)
        : ('Aceptar reto', ChunkyTone.green, Icons.check_circle_rounded);

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'MISIÓN DEL DÍA',
                  style: t.labelSmall?.copyWith(
                    color: AppColors.greenDeep,
                    fontSize: 12,
                  ),
                ),
              ),
              Pill(
                label: '+${mission.reward} Gotas',
                icon: Icons.water_drop_rounded,
                color: AppColors.cyanSoft,
                foreground: AppColors.ink,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBlue,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  mission.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mission.title, style: t.titleLarge),
                    Text(mission.description, style: t.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.medium),
            switchInCurve: AppMotion.easeOut,
            child: ChunkyButton(
              key: ValueKey(label),
              label: label,
              tone: tone,
              leading: icon,
              height: 52,
              onPressed: done
                  ? null
                  : () {
                      if (!accepted) {
                        ref.read(explorerProvider.notifier).acceptMission();
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                '¡Reto aceptado! Completa “${gameById(mission.game).title}” hoy.',
                              ),
                            ),
                          );
                      } else {
                        context.push(Routes.game(mission.game));
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }
}
