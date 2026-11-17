import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/illustrations/scene_painter.dart';
import '../../core/widgets/chunky_button.dart';
import '../models/explorer.dart';
import '../models/place.dart';
import 'places_content.dart';

enum GameId {
  rescata,
  quiz,
  detective,
  palabras,
  camino,
  guardianes,
  mitos,
  recicla,
  rompecabezas,
}

/// Cómo se desbloquea un minijuego extra. Basta con cumplir UNA condición:
/// llegar al [level], escanear un tótem de la [zone] o haber escaneado
/// [scans] tótems en total. Sin condiciones = abierto desde el inicio.
@immutable
class UnlockRule {
  const UnlockRule({this.level, this.zone, this.scans});
  const UnlockRule.open() : level = null, zone = null, scans = null;

  final int? level;
  final Zone? zone;
  final int? scans;

  bool get isOpen => level == null && zone == null && scans == null;

  bool met(ExplorerProgress p) {
    if (isOpen) return true;
    if (level != null && LevelProgress.of(p.gotitas).level >= level!) {
      return true;
    }
    if (scans != null && scannedCount(p) >= scans!) return true;
    if (zone != null &&
        places.any((pl) => pl.zone == zone && p.visited.contains(pl.id))) {
      return true;
    }
    return false;
  }

  /// Texto para la tarjeta bloqueada: "Nivel 2 o escanea un tótem del Centro".
  String get label {
    final parts = <String>[
      if (level != null) 'Llega al Nivel $level',
      if (zone != null)
        'escanea un tótem ${zone == Zone.centro ? 'del Centro' : 'de la ${zone!.label}'}',
      if (scans != null) 'escanea $scans tótems',
    ];
    if (parts.isEmpty) return '';
    final text = parts.join(' o ');
    return text[0].toUpperCase() + text.substring(1);
  }
}

/// Tótems escaneados (sectores registrados con QR que existen hoy).
int scannedCount(ExplorerProgress p) =>
    places.where((pl) => p.visited.contains(pl.id)).length;

@immutable
class GameInfo {
  const GameInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.easy,
    required this.reward,
    required this.icon,
    required this.cta,
    required this.ctaIcon,
    required this.tone,
    required this.cardColor,
    required this.scene,
    this.unlock = const UnlockRule.open(),
    this.isNew = false,
  });

  final GameId id;
  final String title;
  final String description;
  final bool easy;
  final int reward;
  final IconData icon;
  final String cta;
  final IconData ctaIcon;
  final ChunkyTone tone;
  final Color cardColor;
  final SceneSpec scene;
  final UnlockRule unlock;
  final bool isNew;

  String get difficulty => easy ? 'Fácil' : 'Media';

  /// Abierto si cumple su regla o si ya se había ganado antes (no se le
  /// quita a nadie un juego que ya conocía).
  bool unlockedFor(ExplorerProgress p) =>
      unlock.met(p) || p.completedGames.contains(id.name);

  /// Gotitas por repetir un juego ya completado (evita "granjear" XP).
  static const replayReward = 10;
}

