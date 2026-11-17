import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import '../content/game_content.dart';
import '../content/places_content.dart';
import '../models/explorer.dart';
import '../models/place.dart';
import 'activity_log.dart';
import 'place_codec.dart';

/// Colecciones de Firestore (proyecto `appriova`).
///
/// * `sectors/{id}`     — contenido de los 13 sectores (editable en consola).
/// * `quizBank/{n}`     — preguntas de "¿Cuánto sabes de Loja?".
/// * `games/{id}`, `medals/{id}`, `missions/{n}` — catálogo (referencia).
/// * `sensors/{id}`     — base y lecturas de la red de sensores.
/// * `users/{uid}`      — perfil y avance del explorador (+ `visits`, `games`).
/// * `sectorStats/{id}`, `gameStats/{id}` — contadores anónimos.
abstract final class Col {
  static const sectors = 'sectors';
  static const quizBank = 'quizBank';
  static const sensors = 'sensors';
  static const users = 'users';
  static const sectorStats = 'sectorStats';
  static const gameStats = 'gameStats';
}

/// Conexión con Firebase. Todo es "mejor esfuerzo": la app se usa sin
/// internet y sin cuenta; cuando hay conexión, sincroniza.
class Cloud implements ActivityLog {
  Cloud._(this.db, this.auth);

  final FirebaseFirestore db;
  final FirebaseAuth auth;

