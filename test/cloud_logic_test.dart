import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riova/data/content/places_content.dart';
import 'package:riova/data/remote/place_codec.dart';
import 'package:riova/state/sensor_network.dart';

void main() {
  group('PlaceCodec', () {
    test('ida y vuelta conserva todo el contenido', () {
      for (final p in bundledPlaces) {
        final back = PlaceCodec.merge(p, PlaceCodec.toMap(p));
        expect(PlaceCodec.toMap(back), PlaceCodec.toMap(p), reason: p.id);
      }
    });

    test('aplica ediciones válidas e ignora las inválidas', () {
      final base = placeById('tebaida');
      final edited = PlaceCodec.merge(base, {
        'headline': 'Titular editado en la consola',
        'name': '',
        'lat': 'no es número',
        'story': ['Nuevo párrafo'],
        'voices': [
          {'who': 'Docente', 'quote': '¡Cuidemos el río!'},
          {'who': 'Sin cita'},
        ],
        'problems': [
          {'kind': 'inexistente', 'summary': 'x', 'detail': 'y'},
        ],
        'photos': [
          {'caption': 'Pie de foto nuevo'},
        ],
        'quiz': {
          'question': '¿?',
          'options': ['solo una'],
          'answer': 0,
        },
      });
      expect(edited.headline, 'Titular editado en la consola');
      expect(edited.name, base.name);
      expect(edited.position, base.position);
      expect(edited.story, ['Nuevo párrafo']);
      expect(edited.voices.single.who, 'Docente');
      expect(edited.problems, base.problems);
      expect(edited.photos.first.caption, 'Pie de foto nuevo');
      expect(edited.photos.first.asset, base.photos.first.asset);
      expect(edited.photos.length, base.photos.length);
      expect(edited.quiz, base.quiz);
    });
  });

  group('Sensores desde Firestore', () {
    test('una lectura IoT reciente reemplaza la simulación', () async {
      final c = ProviderContainer(
        overrides: [
          remoteSensorDocsProvider.overrideWith(
            (ref) => Stream.value({
              'jipiro': {
                'baseline': {'quality': 50},
                'live': {
                  'quality': 42,
                  'level': 1.8,
                  'temperature': 13,
                  'ph': 6.5,
                },
                'liveAt': DateTime.now(),
              },
              'tebaida': {
                'live': {'quality': 10},
                'liveAt': DateTime.now().subtract(const Duration(hours: 2)),
              },
            }),
          ),
        ],
      );
      addTearDown(c.dispose);
      c.listen(sensorNetworkProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      final jipiro = c.read(placeReadingProvider('jipiro'));
      expect(jipiro.live, isTrue);
      expect(jipiro.quality, 42);
      expect(jipiro.levelLabel, 'Crecida');
      final tebaida = c.read(placeReadingProvider('tebaida'));
      expect(tebaida.live, isFalse, reason: 'lectura de hace 2 h = vieja');
      expect(tebaida.quality, greaterThan(70));
    });
  });
}