const games = <GameInfo>[
  // ── Abiertos desde el inicio (Zona Sur) ──
  GameInfo(
    id: GameId.rescata,
    title: 'Rescata el Río',
    description: 'Recoge la basura y devuelve la vida al río Malacatos.',
    easy: true,
    reward: 50,
    icon: Icons.cleaning_services_outlined,
    cta: '¡Jugar!',
    ctaIcon: Icons.play_circle_outline_rounded,
    tone: ChunkyTone.cyan,
    cardColor: Color(0xFFDDE7F1),
    scene: SceneSpec(willows: 4, seed: 2, erosion: 0.35),
  ),
  GameInfo(
    id: GameId.quiz,
    title: '¿Cuánto sabes de Loja?',
    description: 'Responde preguntas y demuestra cuánto sabes sobre los ríos.',
    easy: true,
    reward: 30,
    icon: Icons.quiz_outlined,
    cta: '¡Responder!',
    ctaIcon: Icons.question_answer_outlined,
    tone: ChunkyTone.soft,
    cardColor: Color(0xFFD9E3EE),
    scene: SceneSpec.valley,
  ),
  // ── Zona Centro: Nivel 2 o tótem del Centro ──
  GameInfo(
    id: GameId.detective,
    title: 'Detective de Inundaciones',
    description:
        'Investiga qué provoca las inundaciones y encuentra las causas.',
    easy: false,
    reward: 60,
    icon: Icons.manage_search_rounded,
    cta: '¡Investigar!',
    ctaIcon: Icons.search_rounded,
    tone: ChunkyTone.blue,
    cardColor: Color(0xFFE4EEFC),
    scene: SceneSpec.storm,
    unlock: UnlockRule(level: 2, zone: Zone.centro),
  ),
  GameInfo(
    id: GameId.palabras,
    title: 'Encuentra Palabras',
    description:
        'Encuentra las palabras escondidas antes de completar el desafío.',
    easy: false,
    reward: 40,
    icon: Icons.spellcheck_rounded,
    cta: '¡Buscar!',
    ctaIcon: Icons.find_in_page_outlined,
    tone: ChunkyTone.red,
    cardColor: Color(0xFFEBDCE1),
    scene: SceneSpec(lake: true, willows: 3, seed: 15),
    unlock: UnlockRule(level: 2, zone: Zone.centro),
  ),
  // ── Zona Norte: Nivel 3 o tótem del Norte ──
  GameInfo(
    id: GameId.camino,
    title: 'El Camino del Agua',
    description:
        'Guía el agua por el camino correcto hasta llegar al río Zamora.',
    easy: true,
    reward: 40,
    icon: Icons.alt_route_rounded,
    cta: '¡Comenzar!',
    ctaIcon: Icons.navigation_outlined,
    tone: ChunkyTone.teal,
    cardColor: Color(0xFFD6EEDD),
    scene: SceneSpec(willows: 5, path: true, seed: 8),
    unlock: UnlockRule(level: 3, zone: Zone.norte),
  ),
  GameInfo(
    id: GameId.guardianes,
    title: 'Guardianes Naturaleza',
    description:
        'Descubre las plantas y animales que viven junto a nuestros ríos.',
    easy: false,
    reward: 50,
    icon: Icons.forest_outlined,
    cta: '¡Descubrir!',
    ctaIcon: Icons.travel_explore_rounded,
    tone: ChunkyTone.forest,
    cardColor: Color(0xFFE6F0FB),
    scene: SceneSpec.nature,
    unlock: UnlockRule(level: 3, zone: Zone.norte),
  ),
  // ── Nuevos minijuegos extra ──
  GameInfo(
    id: GameId.mitos,
    title: 'Mitos y Verdades',
    description:
        'Desliza cada tarjeta: ¿verdadero o falso? Descubre los mitos del río.',
    easy: true,
    reward: 40,
    icon: Icons.swipe_rounded,
    cta: '¡Deslizar!',
    ctaIcon: Icons.swipe_right_alt_rounded,
    tone: ChunkyTone.blue,
    cardColor: Color(0xFFE3EAFB),
    scene: SceneSpec(willows: 3, seed: 51),
    unlock: UnlockRule(level: 4, zone: Zone.sur),
    isNew: true,
  ),
  GameInfo(
    id: GameId.recicla,
    title: 'Recicla en la Orilla',
    description:
        'Arrastra cada residuo al tacho correcto antes de que llegue al río.',
    easy: false,
    reward: 50,
    icon: Icons.recycling_rounded,
    cta: '¡Reciclar!',
    ctaIcon: Icons.pan_tool_alt_outlined,
    tone: ChunkyTone.green,
    cardColor: Color(0xFFDDF1E3),
    scene: SceneSpec(willows: 4, path: true, seed: 57, erosion: 0.2),
    unlock: UnlockRule(level: 5, scans: 3),
    isNew: true,
  ),
  GameInfo(
    id: GameId.rompecabezas,
    title: 'Rompecabezas del Río',
    description:
        'Ordena las piezas y descubre fotos reales de los sectores de Loja.',
    easy: false,
    reward: 60,
    icon: Icons.extension_outlined,
    cta: '¡Armar!',
    ctaIcon: Icons.grid_view_rounded,
    tone: ChunkyTone.teal,
    cardColor: Color(0xFFDCEFF3),
    scene: SceneSpec.park,
    unlock: UnlockRule(level: 6, scans: 6),
    isNew: true,
  ),
];

GameInfo gameById(GameId id) => games.firstWhere((g) => g.id == id);

