import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/illustrations/scene_painter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/chunky_button.dart';
import '../../../core/widgets/pressable.dart';
import '../../../data/models/place.dart';
import 'place_marker.dart';

/// Tarjeta del sector seleccionado, flotando sobre el mapa.
class PlaceCard extends StatelessWidget {
  const PlaceCard({
    super.key,
    required this.place,
    required this.state,
    required this.me,
    required this.onClose,
    required this.onLearnMore,
    required this.onRegister,
  });

  final Place place;
  final PlaceState state;
  final LatLng? me;
  final VoidCallback onClose;
  final VoidCallback onLearnMore;
  final VoidCallback onRegister;

  static String formatDistance(double meters) => meters < 1000
      ? '${meters.round()} m'
      : '${(meters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final distance = me == null
        ? null
        : const Distance().as(LengthUnit.Meter, me!, place.position);
    final nearby = distance != null && distance < 150;

    final status = switch (state) {
      PlaceState.visited => Pill(
        label: 'Sector Superado ★★★',
        color: AppColors.mint,
        foreground: AppColors.greenDeep,
        dense: true,
      ),
      PlaceState.available => Pill(
        label: '¡Misión disponible!',
        icon: Icons.water_drop_rounded,
        color: AppColors.cyanSoft,
        dense: true,
      ),
    };

    return AppCard(
      ledgeColor: AppColors.cyanSoft,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: Image.asset(
                    place.cover.asset,
                    fit: BoxFit.cover,
                    cacheWidth: 300,
                    errorBuilder: (_, _, _) =>
                        SceneIllustration(spec: place.scene),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Pill(
                          label: '${place.code} • ${place.zone.label}',
                          uppercase: true,
                          dense: true,
                        ),
                        status,
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      place.name,
                      style: t.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.water_rounded,
                          size: 16,
                          color: place.river.color,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(place.river.label, style: t.bodySmall),
                        ),
                        if (distance != null) ...[
                          const SizedBox(width: 10),
                          Icon(
                            Icons.near_me_outlined,
                            size: 15,
                            color: AppColors.blue,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            nearby ? '¡Estás aquí!' : formatDistance(distance),
                            style: t.bodySmall?.copyWith(
                              color: AppColors.blue,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Pressable(
                semanticLabel: 'Cerrar',
                onTap: onClose,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.close_rounded, color: AppColors.inkMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            place.description,
            style: t.bodyMedium?.copyWith(color: AppColors.ink),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ChunkyButton(
                  label: 'CONOCE MÁS',
                  tone: ChunkyTone.teal,
                  height: 48,
                  fontSize: 14,
                  trailing: Icons.auto_stories_outlined,
                  onPressed: onLearnMore,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChunkyButton(
                  label: 'REGISTRAR',
                  tone: ChunkyTone.green,
                  height: 48,
                  fontSize: 14,
                  leading: Icons.qr_code_scanner_rounded,
                  onPressed: onRegister,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
