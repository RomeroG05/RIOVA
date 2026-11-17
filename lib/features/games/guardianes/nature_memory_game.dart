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

class _Species {
  const _Species(this.emoji, this.name, this.fact);
  final String emoji;
  final String name;
  final String fact;
}

const _pool = [
  _Species(
    '🌳',
    'Sauce Llorón',
    'Sus raíces sujetan la tierra de las orillas y frenan las crecidas.',
  ),
  _Species(
    '🐦',
    'Colibrí',
    'Visita las flores junto al río para tomar néctar y las poliniza.',
  ),
  _Species(
    '🐟',
    'Trucha',
    'Solo vive en aguas frías, limpias y con mucho oxígeno.',
  ),
  _Species(
    '🐸',
    'Rana',
    'Si hay ranas, ¡el agua está sana! Son muy sensibles a la contaminación.',
  ),
  _Species(
    '🦋',
    'Mariposa',
    'Poliniza las plantas de la ribera mientras busca néctar.',
  ),
  _Species(
    '🌸',
    'Orquídea',
    'Los bosques húmedos de Loja guardan muchísimas especies de orquídeas.',
  ),
  _Species(
    '🦆',
    'Pato Andino',
    'Anida entre las plantas de las orillas tranquilas.',
  ),
  _Species(
    '🐻',
    'Oso de Anteojos',
    'Vive en los bosques andinos que protegen los nacimientos de agua.',
  ),
];

class _Card {
  _Card(this.species);
  final _Species species;
  bool up = false;
  bool matched = false;
}

/// Minijuego "Guardianes Naturaleza" (memoria).
class NatureMemoryGame extends ConsumerStatefulWidget {
  const NatureMemoryGame({super.key});

  @override
  ConsumerState<NatureMemoryGame> createState() => _NatureMemoryGameState();
}

class _NatureMemoryGameState extends ConsumerState<NatureMemoryGame> {
  static const _pairs = 6;
  final game = gameById(GameId.guardianes);
  final _rand = math.Random();

  bool _started = false;
  List<_Card> _cards = [];
  final _open = <int>[];
  bool _locked = false;
  int _moves = 0;
  int _seconds = 0;
  Timer? _timer;
  _Species? _lastFound;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    final chosen = ([..._pool]..shuffle(_rand)).take(_pairs);
    setState(() {
      _started = true;
      _cards = [
        for (final s in chosen) ...[_Card(s), _Card(s)],
      ]..shuffle(_rand);
      _open.clear();
      _moves = 0;
      _seconds = 0;
      _lastFound = null;
      _locked = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _seconds++),
    );
  }

  Future<void> _flip(int i) async {
    final card = _cards[i];
    if (_locked || card.up || card.matched) return;
    HapticFeedback.selectionClick();
    setState(() {
      card.up = true;
      _open.add(i);
    });
    if (_open.length < 2) return;

    _moves++;
    final a = _cards[_open[0]], b = _cards[_open[1]];
    if (a.species == b.species) {
      HapticFeedback.mediumImpact();
      setState(() {
        a.matched = b.matched = true;
        _lastFound = a.species;
        _open.clear();
      });
      if (_cards.every((c) => c.matched)) _win();
    } else {
      _locked = true;
      await Future<void>.delayed(const Duration(milliseconds: 850));
      if (!mounted) return;
      setState(() {
        a.up = b.up = false;
        _open.clear();
        _locked = false;
      });
    }
  }

  Future<void> _win() async {
    _timer?.cancel();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final again = await finishGame(
      context,
      ref,
      game: game,
      won: true,
      score: math.max(0, 100 - _moves * 3),
      summary:
          'Encontraste las $_pairs parejas en $_moves intentos y $_seconds segundos.',
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
            'Hay $_pairs parejas de plantas y animales escondidas.',
            'Toca dos cartas para darles la vuelta. Si son iguales, ¡las descubres!',
            'Cada pareja te enseña cómo ayuda al río.',
          ],
        ),
      );
    }
    final t = Theme.of(context).textTheme;
    final found = _cards.where((c) => c.matched).length ~/ 2;
    final done = found == _pairs;
    return GameScaffold(
      game: game,
      inProgress: !done,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: GameHud(
              seconds: _seconds,
              countdown: false,
              progress: '$found/$_pairs Parejas',
              progressIcon: Icons.eco_outlined,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: Text('Intentos: $_moves', style: t.titleSmall)),
                Flexible(
                  child: Text(
                    'Toca dos cartas',
                    style: t.bodySmall,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(
                builder: (context, c) {
                  const cols = 3;
                  final rows = (_cards.length / cols).ceil();
                  const gap = 10.0;
                  final cellW = (c.maxWidth - gap * (cols - 1)) / cols;
                  final cellH = math.min(
                    (c.maxHeight - gap * (rows - 1)) / rows,
                    cellW * 1.25,
                  );
                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      mainAxisSpacing: gap,
                      crossAxisSpacing: gap,
                      childAspectRatio: cellW / cellH,
                    ),
                    itemCount: _cards.length,
                    itemBuilder: (context, i) =>
                        _MemoryCard(card: _cards[i], onTap: () => _flip(i)),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SequentialSwap(
              child: RioSays(
                key: ValueKey(_lastFound?.name),
                label: _lastFound == null
                    ? 'Río dice:'
                    : '${_lastFound!.emoji} ${_lastFound!.name}:',
                mood: _lastFound == null ? MascotMood.happy : MascotMood.wow,
                message: _lastFound?.fact ?? '¡Encuentra a los guardianes de la naturaleza que viven junto al río!',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carta que gira según `card.up`, con perspectiva.
class _MemoryCard extends StatefulWidget {
  const _MemoryCard({required this.card, required this.onTap});

  final _Card card;
  final VoidCallback onTap;

  @override
  State<_MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<_MemoryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
    value: widget.card.up ? 1 : 0,
  );

  @override
  void didUpdateWidget(_MemoryCard old) {
    super.didUpdateWidget(old);
    final target = widget.card.up ? 1.0 : 0.0;
    if (_c.value != target) {
      if (AppMotion.reduced(context)) {
        _c.value = target;
      } else {
        _c.animateTo(target, curve: AppMotion.easeInOut);
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final card = widget.card;
    return Semantics(
      button: true,
      label: card.up || card.matched ? card.species.name : 'Carta oculta',
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: card.matched ? 0.95 : 1,
          duration: AppMotion.of(context, AppMotion.medium),
          curve: AppMotion.playful,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final angle = _c.value * math.pi;
              final front = angle > math.pi / 2;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0015)
                  ..rotateY(angle),
                child: front
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(math.pi),
                        child: Container(
                          decoration: BoxDecoration(
                            color: card.matched
                                ? AppColors.mintSoft
                                : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: card.matched
                                  ? AppColors.green
                                  : AppColors.outline,
                              width: card.matched ? 2.5 : 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                card.species.emoji,
                                style: const TextStyle(fontSize: 38),
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Text(
                                  card.species.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  style: t.labelMedium?.copyWith(
                                    color: AppColors.ink,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.green, AppColors.greenDeep],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x2A136B33),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: RioMascot(
                            size: 40,
                            interactive: false,
                            idle: false,
                          ),
                        ),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}
