import 'package:flutter/material.dart';

/// Paleta extraída del prototipo de Figma de RÍOVA, con su versión oscura.
///
/// Los colores son getters: devuelven la variante clara u oscura según
/// [AppColors.dark], que fija la raíz de la app (ver `RiovaApp`). Cuando
/// cambia el tema, la app reconstruye todo el árbol para recoger los nuevos
/// valores sin perder la navegación.
///
/// Los pares `x` / `xDark` existen para los botones "chunky": la cara usa el
/// color base y el borde inferior (la "repisa" 3D) usa la variante oscura.
abstract final class AppColors {
  /// `true` mientras la app se dibuja en modo oscuro.
  static bool dark = false;

  static Color _p(Color light, Color night) => dark ? night : light;

  // Superficies
  static Color get background =>
      _p(const Color(0xFFF4F7FC), const Color(0xFF0D1824));
  static Color get surface => _p(Colors.white, const Color(0xFF162535));
  static Color get surfaceTint =>
      _p(const Color(0xFFEAF2FD), const Color(0xFF1B2D40));
  static Color get surfaceBlue =>
      _p(const Color(0xFFDCEAFB), const Color(0xFF213750));
  static Color get outline =>
      _p(const Color(0xFFD3E1F2), const Color(0xFF2B4560));

  // Tinta
  static Color get ink => _p(const Color(0xFF0F2438), const Color(0xFFE9F2FB));
  static Color get inkSoft =>
      _p(const Color(0xFF475A6E), const Color(0xFFB3C4D6));
  static Color get inkMuted =>
      _p(const Color(0xFF7E8EA1), const Color(0xFF8295AA));

  // Marca
  static Color get teal => _p(const Color(0xFF00657F), const Color(0xFF2FA9C9));
  static Color get tealDark =>
      _p(const Color(0xFF004658), const Color(0xFF1A7892));
  static const cyan = Color(0xFF12BDEA);
  static const cyanDark = Color(0xFF0A7FA2);
  static Color get cyanSoft =>
      _p(const Color(0xFFCFEFFB), const Color(0xFF123D50));
  static Color get blue => _p(const Color(0xFF0B57B8), const Color(0xFF5B9BEF));
  static Color get blueDark =>
      _p(const Color(0xFF073D82), const Color(0xFF346FC2));
  static Color get blueSoft =>
      _p(const Color(0xFFDCE8FB), const Color(0xFF1B3354));

  // Naturaleza
  static const green = Color(0xFF4CC371);
  static const greenDark = Color(0xFF2B8A4A);
  static Color get greenDeep =>
      _p(const Color(0xFF136B33), const Color(0xFF86E3A6));
  static Color get mint => _p(const Color(0xFF8DF0AA), const Color(0xFF1F5C38));
  static Color get mintSoft =>
      _p(const Color(0xFFDDF6E6), const Color(0xFF173B2A));

  // Estados
  static Color get red => _p(const Color(0xFFC81E25), const Color(0xFFEF5A5F));
  static Color get redDark =>
      _p(const Color(0xFF8C1116), const Color(0xFFA9292E));
  static Color get redSoft =>
      _p(const Color(0xFFFDE4E5), const Color(0xFF41202A));
  static const heart = Color(0xFFD7262E);
  static const yellow = Color(0xFFF6CF4E);
  static Color get yellowSoft =>
      _p(const Color(0xFFFFF6D2), const Color(0xFF3B321A));
  static Color get amberInk =>
      _p(const Color(0xFF7A4A00), const Color(0xFFFFD873));
  static const orange = Color(0xFFF08A24);

  // Ríos (consistentes entre mapa real y ruta ilustrada)
  static const malacatos = Color(0xFF38B7EE);
  static const zamora = Color(0xFF48C9A0);

  static Color get disabled =>
      _p(const Color(0xFFC9D3DF), const Color(0xFF34495F));
  static Color get disabledDark =>
      _p(const Color(0xFFA5B2C2), const Color(0xFF27394C));
}
