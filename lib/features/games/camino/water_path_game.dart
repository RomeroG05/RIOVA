import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/mascot/rio_mascot.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/chunky_button.dart';
import '../../../data/content/game_content.dart';
import '../common/game_scaffold.dart';

// Conexiones de cada pieza como máscara de bits.
const _n = 1, _e = 2, _s = 4, _w = 8;

int rotateMask(int m, int turns) {
  var r = m;
  for (var i = 0; i < turns % 4; i++) {
    r = ((r << 1) | (r >> 3)) & 15;
  }
  return r;
}

/// Tablero del rompecabezas. Lógica pura, sin Flutter: fácil de testear.
class PipeBoard {
  PipeBoard._(this.size, this.base, this.turns);

  final int size;

  /// Forma de cada pieza sin rotar.
  final List<int> base;

  /// Cuartos de vuelta aplicados (acumulativos, para animar siempre en
  /// sentido horario).
  final List<int> turns;

  int mask(int i) => rotateMask(base[i], turns[i]);

  /// Genera un tablero con solución garantizada: primero traza un camino
  /// aleatorio de la esquina superior izquierda a la inferior derecha,
  /// asigna las piezas que ese camino necesita, rellena el resto y por
  /// último gira todo al azar.
  factory PipeBoard.generate(int size, math.Random rnd) {
    final total = size * size;
    final path = <int>[];
    final seen = <int>{};

    bool dfs(int cell) {
      path.add(cell);
      seen.add(cell);
      if (cell == total - 1) return true;
      final r = cell ~/ size, c = cell % size;
      final next = <int>[
        if (r > 0) cell - size,
        if (c < size - 1) cell + 1,
        if (r < size - 1) cell + size,
        if (c > 0) cell - 1,
      ]..shuffle(rnd);
      for (final nx in next) {
        if (!seen.contains(nx) && dfs(nx)) return true;
      }
      path.removeLast();
      return false;
    }

    dfs(0);

    final solved = List<int>.filled(total, 0);
    for (var i = 0; i < path.length; i++) {
      final cell = path[i];
      var m = 0;
      if (i == 0) m |= _n; // entra desde el nacimiento
      if (i == path.length - 1) m |= _s; // sale hacia el río
      for (final other in [
        if (i > 0) path[i - 1],
        if (i < path.length - 1) path[i + 1],
      ]) {
        final d = other - cell;
        if (d == -size) m |= _n;
        if (d == size) m |= _s;
        if (d == 1) m |= _e;
        if (d == -1) m |= _w;
      }
      solved[cell] = m;
    }
    const fillers = [_n | _s, _n | _e, _n | _e | _s];
    for (var i = 0; i < total; i++) {
      if (solved[i] == 0) {
        solved[i] = rotateMask(
          fillers[rnd.nextInt(fillers.length)],
          rnd.nextInt(4),
        );
      }
    }

    final turns = List<int>.generate(total, (_) => rnd.nextInt(4));
    final board = PipeBoard._(size, solved, turns);
    if (board.isSolved) {
      board.turns[0] += 1;
    }
    return board;
  }

  void rotate(int i) => turns[i]++;

  /// Celdas con agua (recorrido desde el nacimiento) y su distancia.
  Map<int, int> flow() {
    final result = <int, int>{};
    if (mask(0) & _n == 0) return result;
    final queue = <int>[0];
    result[0] = 0;
    while (queue.isNotEmpty) {
      final cell = queue.removeAt(0);
      final m = mask(cell);
      final r = cell ~/ size, c = cell % size;
      void tryGo(int bit, int opposite, bool ok, int nx) {
        if (!ok || m & bit == 0 || result.containsKey(nx)) return;
        if (mask(nx) & opposite == 0) return;
        result[nx] = result[cell]! + 1;
        queue.add(nx);
      }

      tryGo(_n, _s, r > 0, cell - size);
      tryGo(_s, _n, r < size - 1, cell + size);
      tryGo(_e, _w, c < size - 1, cell + 1);
      tryGo(_w, _e, c > 0, cell - 1);
    }
    return result;
  }

  bool get isSolved {
    final f = flow();
    final last = size * size - 1;
    return f.containsKey(last) && mask(last) & _s != 0;
  }
}

/// Minijuego "El Camino del Agua".
class WaterPathGame extends ConsumerStatefulWidget {
  const WaterPathGame({super.key});

  @override
  ConsumerState<WaterPathGame> createState() => _WaterPathGameState();
}

class _WaterPathGameState extends ConsumerState<WaterPathGame> {
  static const _sizes = [4, 5, 5];
  final game = gameById(GameId.camino);
  final _rand = math.Random();

  bool _started = false;
  int _level = 0;
  int _moves = 0;
  int _stars = 0;
  bool _levelDone = false;
  late PipeBoard _board;

  void _start() {
    setState(() {
      _started = true;
      _level = 0;
      _stars = 0;
      _newBoard();
    });
  }

  void _newBoard() {
    _board = PipeBoard.generate(_sizes[_level], _rand);
    _moves = 0;
    _levelDone = false;
  }

  void _rotate(int i) {
    if (_levelDone) return;
    HapticFeedback.selectionClick();
    setState(() {
      _board.rotate(i);
      _moves++;
    });
    if (_board.isSolved) {
      HapticFeedback.mediumImpact();
      final n = _board.size * _board.size;
      final stars = _moves <= n
          ? 3
          : _moves <= n * 1.6
          ? 2
          : 1;
      setState(() {
        _levelDone = true;
        _stars += stars;
      });
    }
  }

