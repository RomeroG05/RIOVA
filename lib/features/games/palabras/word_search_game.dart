import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/mascot/rio_mascot.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../../data/content/game_content.dart';
import '../common/game_scaffold.dart';

typedef Cell = (int, int);

/// Sopa de letras: lógica pura, separada de la UI.
class WordGrid {
  WordGrid._(this.size, this.letters, this.words);

  final int size;
  final List<List<String>> letters;
  final List<String> words;

  static const _dirs = [(0, 1), (1, 0), (1, 1), (-1, 1)];
  static const _alphabet = 'ABCDEFGHIJLMNOPRSTUVZÑ';

  factory WordGrid.generate(List<String> words, int size, math.Random rnd) {
    while (true) {
      final grid = List.generate(size, (_) => List<String>.filled(size, ''));
      var ok = true;
      for (final word in ([
        ...words,
      ]..sort((a, b) => b.length.compareTo(a.length)))) {
        var placed = false;
        for (var attempt = 0; attempt < 300 && !placed; attempt++) {
          final (dr, dc) = _dirs[rnd.nextInt(_dirs.length)];
          final r0 = rnd.nextInt(size), c0 = rnd.nextInt(size);
          final rEnd = r0 + dr * (word.length - 1),
              cEnd = c0 + dc * (word.length - 1);
          if (rEnd < 0 || rEnd >= size || cEnd < 0 || cEnd >= size) continue;
          var fits = true;
          for (var i = 0; i < word.length; i++) {
            final cur = grid[r0 + dr * i][c0 + dc * i];
            if (cur.isNotEmpty && cur != word[i]) {
              fits = false;
              break;
            }
          }
          if (!fits) continue;
          for (var i = 0; i < word.length; i++) {
            grid[r0 + dr * i][c0 + dc * i] = word[i];
          }
          placed = true;
        }
        if (!placed) {
          ok = false;
          break;
        }
      }
      if (!ok) continue;
      for (final row in grid) {
        for (var c = 0; c < size; c++) {
          if (row[c].isEmpty) row[c] = _alphabet[rnd.nextInt(_alphabet.length)];
        }
      }
      return WordGrid._(size, grid, words);
    }
  }

  /// Celdas en línea recta entre [a] y [b], o `null` si no es una línea
  /// horizontal, vertical o diagonal.
  static List<Cell>? line(Cell a, Cell b) {
    final dr = b.$1 - a.$1, dc = b.$2 - a.$2;
    if (dr != 0 && dc != 0 && dr.abs() != dc.abs()) return null;
    final steps = math.max(dr.abs(), dc.abs());
    final sr = dr.sign, sc = dc.sign;
    return [for (var i = 0; i <= steps; i++) (a.$1 + sr * i, a.$2 + sc * i)];
  }

  String read(List<Cell> cells) => cells.map((c) => letters[c.$1][c.$2]).join();

  /// Palabra que coincide con la selección (en cualquier sentido).
  String? match(List<Cell> cells, Set<String> found) {
    final s = read(cells);
    final rev = s.split('').reversed.join();
    for (final w in words) {
      if (!found.contains(w) && (w == s || w == rev)) return w;
    }
    return null;
  }
}

class _Found {
  _Found(this.word, this.cells, this.color);
  final String word;
  final List<Cell> cells;
  final Color color;
}

/// Minijuego "Encuentra Palabras".
class WordSearchGame extends ConsumerStatefulWidget {
  const WordSearchGame({super.key});

  /// Listas de palabras; cada partida usa una al azar. Las dos primeras
  /// vienen de las sopas de letras del periódico del Taller UA II (2026).
  static const wordSets = [
    ['TEBAIDA', 'TALUDES', 'MEMORIA', 'URBANO', 'SAUCE', 'LLUVIA'],
    ['RIBERA', 'ALISO', 'CAUCE', 'PUENTES', 'LIMPIEZA', 'ZAMORA'],
    ['AGUA', 'SAUCE', 'ZAMORA', 'TRUCHA', 'LLUVIA', 'ORILLA'],
  ];

  @override
  ConsumerState<WordSearchGame> createState() => _WordSearchGameState();
}

class _WordSearchGameState extends ConsumerState<WordSearchGame> {
  static const _size = 9;
  static const _seconds = 180;

  static const _wordCount = 6;
  static const _colors = [
    Color(0xFF38B7EE),
    Color(0xFF4CC371),
    Color(0xFFF6CF4E),
    Color(0xFFB98AF5),
    Color(0xFFFF8FA3),
    Color(0xFF48C9A0),
  ];

  final game = gameById(GameId.palabras);
  final _rand = math.Random();

