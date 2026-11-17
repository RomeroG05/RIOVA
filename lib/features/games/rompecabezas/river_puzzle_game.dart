import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/chunky_button.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../../core/widgets/pressable.dart';
import '../../../data/content/game_content.dart';
import '../../../data/content/places_content.dart';
import '../../../data/models/place.dart';
import '../common/game_scaffold.dart';

/// Tablero del rompecabezas deslizante. `cells[pos]` = pieza que ocupa esa
/// posición; la pieza `n*n-1` es el hueco. Lógica pura, testeable.
class SlidePuzzle {
  SlidePuzzle._(this.n, this.cells);

  final int n;
  final List<int> cells;

  int get blank => n * n - 1;
  int get blankPos => cells.indexOf(blank);
  bool get isSolved {
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] != i) return false;
    }
    return true;
  }

  /// Mezcla con movimientos válidos desde el estado resuelto: siempre tiene
  /// solución (una permutación al azar podría no tenerla).
  factory SlidePuzzle.shuffled(int n, math.Random rnd, {int moves = 150}) {
    final p = SlidePuzzle._(n, List.generate(n * n, (i) => i));
    var last = -1;
    for (var k = 0; k < moves || p.isSolved; k++) {
      final options = p.movable().where((pos) => pos != last).toList();
      final pick = options[rnd.nextInt(options.length)];
      last = p.blankPos;
      p.move(pick);
    }
    return p;
  }

  /// Posiciones vecinas del hueco (las piezas que se pueden mover).
  List<int> movable() {
    final b = blankPos, r = b ~/ n, c = b % n;
    return [
      if (r > 0) b - n,
      if (r < n - 1) b + n,
      if (c > 0) b - 1,
      if (c < n - 1) b + 1,
    ];
  }

  /// Mueve la pieza de [pos] al hueco si es vecina. Devuelve si se movió.
  bool move(int pos) {
    if (!movable().contains(pos)) return false;
    final b = blankPos;
    cells[b] = cells[pos];
    cells[pos] = blank;
    return true;
  }

  int positionOf(int tile) => cells.indexOf(tile);
}

/// Minijuego "Rompecabezas del Río": fotos reales de los sectores.
class RiverPuzzleGame extends ConsumerStatefulWidget {
  const RiverPuzzleGame({super.key});

  @override
  ConsumerState<RiverPuzzleGame> createState() => _RiverPuzzleGameState();
}

class _RiverPuzzleGameState extends ConsumerState<RiverPuzzleGame> {
  static const _n = 3;

  final game = gameById(GameId.rompecabezas);
  final _rand = math.Random();

  bool _started = false;
  bool _solved = false;
  bool _peek = false;
  late SlidePuzzle _puzzle;
  late Place _place;
  late PlacePhoto _photo;
  int _moves = 0;
  int _seconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    final options = [
      for (final p in places)
        for (final ph in p.photos)
          if (!ph.drawing) (p, ph),
    ];
    final (place, photo) = options[_rand.nextInt(options.length)];
    setState(() {
      _started = true;
      _solved = false;
      _peek = false;
      _place = place;
      _photo = photo;
      _puzzle = SlidePuzzle.shuffled(_n, _rand);
      _moves = 0;
      _seconds = 0;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_solved) setState(() => _seconds++);
    });
  }

  void _tap(int pos) {
    if (_solved) return;
    if (_puzzle.move(pos)) {
      HapticFeedback.selectionClick();
      setState(() => _moves++);
      if (_puzzle.isSolved) _win();
    }
  }

  Future<void> _win() async {
    _timer?.cancel();
    HapticFeedback.mediumImpact();
    setState(() => _solved = true);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    final again = await finishGame(
      context,
      ref,
      game: game,
      won: true,
      score: math.max(10, 400 - _moves * 2 - _seconds),
      summary:
          'Armaste la foto de ${_place.shortName} en $_moves movimientos. ${_place.fact}',
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
          instructions: const [
            'Una foto real de un sector de Loja se rompió en 9 piezas.',
            'Toca una pieza junto al espacio vacío para deslizarla.',
            'Mantén presionado “Ver foto” si necesitas una pista.',
          ],
        ),
      );
    }
    final t = Theme.of(context).textTheme;
    return GameScaffold(
      game: game,
      inProgress: !_solved,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          GameHud(
            seconds: _seconds,
            countdown: false,
            progress: '$_moves mov.',
            progressIcon: Icons.touch_app_outlined,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('¿Qué lugar es?', style: t.titleMedium),
                    Text(
                      _solved
                          ? '${_place.code} • ${_place.name}'
                          : 'Pista: ${_place.zone.label} • río ${_place.river.shortLabel}',
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTapDown: (_) => setState(() => _peek = true),
                onTapUp: (_) => setState(() => _peek = false),
                onTapCancel: () => setState(() => _peek = false),
                child: Pill(
                  label: 'Ver foto',
                  icon: Icons.visibility_outlined,
                  color: AppColors.cyanSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, c) {
                final size = c.maxWidth;
                final tile = size / _n;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: ColoredBox(
                    color: const Color(0xFF0B2236),
                    child: Stack(
                      children: [
                        for (var id = 0; id < _n * _n; id++)
                          if (id != _puzzle.blank || _solved)
                            _tilePositioned(id, tile, size),
                        // Pista: la foto completa encima mientras se mantiene presionado.
                        IgnorePointer(
                          child: AnimatedOpacity(
                            opacity: _peek || _solved ? 1 : 0,
                            duration: AppMotion.of(context, AppMotion.medium),
                            curve: AppMotion.easeOut,
                            child: Image.asset(
                              _photo.asset,
                              fit: BoxFit.cover,
                              width: size,
                              height: size,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.medium),
            child: _solved
                ? EntranceFade(
                    key: const ValueKey('done'),
                    child: AppCard(
                      color: AppColors.mintSoft,
                      child: Text(
                        '¡Lo armaste! ${_photo.caption}.',
                        style: t.bodyMedium?.copyWith(color: AppColors.ink),
                      ),
                    ),
                  )
                : ChunkyButton(
                    key: const ValueKey('reset'),
                    label: 'Otra foto',
                    tone: ChunkyTone.soft,
                    leading: Icons.shuffle_rounded,
                    onPressed: _start,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tilePositioned(int id, double tile, double size) {
    final pos = _puzzle.positionOf(id);
    final r = pos ~/ _n, c = pos % _n;
    final hr = id ~/ _n, hc = id % _n; // parte de la foto que le toca
    return AnimatedPositioned(
      key: ValueKey(id),
      duration: AppMotion.of(context, const Duration(milliseconds: 170)),
      curve: AppMotion.easeOut,
      left: c * tile,
      top: r * tile,
      width: tile,
      height: tile,
      child: Pressable(
        haptic: false,
        scale: 0.96,
        onTap: () => _tap(pos),
        child: Padding(
          padding: EdgeInsets.all(_solved ? 0 : 1.5),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_solved ? 0 : 8),
            child: OverflowBox(
              maxWidth: size,
              maxHeight: size,
              alignment: Alignment(
                -1 + 2 * hc / (_n - 1),
                -1 + 2 * hr / (_n - 1),
              ),
              child: Image.asset(
                _photo.asset,
                fit: BoxFit.cover,
                width: size,
                height: size,
                cacheWidth: 900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
