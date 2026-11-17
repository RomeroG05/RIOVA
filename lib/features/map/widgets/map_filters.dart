import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/widgets/pressable.dart';
import '../../../data/models/place.dart';

/// Selector segmentado "Ambos Ríos / Malacatos / Zamora" con indicador
/// deslizante.
class RiverFilter extends StatelessWidget {
  const RiverFilter({super.key, required this.value, required this.onChanged});

  final River? value;
  final ValueChanged<River?> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final options = <(River?, String, String?)>[
      (null, 'Ambos Ríos', null),
      (River.malacatos, 'Malacatos', '(Oeste)'),
      (River.zamora, 'Zamora', '(Este)'),
    ];
    final index = options.indexWhere((o) => o.$1 == value);
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceBlue,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: Alignment(-1 + index * 1.0, 0),
            duration: AppMotion.of(context, AppMotion.medium),
            curve: AppMotion.easeInOut,
            child: FractionallySizedBox(
              widthFactor: 1 / 3,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x140B3B66),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final o in options)
                Expanded(
                  child: Semantics(
                    selected: o.$1 == value,
                    button: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(o.$1),
                      child: Center(
                        child: Text.rich(
                          TextSpan(
                            text: o.$2,
                            children: [
                              if (o.$3 != null)
                                TextSpan(
                                  text: '\n${o.$3}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          style: t.labelMedium?.copyWith(
                            color: o.$1 == value
                                ? AppColors.blue
                                : AppColors.inkSoft,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Chips horizontales de zona. Tocar la zona activa la deselecciona.
class ZoneChips extends StatelessWidget {
  const ZoneChips({super.key, required this.value, required this.onChanged});

  final Zone? value;
  final ValueChanged<Zone?> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: Zone.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final z = Zone.values[i];
          final selected = z == value;
          return Pressable(
            semanticLabel: '${z.label} (${z.nickname})',
            onTap: () => onChanged(selected ? null : z),
            child: AnimatedContainer(
              duration: AppMotion.of(context, AppMotion.fast),
              curve: AppMotion.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? AppColors.blue : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? AppColors.blue : AppColors.outline,
                  width: 1.5,
                ),
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0x400B57B8),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ]
                    : const [],
              ),
              child: Row(
                children: [
                  Icon(
                    z.icon,
                    size: 18,
                    color: selected ? Colors.white : AppColors.teal,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${z.label} (${z.nickname})',
                    style: t.labelMedium?.copyWith(
                      color: selected ? Colors.white : AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Interruptor "Mapa real / Ruta" sobre el mapa.
class ViewToggle extends StatelessWidget {
  const ViewToggle({
    super.key,
    required this.routeView,
    required this.onChanged,
  });

  final bool routeView;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    // Solo iconos: deja espacio al semáforo en pantallas angostas.
    Widget item(bool route, IconData icon, String label) {
      final selected = routeView == route;
      return Tooltip(
        message: label,
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          child: GestureDetector(
            onTap: () => onChanged(route),
            child: AnimatedContainer(
              duration: AppMotion.of(context, AppMotion.fast),
              curve: AppMotion.easeOut,
              width: 44,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? AppColors.teal : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                icon,
                size: 20,
                color: selected ? Colors.white : AppColors.teal,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260B3B66),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          item(false, Icons.map_outlined, 'Mapa real'),
          item(true, Icons.route_rounded, 'Ruta de aventura'),
        ],
      ),
    );
  }
}

/// Botón circular de control del mapa (zoom, ubicación).
class MapControlButton extends StatelessWidget {
  const MapControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: label,
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x260B3B66),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: busy
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Icon(icon, color: AppColors.teal),
      ),
    );
  }
}
