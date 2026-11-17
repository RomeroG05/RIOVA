import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/day_key.dart';
import '../data/content/banner_content.dart';
import '../data/content/economy.dart';
import '../data/content/game_content.dart';
import '../data/content/hat_content.dart';
import '../data/content/places_content.dart';
import '../data/models/explorer.dart';
import '../data/models/place.dart';
import '../data/remote/activity_log.dart';
import '../data/repositories/progress_repository.dart';

/// Se sobrescribe en `main()` con la instancia ya abierta.
final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) =>
      throw UnimplementedError('progressRepositoryProvider sin inicializar'),
);

final explorerProvider = NotifierProvider<ExplorerController, ExplorerState>(
  ExplorerController.new,
);

@immutable
class ExplorerState {
  const ExplorerState({required this.profile, required this.progress});

  final ExplorerProfile? profile;
  final ExplorerProgress progress;

  LevelProgress get level => LevelProgress.of(progress.gotitas);
  int get streak => currentStreak(progress.activeDays, DateTime.now());
  int get unlockedMedals => medals.where((m) => m.unlocked(progress)).length;

  ExplorerState copyWith({
    ExplorerProfile? profile,
    ExplorerProgress? progress,
  }) => ExplorerState(
    profile: profile ?? this.profile,
    progress: progress ?? this.progress,
  );
}

/// Resultado de una acción que otorga gotitas. La UI lo usa para mostrar
/// la celebración adecuada (subida de nivel, medallas nuevas).
@immutable
class RewardOutcome {
  const RewardOutcome({
    this.gotitas = 0,
    this.levelUp,
    this.newMedals = const [],
    this.newGames = const [],
    this.newHats = const [],
    this.newBanners = const [],
    this.missionBonus = 0,
  });

  final int gotitas;
  final LevelInfo? levelUp;
  final List<Medal> newMedals;

  /// Minijuegos extra que se desbloquearon con esta recompensa.
  final List<GameInfo> newGames;

  /// Sombreros que se pueden comprar desde este nuevo nivel.
  final List<HatInfo> newHats;

  /// Banners que se pueden comprar desde este nuevo nivel.
  final List<BannerInfo> newBanners;
  final int missionBonus;

  int get total => gotitas + missionBonus;
  bool get isEmpty =>
      total == 0 && levelUp == null && newMedals.isEmpty && newGames.isEmpty;
}

/// Resultado de comprar algo en la tienda (sombrero o banner).
enum Purchase { bought, notEnough, alreadyOwned, levelLocked }

class ExplorerController extends Notifier<ExplorerState> {
  ProgressRepository get _repo => ref.read(progressRepositoryProvider);
  ActivityLog get _log => ref.read(activityLogProvider);

  @override
  ExplorerState build() {
    final repo = ref.watch(progressRepositoryProvider);
    // Cada cambio de perfil o avance también se respalda en la nube.
    listenSelf(
      (_, next) =>
          ref.read(activityLogProvider).saveState(next.profile, next.progress),
    );
    return ExplorerState(
      profile: repo.loadProfile(),
      progress: _withKnownPlaces(repo.loadProgress()),
    );
  }

  /// Descarta sectores que ya no existen (versiones anteriores de la app),
  /// para que los contadores "x de 13" no se pasen de la cuenta.
  static ExplorerProgress _withKnownPlaces(ExplorerProgress p) {
    final known = {for (final place in places) place.id};
    Set<String> keep(Set<String> ids) => ids.where(known.contains).toSet();
    return p.copyWith(
      visited: keep(p.visited),
      quizzes: keep(p.quizzes),
      checklists: keep(p.checklists),
    );
  }

  String get _today => dayKey(DateTime.now());

  Future<void> createProfile(ExplorerProfile profile) async {
    state = state.copyWith(profile: profile);
    await _repo.saveProfile(profile);
    markActiveToday();
  }

  Future<void> updateAvatar(ExplorerAvatar avatar) async {
    final profile = state.profile;
    if (profile == null) return;
    final next = profile.copyWith(avatar: avatar);
    state = state.copyWith(profile: next);
    await _repo.saveProfile(next);
  }

  /// Registra el día de hoy como activo (racha). Idempotente.
  void markActiveToday() {
    final p = state.progress;
    if (p.activeDays.contains(_today)) return;
    _commit(_withActivity(p));
  }

  ExplorerProgress _withActivity(ExplorerProgress p) {
    final days = {...p.activeDays, _today};
    // Solo se guardan los últimos 60 días: suficiente para racha y semana.
    final cutoff = dayKey(DateTime.now().subtract(const Duration(days: 60)));
    days.removeWhere((d) => d.compareTo(cutoff) < 0);
    final streak = currentStreak(days, DateTime.now());
    return p.copyWith(
      activeDays: days,
      bestStreak: math.max(p.bestStreak, streak),
    );
  }

  void _commit(ExplorerProgress next) {
    state = state.copyWith(progress: next);
    unawaited(_repo.saveProgress(next));
  }

  RewardOutcome _reward(
    ExplorerProgress next, {
    required int earned,
    int missionBonus = 0,
  }) {
    final before = state.progress;
    final beforeLevel = LevelProgress.of(before.gotitas).level;
    next = _withActivity(
      next.copyWith(gotitas: before.gotitas + earned + missionBonus),
    );
    final afterLevel = LevelProgress.of(next.gotitas);
    final newMedals = medals
        .where((m) => !m.unlocked(before) && m.unlocked(next))
        .toList(growable: false);
    final newGames = games
        .where((g) => !g.unlockedFor(before) && g.unlockedFor(next))
        .toList(growable: false);
    final newHats = hats
        .where(
          (h) => !h.availableAt(beforeLevel) && h.availableAt(afterLevel.level),
        )
        .toList(growable: false);
    final newBanners = banners
        .where(
          (b) => !b.availableAt(beforeLevel) && b.availableAt(afterLevel.level),
        )
        .toList(growable: false);
    _commit(next);
    return RewardOutcome(
      gotitas: earned,
      missionBonus: missionBonus,
      levelUp: afterLevel.level > beforeLevel ? afterLevel.current : null,
      newMedals: newMedals,
      newGames: newGames,
      newHats: newHats,
      newBanners: newBanners,
    );
  }