  /// `null` si Firebase no pudo iniciarse (la app sigue funcionando).
  static Future<Cloud?> start() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 6));
    } catch (e) {
      debugPrint('[RÍOVA] Firebase no disponible: $e');
      return null;
    }
    final cloud = Cloud._(FirebaseFirestore.instance, FirebaseAuth.instance);
    // Inicio de sesión anónimo en segundo plano: no frena el arranque.
    unawaited(cloud._signIn());
    return cloud;
  }

  String? get uid => auth.currentUser?.uid;

  Future<String?> _signIn() async {
    if (auth.currentUser != null) return auth.currentUser!.uid;
    try {
      final cred = await auth.signInAnonymously().timeout(
        const Duration(seconds: 20),
      );
      debugPrint('[RÍOVA] Sesión anónima lista.');
      // Si hubo cambios antes de tener sesión, se envían ahora.
      _flushState();
      return cred.user?.uid;
    } catch (e) {
      debugPrint(
        '[RÍOVA] Sin sesión anónima (¿Authentication › Anónimo habilitado?): $e',
      );
      return null;
    }
  }

  Future<String?> _uid() async => uid ?? await _signIn();

  // ───────────── Contenido ─────────────

  /// Aplica el contenido de Firestore sobre el contenido empaquetado.
  /// Primero usa la caché local (instantáneo) y luego, en segundo plano, el
  /// servidor; [onUpdated] avisa cuando llegó algo nuevo.
  Future<void> syncContent({VoidCallback? onUpdated}) async {
    try {
      final cached = await db
          .collection(Col.sectors)
          .get(const GetOptions(source: Source.cache));
      _applySectors(cached);
      final cachedQuiz = await db
          .collection(Col.quizBank)
          .get(const GetOptions(source: Source.cache));
      _applyQuiz(cachedQuiz);
    } catch (_) {
      // Primera vez: aún no hay caché.
    }
    unawaited(() async {
      try {
        final fresh = await db
            .collection(Col.sectors)
            .get(const GetOptions(source: Source.server));
        final changed = _applySectors(fresh);
        final quiz = await db
            .collection(Col.quizBank)
            .get(const GetOptions(source: Source.server));
        if (_applyQuiz(quiz) || changed) onUpdated?.call();
      } catch (e) {
        debugPrint('[RÍOVA] Contenido remoto no disponible: $e');
      }
    }());
  }

  bool _applySectors(QuerySnapshot<Map<String, dynamic>> snap) {
    var changed = false;
    for (final doc in snap.docs) {
      final i = places.indexWhere((p) => p.id == doc.id);
      if (i < 0) continue;
      places[i] = PlaceCodec.merge(bundledPlaces[i], doc.data());
      changed = true;
    }
    return changed;
  }

  bool _applyQuiz(QuerySnapshot<Map<String, dynamic>> snap) {
    final remote = <QuizQuestion>[];
    final docs = [...snap.docs]..sort((a, b) => a.id.compareTo(b.id));
    for (final doc in docs) {
      if (doc.data()['active'] == false) continue;
      final q = PlaceCodec.quizFromMap(doc.data(), _invalidQuiz);
      if (!identical(q, _invalidQuiz)) remote.add(q);
    }
    // Solo se reemplaza si hay suficientes preguntas para una partida.
    if (remote.length < 8) return false;
    lojaQuizBank
      ..clear()
      ..addAll(remote);
    return true;
  }

  static const _invalidQuiz = QuizQuestion(
    question: '',
    options: [],
    answer: -1,
  );

  // ───────────── Sensores ─────────────

  /// Documentos de `sensors` en tiempo real (vacío si no hay conexión).
  Stream<Map<String, Map<String, Object?>>> sensorDocs() => db
      .collection(Col.sensors)
      .snapshots()
      .map(
        (s) => {
          for (final d in s.docs)
            d.id: d.data().map(
              (k, v) => MapEntry(k, v is Timestamp ? v.toDate() : v),
            ),
        },
      )
      .handleError((Object e) => debugPrint('[RÍOVA] Sensores remotos: $e'));

  // ───────────── Explorador ─────────────

  Timer? _debounce;
  (ExplorerProfile?, ExplorerProgress)? _pending;

  @override
  void saveState(ExplorerProfile? profile, ExplorerProgress progress) {
    _pending = (profile, progress);
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), _flushState);
  }

  void _flushState() {
    final pending = _pending;
    final id = uid;
    if (pending == null || id == null) return;
    _pending = null;
    final (profile, progress) = pending;
    final level = LevelProgress.of(progress.gotitas);
    _safe(
      db.collection(Col.users).doc(id).set({
        'profile': profile?.toJson(),
        'progress': progress.toJson(),
        'level': level.level,
        'levelTitle': level.current.title,
        'visitedCount': progress.visited.length,
        'updatedAt': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.name,
      }, SetOptions(merge: true)),
    );
  }

  @override
  void visit(Place place) => unawaited(() async {
    final id = await _uid();
    if (id == null) return;
    _safe(
      db.collection(Col.users).doc(id).collection('visits').doc(place.id).set({
        'placeId': place.id,
        'code': place.code,
        'name': place.name,
        'at': FieldValue.serverTimestamp(),
      }),
    );
    _safe(
      db.collection(Col.sectorStats).doc(place.id).set({
        'visits': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );
  }());

  @override
  void game(GameId game, {required bool won, required int score}) =>
      unawaited(() async {
        final id = await _uid();
        if (id == null) return;
        _safe(
          db.collection(Col.users).doc(id).collection('games').add({
            'game': game.name,
            'won': won,
            'score': score,
            'at': FieldValue.serverTimestamp(),
          }),
        );
        _safe(
          db.collection(Col.gameStats).doc(game.name).set({
            'plays': FieldValue.increment(1),
            if (won) 'wins': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)),
        );
      }());

  @override
  void quiz(Place place, {required bool firstTry}) => unawaited(() async {
    final id = await _uid();
    if (id == null || !firstTry) return;
    _safe(
      db.collection(Col.sectorStats).doc(place.id).set({
        'quizFirstTry': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );
  }());

  @override
  Future<void> resetUser() async {
    _debounce?.cancel();
    _pending = null;
    final id = uid;
    if (id == null) return;
    try {
      final userDoc = db.collection(Col.users).doc(id);
      final batch = db.batch();
      for (final sub in ['visits', 'games']) {
        final docs = await userDoc
            .collection(sub)
            .get()
            .timeout(const Duration(seconds: 8));
        for (final d in docs.docs) {
          batch.delete(d.reference);
        }
      }
      batch.delete(userDoc);
      await batch.commit().timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('[RÍOVA] No se pudo borrar en la nube: $e');
    }
    // Nueva identidad anónima para la nueva aventura.
    await auth.signOut();
    unawaited(_signIn());
  }

  void _safe(Future<void> write) {
    write.catchError(
      (Object e) => debugPrint('[RÍOVA] Escritura pendiente/fallida: $e'),
    );
  }
}
