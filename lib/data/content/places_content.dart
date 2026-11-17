import 'package:latlong2/latlong.dart';

import '../models/place.dart';
import 'sectors_content.dart';

export 'sectors_content.dart';

/// Centro del valle de Loja (parque central) para encuadrar el mapa.
const lojaCenter = LatLng(-3.9960, -79.2040);

// Trazados reales de los ríos, extraídos de OpenStreetMap (© colaboradores
// de OSM, licencia ODbL) y simplificados (Douglas-Peucker, ~9 m).
//
// En Loja, el Malacatos (oeste) y el Zamora Huayco (este) se unen junto a la
// Puerta de la Ciudad y forman el río Zamora, que sigue hacia el norte.
// En la app, "Río Zamora" agrupa al Zamora Huayco y al Zamora.

/// Punto de confluencia (Puente Bolívar – Puerta de la Ciudad).
const confluence = LatLng(-3.98890, -79.20350);

/// Río Malacatos, de sur a norte hasta la confluencia.
const malacatosPath = <LatLng>[
  LatLng(-4.05787, -79.19685),
  LatLng(-4.05704, -79.19665),
  LatLng(-4.05642, -79.19619),
  LatLng(-4.05588, -79.19685),
  LatLng(-4.05530, -79.19688),
  LatLng(-4.05394, -79.19665),
  LatLng(-4.05314, -79.19701),
  LatLng(-4.05280, -79.19659),
  LatLng(-4.05200, -79.19656),
  LatLng(-4.05093, -79.19682),
  LatLng(-4.05058, -79.19714),
  LatLng(-4.04997, -79.19741),
  LatLng(-4.04783, -79.19766),
  LatLng(-4.04593, -79.19754),
  LatLng(-4.04527, -79.19723),
  LatLng(-4.04446, -79.19735),
  LatLng(-4.04375, -79.19729),
  LatLng(-4.04298, -79.19766),
  LatLng(-4.04271, -79.19794),
  LatLng(-4.04204, -79.19953),
  LatLng(-4.04183, -79.19980),
  LatLng(-4.04126, -79.19964),
  LatLng(-4.04115, -79.19974),
  LatLng(-4.04116, -79.20044),
  LatLng(-4.04068, -79.20099),
  LatLng(-4.04033, -79.20108),
  LatLng(-4.03995, -79.20066),
  LatLng(-4.03978, -79.20066),
  LatLng(-4.03948, -79.20090),
  LatLng(-4.03863, -79.20118),
  LatLng(-4.03827, -79.20063),
  LatLng(-4.03729, -79.20062),
  LatLng(-4.03686, -79.20021),
  LatLng(-4.03654, -79.20021),
  LatLng(-4.03589, -79.19988),
  LatLng(-4.03505, -79.19997),
  LatLng(-4.03459, -79.19988),
  LatLng(-4.03415, -79.20018),
  LatLng(-4.03389, -79.20082),
  LatLng(-4.03351, -79.20100),
  LatLng(-4.03220, -79.20144),
  LatLng(-4.03159, -79.20102),
  LatLng(-4.03104, -79.20125),
  LatLng(-4.03064, -79.20173),
  LatLng(-4.03041, -79.20159),
  LatLng(-4.02991, -79.20049),
  LatLng(-4.02934, -79.20053),
  LatLng(-4.02854, -79.20133),
  LatLng(-4.02829, -79.20139),
  LatLng(-4.02659, -79.20041),
  LatLng(-4.02588, -79.20121),
  LatLng(-4.02509, -79.20115),
  LatLng(-4.02432, -79.20074),
  LatLng(-4.02351, -79.20074),
  LatLng(-4.02240, -79.20129),
  LatLng(-4.02159, -79.20197),
  LatLng(-4.01974, -79.20269),
  LatLng(-4.01913, -79.20282),
  LatLng(-4.01801, -79.20265),
  LatLng(-4.01647, -79.20278),
  LatLng(-4.01470, -79.20269),
  LatLng(-4.00939, -79.20367),
  LatLng(-3.99239, -79.20566),
  LatLng(-3.99176, -79.20563),
  LatLng(-3.98973, -79.20452),
  LatLng(-3.98890, -79.20354),
];

