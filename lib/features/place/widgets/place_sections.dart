import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mascot/rio_mascot.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/pressable.dart';
import '../../../data/models/place.dart';
import '../../../state/sensor_network.dart';
import '../../../state/tts_service.dart';
import '../../../core/widgets/two_column_grid.dart';
import '../../../core/widgets/motion_widgets.dart';

/// Botón "Escuchar" que lee un texto con la voz del sistema.
class ListenButton extends ConsumerWidget {
  const ListenButton({
    super.key,
    required this.id,
    required this.text,
    this.label = 'Escuchar',
    this.color = AppColors.yellow,
    this.foreground = AppColors.amberInk,
    this.compact = false,
  });

  /// Muestra solo el ícono en pantallas angostas (< 380 dp).
  final bool compact;

  final String id;
  final String text;
  final String label;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tts = ref.watch(ttsProvider);
    return ValueListenableBuilder<String?>(
      valueListenable: tts.speaking,
      builder: (context, speaking, _) {
        final active = speaking == id;
        return Pressable(
          semanticLabel: active ? 'Detener lectura' : label,
          onTap: () => tts.toggle(id, text),
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.fast),
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: active ? foreground : color,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  active ? Icons.stop_rounded : Icons.volume_up_rounded,
                  size: 18,
                  color: active ? Colors.white : foreground,
                ),
                if (!(compact && MediaQuery.sizeOf(context).width < 380)) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      active ? 'Detener' : label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: active ? Colors.white : foreground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// "Condición del Río en Vivo" con los 4 sensores simulados.
class LiveConditions extends ConsumerWidget {
  const LiveConditions({super.key, required this.place});

  final Place place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final r = ref.watch(placeReadingProvider(place.id));
    final clean = r.status == RiverStatus.clean;
    final message = clean
        ? '¡Las aguas en ${place.shortName} están saludables y cristalinas hoy!'
        : 'Los sensores detectan residuos en ${place.shortName}. ¡Necesitamos guardianes!';

    return AppCard(
      ledgeColor: AppColors.cyanSoft,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBubble(icon: Icons.sensors_rounded, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Condición del Río en Vivo', style: t.titleMedium),
                    Text(
                      r.live
                          ? 'Sensor IoT en vivo • Actualizado ahora'
                          : 'Sensores simulados • Se actualiza cada 4 s',
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
              Pill(
                label: r.flowLabel,
                icon: Icons.circle,
                color: r.level < 1.1
                    ? AppColors.mintSoft
                    : AppColors.yellowSoft,
                foreground: r.level < 1.1
                    ? AppColors.greenDeep
                    : AppColors.amberInk,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          TwoColumnGrid(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Metric(
                icon: Icons.water_drop_rounded,
                tint: AppColors.cyanSoft,
                iconColor: AppColors.cyanDark,
                label: 'Calidad del Agua',
                value: '${r.quality.round()}% ${r.qualityLabel}',
              ),
              _Metric(
                icon: Icons.straighten_rounded,
                tint: AppColors.blueSoft,
                iconColor: AppColors.blue,
                label: 'Caudal y Nivel',
                value:
                    '${r.level.toStringAsFixed(1).replaceAll('.', ',')} m • ${r.levelLabel}',
              ),
              _Metric(
                icon: Icons.thermostat_rounded,
                tint: AppColors.yellowSoft,
                iconColor: AppColors.orange,
                label: 'Temperatura',
                value: '${r.temperature.round()}°C • ${r.temperatureLabel}',
              ),
              _Metric(
                icon: Icons.science_outlined,
                tint: AppColors.mintSoft,
                iconColor: AppColors.greenDark,
                label: 'Oxígeno y Salud',
                value:
                    '${r.ph.toStringAsFixed(1).replaceAll('.', ',')} pH • ${r.phLabel}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: clean ? AppColors.cyanSoft : AppColors.mintSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                RioMascot(
                  size: 26,
                  mood: clean ? MascotMood.happy : MascotMood.sad,
                  interactive: false,
                  idle: false,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SequentialSwap(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'RÍO: $message',
                      key: ValueKey(clean),
                      style: t.labelMedium?.copyWith(color: AppColors.tealDark),
                    ),
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

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.tint,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color tint;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tint),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            child: Icon(icon, size: 19, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: t.bodySmall?.copyWith(fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // Los valores cambian cada pocos segundos: un fundido corto
                // indica "dato nuevo" sin distraer.
                SequentialSwap(
                  duration: AppMotion.medium,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    key: ValueKey(value),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleSmall?.copyWith(
                      color: AppColors.blue,
                      fontSize: 13.5,
                    ),
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

/// Tarjeta amarilla "¿SABÍAS QUE...?" con lectura en voz alta.
class FactCard extends StatelessWidget {
  const FactCard({super.key, required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      color: AppColors.yellowSoft,
      borderColor: AppColors.yellow,
      ledgeColor: AppColors.yellow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBubble(
                icon: Icons.water_drop_rounded,
                color: AppColors.yellow,
                foreground: Colors.white,
                size: 44,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '¿SABÍAS QUE...? ✨',
                  style: t.titleMedium?.copyWith(color: AppColors.amberInk),
                ),
              ),
              const SizedBox(width: 6),
              ListenButton(
                id: 'fact-${place.id}',
                text: place.fact,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            place.fact,
            style: t.bodyLarge?.copyWith(
              color: AppColors.amberInk,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0x33F6CF4E)),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              for (final tag in place.factTags)
                Text(
                  '• $tag',
                  style: t.labelMedium?.copyWith(color: AppColors.amberInk),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "¡Viajemos en el tiempo!": la historia del sector con relato sonoro.
class TimelineSection extends StatelessWidget {
  const TimelineSection({super.key, required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final steps = place.timeline;
    final story = steps.map((s) => '${s.title}. ${s.text}').join(' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: '¡Viajemos en el tiempo!',
          icon: Icons.history_rounded,
        ),
        const SizedBox(height: 12),
        AppCard(
          ledgeColor: AppColors.blueSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(18),
                ),
                width: double.infinity,
                // Wrap: si el botón no cabe junto al título, baja de línea.
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.headphones_rounded,
                          color: AppColors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text('Relato sonoro', style: t.titleSmall),
                      ],
                    ),
                    ListenButton(
                      id: 'timeline-${place.id}',
                      text: story,
                      label: 'Escuchar relato',
                      color: AppColors.blue,
                      foreground: Colors.white,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              for (final (i, s) in steps.indexed)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(
                              color: AppColors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (i < steps.length - 1)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: AppColors.blueSoft,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: i < steps.length - 1 ? 14 : 0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.title,
                                style: t.titleSmall?.copyWith(
                                  color: AppColors.blue,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(s.text, style: t.bodyMedium),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "¡Amigos de la naturaleza!"
class SpeciesSection extends StatelessWidget {
  const SpeciesSection({super.key, required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: '¡Amigos de la naturaleza!',
          icon: Icons.forest_outlined,
          iconColor: AppColors.greenDark,
          trailing: Pill(
            label: '${place.species.length} Especies',
            color: AppColors.mint,
            foreground: AppColors.greenDeep,
            dense: true,
          ),
        ),
        const SizedBox(height: 10),
        RioSays(
          message:
              '¡Los árboles y aves son los verdaderos cuidadores del río ${place.river.shortLabel}!',
        ),
        const SizedBox(height: 12),
        TwoColumnGrid(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final s in place.species)
              AppCard(
                ledgeColor: AppColors.blueSoft,
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: s.isFauna
                            ? AppColors.yellowSoft
                            : AppColors.mintSoft,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        s.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.name,
                      style: t.titleSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Pill(
                      label: s.tag,
                      dense: true,
                      color: s.isFauna
                          ? AppColors.yellowSoft
                          : AppColors.cyanSoft,
                      foreground: s.isFauna
                          ? AppColors.amberInk
                          : AppColors.tealDark,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.text,
                      style: t.bodySmall,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// "La noticia del río": titular y relato del periódico del sector.
class StorySection extends StatelessWidget {
  const StorySection({super.key, required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      ledgeColor: AppColors.blueSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Pill(
                label: 'La noticia del río • ${place.code}',
                icon: Icons.newspaper_rounded,
                uppercase: true,
                dense: true,
              ),
              ListenButton(
                id: 'story-${place.id}',
                text: '${place.headline}. ${place.story.join(' ')}',
                label: 'Escuchar',
                color: AppColors.blue,
                foreground: Colors.white,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(place.headline, style: t.titleLarge),
          const SizedBox(height: 10),
          for (final (i, p) in place.story.indexed) ...[
            Text(
              p,
              style: t.bodyLarge?.copyWith(
                color: i == 0 ? AppColors.ink : AppColors.inkSoft,
              ),
            ),
            if (i < place.story.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

/// "Voces del barrio": testimonios de vecinos recogidos en el periódico.
class VoicesSection extends StatelessWidget {
  const VoicesSection({super.key, required this.place});

  final Place place;

  static const _tints = [
    AppColors.cyanSoft,
    AppColors.mintSoft,
    AppColors.yellowSoft,
    AppColors.blueSoft,
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (place.voices.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Voces del barrio',
          icon: Icons.forum_outlined,
          subtitle: 'Lo que cuentan las personas que viven junto al río.',
        ),
        const SizedBox(height: 12),
        for (final (i, v) in place.voices.indexed) ...[
          Align(
            alignment: i.isEven ? Alignment.centerLeft : Alignment.centerRight,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.82,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: _tints[i % _tints.length],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(i.isEven ? 4 : 20),
                    bottomRight: Radius.circular(i.isEven ? 20 : 4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '“${v.quote}”',
                      style: t.bodyLarge?.copyWith(color: AppColors.ink),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '— ${v.who}',
                      style: t.labelMedium?.copyWith(color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
