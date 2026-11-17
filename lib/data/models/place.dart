import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/illustrations/scene_painter.dart';
import '../../core/theme/app_colors.dart';

enum River {
  malacatos('Río Malacatos', 'Malacatos', 'Oeste', AppColors.malacatos),
  zamora('Río Zamora', 'Zamora', 'Este', AppColors.zamora);

  const River(this.label, this.shortLabel, this.side, this.color);
  final String label;
  final String shortLabel;
  final String side;
  final Color color;
}

enum Zone {
  sur('Zona Sur', 'Inicio', 'Cabecera y Nacientes', Icons.flag_rounded),
  centro('Centro', 'Corazón', 'Casco Urbano', Icons.location_city_rounded),
  norte(
    'Zona Norte',
    'Ruta Natural',
    'Parque Jipiro & Sauces',
    Icons.park_rounded,
  );

  const Zone(this.label, this.nickname, this.longLabel, this.icon);
  final String label;
  final String nickname;
  final String longLabel;
  final IconData icon;
}

/// Tipo de problema del río: define título, ícono, color y consejo.
enum ProblemKind {
  contaminacion(
    'Contaminación',
    Icons.water_drop_outlined,
    AppColors.red,
    'Usa los basureros y nunca tires nada al río.',
  ),
  basura(
    'Basura y escombros',
    Icons.delete_outline_rounded,
    AppColors.red,
    'Lleva tu basura a casa si no hay basurero cerca.',
  ),
  inundacion(
    'Inundaciones',
    Icons.thunderstorm_outlined,
    AppColors.blue,
    'Aléjate de la orilla cuando llueve fuerte.',
  ),
  erosion(
    'Erosión',
    Icons.landslide_outlined,
    AppColors.amberInk,
    'Cuida los árboles de la orilla: sus raíces sujetan la tierra.',
  ),
  abandono(
    'Espacios abandonados',
    Icons.park_outlined,
    AppColors.greenDeep,
    'Usa y cuida los parques: un lugar querido se mantiene vivo.',
  ),
  inseguridad(
    'Inseguridad',
    Icons.nightlight_outlined,
    AppColors.inkSoft,
    'Pasea por el río de día y siempre acompañado.',
  ),
  olores(
    'Malos olores',
    Icons.air_rounded,
    AppColors.orange,
    'Avisa a un adulto si ves tuberías vertiendo agua sucia al río.',
  ),
  muros(
    'Río encerrado',
    Icons.fence_rounded,
    AppColors.blue,
    'Los ríos necesitan espacio y orillas verdes, no solo muros.',
  );

  const ProblemKind(this.title, this.icon, this.color, this.help);
  final String title;
  final IconData icon;
  final Color color;
  final String help;
}

@immutable
class RiverProblem {
  const RiverProblem({
    this.kind = ProblemKind.contaminacion,
    required this.title,
    required this.summary,
    required this.detail,
    required this.help,
    required this.icon,
    required this.color,
  });

  final ProblemKind kind;
  final String title;
  final String summary;
  final String detail;
  final String help;
  final IconData icon;
  final Color color;
}

@immutable
class TimelineStep {
  const TimelineStep(this.title, this.text);
  final String title;
  final String text;
}

@immutable
class Species {
  const Species({
    required this.name,
    required this.emoji,
    required this.tag,
    required this.text,
    this.isFauna = false,
  });

  final String name;
  final String emoji;
  final String tag;
  final String text;
  final bool isFauna;
}

@immutable
class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.options,
    required this.answer,
    this.explanation = '',
  });

  final String question;
  final List<String> options;
  final int answer;
  final String explanation;
}

/// Foto real del sector (tomada del periódico del Taller de Proyectos
/// Urbano Arquitectónicos II, enero 2026).
@immutable
class PlacePhoto {
  const PlacePhoto(this.asset, this.caption, {this.drawing = false});
  final String asset;
  final String caption;

  /// `true` para ilustraciones, collages o cómics (no son fotografías).
  final bool drawing;
}

/// Testimonio de un vecino recogido en el periódico.
@immutable
class Voice {
  const Voice(this.who, this.quote);
  final String who;
  final String quote;
}

/// Un sector fluvial: punto real del mapa + tótem QR + ficha educativa.
@immutable
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.shortName,
    required this.zone,
    required this.river,
    required this.position,
    required this.totem,
    required this.tagline,
    required this.description,
    required this.fact,
    required this.factTags,
    required this.quiz,
    required this.scene,
    required this.code,
    required this.headline,
    required this.story,
    required this.photos,
    required this.voices,
    required this.problems,
    required this.timeline,
    required this.species,
    this.landmark = false,
  });

  final String id;
  final String name;
  final String shortName;
  final Zone zone;
  final River river;
  final LatLng position;

  /// Número del tótem físico (aparece en el código QR: `riova://totem/04`).
  final int totem;
  final String tagline;
  final String description;
  final String fact;
  final List<String> factTags;
  final QuizQuestion quiz;
  final SceneSpec scene;
  final bool landmark;

  /// Código del sector en el periódico (A1…A4, B1…B3, C1…C6).
  final String code;

  /// Titular del periódico para este sector.
  final String headline;

  /// Relato del sector (párrafos cortos).
  final List<String> story;
  final List<PlacePhoto> photos;
  final List<Voice> voices;
  final List<RiverProblem> problems;
  final List<TimelineStep> timeline;
  final List<Species> species;

  PlacePhoto get cover => photos.first;

  String get totemCode => 'T${totem.toString().padLeft(2, '0')}';
  String get qrPayload => 'riova://totem/${totem.toString().padLeft(2, '0')}';
}
