import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/explorer_controller.dart';
import '../mascot/rio_mascot.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import 'motion_widgets.dart';
import 'pressable.dart';
import 'hat.dart';

/// Contador de gotitas con pulso cuando aumenta.
class GotitasBadge extends ConsumerStatefulWidget {
  const GotitasBadge({super.key, this.showWord = false, this.filled = false});

  final bool showWord;
  final bool filled;

  @override
  ConsumerState<GotitasBadge> createState() => _GotitasBadgeState();
}

class _GotitasBadgeState extends ConsumerState<GotitasBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(explorerProvider.select((s) => s.progress.wallet), (prev, next) {
      if (prev != null && next > prev && !AppMotion.reduced(context)) {
        _pulse.forward(from: 0);
      }
    });
    final gotitas = ref.watch(
      explorerProvider.select((s) => s.progress.wallet),
    );
    final t = Theme.of(context).textTheme;
    return Semantics(
      label: '$gotitas gotitas disponibles',
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final v = Curves.easeOut.transform(
            1 - (_pulse.value - 0.5).abs() * 2,
          );
          return Transform.scale(
            scale: 1 + (_pulse.isAnimating ? v * 0.12 : 0),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: widget.filled ? AppColors.cyanSoft : AppColors.blueSoft,
            borderRadius: BorderRadius.circular(999),
            border: widget.filled
                ? Border.all(color: AppColors.cyan.withValues(alpha: 0.5))
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.filled
                    ? Icons.water_drop_rounded
                    : Icons.water_drop_outlined,
                size: 18,
                color: AppColors.teal,
              ),
              const SizedBox(width: 4),
              CountUpText(
                gotitas,
                suffix: widget.showWord ? ' Gotitas' : '',
                style: t.titleSmall?.copyWith(color: AppColors.teal),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón circular con el avatar del explorador (y su sombrero) que se ve
/// en la barra de todas las pantallas; abre el perfil.
class ProfileButton extends ConsumerWidget {
  const ProfileButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = ref.watch(explorerProvider.select((s) => s.profile?.avatar));
    final hat = ref.watch(
      explorerProvider.select((s) => s.progress.equippedHat),
    );
    return Pressable(
      semanticLabel: 'Ir a mi perfil',
      onTap: () => context.go('/perfil'),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: WithHat(
            hatId: avatar == null ? null : hat,
            size: 40,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.teal,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: avatar != null
                  ? Text(avatar.emoji, style: const TextStyle(fontSize: 20))
                  : const Icon(
                      Icons.person_outline_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Logotipo pequeño "RÍOVA" + nombre de sección, como en la barra del diseño.
class RiovaLogo extends StatelessWidget {
  const RiovaLogo({super.key, this.section});

  final String? section;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const RioMascot(size: 26, interactive: false, idle: false),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RÍOVA',
              style: t.titleLarge?.copyWith(
                color: AppColors.blue,
                height: 1,
                letterSpacing: 0.4,
              ),
            ),
            if (section != null)
              Text(
                section!.toUpperCase(),
                style: t.labelSmall?.copyWith(
                  color: AppColors.blue,
                  fontSize: 10.5,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Barra superior fija de las pestañas principales.
class RiovaSliverHeader extends StatelessWidget {
  const RiovaSliverHeader({super.key, required this.section});

  final String section;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      toolbarHeight: 64,
      backgroundColor: AppColors.background,
      titleSpacing: 16,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: RiovaLogo(section: section),
      ),
      actions: const [
        GotitasBadge(),
        SizedBox(width: 6),
        ProfileButton(),
        SizedBox(width: 10),
      ],
    );
  }
}

/// Barra de pantallas secundarias: atrás + logo + gotitas + avatar.
class RiovaBackBar extends StatelessWidget implements PreferredSizeWidget {
  const RiovaBackBar({super.key, this.title, this.onBack});

  final String? title;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppBar(
      toolbarHeight: 64,
      automaticallyImplyLeading: false,
      titleSpacing: 12,
      title: Row(
        children: [
          Pressable(
            semanticLabel: 'Atrás',
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.blueSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.blue,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const RioMascot(size: 24, interactive: false, idle: false),
          if (title != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title!,
                style: t.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
      actions: [
        // En teléfonos angostos se omite la palabra "Gotitas" para que la
        // barra no desborde.
        GotitasBadge(
          showWord: MediaQuery.sizeOf(context).width >= 380,
          filled: true,
        ),
        const SizedBox(width: 6),
        const ProfileButton(),
        const SizedBox(width: 10),
      ],
    );
  }
}
