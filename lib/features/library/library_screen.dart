import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/illustrations/scene_painter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/motion_widgets.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/riova_header.dart';
import '../../state/tts_service.dart';
import '../place/widgets/place_sections.dart';

class _Story {
  const _Story(
    this.emoji,
    this.title,
    this.kind,
    this.summary,
    this.body,
    this.scene,
  );
  final String emoji;
  final String title;
  final String kind;
  final String summary;
  final String body;
  final SceneSpec scene;
}

const _stories = [
  _Story(
    '🌊',
    'Lo que el río se llevó',
    'Cuento',
    'Una historia del periódico del Taller UA II sobre el futuro del río.',
    'En Loja, la ciudad crecía y crecía. “Debemos encerrar al río entre muros, será lo mejor”, dijeron. Y el río quedó atrapado en paredes de hormigón, sin su cauce natural. '
        'Una noche de lluvia, el río decidió hacerse escuchar: “Debo tomar lo que una vez fue mío por naturaleza, lo siento”. El agua salió y llegó a casas y negocios. '
        'Entonces las personas entendieron. Las autoridades decidieron devolverle al río su cauce natural y acercarlo de nuevo a la gente. '
        'Desde ese día, el río y la ciudad aprendieron a vivir juntos.',
    SceneSpec.river,
  ),
  _Story(
    '⛈️',
    'El día que el río se cobró la ciudad',
    'Historia real',
    'Lo que pasó el 10 de marzo de 2025 en el centro de Loja.',
    'El lunes 10 de marzo de 2025 cayó sobre Loja un aguacero récord: 76,6 litros de agua por metro cuadrado en solo 24 horas. '
        'El río Malacatos, que había perdido espacio por las construcciones y estaba lleno de basura, no pudo llevarse tanta agua y se desbordó. '
        'Las calles del centro se llenaron de lodo, varios negocios se arruinaron y el puente de la calle Imbabura se derrumbó. '
        'Ese día aprendimos que el río necesita espacio, árboles en sus orillas y que nadie tire basura en él.',
    SceneSpec.storm,
  ),
  _Story(
    '💧',
    'El viaje de una gota',
    'Cuento',
    'Gotita nace en las montañas y viaja hasta la Amazonía.',
    'Gotita cayó de una nube sobre el bosque de Podocarpus. Las raíces y el musgo la guardaron unos días, como una esponja. '
        'Luego bajó por una quebrada fría hasta el río Malacatos, saludó a las truchas y pasó junto a los sauces de La Tebaida. '
        'En el norte de Loja se unió al río Zamora y siguió su viaje, muy lejos, hasta la Amazonía. '
        'Gotita aprendió algo importante: todo lo que pasa en la ciudad llega al río.',
    SceneSpec.nature,
  ),
  _Story(
    '🌳',
    '¿Por qué los sauces "lloran"?',
    'Dato curioso',
    'Sus ramas cuelgan hacia el agua por una buena razón.',
    'Los sauces llorones tienen ramas largas y flexibles que cuelgan hacia el agua. Son flexibles para no romperse con el viento ni con las crecidas. '
        'Sus raíces forman una red que sujeta la tierra de la orilla. Por eso, plantar sauces es una de las mejores maneras de proteger a la ciudad de la erosión.',
    SceneSpec.park,
  ),
  _Story(
    '🐟',
    'La trucha exigente',
    'Fauna',
    'Solo vive donde el agua está fría y limpia.',
    'La trucha necesita agua fría y con mucho oxígeno. Si el río se calienta o se ensucia con basura y grasas, la trucha se va o enferma. '
        'Por eso, ver truchas en un río es una señal de que el agua está sana.',
    SceneSpec.river,
  ),
  _Story(
    '🐻',
    'El oso de anteojos',
    'Fauna',
    'El guardián de los bosques que cuidan el agua.',
    'El oso de anteojos es el único oso de Sudamérica. Tiene manchas claras alrededor de los ojos que parecen gafas. '
        'Vive en los bosques andinos, los mismos que guardan el agua que luego llega a los ríos. Cuidar su hogar es cuidar nuestra agua.',
    SceneSpec.nature,
  ),
  _Story(
    '🌧️',
    'Lluvias andinas',
    'Ciencia',
    'Por qué el río puede crecer en pocas horas.',
    'En las montañas que rodean Loja puede llover mucho en poco tiempo. Toda esa agua baja por las laderas y llega al río a la vez. '
        'Si el cauce está lleno de basura o sedimentos, el agua no cabe y se desborda. Por eso nunca hay que acercarse a la orilla durante lluvias fuertes.',
    SceneSpec.storm,
  ),
  _Story(
    '🏞️',
    'Podocarpus: fábrica de agua',
    'Lugar',
    'Un parque nacional que alimenta los ríos de Loja.',
    'Cerca de Loja está el Parque Nacional Podocarpus. Sus bosques y páramos atrapan la humedad de las nubes y la convierten en pequeñas quebradas. '
        'Muchas de esas aguas llegan a la ciudad. Proteger el parque es proteger el agua que tomamos.',
    SceneSpec.valley,
  ),
];

/// "Biblioteca del Agua": historias, cuentos y datos curiosos.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  // Se obtiene en initState: en dispose ya no es seguro usar `ref`.
  late final TtsService _tts;

  @override
  void initState() {
    super.initState();
    _tts = ref.read(ttsProvider);
  }

  int? _open;

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: const RiovaBackBar(title: 'Biblioteca del Agua'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          EntranceFade(
            child: Text(
              'Historias, cuentos y datos curiosos de nuestra fauna y flora. Toca una para leerla o escucharla.',
              style: t.bodyLarge?.copyWith(color: AppColors.inkSoft),
            ),
          ),
          const SizedBox(height: 16),
          for (final (i, s) in _stories.indexed) ...[
            EntranceFade(
              index: i + 1,
              child: Pressable(
                scale: 0.99,
                onTap: () => setState(() => _open = _open == i ? null : i),
                semanticLabel: s.title,
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceTint,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                s.emoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Pill(
                                    label: s.kind,
                                    dense: true,
                                    color: AppColors.mintSoft,
                                    foreground: AppColors.greenDeep,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(s.title, style: t.titleMedium),
                                  Text(s.summary, style: t.bodySmall),
                                ],
                              ),
                            ),
                            AnimatedRotation(
                              turns: _open == i ? 0.5 : 0,
                              duration: AppMotion.of(context, AppMotion.fast),
                              child: Icon(
                                Icons.expand_more_rounded,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedSize(
                        duration: AppMotion.of(context, AppMotion.medium),
                        curve: AppMotion.easeOut,
                        alignment: Alignment.topCenter,
                        child: _open == i
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 140,
                                    width: double.infinity,
                                    child: SceneIllustration(spec: s.scene),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(s.body, style: t.bodyLarge),
                                        const SizedBox(height: 12),
                                        ListenButton(
                                          id: 'library-$i',
                                          text: '${s.title}. ${s.body}',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox(width: double.infinity),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