/// Río Zamora Huayco (este) hasta la confluencia y luego río Zamora (norte).
const zamoraPath = <LatLng>[
  LatLng(-4.02951, -79.18058),
  LatLng(-4.02942, -79.18097),
  LatLng(-4.02897, -79.18120),
  LatLng(-4.02868, -79.18167),
  LatLng(-4.02704, -79.18238),
  LatLng(-4.02621, -79.18299),
  LatLng(-4.02565, -79.18290),
  LatLng(-4.02419, -79.18320),
  LatLng(-4.02391, -79.18356),
  LatLng(-4.02335, -79.18338),
  LatLng(-4.02299, -79.18365),
  LatLng(-4.02204, -79.18346),
  LatLng(-4.02145, -79.18393),
  LatLng(-4.02078, -79.18377),
  LatLng(-4.01989, -79.18427),
  LatLng(-4.01858, -79.18441),
  LatLng(-4.01828, -79.18460),
  LatLng(-4.01775, -79.18468),
  LatLng(-4.01742, -79.18515),
  LatLng(-4.01668, -79.18579),
  LatLng(-4.01640, -79.18577),
  LatLng(-4.01590, -79.18545),
  LatLng(-4.01557, -79.18556),
  LatLng(-4.01504, -79.18603),
  LatLng(-4.01465, -79.18611),
  LatLng(-4.01118, -79.18574),
  LatLng(-4.01085, -79.18591),
  LatLng(-4.01041, -79.18654),
  LatLng(-4.00871, -79.18692),
  LatLng(-4.00793, -79.18734),
  LatLng(-4.00753, -79.18734),
  LatLng(-4.00653, -79.18807),
  LatLng(-4.00583, -79.18954),
  LatLng(-4.00438, -79.19024),
  LatLng(-4.00414, -79.19053),
  LatLng(-4.00407, -79.19082),
  LatLng(-4.00423, -79.19222),
  LatLng(-4.00356, -79.19378),
  LatLng(-4.00214, -79.19518),
  LatLng(-4.00129, -79.19539),
  LatLng(-3.99939, -79.19620),
  LatLng(-3.99770, -79.19704),
  LatLng(-3.99674, -79.19770),
  LatLng(-3.99569, -79.19797),
  LatLng(-3.99310, -79.20079),
  LatLng(-3.99151, -79.20142),
  LatLng(-3.98971, -79.20331),
  LatLng(-3.98890, -79.20354),
  LatLng(-3.98789, -79.20308),
  LatLng(-3.98536, -79.20228),
  LatLng(-3.98431, -79.20232),
  LatLng(-3.98250, -79.20277),
  LatLng(-3.98024, -79.20275),
  LatLng(-3.97912, -79.20312),
  LatLng(-3.97860, -79.20309),
  LatLng(-3.97687, -79.20222),
  LatLng(-3.97615, -79.20220),
  LatLng(-3.97323, -79.20354),
  LatLng(-3.97034, -79.20514),
  LatLng(-3.96869, -79.20748),
  LatLng(-3.96847, -79.20816),
  LatLng(-3.96792, -79.20894),
  LatLng(-3.96772, -79.20911),
  LatLng(-3.96607, -79.20950),
  LatLng(-3.96445, -79.21008),
  LatLng(-3.96407, -79.21050),
  LatLng(-3.96375, -79.21144),
  LatLng(-3.96348, -79.21179),
  LatLng(-3.96315, -79.21208),
  LatLng(-3.96202, -79.21243),
  LatLng(-3.96175, -79.21263),
  LatLng(-3.96158, -79.21307),
  LatLng(-3.96160, -79.21399),
  LatLng(-3.96138, -79.21454),
  LatLng(-3.96092, -79.21475),
  LatLng(-3.96045, -79.21474),
  LatLng(-3.95952, -79.21427),
  LatLng(-3.95904, -79.21428),
  LatLng(-3.95887, -79.21474),
  LatLng(-3.95887, -79.21596),
  LatLng(-3.95836, -79.21608),
  LatLng(-3.95704, -79.21588),
  LatLng(-3.95511, -79.21663),
  LatLng(-3.95431, -79.21759),
  LatLng(-3.95408, -79.21846),
  LatLng(-3.95375, -79.21897),
  LatLng(-3.95324, -79.21933),
  LatLng(-3.95292, -79.21941),
  LatLng(-3.95241, -79.21922),
  LatLng(-3.95069, -79.21920),
  LatLng(-3.94828, -79.22025),
  LatLng(-3.94766, -79.22021),
  LatLng(-3.94683, -79.21997),
  LatLng(-3.94550, -79.21913),
  LatLng(-3.94462, -79.21911),
  LatLng(-3.94352, -79.21961),
  LatLng(-3.94320, -79.22038),
  LatLng(-3.94279, -79.22072),
  LatLng(-3.94203, -79.22109),
  LatLng(-3.94056, -79.22152),
  LatLng(-3.94024, -79.22176),
  LatLng(-3.93979, -79.22259),
  LatLng(-3.93902, -79.22289),
  LatLng(-3.93749, -79.22321),
  LatLng(-3.93648, -79.22359),
  LatLng(-3.93593, -79.22402),
  LatLng(-3.93541, -79.22402),
  LatLng(-3.93369, -79.22221),
  LatLng(-3.93325, -79.22212),
  LatLng(-3.93304, -79.22225),
  LatLng(-3.93252, -79.22338),
  LatLng(-3.93224, -79.22349),
  LatLng(-3.93126, -79.22326),
  LatLng(-3.93058, -79.22338),
  LatLng(-3.92979, -79.22328),
  LatLng(-3.92922, -79.22344),
  LatLng(-3.92898, -79.22370),
  LatLng(-3.92851, -79.22478),
  LatLng(-3.92768, -79.22537),
  LatLng(-3.92722, -79.22526),
  LatLng(-3.92685, -79.22453),
  LatLng(-3.92616, -79.22459),
  LatLng(-3.92599, -79.22447),
  LatLng(-3.92552, -79.22342),
  LatLng(-3.92503, -79.22305),
  LatLng(-3.92477, -79.22401),
  LatLng(-3.92403, -79.22423),
  LatLng(-3.92372, -79.22464),
  LatLng(-3.92336, -79.22600),
  LatLng(-3.92302, -79.22643),
  LatLng(-3.92226, -79.22563),
  LatLng(-3.92165, -79.22553),
  LatLng(-3.92088, -79.22566),
  LatLng(-3.91982, -79.22532),
  LatLng(-3.91940, -79.22551),
  LatLng(-3.91926, -79.22583),
  LatLng(-3.91896, -79.22602),
  LatLng(-3.91805, -79.22615),
];

