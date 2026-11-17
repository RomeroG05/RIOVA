import 'package:flutter/foundation.dart';

/// Banner (fondo de la tarjeta del perfil). Igual que los sombreros: se
/// compra con gotitas disponibles, algunos piden nivel mínimo y se dibuja
/// con `BannerPainter`.
@immutable
class BannerInfo {
  const BannerInfo({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    this.minLevel = 1,
  });

  final String id;
  final String name;
  final int price;
  final String description;

  /// Nivel mínimo para poder comprarlo (además de tener las gotitas).
  final int minLevel;

  bool availableAt(int level) => level >= minLevel;
}

const banners = <BannerInfo>[
  BannerInfo(
    id: 'cielo_andino',
    name: 'Cielo Andino',
    price: 80,
    description: 'Nubes sobre las montañas que rodean el valle de Loja.',
  ),
  BannerInfo(
    id: 'rio_malacatos',
    name: 'Río Malacatos',
    price: 120,
    description: 'Las olas del río que cruza Loja por el oeste.',
  ),
  BannerInfo(
    id: 'bosque_sauces',
    name: 'Bosque de Sauces',
    price: 160,
    description: 'Hojas de sauce, el árbol que protege las orillas.',
    minLevel: 2,
  ),
  BannerInfo(
    id: 'atardecer_loja',
    name: 'Atardecer en Loja',
    price: 220,
    description: 'El sol se esconde detrás de las montañas del valle.',
    minLevel: 3,
  ),
  BannerInfo(
    id: 'laguna_jipiro',
    name: 'Laguna de Jipiro',
    price: 280,
    description: 'Reflejos en la laguna del parque más querido de Loja.',
    minLevel: 3,
  ),
  BannerInfo(
    id: 'noche_estrellada',
    name: 'Noche Estrellada',
    price: 360,
    description: 'Estrellas sobre el río cuando la ciudad duerme.',
    minLevel: 4,
  ),
  BannerInfo(
    id: 'puerta_ciudad',
    name: 'Puerta de la Ciudad',
    price: 450,
    description:
        'El castillo donde el Malacatos y el Zamora Huayco se abrazan.',
    minLevel: 5,
  ),
  BannerInfo(
    id: 'aurora_gotitas',
    name: 'Aurora de Gotitas',
    price: 700,
    description:
        'Legendario: una lluvia de gotitas de colores para grandes guardianes.',
    minLevel: 7,
  ),
];

BannerInfo? bannerById(String? id) {
  for (final b in banners) {
    if (b.id == id) return b;
  }
  return null;
}
