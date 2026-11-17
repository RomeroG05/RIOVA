import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/mascot/rio_mascot.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/chunky_button.dart';
import '../../core/widgets/hat.dart';
import '../../core/widgets/motion_widgets.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/reward_dialog.dart';
import '../../core/widgets/riova_header.dart';
import '../../core/widgets/two_column_grid.dart';
import '../../data/content/hat_content.dart';
import '../../state/explorer_controller.dart';

/// "Tienda de Sombreros": se compran con gotitas disponibles para el avatar.
class HatStoreScreen extends ConsumerStatefulWidget {
  const HatStoreScreen({super.key});

  @override
  ConsumerState<HatStoreScreen> createState() => _HatStoreScreenState();
}

class _HatStoreScreenState extends ConsumerState<HatStoreScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confetti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  String? _selected;
  int _celebrate = 0;

  @override
  void initState() {
    super.initState();
    final p = ref.read(explorerProvider).progress;
    _selected = p.equippedHat ?? hats.first.id;
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _buy(HatInfo hat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: HatIcon(hatId: hat.id, width: 90),
        title: Text('¿Comprar ${hat.name}?'),
        content: Text(
          'Cuesta ${hat.price} gotitas. Tu nivel no baja: solo gastas gotitas disponibles.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Todavía no'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('¡Comprar!'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final result = ref.read(explorerProvider.notifier).buyHat(hat);
    if (result == HatPurchase.bought) {
      HapticFeedback.heavyImpact();
      setState(() => _celebrate++);
      if (!AppMotion.reduced(context)) _confetti.forward(from: 0);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('¡Nuevo sombrero! Ya llevas puesto: ${hat.name}.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = ref.watch(explorerProvider);
    final p = s.progress;
    final hat = hatById(_selected) ?? hats.first;
    final owned = p.ownedHats.contains(hat.id);
    final wearing = p.equippedHat == hat.id;
    final missing = hat.price - p.wallet;
    final level = s.level.level;
    final levelLocked = !owned && !hat.availableAt(level);

    final ChunkyButton action;
    if (wearing) {
      action = ChunkyButton(
        label: 'Quitármelo',
        tone: ChunkyTone.soft,
        leading: Icons.do_not_disturb_on_outlined,
        onPressed: () => ref.read(explorerProvider.notifier).equipHat(null),
      );
    } else if (owned) {
      action = ChunkyButton(
        label: 'Ponérmelo',
        tone: ChunkyTone.teal,
        leading: Icons.checkroom_rounded,
        onPressed: () {
          HapticFeedback.selectionClick();
          ref.read(explorerProvider.notifier).equipHat(hat.id);
        },
      );
    } else if (levelLocked) {
      action = ChunkyButton(
        label: 'Se desbloquea en el Nivel ${hat.minLevel}',
        leading: Icons.lock_outline_rounded,
        singleLine: true,
        onPressed: null,
      );
    } else if (missing > 0) {
      action = ChunkyButton(
        label: 'Te faltan $missing gotitas',
        leading: Icons.lock_outline_rounded,
        singleLine: true,
        onPressed: null,
      );
    } else {
      action = ChunkyButton(
        label: 'Comprar por ${hat.price} 💧',
        tone: ChunkyTone.green,
        leading: Icons.shopping_bag_outlined,
        singleLine: true,
        onPressed: () => _buy(hat),
      );
    }

    return Scaffold(
      appBar: const RiovaBackBar(title: 'Tienda'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          // ── Vista previa ──
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3FC6F1), Color(0xFF1E6FD9)],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Tienda de Sombreros',
                            style: t.titleLarge?.copyWith(color: Colors.white),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.water_drop_rounded,
                                color: AppColors.teal,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              CountUpText(
                                p.wallet,
                                style: t.titleSmall?.copyWith(
                                  color: AppColors.teal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 46),
                    TweenAnimationBuilder<double>(
                      key: ValueKey(_celebrate),
                      tween: Tween(begin: _celebrate == 0 ? 1 : 1.2, end: 1),
                      duration: AppMotion.of(
                        context,
                        const Duration(milliseconds: 600),
                      ),
                      curve: AppMotion.playful,
                      builder: (context, v, child) =>
                          Transform.scale(scale: v, child: child),
                      child: AnimatedSwitcher(
                        duration: AppMotion.of(context, AppMotion.medium),
                        switchInCurve: AppMotion.playful,
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: Tween(begin: 0.85, end: 1.0).animate(anim),
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: WithHat(
                          key: ValueKey(hat.id),
                          hatId: hat.id,
                          size: 120,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F6FD),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 5),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              s.profile?.avatar.emoji ?? '💧',
                              style: const TextStyle(fontSize: 60),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      hat.name,
                      style: t.headlineSmall?.copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hat.description,
                      textAlign: TextAlign.center,
                      style: t.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                    const SizedBox(height: 14),
                    action,
                  ],
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _confetti,
                    builder: (context, _) =>
                        CustomPaint(painter: ConfettiPainter(_confetti.value)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const RioSays(
            message: '¡Gana gotitas jugando, escaneando tótems y respondiendo preguntas! Comprar sombreros no baja tu nivel.',
          ),
          const SizedBox(height: 18),
          SectionTitle(
            title: 'Sombreros',
            icon: Icons.storefront_outlined,
            trailing: Pill(
              label: '${p.ownedHats.length}/${hats.length} tuyos',
              dense: true,
              color: AppColors.cyanSoft,
            ),
          ),
          const SizedBox(height: 12),
          TwoColumnGrid(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final (i, h) in hats.indexed)
                EntranceFade(
                  index: i.clamp(0, 6),
                  child: _HatTile(
                    hat: h,
                    selected: h.id == hat.id,
                    owned: p.ownedHats.contains(h.id),
                    wearing: p.equippedHat == h.id,
                    affordable: p.wallet >= h.price,
                    levelLocked: !h.availableAt(s.level.level),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selected = h.id);
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            color: AppColors.surfaceTint,
            child: Row(
              children: [
                const RioMascot(size: 40, interactive: false, idle: false),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tienes ${p.gotitas} gotitas ganadas (para tu nivel) y ${p.wallet} disponibles para la tienda.',
                    style: t.bodyMedium?.copyWith(color: AppColors.ink),
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

class _HatTile extends StatelessWidget {
  const _HatTile({
    required this.hat,
    required this.selected,
    required this.owned,
    required this.wearing,
    required this.affordable,
    required this.onTap,
    this.levelLocked = false,
  });

  final HatInfo hat;
  final bool selected;
  final bool owned;
  final bool wearing;
  final bool affordable;
  final VoidCallback onTap;

  /// Aún no se alcanza el nivel mínimo del sombrero.
  final bool levelLocked;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final Widget badge = wearing
        ? const Pill(
            label: 'Puesto',
            icon: Icons.check_rounded,
            dense: true,
            color: AppColors.mint,
            foreground: AppColors.greenDeep,
          )
        : owned
        ? const Pill(label: 'Tuyo', dense: true, color: AppColors.cyanSoft)
        : levelLocked
        ? Pill(
            label: 'Nivel ${hat.minLevel}',
            icon: Icons.lock_outline_rounded,
            dense: true,
            color: AppColors.surfaceBlue,
            foreground: AppColors.inkSoft,
          )
        : Pill(
            label: '${hat.price}',
            icon: Icons.water_drop_rounded,
            dense: true,
            color: affordable ? AppColors.cyan : AppColors.surfaceBlue,
            foreground: affordable ? Colors.white : AppColors.inkSoft,
          );
    return Pressable(
      onTap: onTap,
      semanticLabel:
          '${hat.name}, ${owned
              ? 'comprado'
              : levelLocked
              ? 'se desbloquea en el nivel ${hat.minLevel}'
              : '${hat.price} gotitas'}',
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.fast),
        curve: AppMotion.easeOut,
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.blueSoft : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.teal : AppColors.outline,
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x100B3B66),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Opacity(
              opacity: owned || (affordable && !levelLocked) ? 1 : 0.55,
              child: HatIcon(hatId: hat.id, width: 84),
            ),
            const SizedBox(height: 8),
            Text(
              hat.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: t.titleSmall,
            ),
            const SizedBox(height: 6),
            badge,
          ],
        ),
      ),
    );
  }
}
