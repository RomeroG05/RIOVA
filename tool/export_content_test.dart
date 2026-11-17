// Exporta el contenido empaquetado a firebase/seed.json para subirlo a
// Firestore con `python3 tool/seed_firestore.py`.
//
//   flutter test tool/export_content_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:riova/data/content/game_content.dart';
import 'package:riova/data/content/places_content.dart';
import 'package:riova/data/remote/place_codec.dart';
import 'package:riova/state/sensor_network.dart';

void main() {
  test('exportar contenido a firebase/seed.json', () {
    String two(int n) => n.toString().padLeft(2, '0');
    final seed = <String, Map<String, Object?>>{
      'sectors': {for (final p in bundledPlaces) p.id: PlaceCodec.toMap(p)},
      'quizBank': {
        for (final (i, q) in bundledQuizBank.indexed)
          'q${two(i + 1)}': {...PlaceCodec.quizToMap(q), 'active': true},
      },
      'games': {
        for (final g in games)
          g.id.name: {
            'title': g.title,
            'description': g.description,
            'difficulty': g.difficulty,
            'reward': g.reward,
            'replayReward': GameInfo.replayReward,
            'isNew': g.isNew,
            'unlock': {
              'open': g.unlock.isOpen,
              if (g.unlock.level != null) 'level': g.unlock.level,
              if (g.unlock.zone != null) 'zone': g.unlock.zone!.name,
              if (g.unlock.scans != null) 'scans': g.unlock.scans,
              'label': g.unlock.label,
            },
          },
      },
      'medals': {
        for (final m in medals)
          m.id: {
            'title': m.title,
            'howTo': m.howTo,
            'secret': m.secret,
            'type': m.byLevel ? 'nivel' : 'qr',
          },
      },
      'missions': {
        for (final (i, m) in dailyMissions.indexed)
          'm${two(i + 1)}': {
            'title': m.title,
            'description': m.description,
            'game': m.game.name,
            'reward': m.reward,
            'emoji': m.emoji,
          },
      },
      'sensors': {
        for (final p in bundledPlaces)
          p.id: {
            'placeId': p.id,
            'name': p.name,
            'source': 'simulado',
            'baseline': {
              for (final e in SensorNetwork.defaultBaseline(p).entries)
                e.key: double.parse(e.value.toStringAsFixed(2)),
            },
          },
      },
      'meta': {
        'content': {
          'credit': periodicalCredit,
          'sectors': bundledPlaces.length,
          'quizQuestions': bundledQuizBank.length,
        },
      },
    };
    final file = File('firebase/seed.json')..createSync(recursive: true);
    file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(seed));
    expect(seed['sectors'], hasLength(13));
  });
}
