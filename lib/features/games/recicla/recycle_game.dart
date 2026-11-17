import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/mascot/rio_mascot.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../../data/content/game_content.dart';
import '../common/game_scaffold.dart';

enum Bin {
  organico('Orgánicos', '🍂', Color(0xFF4CC371), Color(0xFF2B8A4A)),
  plastico('Plásticos', '🥤', Color(0xFFF6CF4E), Color(0xFFB8860B)),
  papel('Papel y cartón', '📦', Color(0xFF5B8DEF), Color(0xFF0B57B8)),
  vidrio('Vidrio', '🍾', Color(0xFF48C9A0), Color(0xFF137A5C));

  const Bin(this.label, this.emoji, this.color, this.dark);
  final String label;
  final String emoji;
  final Color color;
  final Color dark;
}

@immutable
class Waste {
  const Waste(this.emoji, this.name, this.bin);
  final String emoji;
  final String name;
  final Bin bin;
}

const wastePool = <Waste>[
  Waste('🍌', 'Cáscara de guineo', Bin.organico),
  Waste('🍎', 'Manzana mordida', Bin.organico),
  Waste('🍂', 'Hojas secas', Bin.organico),
  Waste('🥚', 'Cáscaras de huevo', Bin.organico),
  Waste('🌽', 'Tusa de choclo', Bin.organico),
  Waste('🥤', 'Vaso plástico', Bin.plastico),
  Waste('🧴', 'Botella de shampoo', Bin.plastico),
  Waste('🛍️', 'Funda plástica', Bin.plastico),
  Waste('🥡', 'Tarrina plástica', Bin.plastico),
  Waste('📰', 'Periódico', Bin.papel),
  Waste('📦', 'Caja de cartón', Bin.papel),
  Waste('📄', 'Hoja de cuaderno', Bin.papel),
  Waste('✉️', 'Sobre de papel', Bin.papel),
  Waste('🍾', 'Botella de vidrio', Bin.vidrio),
  Waste('🫙', 'Frasco de vidrio', Bin.vidrio),
  Waste('🥛', 'Vaso de vidrio', Bin.vidrio),
];

/// Minijuego "Recicla en la Orilla": arrastrar residuos al tacho correcto.
class RecycleGame extends ConsumerStatefulWidget {
  const RecycleGame({super.key});

  @override
  ConsumerState<RecycleGame> createState() => _RecycleGameState();
}

class _RecycleGameState extends ConsumerState<RecycleGame> {
  static const _total = 12;
  static const _seconds = 75;

  final game = gameById(GameId.recicla);
  final _rand = math.Random();

