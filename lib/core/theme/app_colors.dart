import 'package:flutter/material.dart';

/// Paleta extraída del prototipo de Figma de RÍOVA.
///
/// Los pares `x` / `xDark` existen para los botones "chunky": la cara usa el
/// color base y el borde inferior (la "repisa" 3D) usa la variante oscura.
abstract final class AppColors {
  // Superficies
  static const background = Color(0xFFF4F7FC);
  static const surface = Colors.white;
  static const surfaceTint = Color(0xFFEAF2FD);
  static const surfaceBlue = Color(0xFFDCEAFB);
  static const outline = Color(0xFFD3E1F2);

  // Tinta
  static const ink = Color(0xFF0F2438);
  static const inkSoft = Color(0xFF475A6E);
  static const inkMuted = Color(0xFF7E8EA1);

  // Marca
  static const teal = Color(0xFF00657F);
  static const tealDark = Color(0xFF004658);
  static const cyan = Color(0xFF12BDEA);
  static const cyanDark = Color(0xFF0A7FA2);
  static const cyanSoft = Color(0xFFCFEFFB);
  static const blue = Color(0xFF0B57B8);
  static const blueDark = Color(0xFF073D82);
  static const blueSoft = Color(0xFFDCE8FB);

  // Naturaleza
  static const green = Color(0xFF4CC371);
  static const greenDark = Color(0xFF2B8A4A);
  static const greenDeep = Color(0xFF136B33);
  static const mint = Color(0xFF8DF0AA);
  static const mintSoft = Color(0xFFDDF6E6);

  // Estados
  static const red = Color(0xFFC81E25);
  static const redDark = Color(0xFF8C1116);
  static const redSoft = Color(0xFFFDE4E5);
  static const heart = Color(0xFFD7262E);
  static const yellow = Color(0xFFF6CF4E);
  static const yellowSoft = Color(0xFFFFF6D2);
  static const amberInk = Color(0xFF7A4A00);
  static const orange = Color(0xFFF08A24);

  // Ríos (consistentes entre mapa real y ruta ilustrada)
  static const malacatos = Color(0xFF38B7EE);
  static const zamora = Color(0xFF48C9A0);

  static const disabled = Color(0xFFC9D3DF);
  static const disabledDark = Color(0xFFA5B2C2);
}
