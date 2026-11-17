import 'package:flutter/foundation.dart';

/// Sombrero de la tienda. Se compra con gotitas disponibles (no baja el
/// nivel) y se dibuja con `HatPainter`.
@immutable
class HatInfo {
  const HatInfo({
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

const hats = <HatInfo>[
  HatInfo(
    id: 'gorra_explorador',
    name: 'Gorra de Explorador',
    price: 40,
    description: 'Para recorrer los senderos del río con el sol a la espalda.',
  ),
  HatInfo(
    id: 'pescador',
    name: 'Sombrero de Pescador',
    price: 60,
    description: 'Como el de quienes esperan ver truchas en aguas limpias.',
  ),
  HatInfo(
    id: 'chullo',
    name: 'Chullo Andino',
    price: 80,
    description:
        'Gorro de lana con orejeras, perfecto para las mañanas frías de Loja.',
  ),
  HatInfo(
    id: 'guardaparques',
    name: 'Casco de Guardaparques',
    price: 100,
    description:
        'El sombrero de quienes cuidan los bosques que guardan el agua.',
    minLevel: 2,
  ),
  HatInfo(
    id: 'detective',
    name: 'Gorro de Detective',
    price: 120,
    description: 'Ideal para investigar por qué se inunda el río.',
    minLevel: 2,
  ),
  HatInfo(
    id: 'corona_sauce',
    name: 'Corona de Sauce',
    price: 150,
    description: 'Hecha con hojas de sauce, el árbol que protege las orillas.',
    minLevel: 3,
  ),
  HatInfo(
    id: 'paja_toquilla',
    name: 'Sombrero de Paja Toquilla',
    price: 200,
    description: 'El clásico sombrero ecuatoriano, tejido a mano.',
    minLevel: 3,
  ),
  HatInfo(
    id: 'boina_musical',
    name: 'Boina Musical',
    price: 250,
    description: 'Loja es la capital musical del Ecuador. ¡Que suene el río!',
    minLevel: 4,
  ),
  HatInfo(
    id: 'colibri',
    name: 'Gorro de Colibrí',
    price: 300,
    description:
        'Inspirado en los colibríes que visitan las flores de la ribera.',
    minLevel: 5,
  ),
  HatInfo(
    id: 'corona_gotitas',
    name: 'Corona de Gotitas',
    price: 400,
    description: 'Legendaria: solo para los grandes guardianes del agua.',
    minLevel: 6,
  ),
];

HatInfo? hatById(String? id) {
  for (final h in hats) {
    if (h.id == id) return h;
  }
  return null;
}
