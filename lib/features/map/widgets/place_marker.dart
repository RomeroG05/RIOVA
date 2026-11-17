import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../../core/widgets/pressable.dart';
import '../../../data/models/place.dart';
import '../../../state/sensor_network.dart';

enum PlaceState { visited, available }

IconData placeIcon(Place p, PlaceState s) {
  switch (p.id) {
    case 'puerta':
      return Icons.account_balance_outlined;
    case 'jipiro':
      return Icons.fort_outlined;
    case 'mayorista':
      return Icons.storefront_outlined;
    case 'tebaida':
      return Icons.park_outlined;
  }
  return s == PlaceState.visited ? Icons.eco_rounded : Icons.explore_rounded;
}

/// Nodo circular de un sector, compartido por el mapa real y la ruta.
class PlaceNode extends StatelessWidget {
  const PlaceNode({
    super.key,
    required this.place,
    required this.state,
    required this.selected,
    required this.onTap,
    this.status,
    this.size = 48,
    this.showLabel = true,
  });

  final Place place;
  final PlaceState state;
  final bool selected;
  final VoidCallback onTap;
  final RiverStatus? status;
  final double size;
  final bool showLabel;

  /// Alto total del nodo con etiqueta, para anclarlo en el mapa.
  static double heightFor(double size) => size + 44;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final (colors, fg) = switch (state) {
      PlaceState.visited => (
        const [Color(0xFF6BD48B), AppColors.greenDark],
        Colors.white,
      ),
      PlaceState.available => (
        const [Color(0xFF4DD3F7), AppColors.cyanDark],
        Colors.white,
      ),
    };

    final circle = AnimatedScale(
      scale: selected ? 1.16 : 1,
      duration: AppMotion.of(context, AppMotion.medium),
      curve: AppMotion.playful,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          border: Border.all(
            color: selected ? AppColors.ink : Colors.white,
            width: selected ? 3 : 3,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.last.withValues(alpha: 0.45),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(placeIcon(place, state), color: fg, size: size * 0.48),
      ),
    );

    return Pressable(
      onTap: onTap,
      semanticLabel:
          '${place.name}, ${switch (state) {
            PlaceState.visited => 'visitado',
            PlaceState.available => 'disponible',
          }}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size + 16,
            height: size + 4,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                PulseRing(
                  active: state == PlaceState.available && !selected,
                  size: size,
                  child: circle,
                ),
                if (status != null)
                  Positioned(
                    right: 2,
                    top: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: status == RiverStatus.clean
                            ? AppColors.cyan
                            : AppColors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (showLabel) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              constraints: const BoxConstraints(maxWidth: 128),
              decoration: BoxDecoration(
                color: selected ? AppColors.teal : AppColors.surface,
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F0B3B66),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                place.shortName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.labelMedium?.copyWith(
                  color: selected ? Colors.white : AppColors.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                ),
              ),
            ),
            if (state == PlaceState.visited)
              Text(
                '★★★',
                style: TextStyle(
                  color: AppColors.blue,
                  fontSize: 11,
                  letterSpacing: 1,
                  height: 1.3,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Punto azul de "estás aquí".
class MeDot extends StatelessWidget {
  const MeDot({super.key});

  @override
  Widget build(BuildContext context) {
    return PulseRing(
      color: AppColors.blue,
      size: 22,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: AppColors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: const [BoxShadow(color: Color(0x400B57B8), blurRadius: 8)],
        ),
      ),
    );
  }
}
