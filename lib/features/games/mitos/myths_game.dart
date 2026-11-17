import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/mascot/rio_mascot.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/chunky_button.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../../data/content/game_content.dart';
import '../common/game_scaffold.dart';

/// Afirmación del juego "Mitos y Verdades" (inspirado en la sección
/// "Mitos y verdades del río Zamora" del periódico del Taller UA II).
@immutable
class MythCard {
  const MythCard(this.emoji, this.text, this.isTrue, this.why);
  final String emoji;
  final String text;
  final bool isTrue;
  final String why;
}

const mythDeck = <MythCard>[
  MythCard(
    '🌳',
    'La vegetación de la orilla ayuda a proteger el río.',
    true,
    'Las raíces sujetan la tierra y frenan la fuerza del agua.',
  ),
  MythCard(
    '🙅',
    'El río no necesita que las personas lo cuiden.',
    false,
    'Todo lo que tiramos en la ciudad termina en el río: cuidarlo es tarea de todos.',
  ),
  MythCard(
    '🤝',
    'Todos somos responsables de conservar el río Zamora.',
    true,
    'Vecinos, escuelas y autoridades: cada uno puede ayudar.',
  ),
  MythCard(
    '🧱',
    'Encerrar el río entre muros evita todas las inundaciones.',
    false,
    'Los muros le quitan espacio al río; con lluvias fuertes el agua sale con más fuerza.',
  ),
  MythCard(
    '🌉',
    'La basura que se atora bajo los puentes puede hacer que el río se desborde.',
    true,
    'Forma tapones, como pequeñas represas: el famoso “efecto represa”.',
  ),
  MythCard(
    '🐟',
    'Las truchas pueden vivir felices en agua sucia y caliente.',
    false,
    'Las truchas necesitan agua fría, limpia y con mucho oxígeno.',
  ),
  MythCard(
    '🔀',
    'El Malacatos y el Zamora Huayco se unen junto a la Puerta de la Ciudad.',
    true,
    'De esa unión nace el río Zamora, que sigue hacia el norte.',
  ),
  MythCard(
    '🏙️',
    'El cemento de las calles absorbe la lluvia igual que la tierra.',
    false,
    'El cemento no absorbe agua: la lluvia corre rápido hacia el río.',
  ),
  MythCard(
    '🌧️',
    'Entre marzo y mayo llueve más y el Malacatos puede crecer.',
    true,
    'Por eso hay que alejarse de la orilla cuando llueve fuerte.',
  ),
  MythCard(
    '🧴',
    'Si tiro una botella al río, desaparece en unos días.',
    false,
    'Un plástico puede tardar cientos de años en desaparecer.',
  ),
  MythCard(
    '🦆',
    'La laguna del Parque Jipiro es refugio de aves.',
    true,
    'Por eso no se les da comida chatarra: les hace daño y ensucia el agua.',
  ),
  MythCard(
    '🏭',
    'Todas las aguas sucias de Loja se limpian antes de llegar al río.',
    false,
    'Gran parte todavía llega sin tratar; la planta de Sauces Norte no alcanza para todo.',
  ),
  MythCard(
    '🌊',
    'Las aguas del río Zamora llegan hasta la Amazonía.',
    true,
    'Forma parte de la gran cuenca del río Amazonas.',
  ),
  MythCard(
    '🌵',
    'Cortar los árboles de la orilla hace que el río sea más limpio.',
    false,
    'Sin árboles la orilla se erosiona y llegan más sedimentos y basura al agua.',
  ),
];

/// Minijuego "Mitos y Verdades": tarjetas que se deslizan con el dedo.
class MythsGame extends ConsumerStatefulWidget {
  const MythsGame({super.key});

  @override
  ConsumerState<MythsGame> createState() => _MythsGameState();
}

