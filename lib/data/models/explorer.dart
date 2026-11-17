import 'package:flutter/foundation.dart';

enum ExplorerAvatar {
  oso('🐻', 'Oso de Anteojos', 'Andes'),
  condor('🦅', 'Cóndor Andino', 'Cielos Andinos'),
  nutria('🦦', 'Nutria de Río', 'Ríos y Selva'),
  tortuga('🐢', 'Tortuga Charapa', 'Amazonía');

  const ExplorerAvatar(this.emoji, this.label, this.habitat);
  final String emoji;
  final String label;
  final String habitat;
}

@immutable
class ExplorerProfile {
  const ExplorerProfile({
    required this.name,
    required this.avatar,
    required this.age,
  });

  final String name;
  final ExplorerAvatar avatar;

  /// Edad elegida; 9 representa "9+".
  final int age;

  ExplorerProfile copyWith({String? name, ExplorerAvatar? avatar, int? age}) =>
      ExplorerProfile(
        name: name ?? this.name,
        avatar: avatar ?? this.avatar,
        age: age ?? this.age,
      );

  Map<String, Object?> toJson() => {
    'name': name,
    'avatar': avatar.name,
    'age': age,
  };

  factory ExplorerProfile.fromJson(Map<String, Object?> json) =>
      ExplorerProfile(
        name: json['name'] as String? ?? 'Explorador',
        avatar:
            ExplorerAvatar.values.asNameMap()[json['avatar']] ??
            ExplorerAvatar.oso,
        age: (json['age'] as num?)?.toInt() ?? 7,
      );
}

/// Todo el avance del explorador. Inmutable: cada cambio crea una copia.
@immutable
class ExplorerProgress {
  const ExplorerProgress({
    this.gotitas = 0,
    this.visited = const {},
    this.completedGames = const {},
    this.bestScores = const {},
    this.quizzes = const {},
    this.checklists = const {},
    this.activeDays = const {},
    this.bestStreak = 0,
    this.missionAccepted,
    this.missionCompleted,
    this.spent = 0,
    this.ownedHats = const {},
    this.equippedHat,
  });

  /// Gotitas GANADAS en total (experiencia, XP). Nunca bajan: definen el
  /// nivel, los minijuegos extra y las medallas.
  final int gotitas;

  /// Gotitas gastadas en la tienda.
  final int spent;

  /// Gotitas DISPONIBLES para gastar en la tienda.
  int get wallet => gotitas - spent;

  /// Sombreros comprados y el que lleva puesto el avatar (o `null`).
  final Set<String> ownedHats;
  final String? equippedHat;
  final Set<String> visited;
  final Set<String> completedGames;
  final Map<String, int> bestScores;
  final Set<String> quizzes;
  final Set<String> checklists;

  /// Días con actividad, en formato `yyyy-MM-dd`.
  final Set<String> activeDays;
  final int bestStreak;

  /// Día (`yyyy-MM-dd`) en que se aceptó / completó la misión del día.
  final String? missionAccepted;
  final String? missionCompleted;

  ExplorerProgress copyWith({
    int? gotitas,
    Set<String>? visited,
    Set<String>? completedGames,
    Map<String, int>? bestScores,
    Set<String>? quizzes,
    Set<String>? checklists,
    Set<String>? activeDays,
    int? bestStreak,
    String? missionAccepted,
    String? missionCompleted,
    int? spent,
    Set<String>? ownedHats,
    Object? equippedHat = _keep,
  }) => ExplorerProgress(
    gotitas: gotitas ?? this.gotitas,
    visited: visited ?? this.visited,
    completedGames: completedGames ?? this.completedGames,
    bestScores: bestScores ?? this.bestScores,
    quizzes: quizzes ?? this.quizzes,
    checklists: checklists ?? this.checklists,
    activeDays: activeDays ?? this.activeDays,
    bestStreak: bestStreak ?? this.bestStreak,
    missionAccepted: missionAccepted ?? this.missionAccepted,
    missionCompleted: missionCompleted ?? this.missionCompleted,
    spent: spent ?? this.spent,
    ownedHats: ownedHats ?? this.ownedHats,
    equippedHat: identical(equippedHat, _keep)
        ? this.equippedHat
        : equippedHat as String?,
  );

  static const _keep = Object();

  Map<String, Object?> toJson() => {
    'gotitas': gotitas,
    'visited': visited.toList(),
    'completedGames': completedGames.toList(),
    'bestScores': bestScores,
    'quizzes': quizzes.toList(),
    'checklists': checklists.toList(),
    'activeDays': activeDays.toList(),
    'bestStreak': bestStreak,
    'missionAccepted': missionAccepted,
    'missionCompleted': missionCompleted,
    'spent': spent,
    'ownedHats': ownedHats.toList(),
    'equippedHat': equippedHat,
  };

  factory ExplorerProgress.fromJson(Map<String, Object?> json) {
    Set<String> set(String k) =>
        ((json[k] as List?) ?? const []).whereType<String>().toSet();
    return ExplorerProgress(
      gotitas: (json['gotitas'] as num?)?.toInt() ?? 0,
      visited: set('visited'),
      completedGames: set('completedGames'),
      bestScores: ((json['bestScores'] as Map?) ?? const {}).map(
        (k, v) => MapEntry(k as String, (v as num).toInt()),
      ),
      quizzes: set('quizzes'),
      checklists: set('checklists'),
      activeDays: set('activeDays'),
      bestStreak: (json['bestStreak'] as num?)?.toInt() ?? 0,
      missionAccepted: json['missionAccepted'] as String?,
      missionCompleted: json['missionCompleted'] as String?,
      spent: (json['spent'] as num?)?.toInt() ?? 0,
      ownedHats: set('ownedHats'),
      equippedHat: json['equippedHat'] as String?,
    );
  }
}

/// Niveles: el umbral es el total de gotitas necesario para alcanzarlo.
@immutable
class LevelInfo {
  const LevelInfo(this.level, this.title, this.threshold);
  final int level;
  final String title;
  final int threshold;
}

const levels = <LevelInfo>[
  LevelInfo(1, 'Gotita Curiosa', 0),
  LevelInfo(2, 'Explorador', 80),
  LevelInfo(3, 'Aprendiz del Agua', 200),
  LevelInfo(4, 'Guardián del Río', 350),
  LevelInfo(5, 'Protector Fluvial', 550),
  LevelInfo(6, 'Héroe de Loja', 800),
  LevelInfo(7, 'Leyenda del Agua', 1100),
  LevelInfo(8, 'Gran Guardián', 1500),
];

@immutable
class LevelProgress {
  const LevelProgress({
    required this.current,
    required this.next,
    required this.gotitas,
  });

  final LevelInfo current;
  final LevelInfo? next;
  final int gotitas;

  int get level => current.level;
  bool get isMax => next == null;
  int get intoLevel => gotitas - current.threshold;
  int get levelSpan => (next?.threshold ?? gotitas) - current.threshold;
  int get remaining => isMax ? 0 : next!.threshold - gotitas;
  double get fraction => isMax ? 1 : intoLevel / levelSpan;

  factory LevelProgress.of(int gotitas) {
    var index = 0;
    for (var i = 0; i < levels.length; i++) {
      if (gotitas >= levels[i].threshold) index = i;
    }
    return LevelProgress(
      current: levels[index],
      next: index + 1 < levels.length ? levels[index + 1] : null,
      gotitas: gotitas,
    );
  }
}
