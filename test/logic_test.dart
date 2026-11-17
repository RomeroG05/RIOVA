import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:riova/data/models/place.dart';
import 'package:riova/core/utils/day_key.dart';
import 'package:riova/data/content/game_content.dart';
import 'package:riova/data/content/places_content.dart';
import 'package:riova/data/models/explorer.dart';
import 'package:riova/data/remote/place_codec.dart';
import 'package:riova/data/repositories/progress_repository.dart';
import 'package:riova/features/games/camino/water_path_game.dart';
import 'package:riova/features/games/palabras/word_search_game.dart';
import 'package:riova/state/explorer_controller.dart';

ProviderContainer _container([ProgressRepository? repo]) {
  final c = ProviderContainer(
    overrides: [
      progressRepositoryProvider.overrideWithValue(
        repo ?? InMemoryProgressRepository(),
      ),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('Sectores y códigos QR', () {
    test('hay 13 sectores con tótems únicos', () {
      expect(places, hasLength(13));
      expect(places.map((p) => p.totem).toSet(), hasLength(13));
      expect(places.map((p) => p.id).toSet(), hasLength(13));
    });

    test('La Tebaida es el sector A3, parada 3 de la Zona Sur, tótem #03', () {
      final tebaida = placeById('tebaida');
      expect(tebaida.code, 'A3');
      expect(stopNumber(tebaida), 3);
      expect(tebaida.totemCode, 'T03');
    });

    test('los 13 sectores del periódico: A1–A4, B1–B3, C1–C6', () {
      expect(places.map((p) => p.code), [
        'A1',
        'A2',
        'A3',
        'A4',
        'B1',
        'B2',
        'B3',
        'C1',
        'C2',
        'C3',
        'C4',
        'C5',
        'C6',
      ]);
      expect(places.map((p) => p.totem), List.generate(13, (i) => i + 1));
    });

    test('cada sector tiene fotos existentes, voces, problemas, historia y especies', () {
      for (final p in places) {
        expect(p.photos.length, greaterThanOrEqualTo(2), reason: p.id);
        for (final photo in p.photos) {
          expect(File(photo.asset).existsSync(), isTrue, reason: photo.asset);
        }
        expect(p.voices, isNotEmpty, reason: p.id);
        expect(p.problems, isNotEmpty, reason: p.id);
        expect(p.timeline, hasLength(3), reason: p.id);
        expect(p.species, isNotEmpty, reason: p.id);
        expect(p.story, isNotEmpty, reason: p.id);
      }
    });

    test('acepta los formatos de código del tótem', () {
      for (final raw in [
        'riova://totem/03',
        'RIOVA-T03',
        'T03',
        't3',
        '03',
        ' 3 ',
      ]) {
        expect(placeFromCode(raw)?.id, 'tebaida', reason: raw);
      }
      expect(placeFromCode('https://example.com'), isNull);
      expect(placeFromCode('T99'), isNull);
    });

    test('cada sector está a menos de 300 m de su río real', () {
      // Distancia punto–segmento en una proyección local (metros); a esta
      // escala (pocos km) el error es despreciable.
      double toSegment(LatLng p, LatLng a, LatLng b) {
        const mPerDeg = 111320.0;
        final k = math.cos(p.latitude * math.pi / 180);
        final ax = (a.longitude - p.longitude) * mPerDeg * k,
            ay = (a.latitude - p.latitude) * mPerDeg;
        final bx = (b.longitude - p.longitude) * mPerDeg * k,
            by = (b.latitude - p.latitude) * mPerDeg;
        final dx = bx - ax, dy = by - ay;
        final len2 = dx * dx + dy * dy;
        final t = len2 == 0
            ? 0.0
            : (-(ax * dx + ay * dy) / len2).clamp(0.0, 1.0);
        final x = ax + t * dx, y = ay + t * dy;
        return math.sqrt(x * x + y * y);
      }

      for (final p in places) {
        final path = p.river == River.malacatos ? malacatosPath : zamoraPath;
        var nearest = double.infinity;
        for (var i = 1; i < path.length; i++) {
          nearest = math.min(
            nearest,
            toSegment(p.position, path[i - 1], path[i]),
          );
        }
        expect(nearest, lessThan(300), reason: '${p.id}: ${nearest.round()} m');
      }
    });

    test('cada QR generado vuelve a su propio sector', () {
      for (final p in places) {
        expect(placeFromCode(p.qrPayload)?.id, p.id);
      }
    });
  });

  group('Niveles', () {
    test('umbrales', () {
      expect(LevelProgress.of(0).level, 1);
      expect(LevelProgress.of(79).level, 1);
      expect(LevelProgress.of(80).level, 2);
      expect(LevelProgress.of(240).level, 3);
      expect(LevelProgress.of(240).remaining, 110);
      expect(LevelProgress.of(99999).isMax, isTrue);
    });
  });

  group('Racha', () {
    test('cuenta días seguidos y tolera que hoy aún no haya actividad', () {
      final today = DateTime(2026, 11, 16);
      final days = {
        for (var i = 1; i <= 4; i++) dayKey(DateTime(2026, 11, 16 - i)),
      };
      expect(currentStreak(days, today), 4);
      expect(currentStreak({...days, dayKey(today)}, today), 5);
      expect(currentStreak({dayKey(DateTime(2026, 11, 10))}, today), 0);
    });
  });

  group('Recompensas del explorador', () {
    test(
      'registrar una parada da +30 solo la primera vez y desbloquea medalla',
      () {
        final c = _container();
        final ctrl = c.read(explorerProvider.notifier);
        final first = ctrl.registerVisit(placeById('tebaida'));
        expect(first.gotitas, 30);
        expect(first.newMedals.map((m) => m.id), contains('primera_huella'));
        expect(ctrl.registerVisit(placeById('tebaida')).isEmpty, isTrue);
        expect(c.read(explorerProvider).progress.gotitas, 30);
      },
    );

    test('juego: recompensa completa la primera vez, reducida al repetir', () {
      final c = _container();
      final ctrl = c.read(explorerProvider.notifier);
      expect(ctrl.completeGame(GameId.detective, won: true).gotitas, 60);
      expect(
        ctrl.completeGame(GameId.detective, won: true).gotitas,
        GameInfo.replayReward,
      );
      expect(ctrl.completeGame(GameId.detective, won: false).isEmpty, isTrue);
    });

    test('misión del día aceptada suma su bono al ganar el juego correcto', () {
      final c = _container();
      final ctrl = c.read(explorerProvider.notifier);
      final mission = missionFor(
        DateTime.now(),
        c.read(explorerProvider).progress,
      );
      ctrl.acceptMission();
      final outcome = ctrl.completeGame(mission.game, won: true);
      expect(outcome.missionBonus, mission.reward);
      expect(
        c.read(explorerProvider).progress.missionCompleted,
        dayKey(DateTime.now()),
      );
    });

    test('el avance se guarda y se recupera', () {
      final repo = InMemoryProgressRepository();
      final c = _container(repo);
      c.read(explorerProvider.notifier)
        ..registerVisit(placeById('capuli1'))
        ..answerQuiz(placeById('capuli1'), firstTry: true);
      final restored = repo.loadProgress();
      expect(restored.gotitas, 45);
      expect(restored.visited, contains('capuli1'));
    });

    test('el progreso con sectores de versiones anteriores se limpia', () {
      final repo = InMemoryProgressRepository(
        progress: const ExplorerProgress(
          visited: {'pueear', 'motupe', 'tebaida'},
          gotitas: 90,
        ),
      );
      final c = _container(repo);
      expect(c.read(explorerProvider).progress.visited, {'tebaida'});
      expect(c.read(explorerProvider).progress.gotitas, 90);
    });

    test(
      'escanear un tótem del Centro desbloquea sus minijuegos y medallas QR',
      () {
        final c = _container();
        final ctrl = c.read(explorerProvider.notifier);
        ExplorerProgress p() => c.read(explorerProvider).progress;
        expect(unlockedGames(p()).map((g) => g.id), [
          GameId.rescata,
          GameId.quiz,
        ]);

        final out = ctrl.registerVisit(placeById('puerta'));
        expect(
          out.newGames.map((g) => g.id),
          containsAll([GameId.detective, GameId.palabras]),
        );
        expect(
          out.newMedals.map((m) => m.id),
          containsAll(['primera_huella', 'confluencia']),
        );
        expect(gameById(GameId.camino).unlockedFor(p()), isFalse);
      },
    );

    test('subir de nivel desbloquea minijuegos y medallas de nivel', () {
      final c = _container();
      final ctrl = c.read(explorerProvider.notifier);
      ctrl.completeGame(GameId.rescata, won: true); // +50
      final out = ctrl.completeGame(
        GameId.quiz,
        won: true,
      ); // +30 → 80 = Nivel 2
      expect(out.levelUp?.level, 2);
      expect(
        out.newGames.map((g) => g.id),
        containsAll([GameId.detective, GameId.palabras]),
      );
      expect(out.newMedals.map((m) => m.id), ['nivel_2']);
    });

    test('las medallas solo se ganan por nivel o escaneando QR', () {
      // Mucho avance en juegos, quizzes y listas, sin tótems y en Nivel 1.
      const p = ExplorerProgress(
        gotitas: 79,
        completedGames: {'rescata', 'detective', 'guardianes'},
        quizzes: {'tebaida', 'jipiro'},
        checklists: {'tebaida'},
        activeDays: {'2026-11-15', '2026-11-16', '2026-11-17'},
        bestStreak: 3,
      );
      expect(medals.where((m) => m.unlocked(p)), isEmpty);
    });

    test(
      'todos los sectores tienen ficha disponible sin importar el nivel',
      () {
        expect(places, hasLength(13));
        // Ya no existe requiredLevel: cualquier sector se puede abrir.
        for (final pl in places) {
          expect(PlaceCodec.toMap(pl).containsKey('requiredLevel'), isFalse);
        }
      },
    );

    test('la misión del día solo usa juegos desbloqueados', () {
      for (var d = 0; d < 30; d++) {
        final m = missionFor(
          DateTime(2026, 11, 1 + d),
          const ExplorerProgress(),
        );
        expect([GameId.rescata, GameId.quiz], contains(m.game));
      }
    });
  });

  group('El Camino del Agua', () {
    test('los tableros generados empiezan desordenados y tienen solución', () {
      for (var seed = 0; seed < 40; seed++) {
        for (final size in [4, 5]) {
          final board = PipeBoard.generate(size, math.Random(seed));
          expect(board.isSolved, isFalse, reason: 'seed $seed');
          // Con todas las piezas en su orientación original está resuelto.
          for (var i = 0; i < board.turns.length; i++) {
            board.turns[i] = 0;
          }
          expect(board.isSolved, isTrue, reason: 'seed $seed');
        }
      }
    });

    test('rotateMask gira en sentido horario', () {
      const n = 1, e = 2, s = 4, w = 8;
      expect(rotateMask(n, 1), e);
      expect(rotateMask(e | s, 1), s | w);
      expect(rotateMask(n | e, 4), n | e);
    });
  });

  group('Encuentra Palabras', () {
    test('todas las palabras quedan escondidas y se pueden encontrar', () {
      for (final words in WordSearchGame.wordSets) {
        for (var seed = 0; seed < 25; seed++) {
          final grid = WordGrid.generate(words, 9, math.Random(seed));
          final found = <String>{};
          for (var r = 0; r < 9; r++) {
            for (var c = 0; c < 9; c++) {
              for (final (dr, dc) in const [(0, 1), (1, 0), (1, 1), (-1, 1)]) {
                for (final w in words) {
                  final er = r + dr * (w.length - 1),
                      ec = c + dc * (w.length - 1);
                  if (er < 0 || er >= 9 || ec < 0 || ec >= 9) continue;
                  final cells = WordGrid.line((r, c), (er, ec))!;
                  if (grid.read(cells) == w) found.add(w);
                }
              }
            }
          }
          expect(found, words.toSet(), reason: 'seed $seed');
        }
      }
    });

    test('solo acepta líneas rectas', () {
      expect(WordGrid.line((0, 0), (0, 3)), hasLength(4));
      expect(WordGrid.line((0, 0), (3, 3)), hasLength(4));
      expect(WordGrid.line((0, 0), (1, 3)), isNull);
    });
  });
}
