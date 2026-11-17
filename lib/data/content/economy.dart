/// Economía de gotitas de RÍOVA: TODOS los números de recompensas en un
/// solo lugar para poder ajustarlos fácilmente.
///
/// Principios del balance:
/// * Ir al río (escanear tótems) es lo que más paga.
/// * Jugar paga poco; repetir paga muy poco y tiene tope diario, para que
///   no se pueda "granjear" gotitas jugando lo mismo una y otra vez.
/// * Las cosas de la tienda cuestan más de lo que da el contenido de una sola
///   vez: para completar la colección hay que volver varios días.
///
/// Contenido de una sola vez ≈ 13×30 + 250 (juegos) + 13×10 + 13×5 ≈ 835.
/// Lo diario ≈ misión (30) + repeticiones (tope 40) ≈ 70.
/// Sombreros en total = 2770 → la colección completa toma semanas.
abstract final class Economy {
  /// Primer escaneo del tótem QR de un sector.
  static const visit = 30;

  /// Pregunta de repaso de un sector.
  static const quizFirstTry = 10;
  static const quizRetry = 3;

  /// Lista "¡Sé Guardián del Río!" completa (una vez por sector).
  static const checklist = 5;

  /// Repetir un minijuego ya ganado, y máximo diario por repeticiones.
  static const replay = 5;
  static const replayDailyCap = 40;

  /// Bono de la misión del día.
  static const missionBonus = 30;
}
