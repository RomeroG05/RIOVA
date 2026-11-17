import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/illustrations/scene_painter.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/chunky_button.dart';
import '../../core/widgets/motion_widgets.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/riova_header.dart';
import '../../data/content/places_content.dart';
import '../../data/models/place.dart';
import '../../state/explorer_controller.dart';
import '../../state/tts_service.dart';
import 'widgets/place_sections.dart';
import 'widgets/place_interactive.dart';
import '../../state/content_revision.dart';

/// Pantalla "Explorando [lugar]": ficha educativa del sector.
class PlaceScreen extends ConsumerStatefulWidget {
  const PlaceScreen({super.key, required this.placeId});

  final String placeId;

  @override
  ConsumerState<PlaceScreen> createState() => _PlaceScreenState();
}

class _PlaceScreenState extends ConsumerState<PlaceScreen> {
  // Se obtiene en initState: en dispose ya no es seguro usar `ref`.
  late final TtsService _tts;

  @override
  void initState() {
    super.initState();
    _tts = ref.read(ttsProvider);
  }

  @override
  void dispose() {
    // Al salir de la ficha, deja de leer en voz alta.
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(contentRevisionProvider); // textos editados en Firestore
    final place = placeById(widget.placeId);
    final visited = ref.watch(
      explorerProvider.select((s) => s.progress.visited.contains(place.id)),
    );

    final sections = <Widget>[
      _TopChips(place: place),
      _Hero(place: place),
      StorySection(place: place),
      LiveConditions(place: place),
      FactCard(place: place),
      GallerySection(place: place),
      ProblemsSection(place: place),
      VoicesSection(place: place),
      BeforeAfterSection(place: place),
      TimelineSection(place: place),
      SpeciesSection(place: place),
      GuardianChecklist(place: place),
      PlaceQuiz(place: place),
      if (!visited) _RegisterCta(place: place),
    ];

    return Scaffold(
      appBar: const RiovaBackBar(),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        itemCount: sections.length,
        separatorBuilder: (_, i) => SizedBox(height: i == 0 ? 12 : 22),
        itemBuilder: (context, i) =>
            EntranceFade(index: i.clamp(0, 4), child: sections[i]),
      ),
    );
  }
}

class _TopChips extends StatelessWidget {
  const _TopChips({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Pressable(
          semanticLabel: 'Volver al mapa',
          onTap: () => context.go(Routes.map),
          child: const SizedBox(
            height: 48,
            child: Center(
              child: Pill(
                label: 'Volver al mapa',
                icon: Icons.arrow_back_rounded,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Ocupa todo el espacio restante (un Spacer junto a un Flexible se
        // repartía la mitad y recortaba la etiqueta).
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Pill(
              label: '${place.zone.label} • ${place.river.shortLabel}',
              icon: Icons.place_outlined,
              color: AppColors.surfaceBlue,
            ),
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final short = place.shortName;
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: SizedBox(
        height: 230,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              place.cover.asset,
              fit: BoxFit.cover,
              // Si faltara el archivo, se ve la ilustración del sector.
              errorBuilder: (_, _, _) => SceneIllustration(spec: place.scene),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x000B2236), Color(0xE00B2236)],
                  stops: [0.35, 1],
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              child: Pill(
                label: 'Sector ${place.code} • Parada ${stopNumber(place)}',
                icon: Icons.flag_outlined,
                color: AppColors.teal,
                foreground: Colors.white,
              ),
            ),
            const Positioned(
              right: 14,
              top: 14,
              child: Pill(
                label: 'En Vivo',
                icon: Icons.circle,
                color: Colors.white,
                foreground: AppColors.greenDeep,
                dense: true,
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Exploremos $short!',
                    style: t.headlineMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place.tagline,
                    style: t.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
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
}

class _RegisterCta extends StatelessWidget {
  const _RegisterCta({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      color: AppColors.mintSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Estás en ${place.shortName}?', style: t.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Escanea el tótem del sendero para ganar el sello oficial y +30 gotitas.',
            style: t.bodyMedium,
          ),
          const SizedBox(height: 14),
          ChunkyButton(
            label: 'REGISTRAR PARADA (QR)',
            tone: ChunkyTone.green,
            leading: Icons.qr_code_scanner_rounded,
            height: 52,
            onPressed: () => context.push(Routes.scan(placeId: place.id)),
          ),
        ],
      ),
    );
  }
}