  bool _started = false;
  bool _over = false;
  late WordGrid _grid;
  List<String> _words = WordSearchGame.wordSets.first;
  final _found = <_Found>[];
  Cell? _anchor;
  List<Cell> _selection = [];
  int _left = _seconds;
  int _shake = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _started = true;
      _over = false;
      _words = WordSearchGame
          .wordSets[_rand.nextInt(WordSearchGame.wordSets.length)];
      _grid = WordGrid.generate(_words, _size, _rand);
      _found.clear();
      _selection = [];
      _left = _seconds;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _left--);
      if (_left <= 0) _end(false);
    });
  }

  Cell? _cellAt(Offset p, double cell) {
    final r = (p.dy / cell).floor(), c = (p.dx / cell).floor();
    if (r < 0 || c < 0 || r >= _size || c >= _size) return null;
    return (r, c);
  }

  void _panStart(Offset p, double cell) {
    final c = _cellAt(p, cell);
    if (c == null || _over) return;
    HapticFeedback.selectionClick();
    setState(() {
      _anchor = c;
      _selection = [c];
    });
  }

  void _panUpdate(Offset p, double cell) {
    final a = _anchor;
    final c = _cellAt(p, cell);
    if (a == null || c == null) return;
    final line = WordGrid.line(a, c);
    if (line != null && line.length != _selection.length) {
      HapticFeedback.selectionClick();
      setState(() => _selection = line);
    }
  }

  void _panEnd() {
    if (_selection.length > 1) {
      final word = _grid.match(_selection, {for (final f in _found) f.word});
      if (word != null) {
        HapticFeedback.mediumImpact();
        _found.add(
          _Found(word, _selection, _colors[_found.length % _colors.length]),
        );
        if (_found.length == _words.length) _end(true);
      } else {
        HapticFeedback.heavyImpact();
        _shake++;
      }
    }
    setState(() {
      _anchor = null;
      _selection = [];
    });
  }

  Future<void> _end(bool won) async {
    if (_over) return;
    _timer?.cancel();
    setState(() => _over = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    final again = await finishGame(
      context,
      ref,
      game: game,
      won: won,
      score: _found.length * 100 + _left,
      summary: won
          ? '¡Encontraste las ${_words.length} palabras con ${_left}s de sobra!'
          : 'Encontraste ${_found.length} de ${_words.length} palabras. ¡Inténtalo otra vez!',
    );
    if (!mounted) return;
    if (again) {
      _start();
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) {
      return GameScaffold(
        game: game,
        body: GameIntro(
          game: game,
          onStart: _start,
          instructions: [
            'Hay $_wordCount palabras del río escondidas en la sopa de letras.',
            'Arrastra el dedo en línea recta: horizontal, vertical o diagonal.',
            'Encuéntralas todas antes de que se acabe el tiempo.',
          ],
        ),
      );
    }
    final t = Theme.of(context).textTheme;
    final foundWords = {for (final f in _found) f.word};
    return GameScaffold(
      game: game,
      inProgress: !_over,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          GameHud(
            seconds: _left,
            progress: '${_found.length}/${_words.length}',
            progressIcon: Icons.spellcheck_rounded,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (i, w) in _words.indexed)
                AnimatedContainer(
                  duration: AppMotion.of(context, AppMotion.medium),
                  curve: AppMotion.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: foundWords.contains(w)
                        ? _colors[i % _colors.length].withValues(alpha: 0.25)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: foundWords.contains(w)
                          ? _colors[i % _colors.length]
                          : AppColors.outline,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (foundWords.contains(w)) ...[
                        Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: AppColors.greenDeep,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        w,
                        style: t.labelMedium?.copyWith(
                          color: AppColors.ink,
                          letterSpacing: 1,
                          decoration: foundWords.contains(w)
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Shake(
            trigger: _shake,
            child: AppCard(
              padding: const EdgeInsets.all(10),
              child: AspectRatio(
                aspectRatio: 1,
                child: LayoutBuilder(
                  builder: (context, c) {
                    final cell = c.maxWidth / _size;
                    return GestureDetector(
                      onPanStart: (d) => _panStart(d.localPosition, cell),
                      onPanUpdate: (d) => _panUpdate(d.localPosition, cell),
                      onPanEnd: (_) => _panEnd(),
                      onPanCancel: _panEnd,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _HighlightPainter(
                                cell: cell,
                                found: _found,
                                selection: _selection,
                              ),
                            ),
                          ),
                          for (var r = 0; r < _size; r++)
                            for (var col = 0; col < _size; col++)
                              Positioned(
                                left: col * cell,
                                top: r * cell,
                                width: cell,
                                height: cell,
                                child: Center(
                                  child: AnimatedScale(
                                    scale: _selection.contains((r, col))
                                        ? 1.2
                                        : 1,
                                    duration: AppMotion.of(
                                      context,
                                      const Duration(milliseconds: 100),
                                    ),
                                    child: Text(
                                      _grid.letters[r][col],
                                      style: t.titleMedium?.copyWith(
                                        fontSize: cell * 0.46,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          RioSays(
            mood: _found.isEmpty ? MascotMood.thinking : MascotMood.happy,
            message: _found.isEmpty
                ? '¡Pista! Algunas palabras están en diagonal o al revés.'
                : '¡Encontraste “${_found.last.word}”! Sigue buscando.',
          ),
        ],
      ),
    );
  }
}

class _HighlightPainter extends CustomPainter {
  _HighlightPainter({
    required this.cell,
    required this.found,
    required this.selection,
  });

  final double cell;
  final List<_Found> found;
  final List<Cell> selection;

  Offset _center(Cell c) => Offset((c.$2 + 0.5) * cell, (c.$1 + 0.5) * cell);

  void _capsule(Canvas canvas, List<Cell> cells, Color color) {
    if (cells.isEmpty) return;
    canvas.drawLine(
      _center(cells.first),
      _center(cells.last),
      Paint()
        ..color = color
        ..strokeWidth = cell * 0.8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final f in found) {
      _capsule(canvas, f.cells, f.color.withValues(alpha: 0.45));
    }
    _capsule(canvas, selection, AppColors.cyan.withValues(alpha: 0.4));
  }

  @override
  bool shouldRepaint(_HighlightPainter old) => true;
}