GameId? gameIdFromName(String name) => GameId.values.asNameMap()[name];

List<GameInfo> unlockedGames(ExplorerProgress p) =>
    games.where((g) => g.unlockedFor(p)).toList();

// ───────────── Medallas ─────────────
//
// Las medallas se ganan ÚNICAMENTE subiendo de nivel o escaneando los QR de
// los tótems del recorrido.

@immutable
class Medal {
  const Medal({
    required this.id,
    required this.title,
    required this.howTo,
    required this.secret,
    required this.icon,
    required this.colors,
    required this.progress,
    this.byLevel = false,
  });

  final String id;
  final String title;
  final String howTo;

  /// "El secreto de su poder": dato que se revela al inspeccionarla.
  final String secret;
  final IconData icon;
  final List<Color> colors;

  /// `true` = medalla de nivel; `false` = medalla de tótems QR.
  final bool byLevel;

  /// (actual, meta) a partir del progreso.
  final (int, int) Function(ExplorerProgress p) progress;

  bool unlocked(ExplorerProgress p) {
    final (cur, goal) = progress(p);
    return cur >= goal;
  }
}

int _scannedWhere(ExplorerProgress p, bool Function(Place) test) =>
    places.where((pl) => test(pl) && p.visited.contains(pl.id)).length;

int _countWhere(bool Function(Place) test) => places.where(test).length;

Medal _levelMedal(
  String id,
  int level,
  String title,
  String secret,
  IconData icon,
  List<Color> colors,
) => Medal(
  id: id,
  title: title,
  howTo: 'Llega al Nivel $level (${levels[level - 1].title}).',
  secret: secret,
  icon: icon,
  colors: colors,
  byLevel: true,
  progress: (p) => (math.min(LevelProgress.of(p.gotitas).level, level), level),
);

