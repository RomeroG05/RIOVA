import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:riova/features/games/mitos/myths_game.dart';
import 'package:riova/features/games/recicla/recycle_game.dart';
import 'package:riova/features/games/rompecabezas/river_puzzle_game.dart';

void main() {
  test('rompecabezas: siempre mezclado, con solución, y solo mueve vecinos del hueco', () {
    for (var seed = 0; seed < 50; seed++) {
      final p = SlidePuzzle.shuffled(3, math.Random(seed));
      expect(p.isSolved, isFalse);
      expect(p.cells.toSet(), hasLength(9));
      // Paridad de inversiones + fila del hueco: para n impar, inversiones pares = resoluble.
      var inv = 0;
      final tiles = p.cells.where((t) => t != p.blank).toList();
      for (var i = 0; i < tiles.length; i++) {
        for (var j = i + 1; j < tiles.length; j++) {
          if (tiles[i] > tiles[j]) inv++;
        }
      }
      expect(inv.isEven, isTrue, reason: 'seed $seed');
    }
    final p = SlidePuzzle.shuffled(3, math.Random(1));
    final far = List.generate(
      9,
      (i) => i,
    ).firstWhere((i) => i != p.blankPos && !p.movable().contains(i));
    expect(p.move(far), isFalse);
    expect(p.move(p.movable().first), isTrue);
  });

  test('mitos: mezcla de verdades y mitos con explicación', () {
    expect(mythDeck.length, greaterThanOrEqualTo(10));
    expect(mythDeck.where((m) => m.isTrue).length, greaterThanOrEqualTo(4));
    expect(mythDeck.where((m) => !m.isTrue).length, greaterThanOrEqualTo(4));
    expect(mythDeck.every((m) => m.why.isNotEmpty), isTrue);
  });

  test('recicla: cada tacho tiene residuos suficientes', () {
    for (final bin in Bin.values) {
      expect(
        wastePool.where((w) => w.bin == bin).length,
        greaterThanOrEqualTo(3),
        reason: bin.name,
      );
    }
  });
}
