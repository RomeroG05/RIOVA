import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/mascot/rio_mascot.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../../data/content/game_content.dart';
import '../common/game_scaffold.dart';

enum _Phase { intro, playing, over }

class _Item {
  _Item({
    required this.id,
    required this.emoji,
    required this.trash,
    required this.baseX,
    required this.speed,
    required this.phase,
  });

  final int id;
  final String emoji;
  final bool trash;
  final double baseX;
  final double speed;
  final double phase;
  double y = -40;
  double x = 0;

  /// `null` mientras flota; 0→1 durante la animación de recogida.
  double? pop;
}

/// Minijuego "Rescata el Río".
class RescueRiverGame extends ConsumerStatefulWidget {
  const RescueRiverGame({super.key});

  @override
  ConsumerState<RescueRiverGame> createState() => _RescueRiverGameState();
}

class _RescueRiverGameState extends ConsumerState<RescueRiverGame>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _duration = 60.0;
  static const _goal = 20;
  static const _trash = ['🥤', '🛍️', '🥫', '🧃', '👟', '🍾', '📦'];
  static const _animals = ['🐟', '🦆', '🐸', '🐢'];

  final game = gameById(GameId.rescata);
  final _rand = math.Random();
  late final Ticker _ticker = createTicker(_tick);

  _Phase _phase = _Phase.intro;
  bool _paused = false;
  Duration _last = Duration.zero;
  double _time = _duration;
  double _clock = 0;
  double _spawnIn = 0.4;
  int _nextId = 0;
  int _collected = 0;
  int _missed = 0;
  int _lives = 3;
  int _hurt = 0;
  final _items = <_Item>[];
  Size _area = Size.zero;

  double get _cleanliness =>
      (_collected / _goal - _missed * 0.04).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _phase == _Phase.playing) {
      setState(() => _paused = true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _phase = _Phase.playing;
      _paused = false;
      _time = _duration;
      _clock = 0;
      _spawnIn = 0.4;
      _collected = 0;
      _missed = 0;
      _lives = 3;
      _items.clear();
    });
    _last = Duration.zero;
    if (!_ticker.isActive) _ticker.start();
  }

  void _spawn() {
    final trash = _rand.nextDouble() < 0.74;
    final list = trash ? _trash : _animals;
    // A más tiempo, más rápido fluye el río.
    final speedUp = 1 + (_clock / _duration) * 0.8;
    _items.add(
      _Item(
        id: _nextId++,
        emoji: list[_rand.nextInt(list.length)],
        trash: trash,
        baseX: 0.22 + _rand.nextDouble() * 0.56,
        speed: (70 + _rand.nextDouble() * 60) * speedUp,
        phase: _rand.nextDouble() * math.pi * 2,
      ),
    );
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 0.0
        : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (_paused || _phase != _Phase.playing || _area == Size.zero) return;

    _clock += dt;
    _time -= dt;
    _spawnIn -= dt;
    if (_spawnIn <= 0) {
      _spawn();
      _spawnIn = math.max(0.5, 1.1 - _clock / _duration * 0.6);
    }

    for (final it in _items) {
      if (it.pop != null) {
        it.pop = it.pop! + dt * 3.2;
        continue;
      }
      it.y += it.speed * dt;
      it.x = it.baseX + math.sin(it.phase + _clock * 1.8) * 0.035;
    }
    _items.removeWhere((it) {
      if (it.pop != null) return it.pop! >= 1;
      if (it.y > _area.height + 30) {
        if (it.trash) _missed++;
        return true;
      }
      return false;
    });

    setState(() {});
    if (_time <= 0 || _collected >= _goal) _end();
  }

  void _tap(_Item it) {
    if (_paused || it.pop != null || _phase != _Phase.playing) return;
    if (it.trash) {
      HapticFeedback.lightImpact();
      setState(() {
        it.pop = 0;
        _collected++;
      });
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        it.pop = 0;
        _lives--;
        _hurt++;
      });
      if (_lives <= 0) _end();
    }
  }

  Future<void> _end() async {
    if (_phase == _Phase.over) return;
    _ticker.stop();
    setState(() => _phase = _Phase.over);
    final won = _collected >= _goal;
    final again = await finishGame(
      context,
      ref,
      game: game,
      won: won,
      score: _collected,
      summary: won
          ? 'Recogiste $_collected residuos y el río Malacatos vuelve a brillar.'
          : 'Recogiste $_collected de $_goal residuos. ¡Cuidado con los animalitos!',
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
    final t = Theme.of(context).textTheme;
    if (_phase == _Phase.intro) {
      return GameScaffold(
        game: game,
        body: GameIntro(
          game: game,
          onStart: _start,
          instructions: const [
            'La basura baja flotando por el río Malacatos.',
            'Toca la basura para recogerla. Necesitas $_goal en 60 segundos.',
            '¡No toques a los peces, patos, ranas ni tortugas! Pierdes una vida.',
          ],
        ),
      );
    }

    return GameScaffold(
      game: game,
      inProgress: _phase == _Phase.playing,
      onPauseChanged: (p) => setState(() => _paused = p),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Shake(
              trigger: _hurt,
              child: GameHud(
                paused: _paused,
                onPause: () => setState(() => _paused = !_paused),
                seconds: _time.ceil().clamp(0, 999),
                lives: _lives,
                progress: '$_collected/$_goal',
                progressIcon: Icons.delete_outline_rounded,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('Río limpio', style: t.labelMedium),
                const SizedBox(width: 10),
                Expanded(
                  child: ProgressBar(
                    value: _cleanliness,
                    colors: const [AppColors.cyan, AppColors.green],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(_cleanliness * 100).round()}%',
                  style: t.titleSmall?.copyWith(color: AppColors.teal),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: LayoutBuilder(
                  builder: (context, c) {
                    _area = c.biggest;
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _RiverPainter(_cleanliness, _clock),
                          ),
                        ),
                        for (final it in _items) _buildItem(it, c.maxWidth),
                        if (_paused)
                          Positioned.fill(
                            child: ColoredBox(
                              color: const Color(0x990B2236),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const RioMascot(
                                      size: 80,
                                      mood: MascotMood.thinking,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Pausa',
                                      style: t.headlineSmall?.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          setState(() => _paused = false),
                                      child: const Text(
                                        'Continuar',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(_Item it, double width) {
    final pop = it.pop;
    final scale = pop == null ? 1.0 : 1 + pop * 0.5;
    final opacity = pop == null ? 1.0 : (1 - pop).clamp(0.0, 1.0);
    return Positioned(
      key: ValueKey(it.id),
      left: it.x * width - 30,
      top: it.y - 30,
      width: 60,
      height: 60,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _tap(it),
        child: Opacity(
          opacity: opacity,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Transform.rotate(
                angle: math.sin(it.phase + it.y / 60) * 0.25,
                child: Transform.scale(
                  scale: scale,
                  child: Text(it.emoji, style: const TextStyle(fontSize: 36)),
                ),
              ),
              if (pop != null)
                Positioned(
                  top: -10 - pop * 30,
                  child: Text(
                    it.trash ? '+1' : '¡Ay!',
                    style: TextStyle(
                      fontFamily: 'Quicksand',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: it.trash ? AppColors.greenDeep : AppColors.red,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Río visto desde arriba: orillas con pasto y sauces, agua que fluye
/// hacia abajo y cambia de turbia a cristalina.
class _RiverPainter extends CustomPainter {
  _RiverPainter(this.clean, this.clock);

  final double clean;
  final double clock;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final grass = Color.lerp(
      const Color(0xFFB5B07A),
      const Color(0xFF7FCB86),
      clean,
    )!;
    canvas.drawRect(Offset.zero & size, Paint()..color = grass);

    final water = Color.lerp(
      const Color(0xFF8D9B6A),
      const Color(0xFF3FBDEB),
      clean,
    )!;
    final river = Path()..moveTo(w * 0.16, 0);
    for (var y = 0.0; y <= h; y += 20) {
      river.lineTo(w * 0.16 + math.sin(y / 70) * 8, y);
    }
    for (var y = h; y >= 0; y -= 20) {
      river.lineTo(w * 0.84 + math.sin(y / 70 + 1) * 8, y);
    }
    river.close();
    canvas.drawPath(river, Paint()..color = water);

    // Corriente: rayas que bajan.
    final ripple = Paint()
      ..color = Colors.white.withValues(alpha: 0.18 + clean * 0.3)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final offset = (clock * 90) % 80;
    for (var y = -80.0 + offset; y < h; y += 80) {
      for (var i = 0; i < 4; i++) {
        final x = w * (0.26 + i * 0.16);
        final yy = y + (i.isEven ? 0 : 36);
        canvas.drawLine(Offset(x, yy), Offset(x, yy + 22), ripple);
      }
    }

    // Manchas de contaminación que desaparecen al limpiar.
    if (clean < 0.9) {
      final oil = Paint()
        ..color = const Color(0xFF5C5A3A).withValues(alpha: 0.35 * (1 - clean));
      final rnd = math.Random(5);
      for (var i = 0; i < 6; i++) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(
              w * (0.25 + rnd.nextDouble() * 0.5),
              (rnd.nextDouble() * h + clock * 40) % h,
            ),
            width: 50,
            height: 22,
          ),
          oil,
        );
      }
    }

    // Sauces en las orillas.
    final crown = Paint()
      ..color = Color.lerp(
        const Color(0xFF8E9E5A),
        const Color(0xFF3F9A4D),
        clean,
      )!;
    final light = Paint()
      ..color = Color.lerp(
        const Color(0xFFA9B472),
        const Color(0xFF67BF68),
        clean,
      )!;
    for (var i = 0; i < 6; i++) {
      final y = h * (i / 5);
      for (final x in [w * 0.04, w * 0.96]) {
        canvas.drawCircle(Offset(x, y + (x < w / 2 ? 0 : 40)), 26, crown);
        canvas.drawCircle(
          Offset(x - 6, y - 6 + (x < w / 2 ? 0 : 40)),
          14,
          light,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RiverPainter old) =>
      old.clean != clean || old.clock != clock;
}