final medals = <Medal>[
  // ── Por escanear tótems QR ──
  Medal(
    id: 'primera_huella',
    title: 'Primera Huella',
    howTo: 'Escanea el QR de tu primer tótem.',
    secret: 'Todo gran guardián empezó con un solo paso junto al río.',
    icon: Icons.qr_code_scanner_rounded,
    colors: const [Color(0xFF5BC8F5), Color(0xFF1E88E5)],
    progress: (p) => (math.min(scannedCount(p), 1), 1),
  ),
  Medal(
    id: 'guardian_sur',
    title: 'Guardián del Sur',
    howTo:
        'Escanea los ${_countWhere((pl) => pl.zone == Zone.sur)} tótems de la Zona Sur.',
    secret: 'Por el sur, el Malacatos entra a Loja entre huertos y montañas.',
    icon: Icons.flag_rounded,
    colors: const [Color(0xFF7CD3F7), Color(0xFF0A7FA2)],
    progress: (p) => (
      _scannedWhere(p, (pl) => pl.zone == Zone.sur),
      _countWhere((pl) => pl.zone == Zone.sur),
    ),
  ),
  Medal(
    id: 'corazon_loja',
    title: 'Corazón de Loja',
    howTo:
        'Escanea los ${_countWhere((pl) => pl.zone == Zone.centro)} tótems del Centro.',
    secret: 'El 10 de marzo de 2025 una lluvia récord desbordó el Malacatos en el centro.',
    icon: Icons.location_city_rounded,
    colors: const [Color(0xFF6C8CF5), Color(0xFF2E3FA8)],
    progress: (p) => (
      _scannedWhere(p, (pl) => pl.zone == Zone.centro),
      _countWhere((pl) => pl.zone == Zone.centro),
    ),
  ),
  Medal(
    id: 'ruta_natural',
    title: 'Ruta Natural',
    howTo:
        'Escanea los ${_countWhere((pl) => pl.zone == Zone.norte)} tótems de la Zona Norte.',
    secret: 'Por el norte, el Zamora busca su salida hacia la Amazonía.',
    icon: Icons.park_rounded,
    colors: const [Color(0xFF6BD48B), Color(0xFF1F8A47)],
    progress: (p) => (
      _scannedWhere(p, (pl) => pl.zone == Zone.norte),
      _countWhere((pl) => pl.zone == Zone.norte),
    ),
  ),
  Medal(
    id: 'guardian_malacatos',
    title: 'Guardián Malacatos',
    howTo: 'Escanea todos los tótems del río Malacatos.',
    secret: 'El Malacatos cruza Loja por el oeste y se une al Zamora Huayco en la Puerta de la Ciudad.',
    icon: Icons.waves_rounded,
    colors: const [Color(0xFF3F8EE8), Color(0xFF0B3F9C)],
    progress: (p) => (
      _scannedWhere(p, (pl) => pl.river == River.malacatos),
      _countWhere((pl) => pl.river == River.malacatos),
    ),
  ),
  Medal(
    id: 'explorador_zamora',
    title: 'Explorador Zamora',
    howTo: 'Escanea todos los tótems del río Zamora.',
    secret:
        'El Zamora recibe al Malacatos y lleva sus aguas hasta la Amazonía.',
    icon: Icons.explore_outlined,
    colors: const [Color(0xFF48C9A0), Color(0xFF137A5C)],
    progress: (p) => (
      _scannedWhere(p, (pl) => pl.river == River.zamora),
      _countWhere((pl) => pl.river == River.zamora),
    ),
  ),
  Medal(
    id: 'confluencia',
    title: 'Donde los Ríos se Abrazan',
    howTo: 'Escanea el tótem de la Puerta de la Ciudad.',
    secret: 'Junto a la Puerta de la Ciudad, el Malacatos y el Zamora Huayco forman el río Zamora.',
    icon: Icons.call_merge_rounded,
    colors: const [Color(0xFF12BDEA), Color(0xFF4CC371)],
    progress: (p) => (p.visited.contains('puerta') ? 1 : 0, 1),
  ),
  Medal(
    id: 'gran_recorrido',
    title: 'Gran Recorrido',
    howTo: 'Escanea los ${places.length} tótems de Loja.',
    secret:
        '¡Recorriste los ríos de Loja de sur a norte! Eres su gran guardián.',
    icon: Icons.emoji_events_rounded,
    colors: const [Color(0xFFF6CF4E), Color(0xFFE08A1E)],
    progress: (p) => (scannedCount(p), places.length),
  ),
  // ── Por subir de nivel ──
  _levelMedal(
    'nivel_2',
    2,
    'Brote del Río',
    'Las raíces de los sauces sujetan la tierra de las orillas.',
    Icons.spa_rounded,
    const [Color(0xFF8DF0AA), Color(0xFF2B8A4A)],
  ),
  _levelMedal(
    'nivel_3',
    3,
    'Aprendiz del Agua',
    'Los bosques guardan la lluvia y la sueltan poco a poco al río.',
    Icons.water_drop_rounded,
    const [Color(0xFF7CD3F7), Color(0xFF0B57B8)],
  ),
  _levelMedal(
    'nivel_4',
    4,
    'Guardián del Río',
    'La basura bajo los puentes forma tapones que desbordan el río.',
    Icons.shield_rounded,
    const [Color(0xFF5B8DEF), Color(0xFF0B2E6B)],
  ),
  _levelMedal(
    'nivel_5',
    5,
    'Protector Fluvial',
    'Una planta de tratamiento limpia el agua sucia antes de volver al río.',
    Icons.verified_rounded,
    const [Color(0xFF48C9A0), Color(0xFF00657F)],
  ),
  _levelMedal(
    'nivel_6',
    6,
    'Héroe de Loja',
    'Cuidar el río es proteger la vida y la identidad de Loja.',
    Icons.workspace_premium_rounded,
    const [Color(0xFFFF9E80), Color(0xFFC8423B)],
  ),
  _levelMedal(
    'nivel_8',
    8,
    'Gran Guardián',
    'Llegaste a la cima: ¡ahora enseña a otros a cuidar los ríos!',
    Icons.military_tech_rounded,
    const [Color(0xFFF6CF4E), Color(0xFF7A4A00)],
  ),
];

// ───────────── Misiones del día ─────────────

@immutable
class DailyMission {
  const DailyMission({
    required this.title,
    required this.description,
    required this.game,
    this.reward = 50,
    this.emoji = '🌊',
  });

  final String title;
  final String description;
  final GameId game;
  final int reward;
  final String emoji;
}