  /// Visita validada con el QR del tótem (solo la primera vez).
  RewardOutcome registerVisit(Place place) {
    final p = state.progress;
    if (p.visited.contains(place.id)) return const RewardOutcome();
    _log.visit(place);
    return _reward(
      p.copyWith(visited: {...p.visited, place.id}),
      earned: Economy.visit,
    );
  }

  RewardOutcome completeGame(GameId id, {required bool won, int score = 0}) {
    final p = state.progress;
    final best = Map<String, int>.of(p.bestScores);
    best[id.name] = math.max(best[id.name] ?? 0, score);
    _log.game(id, won: won, score: score);
    if (!won) {
      _commit(_withActivity(p.copyWith(bestScores: best)));
      return const RewardOutcome();
    }
    final firstTime = !p.completedGames.contains(id.name);
    // Repetir un juego ya ganado da poco y con tope diario.
    final replayedToday = p.replayDay == _today ? p.replayEarned : 0;
    final replay = firstTime
        ? 0
        : math.max(
            0,
            math.min(Economy.replay, Economy.replayDailyCap - replayedToday),
          );
    final earned = firstTime ? gameById(id).reward : replay;

    var bonus = 0;
    var missionCompleted = p.missionCompleted;
    final mission = missionFor(DateTime.now(), p);
    if (p.missionAccepted == _today &&
        p.missionCompleted != _today &&
        mission.game == id) {
      bonus = mission.reward;
      missionCompleted = _today;
    }
    return _reward(
      p.copyWith(
        completedGames: {...p.completedGames, id.name},
        bestScores: best,
        missionCompleted: missionCompleted,
        replayDay: firstTime ? null : _today,
        replayEarned: firstTime ? null : replayedToday + replay,
      ),
      earned: earned,
      missionBonus: bonus,
    );
  }

  /// Pregunta de repaso de un lugar (una vez): más si acierta a la primera.
  RewardOutcome answerQuiz(Place place, {required bool firstTry}) {
    final p = state.progress;
    if (p.quizzes.contains(place.id)) return const RewardOutcome();
    _log.quiz(place, firstTry: firstTry);
    return _reward(
      p.copyWith(quizzes: {...p.quizzes, place.id}),
      earned: firstTry ? Economy.quizFirstTry : Economy.quizRetry,
    );
  }

  /// Lista "¡Sé Guardián del Río!" completa: una vez por lugar.
  RewardOutcome completeChecklist(Place place) {
    final p = state.progress;
    if (p.checklists.contains(place.id)) return const RewardOutcome();
    return _reward(
      p.copyWith(checklists: {...p.checklists, place.id}),
      earned: Economy.checklist,
    );
  }

  void acceptMission() {
    final p = state.progress;
    if (p.missionAccepted == _today) return;
    _commit(_withActivity(p.copyWith(missionAccepted: _today)));
  }

  /// Compra un sombrero con gotitas DISPONIBLES y se lo pone. No cambia las
  /// gotitas ganadas (XP), así que nunca baja el nivel.
  Purchase buyHat(HatInfo hat) {
    final p = state.progress;
    if (p.ownedHats.contains(hat.id)) return Purchase.alreadyOwned;
    if (!hat.availableAt(LevelProgress.of(p.gotitas).level)) {
      return Purchase.levelLocked;
    }
    if (p.wallet < hat.price) return Purchase.notEnough;
    _commit(
      p.copyWith(
        spent: p.spent + hat.price,
        ownedHats: {...p.ownedHats, hat.id},
        equippedHat: hat.id,
      ),
    );
    return Purchase.bought;
  }

  /// Se pone un sombrero comprado, o se lo quita con `null`.
  void equipHat(String? hatId) {
    final p = state.progress;
    if (hatId != null && !p.ownedHats.contains(hatId)) return;
    if (p.equippedHat == hatId) return;
    _commit(p.copyWith(equippedHat: hatId));
  }

  /// Compra un banner para la tarjeta del perfil y lo equipa. Misma lógica
  /// que los sombreros: nivel mínimo + gotitas disponibles.
  Purchase buyBanner(BannerInfo banner) {
    final p = state.progress;
    if (p.ownedBanners.contains(banner.id)) return Purchase.alreadyOwned;
    if (!banner.availableAt(LevelProgress.of(p.gotitas).level)) {
      return Purchase.levelLocked;
    }
    if (p.wallet < banner.price) return Purchase.notEnough;
    _commit(
      p.copyWith(
        spent: p.spent + banner.price,
        ownedBanners: {...p.ownedBanners, banner.id},
        equippedBanner: banner.id,
      ),
    );
    return Purchase.bought;
  }

  /// Equipa un banner comprado, o vuelve al original con `null`.
  void equipBanner(String? bannerId) {
    final p = state.progress;
    if (bannerId != null && !p.ownedBanners.contains(bannerId)) return;
    if (p.equippedBanner == bannerId) return;
    _commit(p.copyWith(equippedBanner: bannerId));
  }

  Future<void> reset() async {
    await _repo.clear();
    await _log.resetUser();
    state = const ExplorerState(profile: null, progress: ExplorerProgress());
  }
}