Place placeById(String id) => places.firstWhere((p) => p.id == id);

Place? placeByTotem(int totem) {
  for (final p in places) {
    if (p.totem == totem) return p;
  }
  return null;
}

/// Interpreta el contenido de un QR o un código escrito a mano.
/// Acepta `riova://totem/04`, `RIOVA-T04`, `T04`, `T4` o `04`.
Place? placeFromCode(String raw) {
  final text = raw.trim().toUpperCase();
  final match = RegExp(r'(?:RIOVA://TOTEM/|RIOVA-?)?T?0*(\d{1,2})$')
      .firstMatch(text);
  if (match == null) return null;
  return placeByTotem(int.parse(match.group(1)!));
}

List<Place> placesInZone(Zone zone) =>
    places.where((p) => p.zone == zone).toList();

int stopNumber(Place place) => placesInZone(place.zone).indexOf(place) + 1;

// ───────────── Contenido compartido de las fichas ─────────────

const guardianActions = <(String, String)>[
  ('🗑️', 'Deposita la basura siempre en su lugar (cero plásticos).'),
  ('🌱', 'Cuida las plantas y los sauces ribereños.'),
  ('🐾', 'Respeta a las aves y animales silvestres.'),
  ('⚠️', 'Aléjate de las orillas durante lluvias torrenciales.'),
];