const dailyMissions = <DailyMission>[
  DailyMission(
    title: 'Rescata La Tebaida',
    description: 'Recoge residuos a orillas del río en Rescata el Río.',
    game: GameId.rescata,
    emoji: '🧹',
  ),
  DailyMission(
    title: 'Caso Malacatos',
    description:
        'Descubre por qué subió el nivel del río en Detective de Inundaciones.',
    game: GameId.detective,
    emoji: '🔎',
  ),
  DailyMission(
    title: 'Ruta hasta el Zamora',
    description:
        'Conecta los canales para llevar el agua limpia al río Zamora.',
    game: GameId.camino,
    emoji: '🚰',
  ),
  DailyMission(
    title: 'Amigos de la ribera',
    description: 'Encuentra todas las parejas de flora y fauna del río.',
    game: GameId.guardianes,
    emoji: '🌿',
  ),
  DailyMission(
    title: 'Sabio de Loja',
    description: 'Gana el reto de preguntas sobre los ríos de Loja.',
    game: GameId.quiz,
    emoji: '🧠',
  ),
  DailyMission(
    title: 'Palabras del agua',
    description:
        'Encuentra todas las palabras escondidas en la sopa de letras.',
    game: GameId.palabras,
    emoji: '🔤',
  ),
  DailyMission(
    title: 'Cazamitos',
    description: 'Separa los mitos de las verdades sobre el río Zamora.',
    game: GameId.mitos,
    emoji: '🃏',
  ),
  DailyMission(
    title: 'Orilla limpia',
    description: 'Clasifica los residuos en el tacho correcto antes de que lleguen al río.',
    game: GameId.recicla,
    emoji: '♻️',
  ),
  DailyMission(
    title: 'Foto perdida',
    description: 'Arma el rompecabezas de un sector de Loja.',
    game: GameId.rompecabezas,
    emoji: '🧩',
  ),
];

/// La misión del día rota de forma determinista entre los juegos que el
/// explorador ya tiene desbloqueados.
DailyMission missionFor(DateTime day, ExplorerProgress progress) {
  final available = dailyMissions
      .where((m) => gameById(m.game).unlockedFor(progress))
      .toList();
  final dayOfYear = DateTime(
    day.year,
    day.month,
    day.day,
  ).difference(DateTime(day.year)).inDays;
  return available[dayOfYear % available.length];
}

// ───────────── Banco de preguntas ─────────────

