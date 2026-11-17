import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// Tokens de movimiento de la app.
///
/// Reglas (filosofía de animación de Emil Kowalski adaptada a Flutter):
/// * Entradas y salidas usan [easeOut]; nunca `Curves.easeIn` en UI.
/// * Movimiento dentro de pantalla usa [easeInOut].
/// * UI por debajo de 300 ms; hojas y diálogos son la excepción.
/// * Nada aparece desde escala 0: se parte de 0.95 + opacidad 0.
/// * Gestos y "rebotes" usan resortes ([SpringSimulation]) porque conservan
///   velocidad cuando se interrumpen.
/// * Si el sistema pide quitar animaciones, se reduce a fundidos o corte seco.
abstract final class AppMotion {
  static const Curve easeOut = Cubic(0.23, 1, 0.32, 1);
  static const Curve easeInOut = Cubic(0.77, 0, 0.175, 1);
  static const Curve drawer = Cubic(0.32, 0.72, 0, 1);

  /// Sobrepaso suave para momentos lúdicos (selección de avatar, premios).
  static const Curve playful = Cubic(0.34, 1.4, 0.64, 1);

  static const Duration press = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration stagger = Duration(milliseconds: 50);

  /// Resorte de UI: rápido, casi sin rebote.
  static final SpringDescription snappy = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 420,
    ratio: 0.82,
  );

  /// Resorte lúdico para la mascota y celebraciones.
  static final SpringDescription bouncy = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 260,
    ratio: 0.38,
  );

  /// `true` cuando el usuario activó "Quitar animaciones" en Android.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}
