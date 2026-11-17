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
import '../../../core/widgets/pressable.dart';
import '../../../data/content/game_content.dart';
import '../../../data/models/place.dart';
import '../common/game_scaffold.dart';
import '../../../core/widgets/two_column_grid.dart';

/// Minijuego "¿Cuánto sabes de Loja?".
class LojaQuizGame extends ConsumerStatefulWidget {
  const LojaQuizGame({super.key});

  @override
  ConsumerState<LojaQuizGame> createState() => _LojaQuizGameState();
}

class _LojaQuizGameState extends ConsumerState<LojaQuizGame>
    with SingleTickerProviderStateMixin {
  static const _count = 8;
  static const _toWin = 5;
  static const _perQuestion = Duration(seconds: 20);

  final game = gameById(GameId.quiz);
  final _rand = math.Random();
  late final AnimationController _clock =
      AnimationController(vsync: this, duration: _perQuestion)
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) _choose(-1);
        });

  bool _started = false;
  List<QuizQuestion> _questions = [];
  int _index = 0;
  int _score = 0;
  int? _picked;
  int _shake = 0;
  final _results = <bool>[];

  QuizQuestion get _q => _questions[_index];

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _started = true;
      _questions = ([...lojaQuizBank]..shuffle(_rand)).take(_count).toList();
      _index = 0;
      _score = 0;
      _picked = null;
      _results.clear();
    });
    _clock.forward(from: 0);
  }

  Future<void> _choose(int i) async {
    if (_picked != null) return;
    _clock.stop();
    final right = i == _q.answer;
    if (right) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
    setState(() {
      _picked = i;
      if (right) _score++;
      if (!right) _shake++;
      _results.add(right);
    });
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    if (_index + 1 < _questions.length) {
      setState(() {
        _index++;
        _picked = null;
      });
      _clock.forward(from: 0);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final won = _score >= _toWin;
    final again = await finishGame(
      context,
      ref,
      game: game,
      won: won,
      score: _score,
      summary: won
          ? '¡Acertaste $_score de $_count! Eres un sabio de los ríos de Loja.'
          : 'Acertaste $_score de $_count. Necesitas $_toWin para ganar. ¡Visita la Biblioteca del Agua!',
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
            'Responde $_count preguntas sobre Loja y sus ríos.',
            'Tienes 20 segundos por pregunta.',
            'Acierta al menos $_toWin para ganar tus gotitas.',
          ],
        ),
      );
    }
    final t = Theme.of(context).textTheme;
    const bubbleColors = [
      Color(0xFF7CD3F7),
      Color(0xFF9BE3A8),
      Color(0xFFFFD27A),
      Color(0xFFC8B6FF),
    ];
    return GameScaffold(
      game: game,
      inProgress: true,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          GameHud(
            progress: '${_index + 1}/$_count',
            progressIcon: Icons.quiz_outlined,
          ),
          const SizedBox(height: 12),
          // Progreso con puntos de colores.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _count; i++)
                AnimatedContainer(
                  duration: AppMotion.of(context, AppMotion.medium),
                  curve: AppMotion.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 22 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: i < _results.length
                        ? (_results[i] ? AppColors.green : AppColors.red)
                        : i == _index
                        ? AppColors.cyan
                        : AppColors.outline,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              RioMascot(
                size: 64,
                mood: _picked == null
                    ? MascotMood.thinking
                    : _picked == _q.answer
                    ? MascotMood.cheer
                    : MascotMood.sad,
              ),
              const Spacer(),
              SizedBox(
                width: 64,
                height: 64,
                child: AnimatedBuilder(
                  animation: _clock,
                  builder: (context, _) {
                    final left = (_perQuestion.inSeconds * (1 - _clock.value))
                        .ceil();
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: 1 - _clock.value,
                            strokeWidth: 6,
                            backgroundColor: AppColors.blueSoft,
                            color: left <= 5 ? AppColors.red : AppColors.cyan,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Text(
                          '$left',
                          style: t.titleLarge?.copyWith(
                            color: left <= 5 ? AppColors.red : AppColors.teal,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.medium),
            switchInCurve: AppMotion.easeOut,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0.08, 0),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey(_index),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  ledgeColor: AppColors.cyanSoft,
                  child: Text(
                    _q.question,
                    style: t.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                Shake(
                  trigger: _shake,
                  child: TwoColumnGrid(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final (i, o) in _q.options.indexed)
                        _Bubble(
                          text: o,
                          color: bubbleColors[i % bubbleColors.length],
                          state: _picked == null
                              ? null
                              : i == _q.answer
                              ? true
                              : i == _picked
                              ? false
                              : null,
                          dimmed:
                              _picked != null && i != _q.answer && i != _picked,
                          onTap: () => _choose(i),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_picked == -1)
            EntranceFade(
              child: Text(
                '¡Se acabó el tiempo! ⏰',
                textAlign: TextAlign.center,
                style: t.titleSmall?.copyWith(color: AppColors.red),
              ),
            ),
          Text(
            'Aciertos: $_score',
            textAlign: TextAlign.center,
            style: t.titleMedium?.copyWith(color: AppColors.teal),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.color,
    required this.state,
    required this.dimmed,
    required this.onTap,
  });

  final String text;
  final Color color;

  /// `true` correcta, `false` elegida incorrecta, `null` neutra.
  final bool? state;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final bg = state == true
        ? AppColors.green
        : state == false
        ? AppColors.red
        : color;
    final fg = state == null ? AppColors.ink : Colors.white;
    return AnimatedOpacity(
      duration: AppMotion.of(context, AppMotion.fast),
      opacity: dimmed ? 0.4 : 1,
      child: Pressable(
        onTap: onTap,
        semanticLabel: text,
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.fast),
          curve: AppMotion.easeOut,
          constraints: const BoxConstraints(minHeight: 112),
          padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: bg.withValues(alpha: 0.45),
                blurRadius: 0,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 6,
                top: 4,
                child: Container(
                  width: 14,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Center(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: t.titleSmall?.copyWith(color: fg),
                ),
              ),
              if (state != null)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Icon(
                    state! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
