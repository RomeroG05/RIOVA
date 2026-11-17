import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/content/places_content.dart';
import '../data/models/place.dart';

enum RiverStatus { clean, alert }

/// Lectura de un sensor IoT de calidad del agua.
@immutable
class RiverReading {
  const RiverReading({
    required this.quality,
    required this.level,
    required this.temperature,
    required this.ph,
    required this.at,
    this.live = false,
  });

  /// `true` si viene de un sensor real (documento `sensors/{id}` en
  /// Firestore con una lectura reciente); `false` si es simulada.
  final bool live;

  /// 0–100 %
  final double quality;

  /// Nivel del agua en metros.
  final double level;
  final double temperature;
  final double ph;
  final DateTime at;

  RiverStatus get status =>
      quality >= 75 ? RiverStatus.clean : RiverStatus.alert;

  String get qualityLabel => quality >= 85
      ? 'Limpia'
      : quality >= 75
      ? 'Buena'
      : 'Con residuos';

  String get levelLabel => level < 1.1
      ? 'Normal'
      : level < 1.5
      ? 'Alto'
      : 'Crecida';

  String get temperatureLabel => temperature < 17 ? 'Fresca' : 'Tibia';

  String get phLabel => (ph >= 6.8 && ph <= 7.8) ? 'Óptimo' : 'Vigilar';

  String get flowLabel => level < 1.1 ? 'Flujo Estable' : 'Caudal en aumento';
}

@immutable
class _Baseline {
  const _Baseline(this.quality, this.level, this.temperature, this.ph);
  _Baseline.of(Map<String, double> m)
    : this(m['quality']!, m['level']!, m['temperature']!, m['ph']!);
  final double quality;
  final double level;
  final double temperature;
  final double ph;
}

/// Documentos `sensors/{id}` de Firestore. Vacío si no hay Firebase; se
/// sobrescribe en `main()`.
final remoteSensorDocsProvider =
    StreamProvider<Map<String, Map<String, Object?>>>(
      (ref) => const Stream.empty(),
    );

/// Red de sensores de los ríos de Loja.
///
/// Cada sector tiene una línea base y cada 4 s sus valores dan un paseo
/// aleatorio acotado alrededor de ella (simulación). Desde Firestore:
/// * `baseline: {quality, level, temperature, ph}` ajusta esa línea base.
/// * `live: {...}` + `liveAt` (de hace menos de 15 min) — escrito por un
///   sensor IoT real — reemplaza la simulación por la lectura real.
class SensorNetwork extends Notifier<Map<String, RiverReading>> {
  static const interval = Duration(seconds: 4);

  // Los dos tramos que el periódico describe como más contaminados
  // (escombrera de El Capulí y vertidos sin tratar en Sauces Norte II).
  static const _dirty = {'capuli1', 'sauces2'};

  /// Línea base de fábrica de un sector (la misma que se sube a
  /// `sensors/{id}.baseline` en Firestore).
  static Map<String, double> defaultBaseline(Place p) {
    final seeded = math.Random(p.totem * 7919);
    return {
      'quality': _dirty.contains(p.id)
          ? 68 + seeded.nextDouble() * 4
          : 84 + seeded.nextDouble() * 10,
      'level': 0.6 + seeded.nextDouble() * 0.35,
      'temperature': 14.5 + seeded.nextDouble() * 3,
      'ph': 7.0 + seeded.nextDouble() * 0.6,
    };
  }

  final _rand = math.Random();
  final _baselines = <String, _Baseline>{};
  final _live = <String, RiverReading>{};
  static const _liveMaxAge = Duration(minutes: 15);

  @override
  Map<String, RiverReading> build() {
    final timer = Timer.periodic(interval, (_) => _tick());
    ref.onDispose(timer.cancel);
    ref.listen(
      remoteSensorDocsProvider,
      (_, next) => next.whenData(_applyRemote),
    );
    final now = DateTime.now();
    return {
      for (final p in places)
        p.id: () {
          final b = _Baseline.of(defaultBaseline(p));
          _baselines[p.id] = b;
          return RiverReading(
            quality: b.quality,
            level: b.level,
            temperature: b.temperature,
            ph: b.ph,
            at: now,
          );
        }(),
    };
  }

  double _walk(double value, double base, double step, double spread) {
    final next = value + (_rand.nextDouble() * 2 - 1) * step;
    // Tirón suave hacia la línea base para que no se desvíe.
    final pulled = next + (base - next) * 0.15;
    return pulled.clamp(base - spread, base + spread);
  }

  void _applyRemote(Map<String, Map<String, Object?>> docs) {
    double? num_(Map<Object?, Object?> m, String k) =>
        (m[k] is num) ? (m[k]! as num).toDouble() : null;
    for (final MapEntry(key: id, value: d) in docs.entries) {
      final base = _baselines[id];
      if (base == null) continue;
      final b = d['baseline'];
      if (b is Map) {
        _baselines[id] = _Baseline(
          num_(b, 'quality')?.clamp(0, 100) ?? base.quality,
          num_(b, 'level') ?? base.level,
          num_(b, 'temperature') ?? base.temperature,
          num_(b, 'ph') ?? base.ph,
        );
      }
      final live = d['live'], at = d['liveAt'];
      if (live is Map &&
          at is DateTime &&
          DateTime.now().difference(at) < _liveMaxAge) {
        final cur = state[id]!;
        _live[id] = RiverReading(
          quality: num_(live, 'quality') ?? cur.quality,
          level: num_(live, 'level') ?? cur.level,
          temperature: num_(live, 'temperature') ?? cur.temperature,
          ph: num_(live, 'ph') ?? cur.ph,
          at: at,
          live: true,
        );
      } else {
        _live.remove(id);
      }
    }
    _tick();
  }

  void _tick() {
    final now = DateTime.now();
    state = {
      for (final entry in state.entries)
        entry.key: () {
          final real = _live[entry.key];
          if (real != null && now.difference(real.at) < _liveMaxAge) {
            return real;
          }
          final r = entry.value;
          final b = _baselines[entry.key]!;
          return RiverReading(
            quality: _walk(r.quality, b.quality, 1.6, 5).clamp(0, 100),
            level: _walk(r.level, b.level, 0.03, 0.12),
            temperature: _walk(r.temperature, b.temperature, 0.15, 0.8),
            ph: _walk(r.ph, b.ph, 0.04, 0.2),
            at: now,
          );
        }(),
    };
  }
}

final sensorNetworkProvider =
    NotifierProvider<SensorNetwork, Map<String, RiverReading>>(
      SensorNetwork.new,
    );

final placeReadingProvider = Provider.family<RiverReading, String>(
  (ref, placeId) => ref.watch(sensorNetworkProvider.select((m) => m[placeId]!)),
);

@immutable
class NetworkSummary {
  const NetworkSummary(this.averageQuality, this.alerts);
  final double averageQuality;
  final int alerts;

  String get label => averageQuality >= 85
      ? 'Excelente'
      : averageQuality >= 75
      ? 'Bueno'
      : 'Regular';
}

final networkSummaryProvider = Provider<NetworkSummary>((ref) {
  final readings = ref.watch(sensorNetworkProvider).values;
  final avg =
      readings.fold<double>(0, (s, r) => s + r.quality) / readings.length;
  final alerts = readings.where((r) => r.status == RiverStatus.alert).length;
  return NetworkSummary(avg, alerts);
});