class _MythsGameState extends ConsumerState<MythsGame>
    with TickerProviderStateMixin {
  static const _rounds = 10;
  static const _toWin = 7;

  final game = gameById(GameId.mitos);
  final _rand = math.Random();

  late final AnimationController _settle = AnimationController.unbounded(
    vsync: this,
  )..addListener(() => setState(() => _drag = _settleFrom * _settle.value));
  late final AnimationController _fly = AnimationController(
    vsync: this,
    duration: AppMotion.fast,
  )..addListener(() => setState(() {}));

  bool _started = false;
  List<MythCard> _deck = [];
  int _index = 0;
  int _correct = 0;
  int _shake = 0;
  Offset _drag = Offset.zero;
  Offset _settleFrom = Offset.zero;
  Offset _flyTo = Offset.zero;
  bool _busy = false;
  (MythCard, bool)? _last; // tarjeta respondida y si fue correcto

  @override
  void dispose() {
    _settle.dispose();
    _fly.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _started = true;
      _deck = ([...mythDeck]..shuffle(_rand)).take(_rounds).toList();
      _index = 0;
      _correct = 0;
      _last = null;
      _drag = Offset.zero;
      _busy = false;
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_busy) return;
    _settle.stop();
    setState(() => _drag += d.delta);
  }

  void _onPanEnd(DragEndDetails d, double width) {
    if (_busy) return;
    final vx = d.velocity.pixelsPerSecond.dx;
    if (_drag.dx.abs() > width * 0.28 || vx.abs() > 900) {
      _answer(vx.abs() > 900 ? vx > 0 : _drag.dx > 0, width);
    } else {
      // Vuelve al centro con un resorte: conserva la velocidad del dedo.
      _settleFrom = _drag;
      _settle.value = 1;
      _settle.animateWith(
        SpringSimulation(
          AppMotion.snappy,
          1,
          0,
          -vx / math.max(1, _drag.dx.abs()),
        ),
      );
    }
  }

  Future<void> _answer(bool saysTrue, double width) async {
    if (_busy || _index >= _deck.length) return;
    _busy = true;
    final card = _deck[_index];
    final right = saysTrue == card.isTrue;
    right ? HapticFeedback.mediumImpact() : HapticFeedback.heavyImpact();
    _settle.stop();
    _settleFrom = _drag;
    _flyTo = Offset((saysTrue ? 1 : -1) * width * 1.4, _drag.dy + 40);
    if (AppMotion.reduced(context)) {
      _fly.value = 1;
    } else {
      await _fly.animateTo(1, curve: AppMotion.easeOut);
    }
    if (!mounted) return;
    setState(() {
      if (right) _correct++;
      if (!right) _shake++;
      _last = (card, right);
      _index++;
      _drag = Offset.zero;
      _fly.value = 0;
      _busy = false;
    });
    if (_index >= _deck.length) _finish();
  }

  Future<void> _finish() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final won = _correct >= _toWin;
    final again = await finishGame(
      context,
      ref,
      game: game,
      won: won,
      score: _correct,
      summary: won
          ? '¡Acertaste $_correct de $_rounds! Ya sabes separar los mitos de las verdades.'
          : 'Acertaste $_correct de $_rounds. Necesitas $_toWin para ganar.',
    );
    if (!mounted) return;
    if (again) {
      _start();
    } else {
      context.pop();
    }
  }

  Offset get _cardOffset {
    if (_fly.value == 0) return _drag;
    return Offset.lerp(_settleFrom, _flyTo, _fly.value)!;
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
            'Lee cada tarjeta sobre el río.',
            'Desliza a la DERECHA si es verdad, a la IZQUIERDA si es un mito (o usa los botones).',
            'Acierta al menos $_toWin de $_rounds para ganar.',
          ],
        ),
      );
    }
    final t = Theme.of(context).textTheme;
    final done = _index >= _deck.length;
    return GameScaffold(
      game: game,
      inProgress: !done,
      body: LayoutBuilder(
        builder: (context, c) {
          final width = c.maxWidth;
          final offset = _cardOffset;
          final tilt = (offset.dx / width).clamp(-1.0, 1.0);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: GameHud(
                  progress: '${math.min(_index + 1, _rounds)}/$_rounds',
                  progressIcon: Icons.style_outlined,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Aciertos: $_correct',
                        style: t.titleSmall?.copyWith(
                          color: AppColors.greenDeep,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        'Necesitas $_toWin',
                        style: t.bodySmall,
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Shake(
                  trigger: _shake,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Indicadores laterales que se encienden al arrastrar.
                      Positioned(
                        left: 16,
                        child: Opacity(
                          opacity: (-tilt * 2.5).clamp(0.0, 1.0),
                          child: const _SideTag(
                            text: 'MITO',
                            color: AppColors.red,
                            icon: Icons.close_rounded,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 16,
                        child: Opacity(
                          opacity: (tilt * 2.5).clamp(0.0, 1.0),
                          child: const _SideTag(
                            text: 'VERDAD',
                            color: AppColors.green,
                            icon: Icons.check_rounded,
                          ),
                        ),
                      ),
                      // Siguiente tarjeta, esperando detrás.
                      if (_index + 1 < _deck.length)
                        Transform.scale(
                          scale:
                              0.93 +
                              0.07 *
                                  (offset.dx.abs() / (width * 0.4)).clamp(
                                    0.0,
                                    1.0,
                                  ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: _MythFace(
                              card: _deck[_index + 1],
                              width: width,
                              dimmed: true,
                            ),
                          ),
                        ),
                      if (!done)
                        GestureDetector(
                          onPanUpdate: _onPanUpdate,
                          onPanEnd: (d) => _onPanEnd(d, width),
                          child: Transform.translate(
                            offset: offset,
                            child: Transform.rotate(
                              angle: tilt * 0.35,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: _MythFace(
                                  card: _deck[_index],
                                  width: width,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        RioMascot(
                          size: 110,
                          mood: _correct >= _toWin
                              ? MascotMood.cheer
                              : MascotMood.sad,
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedSwitcher(
                  duration: AppMotion.of(context, AppMotion.medium),
                  child: _last == null
                      ? const SizedBox(height: 70, key: ValueKey('none'))
                      : _Explanation(
                          key: ValueKey(_index),
                          card: _last!.$1,
                          right: _last!.$2,
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ChunkyButton(
                        label: 'Mito',
                        tone: ChunkyTone.red,
                        leading: Icons.close_rounded,
                        height: 52,
                        onPressed: done ? null : () => _answer(false, width),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChunkyButton(
                        label: 'Verdad',
                        tone: ChunkyTone.green,
                        leading: Icons.check_rounded,
                        height: 52,
                        onPressed: done ? null : () => _answer(true, width),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MythFace extends StatelessWidget {
  const _MythFace({
    required this.card,
    required this.width,
    this.dimmed = false,
  });

  final MythCard card;
  final double width;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      width: width * 0.78,
      constraints: const BoxConstraints(minHeight: 280),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: dimmed ? const Color(0xFFF1F5FB) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.outline, width: 1.5),
        boxShadow: dimmed
            ? null
            : const [
                BoxShadow(
                  color: Color(0x260B3B66),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(card.emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            card.text,
            textAlign: TextAlign.center,
            style: t.titleLarge?.copyWith(
              color: dimmed ? AppColors.inkMuted : AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          const Pill(
            label: '¿Mito o verdad?',
            icon: Icons.swipe_rounded,
            dense: true,
            color: AppColors.cyanSoft,
          ),
        ],
      ),
    );
  }
}

class _SideTag extends StatelessWidget {
  const _SideTag({required this.text, required this.color, required this.icon});

  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: text,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 14),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 30),
      ),
    );
  }
}

class _Explanation extends StatelessWidget {
  const _Explanation({super.key, required this.card, required this.right});

  final MythCard card;
  final bool right;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      color: right ? AppColors.mintSoft : AppColors.redSoft,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            right ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: right ? AppColors.greenDeep : AppColors.red,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: card.isTrue ? '¡Es verdad! ' : '¡Es un mito! ',
                style: const TextStyle(fontWeight: FontWeight.w800),
                children: [
                  TextSpan(
                    text: card.why,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              style: t.bodyMedium?.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
