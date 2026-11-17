import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/pressable.dart';
import '../../../state/sensor_network.dart';

/// "Semáforo Fluvial en Vivo": resumen plegable de la red de sensores.
class SemaforoPanel extends ConsumerWidget {
  const SemaforoPanel({
    super.key,
    required this.expanded,
    required this.onToggle,
  });

  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final summary = ref.watch(networkSummaryProvider);
    final pct = summary.averageQuality.round();

    final collapsed = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _LiveDot(),
        const SizedBox(width: 8),
        Text('Semáforo $pct%', style: t.titleSmall),
        if (summary.alerts > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '⚠ ${summary.alerts}',
              style: t.labelMedium?.copyWith(color: AppColors.greenDeep),
            ),
          ),
        ],
        const SizedBox(width: 4),
        const Icon(
          Icons.expand_more_rounded,
          size: 20,
          color: AppColors.inkSoft,
        ),
      ],
    );

    final full = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const IconBubble(icon: Icons.sensors_rounded, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Semáforo Fluvial en Vivo', style: t.titleMedium),
                  Text(
                    'Red de sensores IoT en ríos de Loja',
                    style: t.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.expand_less_rounded, color: AppColors.inkSoft),
          ],
        ),
        const SizedBox(height: 10),
        const Pill(
          label: 'Sensores en Vivo • 24/7',
          icon: Icons.podcasts_rounded,
          color: AppColors.mint,
          foreground: AppColors.greenDeep,
          dense: true,
        ),
        const SizedBox(height: 10),
        const _Legend(
          color: AppColors.cyan,
          icon: Icons.water_drop_rounded,
          title: 'Azul: Río Limpio y Sano',
          text: 'Aguas cristalinas, apto para truchas, patos y colibríes.',
        ),
        const SizedBox(height: 8),
        const _Legend(
          color: AppColors.green,
          icon: Icons.warning_amber_rounded,
          title: 'Verde: Alerta de Residuos',
          text: 'Presencia de grasas o plástico. ¡Requiere misión guardián!',
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceTint,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.analytics_outlined, color: AppColors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'Calidad promedio: ',
                    children: [
                      TextSpan(
                        text: '$pct% ${summary.label}',
                        style: const TextStyle(color: AppColors.greenDark),
                      ),
                    ],
                  ),
                  style: t.titleSmall,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, size: 8, color: AppColors.green),
                    const SizedBox(width: 5),
                    Text('${summary.alerts} en alerta', style: t.labelMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Pressable(
      onTap: onToggle,
      scale: 0.99,
      semanticLabel: expanded
          ? 'Plegar semáforo fluvial'
          : 'Ver semáforo fluvial',
      child: Container(
        padding: EdgeInsets.all(expanded ? 14 : 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(expanded ? 22 : 999),
          boxShadow: const [
            BoxShadow(
              color: Color(0x260B3B66),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedSize(
          duration: AppMotion.of(context, AppMotion.medium),
          curve: AppMotion.easeOut,
          alignment: Alignment.topLeft,
          child: AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.fast),
            child: expanded ? full : collapsed,
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.icon,
    required this.title,
    required this.text,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBubble(
            icon: icon,
            color: color,
            foreground: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: t.labelMedium?.copyWith(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(text, style: t.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!AppMotion.reduced(context) && !_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: AppColors.green,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