/// Preguntas empaquetadas de "¿Cuánto sabes de Loja?".
const bundledQuizBank = <QuizQuestion>[
  // Preguntas inspiradas en la sección "Aprendamos juntos" del periódico del
  // Taller UA II (2026).
  QuizQuestion(
    question: '¿Junto a qué lugar se unen el río Malacatos y el Zamora Huayco para formar el río Zamora?',
    options: [
      'Junto a la Puerta de la Ciudad',
      'En el Parque Jipiro',
      'En el aeropuerto',
      'En Vilcabamba',
    ],
    answer: 0,
  ),
  QuizQuestion(
    question: '¿Qué día de 2025 una lluvia récord desbordó el Malacatos y dañó el puente de la calle Imbabura?',
    options: [
      'El 1 de enero',
      'El 10 de marzo',
      'El 24 de diciembre',
      'El 31 de octubre',
    ],
    answer: 1,
  ),
  QuizQuestion(
    question:
        '¿Qué mercado está junto al río Zamora en el sector El Mayorista?',
    options: [
      'Mercado Gran Colombia',
      'Mercado del Mar',
      'Mercado Espacial',
      'Ninguno',
    ],
    answer: 0,
  ),
  QuizQuestion(
    question: 'Verdadero o falso: “La vegetación ayuda a proteger el río”.',
    options: ['Verdadero', 'Falso'],
    answer: 0,
  ),
  QuizQuestion(
    question: 'Verdadero o falso: “El río no necesita cuidado humano”.',
    options: ['Verdadero', 'Falso'],
    answer: 1,
  ),
  QuizQuestion(
    question: '¿Qué es el “desarenador” del Parque Lineal La Tebaida?',
    options: [
      'Una pequeña represa que ayuda a regular el caudal',
      'Un tobogán',
      'Una fábrica de arena',
      'Un puente colgante',
    ],
    answer: 0,
  ),
  QuizQuestion(
    question: '¿Qué pasa cuando la basura se atora debajo de los puentes?',
    options: [
      'Nada',
      'Forma un tapón y el río se desborda',
      'El río se limpia solo',
      'Los peces la reciclan',
    ],
    answer: 1,
  ),
  QuizQuestion(
    question: '¿En qué meses llueve más en Loja y el Malacatos suele crecer?',
    options: [
      'De marzo a mayo',
      'Solo en agosto',
      'Nunca llueve',
      'Solo en Navidad',
    ],
    answer: 0,
  ),
  QuizQuestion(
    question: '¿Qué dos ríos atraviesan la ciudad de Loja?',
    options: [
      'Malacatos y Zamora',
      'Guayas y Daule',
      'Napo y Pastaza',
      'Amazonas y Nilo',
    ],
    answer: 0,
  ),
  QuizQuestion(
    question: '¿En qué parque de Loja hay una laguna con réplicas de construcciones del mundo?',
    options: ['La Tebaida', 'Jipiro', 'Pucará', 'Las Pitas'],
    answer: 1,
  ),
  QuizQuestion(
    question: '¿Qué árbol de las orillas sujeta la tierra con sus raíces?',
    options: ['Cactus', 'Sauce', 'Palmera de playa', 'Pino de plástico'],
    answer: 1,
  ),
  QuizQuestion(
    question: 'Cuando el Malacatos y el Zamora se unen, ¿qué río continúa?',
    options: ['El Malacatos', 'Ninguno', 'El Zamora', 'El Guayas'],
    answer: 2,
  ),
  QuizQuestion(
    question: '¿A qué gran región llegan finalmente las aguas del río Zamora?',
    options: ['A la Amazonía', 'Al desierto', 'A Galápagos', 'A la Antártida'],
    answer: 0,
  ),
  QuizQuestion(
    question: '¿Qué hacemos con la basura cuando visitamos el río?',
    options: [
      'La dejamos en la orilla',
      'La llevamos a un basurero',
      'La lanzamos al agua',
      'La escondemos',
    ],
    answer: 1,
  ),
  QuizQuestion(
    question: '¿Qué animal andino tiene manchas claras alrededor de los ojos?',
    options: ['Cóndor', 'Oso de anteojos', 'Llama', 'Colibrí'],
    answer: 1,
  ),
  QuizQuestion(
    question: 'Loja es conocida en Ecuador como la…',
    options: [
      'Capital musical',
      'Capital del mar',
      'Ciudad del desierto',
      'Ciudad de los volcanes',
    ],
    answer: 0,
  ),
  QuizQuestion(
    question: '¿Qué pasa si se cortan los árboles de las orillas?',
    options: [
      'El río se vuelve más limpio',
      'Nada',
      'La tierra se erosiona y el río se desborda más fácil',
      'Llueve menos',
    ],
    answer: 2,
  ),
  QuizQuestion(
    question: '¿Qué mide un sensor de pH en el río?',
    options: [
      'La velocidad del viento',
      'Si el agua es ácida o básica',
      'Cuántos peces hay',
      'La hora',
    ],
    answer: 1,
  ),
  QuizQuestion(
    question: '¿Qué parque lineal del sur de Loja acompaña al río Malacatos?',
    options: ['Jipiro', 'La Tebaida', 'Orillas del Zamora', 'Pucará'],
    answer: 1,
  ),
  QuizQuestion(
    question: '¿Qué ave gigante de los Andes es símbolo del Ecuador?',
    options: ['Cóndor andino', 'Pingüino', 'Loro', 'Gaviota'],
    answer: 0,
  ),
  QuizQuestion(
    question: '¿Qué es una cuenca hidrográfica?',
    options: [
      'Un recipiente de cocina',
      'El territorio donde la lluvia corre hacia un mismo río',
      'Un tipo de pez',
      'Una montaña sin agua',
    ],
    answer: 1,
  ),
  QuizQuestion(
    question: '¿Qué acción ayuda a cuidar el agua en casa?',
    options: [
      'Dejar la llave abierta',
      'Cerrar la llave mientras te cepillas',
      'Lavar el carro todos los días',
      'Tirar aceite al lavabo',
    ],
    answer: 1,
  ),
];

/// Banco en uso (se reemplaza con `quizBank` de Firestore si hay al menos 8).
final List<QuizQuestion> lojaQuizBank = [...bundledQuizBank];
