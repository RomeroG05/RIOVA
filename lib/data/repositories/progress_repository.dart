import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/explorer.dart';

/// Contrato de persistencia del perfil y el avance del explorador.
abstract interface class ProgressRepository {
  ExplorerProfile? loadProfile();
  ExplorerProgress loadProgress();
  Future<void> saveProfile(ExplorerProfile profile);
  Future<void> saveProgress(ExplorerProgress progress);
  Future<void> clear();
}

/// Implementación real: JSON en SharedPreferences (con caché síncrona para
/// que el estado inicial esté disponible desde el primer frame).
class PrefsProgressRepository implements ProgressRepository {
  PrefsProgressRepository(this._prefs);

  final SharedPreferencesWithCache _prefs;

  static const profileKey = 'riova.profile.v1';
  static const progressKey = 'riova.progress.v1';

  static Future<PrefsProgressRepository> open() async {
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: {profileKey, progressKey},
      ),
    );
    return PrefsProgressRepository(prefs);
  }

  @override
  ExplorerProfile? loadProfile() {
    final raw = _prefs.getString(profileKey);
    if (raw == null) return null;
    try {
      return ExplorerProfile.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on FormatException {
      return null;
    }
  }

  @override
  ExplorerProgress loadProgress() {
    final raw = _prefs.getString(progressKey);
    if (raw == null) return const ExplorerProgress();
    try {
      return ExplorerProgress.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on FormatException {
      return const ExplorerProgress();
    }
  }

  @override
  Future<void> saveProfile(ExplorerProfile profile) =>
      _prefs.setString(profileKey, jsonEncode(profile.toJson()));

  @override
  Future<void> saveProgress(ExplorerProgress progress) =>
      _prefs.setString(progressKey, jsonEncode(progress.toJson()));

  @override
  Future<void> clear() async {
    await _prefs.remove(profileKey);
    await _prefs.remove(progressKey);
  }
}

/// Implementación en memoria (tests y vistas previas). Serializa a JSON
/// igual que la real, así los tests también cubren el formato guardado.
class InMemoryProgressRepository implements ProgressRepository {
  InMemoryProgressRepository({
    ExplorerProfile? profile,
    ExplorerProgress? progress,
  }) : _profile = profile == null ? null : jsonEncode(profile.toJson()),
       _progress = progress == null ? null : jsonEncode(progress.toJson());

  String? _profile;
  String? _progress;

  @override
  ExplorerProfile? loadProfile() => _profile == null
      ? null
      : ExplorerProfile.fromJson(jsonDecode(_profile!) as Map<String, Object?>);

  @override
  ExplorerProgress loadProgress() => _progress == null
      ? const ExplorerProgress()
      : ExplorerProgress.fromJson(
          jsonDecode(_progress!) as Map<String, Object?>,
        );

  @override
  Future<void> saveProfile(ExplorerProfile profile) async =>
      _profile = jsonEncode(profile.toJson());

  @override
  Future<void> saveProgress(ExplorerProgress progress) async =>
      _progress = jsonEncode(progress.toJson());

  @override
  Future<void> clear() async {
    _profile = null;
    _progress = null;
  }
}