  bool _started = false;
  bool _over = false;
  bool _paused = false;
  List<Waste> _queue = [];
  int _sorted = 0;
  int _lives = 3;
  int _left = _seconds;
  int _shake = 0;
  Bin? _bounce;
  int _bounceTick = 0;
  String? _hint;
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
      _paused = false;
      _queue = ([...wastePool]..shuffle(_rand)).take(_total).toList();
      _sorted = 0;
      _lives = 3;
      _left = _seconds;
      _hint = null;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused || _over) return;
      setState(() => _left--);
      if (_left <= 0) _end(false);
    });
  }

  void _drop(Waste w, Bin bin) {
    if (_over || _queue.isEmpty) return;
    if (w.bin == bin) {
      HapticFeedback.mediumImpact();
      setState(() {
        _queue.removeAt(0);
        _sorted++;
        _bounce = bin;
        _bounceTick++;
        _hint = '¡Bien! ${w.name} va en ${bin.label}.';
      });
      if (_queue.isEmpty) _end(true);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _lives--;
        _shake++;
        _hint = '¡Ups! ${w.name} no va en ${bin.label}.';
      });
      if (_lives <= 0) _end(false);
    }
  }

  Future<void> _end(bool won) async {
    if (_over) return;
    _timer?.cancel();
    setState(() => _over = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    final again = await finishGame(
      context,
      ref,
      game: game,
      won: won,
      score: _sorted * 10 + _left,
      summary: won
          ? '¡Clasificaste los $_total residuos! La orilla quedó limpia y el río te lo agradece.'
          : 'Clasificaste $_sorted de $_total residuos. ¡Recuerda: separar la basura evita que llegue al río!',
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
            'Aparecen residuos que alguien dejó junto al río.',
            'Arrástralos con el dedo hasta el tacho correcto: orgánicos, plásticos, papel o vidrio.',
            'Clasifica $_total antes de que se acabe el tiempo. ¡Cada error cuesta una vida!',
          ],
        ),
      );
    }
    final t = Theme.of(context).textTheme;
    final current = _queue.isEmpty ? null : _queue.first;
    return GameScaffold(
      game: game,
      inProgress: !_over,
      onPauseChanged: (p) => setState(() => _paused = p),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: GameHud(
              seconds: _left,
              lives: _lives,
              paused: _paused,
              onPause: () => setState(() => _paused = !_paused),
              progress: '$_sorted/$_total',
              progressIcon: Icons.recycling_rounded,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ProgressBar(
              value: _sorted / _total,
              colors: const [AppColors.green, AppColors.cyan],
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Orilla del río de fondo.
                Positioned.fill(
                  child: CustomPaint(painter: _ShorePainter(_sorted / _total)),
                ),
                if (current != null && !_paused)
                  Draggable<Waste>(
                    key: ValueKey('${current.name}-$_sorted'),
                    data: current,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Transform.scale(
                        scale: 1.15,
                        child: _WasteChip(w: current, lifted: true),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.25,
                      child: _WasteChip(w: current),
                    ),
                    onDragStarted: HapticFeedback.selectionClick,
                    child: EntranceFade(child: _WasteChip(w: current)),
                  ),
                if (_paused) Text('Pausa', style: t.headlineSmall),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 12,
                  child: SequentialSwap(
                    duration: AppMotion.medium,
                    child: _hint == null
                        ? const RioSays(
                            message: '¡Arrastra cada residuo a su tacho!',
                            key: ValueKey('h0'),
                          )
                        : RioSays(
                            key: ValueKey(_hint),
                            message: _hint!,
                            mood: _hint!.startsWith('¡Bien')
                                ? MascotMood.cheer
                                : MascotMood.sad,
                          ),
                  ),
                ),
              ],
            ),
          ),
          Shake(
            trigger: _shake,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
              child: Row(
                children: [
                  for (final bin in Bin.values)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: DragTarget<Waste>(
                          onWillAcceptWithDetails: (_) => true,
                          onAcceptWithDetails: (d) => _drop(d.data, bin),
                          builder: (context, candidates, _) => _BinView(
                            bin: bin,
                            hovering: candidates.isNotEmpty,
                            bounce: _bounce == bin ? _bounceTick : 0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WasteChip extends StatelessWidget {
  const _WasteChip({required this.w, this.lifted = false});

  final Waste w;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0x330B2236),
            blurRadius: lifted ? 24 : 12,
            offset: Offset(0, lifted ? 12 : 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(w.emoji, style: const TextStyle(fontSize: 54)),
          const SizedBox(height: 6),
          Text(
            w.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

class _BinView extends StatelessWidget {
  const _BinView({
    required this.bin,
    required this.hovering,
    required this.bounce,
  });

  final Bin bin;
  final bool hovering;
  final int bounce;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return TweenAnimationBuilder<double>(
      // Rebote corto cada vez que recibe un residuo correcto.
      key: ValueKey(bounce),
      tween: Tween(begin: bounce == 0 ? 1 : 1.18, end: 1),
      duration: AppMotion.of(context, const Duration(milliseconds: 420)),
      curve: AppMotion.playful,
      builder: (context, s, child) => Transform.scale(scale: s, child: child),
      child: AnimatedScale(
        scale: hovering ? 1.08 : 1,
        duration: AppMotion.of(context, AppMotion.fast),
        curve: AppMotion.easeOut,
        child: Container(
          height: 118,
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
          decoration: BoxDecoration(
            color: bin.color,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(14),
              bottom: Radius.circular(22),
            ),
            border: Border(bottom: BorderSide(color: bin.dark, width: 6)),
            boxShadow: hovering
                ? [
                    BoxShadow(
                      color: bin.color.withValues(alpha: 0.6),
                      blurRadius: 18,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 6,
                width: 40,
                decoration: BoxDecoration(
                  color: bin.dark,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Text(bin.emoji, style: const TextStyle(fontSize: 30)),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  bin.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: t.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
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

/// Orilla con pasto y el río abajo; el agua se aclara al reciclar.
class _ShorePainter extends CustomPainter {
  _ShorePainter(this.clean);
  final double clean;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEAF6EC),
    );
    final water = Color.lerp(
      const Color(0xFF9AA77A),
      const Color(0xFF47C0EA),
      clean,
    )!;
    final river = Path()
      ..moveTo(0, h * 0.78)
      ..quadraticBezierTo(w * 0.5, h * 0.7, w, h * 0.8)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(river, Paint()..color = water.withValues(alpha: 0.55));
    final grass = Paint()..color = const Color(0xFFBFE5C6);
    for (var i = 0; i < 9; i++) {
      canvas.drawCircle(Offset(w * (i / 8), h * 0.74), 22, grass);
    }
  }

  @override
  bool shouldRepaint(_ShorePainter old) => old.clean != clean;
}
