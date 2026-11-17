import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../data/content/places_content.dart';
import '../../data/models/explorer.dart';
import '../../data/models/place.dart';
import '../../state/explorer_controller.dart';
import '../onboarding/create_explorer_screen.dart';
import '../../core/widgets/two_column_grid.dart';
import '../../core/widgets/hat.dart';
import '../../data/content/hat_content.dart';

/// Pantalla "Mi perfil".
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final s = ref.watch(explorerProvider);
    final unlocked = s.unlockedMedals;

    final children = <Widget>[
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.circle, size: 12, color: AppColors.cyan),
              const SizedBox(width: 6),
              Text('PANEL DE AVENTURERO', style: t.labelSmall),
            ],
          ),
          const SizedBox(height: 6),
          Text('¡Mi Perfil de Explorador!', style: t.headlineMedium),
          const SizedBox(height: 4),
          Text(
            '¡Mira todo lo que has descubierto en tu aventura!',
            style: t.bodyLarge?.copyWith(color: AppColors.inkSoft),
          ),
        ],
      ),
      _IdentityCard(state: s),
      _StoreCard(state: s),
      _StreakCard(state: s),
      Row(
        children: [
          Expanded(
            child: _Stat(
              icon: Icons.sports_esports_outlined,
              color: AppColors.cyanSoft,
              value: s.progress.completedGames.length,
              label: 'Juegos superados',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Stat(
              icon: Icons.explore_outlined,
              color: AppColors.blueSoft,
              value: s.progress.visited.length,
              label: 'Sectores de Loja',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Stat(
              icon: Icons.military_tech_rounded,
              color: AppColors.mint,
              value: unlocked,
              label: 'Medallas de honor',
            ),
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: '¡Mis medallas! 🎖️',
            trailing: Pill(
              label: '$unlocked de ${medals.length} conseguidas',
              dense: true,
              color: AppColors.cyanSoft,
            ),
            subtitle: 'Se ganan escaneando los tótems QR o subiendo de nivel. Toca una para ver su secreto.',
          ),
          for (final (byLevel, label, icon) in const [
            (false, 'Por escanear tótems QR', Icons.qr_code_scanner_rounded),
            (true, 'Por subir de nivel', Icons.trending_up_rounded),
          ]) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.teal),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: t.titleSmall?.copyWith(color: AppColors.teal),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TwoColumnGrid(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final m in medals.where((m) => m.byLevel == byLevel))
                  _MedalTile(medal: m, progress: s.progress),
              ],
            ),
          ],
        ],
      ),
      _JourneyCard(progress: s.progress),
      AppCard(
        color: AppColors.mintSoft,
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.spa_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Eres parte del cambio! 🌱',
                    style: t.titleMedium?.copyWith(color: AppColors.greenDeep),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Cada lugar que descubres y cada reto que completas te ayuda a conocer y cuidar los ríos Malacatos y Zamora.',
                    style: t.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      Column(
        children: [
          TextButton.icon(
            onPressed: () => context.push(Routes.qrCodes),
            icon: const Icon(Icons.qr_code_2_rounded),
            label: const Text('Códigos QR de los tótems (docentes)'),
          ),
          TextButton.icon(
            onPressed: () => _confirmReset(context, ref),
            icon: const Icon(Icons.restart_alt_rounded),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            label: const Text('Reiniciar aventura'),
          ),
        ],
      ),
    ];

    return CustomScrollView(
      slivers: [
        const RiovaSliverHeader(section: 'Perfil'),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          sliver: SliverList.separated(
            itemCount: children.length,
            separatorBuilder: (_, _) => const SizedBox(height: 18),
            itemBuilder: (context, i) =>
                EntranceFade(index: i.clamp(0, 4), child: children[i]),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Reiniciar la aventura?'),
        content: const Text(
          'Se borrarán tu perfil, gotitas, medallas y paradas registradas en este teléfono y su copia en la nube.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(explorerProvider.notifier).reset();
  }
}

class _IdentityCard extends ConsumerWidget {
  const _IdentityCard({required this.state});

  final ExplorerState state;

  void _changeAvatar(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final current = ref.watch(
            explorerProvider.select((s) => s.profile?.avatar),
          );
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Elige tu guardián',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 14),
                TwoColumnGrid(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final a in ExplorerAvatar.values)
                      AvatarCard(
                        avatar: a,
                        selected: a == current,
                        onTap: () {
                          ref.read(explorerProvider.notifier).updateAvatar(a);
                          Future.delayed(const Duration(milliseconds: 250), () {
                            if (context.mounted) Navigator.pop(context);
                          });
                        },
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final level = state.level;
    final profile = state.profile;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3FC6F1), Color(0xFF1E6FD9), Color(0xFF0B57B8)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x400B57B8),
            blurRadius: 20,
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
                  AnimatedSwitcher(
                    duration: AppMotion.of(context, AppMotion.medium),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: Tween(begin: 0.9, end: 1.0).animate(
                        CurvedAnimation(parent: anim, curve: AppMotion.playful),
                      ),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: WithHat(
                      key: ValueKey((
                        profile?.avatar,
                        state.progress.equippedHat,
                      )),
                      hatId: state.progress.equippedHat,
                      size: 92,
                      child: Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F6FD),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          profile?.avatar.emoji ?? '💧',
                          style: const TextStyle(fontSize: 46),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.name ?? 'Explorador',
                      style: t.headlineMedium?.copyWith(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Pill(
                          label: level.current.title,
                          icon: Icons.shield_rounded,
                          color: AppColors.green,
                          foreground: AppColors.ink,
                          uppercase: true,
                          dense: true,
                        ),
                        Pill(
                          label: 'Nivel ${level.level}',
                          color: const Color(0x33FFFFFF),
                          foreground: Colors.white,
                          dense: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Pressable(
                      onTap: () => _changeAvatar(context, ref),
                      semanticLabel: 'Cambiar avatar',
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0x33FFFFFF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.swap_horiz_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Cambiar avatar',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.labelMedium?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                    const Icon(
                      Icons.water_drop_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Experiencia Fluvial',
                        style: t.titleSmall?.copyWith(color: Colors.white),
                      ),
                    ),
                    Pill(
                      label: level.isMax
                          ? '${level.gotitas} gotitas XP'
                          : '${level.gotitas} / ${level.next!.threshold} gotitas XP',
                      color: const Color(0x33FFFFFF),
                      foreground: Colors.white,
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ProgressBar(
                  value: level.fraction,
                  height: 12,
                  colors: const [AppColors.cyan, AppColors.mint],
                  track: const Color(0x55FFFFFF),
                  showKnob: true,
                ),
                const SizedBox(height: 8),
                Text(
                  level.isMax
                      ? '¡Alcanzaste el nivel máximo! 🏆'
                      : '🚀 ¡Solo faltan ${level.remaining} gotitas para llegar al Nivel ${level.next!.level}!',
                  style: t.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.state});

  final ExplorerState state;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = startOfWeek(today);
    final streak = state.streak;
    final missionDone = state.progress.missionCompleted == dayKey(today);
    const labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    return AppCard(
      ledgeColor: AppColors.blueSoft,
      child: Column(
        children: [
          Row(
            children: [
              const IconBubble(
                icon: Icons.local_fire_department_rounded,
                color: AppColors.blueSoft,
                foreground: AppColors.blue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$streak ${streak == 1 ? 'día seguido' : 'días seguidos'} 🔥',
                      style: t.titleLarge,
                    ),
                    Text(
                      '¡Cada día que aprendes, tu aventura crece!',
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
              Pill(
                label: 'Récord: ${state.progress.bestStreak} d',
                icon: Icons.emoji_events_outlined,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < 7; i++) ...[
                Expanded(
                  child: _DayPill(
                    label: monday.add(Duration(days: i)) == today
                        ? 'HOY'
                        : labels[i],
                    active: state.progress.activeDays.contains(
                      dayKey(
                        DateTime(monday.year, monday.month, monday.day + i),
                      ),
                    ),
                    today:
                        DateTime(monday.year, monday.month, monday.day + i) ==
                        today,
                    future: DateTime(
                      monday.year,
                      monday.month,
                      monday.day + i,
                    ).isAfter(today),
                  ),
                ),
                if (i < 6) const SizedBox(width: 5),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  missionDone
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: AppColors.greenDeep,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    missionDone
                        ? 'Misión de hoy completada'
                        : 'Misión de hoy pendiente',
                    style: t.titleSmall,
                  ),
                ),
                if (missionDone)
                  const Pill(
                    label: '+50 XP GANADOS',
                    color: AppColors.mint,
                    foreground: AppColors.greenDeep,
                    dense: true,
                  )
                else
                  TextButton(
                    onPressed: () => context.go(Routes.home),
                    child: const Text('Ver misión'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.label,
    required this.active,
    required this.today,
    required this.future,
  });

  final String label;
  final bool active;
  final bool today;
  final bool future;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final bg = today
        ? AppColors.cyan
        : future
        ? AppColors.surfaceTint
        : Colors.white;
    return Semantics(
      label: '$label${active ? ', con actividad' : ''}',
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: today ? AppColors.cyan : AppColors.outline),
          boxShadow: today
              ? const [
                  BoxShadow(
                    color: Color(0x5512BDEA),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              label,
              style: t.labelSmall?.copyWith(
                color: today
                    ? Colors.white
                    : future
                    ? AppColors.inkMuted
                    : AppColors.ink,
                fontSize: label == 'HOY' ? 9.5 : 11,
                letterSpacing: 0,
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: today
                    ? Colors.white
                    : active
                    ? AppColors.blueSoft
                    : AppColors.surfaceTint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                future
                    ? Icons.lock_outline_rounded
                    : active
                    ? Icons.water_drop_rounded
                    : Icons.water_drop_outlined,
                size: 15,
                color: future ? AppColors.disabledDark : AppColors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      child: Column(
        children: [
          IconBubble(icon: icon, color: color, size: 42),
          const SizedBox(height: 8),
          CountUpText(value, style: t.headlineSmall),
          Text(
            label,
            style: t.bodySmall?.copyWith(fontSize: 11.5),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _MedalTile extends StatelessWidget {
  const _MedalTile({required this.medal, required this.progress});

  final Medal medal;
  final ExplorerProgress progress;

  void _inspect(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final unlocked = medal.unlocked(progress);
    final (cur, goal) = medal.progress(progress);
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MedalBadge(medal: medal, unlocked: unlocked, size: 96),
            const SizedBox(height: 12),
            Text(medal.title, style: t.headlineSmall),
            const SizedBox(height: 4),
            Pill(
              label: unlocked ? '¡Completada!' : 'Bloqueada',
              color: unlocked ? AppColors.mint : AppColors.surfaceBlue,
              foreground: unlocked ? AppColors.greenDeep : AppColors.inkSoft,
            ),
            const SizedBox(height: 14),
            Text(medal.howTo, style: t.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ProgressBar(value: cur / goal, colors: medal.colors),
            const SizedBox(height: 4),
            Text('${cur.clamp(0, goal)} / $goal', style: t.labelMedium),
            const SizedBox(height: 14),
            AppCard(
              color: unlocked ? AppColors.yellowSoft : AppColors.surfaceTint,
              child: Row(
                children: [
                  Icon(
                    unlocked
                        ? Icons.auto_awesome_rounded
                        : Icons.lock_outline_rounded,
                    color: AppColors.amberInk,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      unlocked ? medal.secret : 'Desbloquéala para descubrir el secreto de su poder.',
                      style: t.bodyMedium?.copyWith(color: AppColors.amberInk),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final unlocked = medal.unlocked(progress);
    return Pressable(
      onTap: () => _inspect(context),
      semanticLabel: '${medal.title}, ${unlocked ? 'completada' : 'bloqueada'}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 14),
        decoration: BoxDecoration(
          color: unlocked ? Colors.white : AppColors.surfaceBlue,
          borderRadius: BorderRadius.circular(22),
          boxShadow: unlocked
              ? const [
                  BoxShadow(
                    color: Color(0x120B3B66),
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _MedalBadge(medal: medal, unlocked: unlocked, size: 58),
            const SizedBox(height: 8),
            Text(
              medal.title,
              style: t.titleSmall?.copyWith(
                color: unlocked ? AppColors.ink : AppColors.inkMuted,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              unlocked ? '¡Completada!' : 'Bloqueada 🔒',
              style: t.labelMedium?.copyWith(
                color: unlocked ? AppColors.greenDeep : AppColors.inkMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedalBadge extends StatelessWidget {
  const _MedalBadge({
    required this.medal,
    required this.unlocked,
    required this.size,
  });

  final Medal medal;
  final bool unlocked;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: unlocked
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: medal.colors,
                  )
                : null,
            color: unlocked ? null : const Color(0xFFDCE8F7),
          ),
          child: Icon(
            medal.icon,
            color: unlocked ? Colors.white : AppColors.inkMuted,
            size: size * 0.46,
          ),
        ),
        Positioned(
          bottom: -size * 0.12,
          child: unlocked
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'LISTA',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: AppColors.greenDeep, fontSize: 9),
                  ),
                )
              : Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 13,
                    color: AppColors.inkSoft,
                  ),
                ),
        ),
      ],
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.progress});

  final ExplorerProgress progress;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final visited = progress.visited.length;
    final pct = (visited / places.length * 100).round();
    const colors = {
      Zone.sur: (AppColors.cyan, AppColors.cyanSoft),
      Zone.centro: (AppColors.blue, AppColors.blueSoft),
      Zone.norte: (AppColors.green, AppColors.mintSoft),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: '¡Mi recorrido por Loja! 🗺️',
          trailing: Pill(label: '$pct% Global', dense: true),
          subtitle:
              '$visited de ${places.length} sectores fluviales explorados en total.',
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            children: [
              for (final z in Zone.values) ...[
                Builder(
                  builder: (context) {
                    final inZone = placesInZone(z);
                    final done = inZone
                        .where((p) => progress.visited.contains(p.id))
                        .length;
                    final (color, soft) = colors[z]!;
                    return Column(
                      children: [
                        Row(
                          children: [
                            Icon(z.icon, size: 18, color: color),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${z.label} (${z.longLabel})',
                                style: t.labelMedium?.copyWith(
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            Pill(
                              label:
                                  '$done de ${inZone.length} (${(done / inZone.length * 100).round()}%)',
                              color: soft,
                              foreground: color == AppColors.green
                                  ? AppColors.greenDeep
                                  : color,
                              dense: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ProgressBar(
                          value: done / inZone.length,
                          colors: [color, color],
                          track: soft,
                        ),
                        const SizedBox(height: 14),
                      ],
                    );
                  },
                ),
              ],
              ChunkyButton(
                label: 'Volver al Mapa Fluvial',
                leading: Icons.explore_outlined,
                onPressed: () => context.go(Routes.map),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Acceso a la "Tienda de Sombreros".
class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.state});

  final ExplorerState state;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = state.progress;
    final next = hats.where((h) => !p.ownedHats.contains(h.id)).firstOrNull;
    return Pressable(
      semanticLabel: 'Abrir la tienda de sombreros',
      onTap: () => context.push(Routes.store),
      child: AppCard(
        color: AppColors.yellowSoft,
        borderColor: AppColors.yellow,
        ledgeColor: AppColors.yellow,
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: HatIcon(hatId: p.equippedHat ?? hats[6].id, width: 48),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tienda de Sombreros 🛍️',
                    style: t.titleMedium?.copyWith(color: AppColors.amberInk),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    next == null
                        ? '¡Tienes los ${hats.length} sombreros! Eres todo un coleccionista.'
                        : 'Tienes ${p.wallet} gotitas para gastar. ${p.ownedHats.length}/${hats.length} sombreros.',
                    style: t.bodyMedium?.copyWith(color: AppColors.amberInk),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.amberInk),
          ],
        ),
      ),
    );
  }
}
