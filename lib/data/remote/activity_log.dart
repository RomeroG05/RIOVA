import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/game_content.dart';
import '../models/explorer.dart';
import '../models/place.dart';

/// Registro de lo que hace el explorador, para guardarlo en la nube.
///
/// La app nunca espera estas llamadas: si no hay internet o Firebase no está
/// disponible, simplemente no se registra nada y todo sigue funcionando.
abstract interface class ActivityLog {
  /// Perfil y avance completos (se guardan con un pequeño retraso para
  /// agrupar varios cambios seguidos en una sola escritura).
  void saveState(ExplorerProfile? profile, ExplorerProgress progress);

  /// Parada validada con el QR del tótem (solo la primera vez).
  void visit(Place place);

  /// Partida terminada de un minijuego.
  void game(GameId id, {required bool won, required int score});

  /// Pregunta de repaso de un sector respondida.
  void quiz(Place place, {required bool firstTry});

  /// "Reiniciar aventura": borra los datos del explorador en la nube.
  Future<void> resetUser();
}

class NoopActivityLog implements ActivityLog {
  const NoopActivityLog();

  @override
  void saveState(ExplorerProfile? profile, ExplorerProgress progress) {}
  @override
  void visit(Place place) {}
  @override
  void game(GameId id, {required bool won, required int score}) {}
  @override
  void quiz(Place place, {required bool firstTry}) {}
  @override
  Future<void> resetUser() async {}
}

/// Se sobrescribe en `main()` cuando Firebase está disponible.
final activityLogProvider = Provider<ActivityLog>(
  (ref) => const NoopActivityLog(),
);