  Future<void> _next() async {
    if (_level < _sizes.length - 1) {
      setState(() {
        _level++;
        _newBoard();
      });
      return;
    }
    final again = await finishGame(
      context,
      ref,
      game: game,
      won: true,
      score: _stars,
      summary:
          'Llevaste el agua limpia hasta el río Zamora en los 3 niveles. Estrellas: $_stars de 9.',
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
            'El agua nace en la montaña (arriba a la izquierda).',
            'Toca las piezas para girarlas y formar un canal continuo.',
            'Lleva el agua hasta el río Zamora (abajo a la derecha). ¡Hay 3 niveles!',
          ],
        ),
      );
    }

    final t = Theme.of(context).textTheme;
    final flow = _board.flow();
    final maxDist = flow.values.fold<int>(0, math.max);
    return GameScaffold(
      game: game,
      inProgress: !_levelDone || _level < _sizes.length - 1,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          GameHud(
            progress: 'Nivel ${_level + 1}/${_sizes.length}',
            progressIcon: Icons.layers_outlined,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const RioMascot(size: 44, interactive: false),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _levelDone
                      ? '¡El agua llegó al río! 🎉'
                      : 'Movimientos: $_moves  •  Gira las piezas',
                  style: t.titleSmall,
                ),
              ),
              Text('⭐ $_stars', style: t.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          // Nacimiento
          Row(
            children: [
              _Endpoint(
                icon: Icons.landscape_rounded,
                label: 'Nacimiento',
                color: AppColors.greenDeep,
                active: true,
              ),
            ],
          ),
          AppCard(
            padding: const EdgeInsets.all(8),
            color: const Color(0xFF9ED39F),
            child: AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _board.size,
                ),
                itemCount: _board.size * _board.size,
                itemBuilder: (context, i) => _PipeTile(
                  base: _board.base[i],
                  turns: _board.turns[i],
                  wet: flow.containsKey(i),
                  delay: maxDist == 0 ? 0 : (flow[i] ?? 0) / maxDist,
                  source: i == 0,
                  onTap: () => _rotate(i),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _Endpoint(
                icon: Icons.water_rounded,
                label: 'Río Zamora',
                color: AppColors.zamora,
                active: _levelDone,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.medium),
            child: _levelDone
                ? ChunkyButton(
                    key: const ValueKey('next'),
                    label: _level < _sizes.length - 1
                        ? 'Siguiente nivel'
                        : '¡Terminar misión!',
                    tone: ChunkyTone.green,
                    trailing: Icons.arrow_forward_rounded,
                    onPressed: _next,
                  )
                : ChunkyButton(
                    key: const ValueKey('reset'),
                    label: 'Nuevo tablero',
                    tone: ChunkyTone.soft,
                    leading: Icons.shuffle_rounded,
                    onPressed: () => setState(_newBoard),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Endpoint extends StatelessWidget {
  const _Endpoint({
    required this.icon,
    required this.label,
    required this.color,
    required this.active,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.medium),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color : AppColors.surfaceBlue,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: active ? Colors.white : AppColors.inkSoft,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: active ? Colors.white : AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

class _PipeTile extends StatelessWidget {
  const _PipeTile({
    required this.base,
    required this.turns,
    required this.wet,
    required this.delay,
    required this.source,
    required this.onTap,
  });

  final int base;
  final int turns;
  final bool wet;
  final double delay;
  final bool source;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: wet ? 'Pieza con agua' : 'Pieza seca',
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: AnimatedRotation(
            turns: turns / 4,
            duration: AppMotion.of(context, AppMotion.fast),
            curve: AppMotion.easeOut,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: wet ? 1 : 0),
              // El agua avanza pieza por pieza según su distancia.
              duration: AppMotion.of(
                context,
                Duration(milliseconds: 220 + (delay * 360).round()),
              ),
              curve: AppMotion.easeOut,
              builder: (context, w, _) =>
                  CustomPaint(painter: _PipePainter(base, w, source)),
            ),
          ),
        ),
      ),
    );
  }
}

class _PipePainter extends CustomPainter {
  _PipePainter(this.mask, this.wet, this.source);

  final int mask;
  final double wet;
  final bool source;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(10),
    );
    canvas.drawRRect(r, Paint()..color = const Color(0xFF7FC781));
    canvas.drawCircle(
      size.center(Offset.zero).translate(-size.width * 0.3, -size.height * 0.3),
      3,
      Paint()..color = const Color(0xFF6AB66E),
    );

    final c = size.center(Offset.zero);
    final width = size.width * 0.34;
    final channel = Paint()
      ..color = const Color(0xFFD9C08E)
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    final water = Paint()
      ..color = Color.lerp(const Color(0xFFD9C08E), AppColors.cyan, wet)!
      ..strokeWidth = width * 0.62
      ..strokeCap = StrokeCap.round;
    final ends = <Offset>[
      if (mask & _n != 0) Offset(c.dx, 0),
      if (mask & _e != 0) Offset(size.width, c.dy),
      if (mask & _s != 0) Offset(c.dx, size.height),
      if (mask & _w != 0) Offset(0, c.dy),
    ];
    for (final e in ends) {
      canvas.drawLine(c, e, channel);
    }
    for (final e in ends) {
      canvas.drawLine(c, e, water);
    }
    if (wet > 0.5) {
      canvas.drawCircle(
        c.translate(-width * 0.12, -width * 0.12),
        width * 0.1,
        Paint()..color = Colors.white.withValues(alpha: 0.7),
      );
    }
    if (source) {
      canvas.drawCircle(c, width * 0.42, Paint()..color = AppColors.blue);
    }
  }

  @override
  bool shouldRepaint(_PipePainter old) => old.mask != mask || old.wet != wet;
}
