import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tamaños de letra que se ofrecen en Ajustes (multiplican la escala del
/// sistema).
enum TextSize {
  small('Pequeña', 0.9),
  normal('Normal', 1.0),
  large('Grande', 1.15),
  huge('Muy grande', 1.3);

  const TextSize(this.label, this.scale);
  final String label;
  final double scale;
}

/// Velocidad de la voz de Río al leer en voz alta.
enum VoiceSpeed {
  slow('Lenta', 0.35),
  normal('Normal', 0.45),
  fast('Rápida', 0.55);

  const VoiceSpeed(this.label, this.rate);
  final String label;
  final double rate;
}

/// Preferencias del dispositivo (no se suben a la nube).
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.textSize = TextSize.normal,
    this.reduceMotion = false,
    this.voiceSpeed = VoiceSpeed.normal,
  });

  final ThemeMode themeMode;
  final TextSize textSize;

  /// Quita las animaciones aunque el sistema no lo pida.
  final bool reduceMotion;
  final VoiceSpeed voiceSpeed;

  AppSettings copyWith({
    ThemeMode? themeMode,
    TextSize? textSize,
    bool? reduceMotion,
    VoiceSpeed? voiceSpeed,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    textSize: textSize ?? this.textSize,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    voiceSpeed: voiceSpeed ?? this.voiceSpeed,
  );

  Map<String, Object?> toJson() => {
    'themeMode': themeMode.name,
    'textSize': textSize.name,
    'reduceMotion': reduceMotion,
    'voiceSpeed': voiceSpeed.name,
  };

  factory AppSettings.fromJson(Map<String, Object?> json) {
    T pick<T extends Enum>(List<T> values, Object? name, T fallback) =>
        values.where((v) => v.name == name).firstOrNull ?? fallback;
    return AppSettings(
      themeMode: pick(ThemeMode.values, json['themeMode'], ThemeMode.system),
      textSize: pick(TextSize.values, json['textSize'], TextSize.normal),
      reduceMotion: json['reduceMotion'] == true,
      voiceSpeed: pick(
        VoiceSpeed.values,
        json['voiceSpeed'],
        VoiceSpeed.normal,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.themeMode == themeMode &&
      other.textSize == textSize &&
      other.reduceMotion == reduceMotion &&
      other.voiceSpeed == voiceSpeed;

  @override
  int get hashCode =>
      Object.hash(themeMode, textSize, reduceMotion, voiceSpeed);
}

/// Dónde se guardan los ajustes.
abstract interface class SettingsRepository {
  AppSettings load();
  Future<void> save(AppSettings settings);
}

class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository([this._value = const AppSettings()]);

  AppSettings _value;

  @override
  AppSettings load() => _value;

  @override
  Future<void> save(AppSettings settings) async => _value = settings;
}

class PrefsSettingsRepository implements SettingsRepository {
  PrefsSettingsRepository(this._prefs);

  final SharedPreferencesWithCache _prefs;
  static const key = 'riova.settings.v1';

  static Future<PrefsSettingsRepository> open() async =>
      PrefsSettingsRepository(
        await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
            allowList: {key},
          ),
        ),
      );

  @override
  AppSettings load() {
    final raw = _prefs.getString(key);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on FormatException {
      return const AppSettings();
    }
  }

  @override
  Future<void> save(AppSettings settings) =>
      _prefs.setString(key, jsonEncode(settings.toJson()));
}

/// En la app se sobrescribe con [PrefsSettingsRepository]; en pruebas basta
/// la versión en memoria.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => InMemorySettingsRepository(),
);

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(settingsRepositoryProvider).load();

  void _set(AppSettings next) {
    if (next == state) return;
    state = next;
    ref.read(settingsRepositoryProvider).save(next);
  }

  void setThemeMode(ThemeMode mode) => _set(state.copyWith(themeMode: mode));
  void setTextSize(TextSize size) => _set(state.copyWith(textSize: size));
  void setReduceMotion(bool value) => _set(state.copyWith(reduceMotion: value));
  void setVoiceSpeed(VoiceSpeed speed) =>
      _set(state.copyWith(voiceSpeed: speed));
}
