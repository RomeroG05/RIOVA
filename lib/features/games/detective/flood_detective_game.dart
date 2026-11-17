import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/illustrations/scene_painter.dart';
import '../../../core/mascot/rio_mascot.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../../core/widgets/pressable.dart';
import '../../../data/content/game_content.dart';
import '../common/game_scaffold.dart';

enum _Tool {
  sauces('Plantar Sauces Ribereños', Icons.spa_outlined),
  escombros('Retirar Escombros', Icons.delete_sweep_outlined),
  canal('Canal de Alivio', Icons.call_split_rounded);

  const _Tool(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _Clue {
  const _Clue({
    required this.spot,
    required this.title,
    required this.tag,
    required this.question,
    required this.options,
    required this.answer,
    required this.praise,
    required this.tool,
    required this.at,
  });

  final String spot;
  final String title;
  final String tag;
  final String question;
  final List<String> options;
  final int answer;
  final String praise;
  final _Tool tool;

  /// Posición del punto en la escena (fracciones 0–1).
  final Offset at;
}

const _clues = [
  _Clue(
    spot: 'Alcantarilla',
    title: 'La Alcantarilla Tapada',
    tag: 'Drenaje urbano',
    question:
        '¿Por qué el agua de lluvia no se fue por la alcantarilla de la calle?',
    options: [
      'Estaba tapada con basura y hojas.',
      'La alcantarilla estaba dormida.',
      'El agua prefiere quedarse en la calle.',
    ],
    answer: 0,
    praise: '¡Exacto! Basura en la calle = alcantarilla tapada.',
    tool: _Tool.escombros,
    at: Offset(0.2, 0.3),
  ),
  _Clue(
    spot: 'Sedimentos',
    title: 'El Fondo Lleno de Tierra',
    tag: 'Sedimentación',
    question:
        '¿Qué pasa cuando tierra y piedras se acumulan en el fondo del río?',
    options: [
      'El río se vuelve más profundo.',
      'El cauce pierde espacio y el agua se desborda más fácil.',
      'Los peces se comen la tierra.',
    ],
    answer: 1,
    praise: '¡Bien visto! Menos espacio en el cauce = más desbordes.',
    tool: _Tool.escombros,
    at: Offset(0.22, 0.74),
  ),
  _Clue(
    spot: 'Orilla',
    title: 'La Orilla Desprotegida',
    tag: 'Erosión Ribereña',
    question: '¿Por qué el caudal del río Malacatos desgajó la tierra en esta curva e inundó el sendero peatonal?',
    options: [
      'Faltan sauces y árboles cuyas raíces tejen el suelo y frenan la fuerza del agua.',
      'Los peces nadaron demasiado rápido y sus aletazos empujaron el agua afuera.',
      'El puente de madera era de color oscuro y atrajo más agua de la cordillera.',
    ],
    answer: 0,
    praise: '¡Deducción brillante! Raíces = Red protectora.',
    tool: _Tool.sauces,
    at: Offset(0.5, 0.52),
  ),
  _Clue(
    spot: 'Desagüe',
    title: 'El Desagüe Saturado',
    tag: 'Lluvias andinas',
    question:
        'Llovió muchísimo en las montañas. ¿Por qué el desagüe no alcanzó?',
    options: [
      'Porque el desagüe era nuevo.',
      'Porque la lluvia era de colores.',
      'Recibió más agua de la que podía llevar en poco tiempo.',
    ],
    answer: 2,
    praise: '¡Correcto! Mucha agua de golpe necesita otra salida.',
    tool: _Tool.canal,
    at: Offset(0.8, 0.28),
  ),
  _Clue(
    spot: 'Crecida Alta',
    title: 'La Gran Crecida',
    tag: 'Caudal máximo',
    question: '¿Qué ayuda a que una crecida no inunde las casas cercanas?',
    options: [
      'Construir casas pegadas al río.',
      'Dar espacio al río con zonas verdes y canales de alivio.',
      'Tirar más tierra al cauce.',
    ],
    answer: 1,
    praise: '¡Eso es! El río también necesita su espacio.',
    tool: _Tool.canal,
    at: Offset(0.78, 0.72),
  ),
];

enum _Phase { intro, playing, over }

/// Minijuego "Detective de Inundaciones".
class FloodDetectiveGame extends ConsumerStatefulWidget {
  const FloodDetectiveGame({super.key});

  @override
  ConsumerState<FloodDetectiveGame> createState() => _FloodDetectiveGameState();
}

class _FloodDetectiveGameState extends ConsumerState<FloodDetectiveGame> {
  static const _totalSeconds = 180;
  final game = gameById(GameId.detective);
  final _panelKey = GlobalKey();

  _Phase _phase = _Phase.intro;
  Timer? _timer;
  bool _paused = false;
  int _seconds = _totalSeconds;
  int _lives = 3;
  int _lupas = 2;
  int _mistakes = 0;
  int _shake = 0;
  int _current = 0;
  final _solved = <int>{};
  final _eliminated = <int>{};
  int? _wrongOption;
  bool _answered = false;
  _Tool? _wrongTool;

  _Clue get _clue => _clues[_current];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _phase = _Phase.playing;
      _seconds = _totalSeconds;
      _lives = 3;
      _lupas = 2;
      _mistakes = 0;
      _solved.clear();
      _paused = false;
      _openClue(0);
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused || _phase != _Phase.playing) return;
      setState(() => _seconds--);
      if (_seconds <= 0) _end(false);
    });
  }

  void _openClue(int i) {
    _current = i;
    _eliminated.clear();
    _wrongOption = null;
    _wrongTool = null;
    _answered = false;
  }

  void _selectSpot(int i) {
    if (_solved.contains(i)) return;
    setState(() => _openClue(i));
    final ctx = _panelKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: AppMotion.of(context, AppMotion.slow),
        curve: AppMotion.easeInOut,
      );
    }
  }

  void _mistake() {
    HapticFeedback.heavyImpact();
    _lives--;
    _mistakes++;
    _shake++;
    if (_lives <= 0) {
      // Deja ver la sacudida antes de cerrar.
      Future.delayed(const Duration(milliseconds: 450), () => _end(false));
    }
  }

  void _answer(int i) {
    if (_answered || _eliminated.contains(i) || _phase != _Phase.playing) {
      return;
    }
    setState(() {
      if (i == _clue.answer) {
        HapticFeedback.mediumImpact();
        _answered = true;
        _wrongOption = null;
      } else {
        _wrongOption = i;
        _eliminated.add(i);
        _mistake();
      }
    });
  }

  void _useLupa() {
    if (_lupas == 0 || _answered) return;
    final candidates = [
      for (var i = 0; i < _clue.options.length; i++)
        if (i != _clue.answer && !_eliminated.contains(i)) i,
    ];
    if (candidates.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _lupas--;
      _eliminated.add(candidates.first);
    });
  }

  void _pickTool(_Tool tool) {
    if (!_answered || _phase != _Phase.playing) return;
    if (tool != _clue.tool) {
      setState(() {
        _wrongTool = tool;
        _mistake();
      });
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _solved.add(_current));
    if (_solved.length == _clues.length) {
      Future.delayed(const Duration(milliseconds: 500), () => _end(true));
      return;
    }
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      final next = List.generate(
        _clues.length,
        (i) => i,
      ).firstWhere((i) => !_solved.contains(i));
      setState(() => _openClue(next));
    });
  }

  Future<void> _end(bool won) async {
    if (_phase == _Phase.over || !mounted) return;
    _timer?.cancel();
    setState(() => _phase = _Phase.over);
    final again = await finishGame(
      context,
      ref,
      game: game,
      won: won,
      score: _solved.length * 100 + _lives * 50 + _seconds,
      summary: won
          ? 'Resolviste el Caso Malacatos con $_lives ${_lives == 1 ? 'vida' : 'vidas'} y ${_seconds}s de sobra.'
          : 'Encontraste ${_solved.length} de ${_clues.length} causas. ¡Los detectives nunca se rinden!',
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
    if (_phase == _Phase.intro) {
      return GameScaffold(
        game: game,
        body: GameIntro(
          game: game,
          accessory: MascotAccessory.magnifier,
          onStart: _start,
          instructions: const [
            'El río Malacatos se desbordó. Investiga las 5 zonas críticas de la escena.',
            'En cada pista responde la pregunta y elige la herramienta de mitigación correcta.',
            'Cada error cuesta una vida. Usa la Super Lupa para descartar una respuesta.',
          ],
        ),
      );
    }

    final t = Theme.of(context).textTheme;
    final resolved = _solved.length / _clues.length;
    final waterLevel = (0.7 - resolved * 0.7 + _mistakes * 0.08).clamp(
      0.0,
      1.0,
    );

    return GameScaffold(
      game: game,
      inProgress: _phase == _Phase.playing,
      onPauseChanged: (p) => setState(() => _paused = p),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Shake(
            trigger: _shake,
            child: GameHud(
              paused: _paused,
              onPause: () => setState(() => _paused = !_paused),
              seconds: _seconds,
              lives: _lives,
              progress: '${_solved.length}/${_clues.length} Pistas',
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.water_drop_outlined,
                      color: AppColors.teal,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Caso Malacatos: Nivel de Control',
                        style: t.titleSmall,
                      ),
                    ),
                    Text(
                      '${(resolved * 100).round()}% Resuelto',
                      style: t.labelMedium?.copyWith(color: AppColors.teal),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ProgressBar(
                  value: resolved,
                  colors: const [
                    AppColors.teal,
                    AppColors.cyan,
                    AppColors.green,
                  ],
                  showKnob: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const RioSays(
            tag: 'MISIÓN FLUVIAL',
            accessory: MascotAccessory.magnifier,
            message: '¡Alerta en el cauce! Investiga las 5 zonas críticas en el río Malacatos para descubrir por qué subió el nivel del agua.',
          ),
          const SizedBox(height: 12),
          _Scene(
            solved: _solved,
            current: _current,
            waterLevel: waterLevel,
            onSelect: _selectSpot,
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            key: _panelKey,
            duration: AppMotion.of(context, AppMotion.medium),
            switchInCurve: AppMotion.easeOut,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0.06, 0),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: _CluePanel(
              key: ValueKey(_current),
              index: _current,
              clue: _clue,
              eliminated: _eliminated,
              wrongOption: _wrongOption,
              answered: _answered,
              lupas: _lupas,
              onAnswer: _answer,
              onLupa: _useLupa,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedOpacity(
            duration: AppMotion.of(context, AppMotion.medium),
            opacity: _answered ? 1 : 0.45,
            child: IgnorePointer(
              ignoring: !_answered,
              child: _ToolsPanel(
                solved: _solved.contains(_current),
                correct: _clue.tool,
                wrong: _wrongTool,
                onPick: _pickTool,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Scene extends StatelessWidget {
  const _Scene({
    required this.solved,
    required this.current,
    required this.waterLevel,
    required this.onSelect,
  });

  final Set<int> solved;
  final int current;
  final double waterLevel;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(26),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.near_me_outlined,
                  color: AppColors.teal,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sector Puente Bolívar, Río Malacatos',
                    style: t.titleSmall,
                  ),
                ),
                Pill(
                  label: 'Pista ${current + 1} Activa',
                  dense: true,
                  color: AppColors.cyanSoft,
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 1.25,
            child: LayoutBuilder(
              builder: (context, c) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: waterLevel),
                        duration: AppMotion.of(
                          context,
                          const Duration(milliseconds: 900),
                        ),
                        curve: AppMotion.easeInOut,
                        builder: (context, level, _) => SceneIllustration(
                          spec: SceneSpec.storm.copyWith(
                            waterLevel: level,
                            rain: level > 0.25,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3D6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE2B866),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            'DETECTIVE DE\nINUNDACIONES',
                            textAlign: TextAlign.center,
                            style: t.labelSmall?.copyWith(
                              color: const Color(0xFF6B4A1D),
                              fontSize: 12,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    for (final (i, clue) in _clues.indexed)
                      Positioned(
                        left: clue.at.dx * c.maxWidth - 60,
                        top: clue.at.dy * c.maxHeight - 24,
                        width: 120,
                        child: _Hotspot(
                          label: clue.spot,
                          solved: solved.contains(i),
                          active: i == current && !solved.contains(i),
                          onTap: () => onSelect(i),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Hotspot extends StatelessWidget {
  const _Hotspot({
    required this.label,
    required this.solved,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool solved;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final (bg, icon, fg) = solved
        ? (AppColors.green, Icons.check_circle_outline_rounded, Colors.white)
        : active
        ? (AppColors.cyan, Icons.search_rounded, Colors.white)
        : (Colors.white, Icons.help_outline_rounded, AppColors.blue);
    return Pressable(
      onTap: onTap,
      semanticLabel: '$label${solved ? ', resuelto' : ''}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PulseRing(
            active: active,
            size: 46,
            child: AnimatedContainer(
              duration: AppMotion.of(context, AppMotion.medium),
              curve: AppMotion.easeOut,
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x330B2236),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: fg, size: 24),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              active ? '¡Investigar aquí!' : label,
              style: t.labelMedium?.copyWith(
                color: AppColors.ink,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CluePanel extends StatelessWidget {
  const _CluePanel({
    super.key,
    required this.index,
    required this.clue,
    required this.eliminated,
    required this.wrongOption,
    required this.answered,
    required this.lupas,
    required this.onAnswer,
    required this.onLupa,
  });

  final int index;
  final _Clue clue;
  final Set<int> eliminated;
  final int? wrongOption;
  final bool answered;
  final int lupas;
  final ValueChanged<int> onAnswer;
  final VoidCallback onLupa;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 10, right: 8),
                decoration: const BoxDecoration(
                  color: AppColors.cyan,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  'Pista #${index + 1}: ${clue.title}',
                  style: t.titleLarge,
                ),
              ),
              Pill(label: clue.tag, dense: true, color: AppColors.cyanSoft),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const IconBubble(icon: Icons.landscape_outlined, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    clue.question,
                    style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final (i, o) in clue.options.indexed) ...[
            _Option(
              letter: String.fromCharCode(65 + i),
              text: o,
              correct: answered && i == clue.answer,
              wrong: wrongOption == i,
              eliminated: eliminated.contains(i) && wrongOption != i,
              praise: answered && i == clue.answer ? clue.praise : null,
              onTap: () => onAnswer(i),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
          Opacity(
            opacity: lupas > 0 && !answered ? 1 : 0.5,
            child: Pressable(
              onTap: lupas > 0 && !answered ? onLupa : null,
              semanticLabel: 'Usar Super Lupa, $lupas disponibles',
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.cyan, AppColors.blue],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.manage_search_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '¡Poder de Río: Super Lupa Rayos X!',
                        style: t.titleSmall?.copyWith(color: Colors.white),
                      ),
                    ),
                    Pill(
                      label: '$lupas Disponibles',
                      color: const Color(0x33FFFFFF),
                      foreground: Colors.white,
                      dense: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.letter,
    required this.text,
    required this.correct,
    required this.wrong,
    required this.eliminated,
    required this.praise,
    required this.onTap,
  });

  final String letter;
  final String text;
  final bool correct;
  final bool wrong;
  final bool eliminated;
  final String? praise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final bg = correct
        ? AppColors.mint
        : wrong
        ? AppColors.redSoft
        : Colors.white;
    return AnimatedOpacity(
      duration: AppMotion.of(context, AppMotion.medium),
      opacity: eliminated ? 0.35 : 1,
      child: Pressable(
        onTap: onTap,
        semanticLabel: 'Opción $letter',
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.fast),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: correct
                  ? AppColors.greenDark
                  : wrong
                  ? AppColors.red
                  : AppColors.outline,
              width: 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: correct
                      ? AppColors.greenDeep
                      : wrong
                      ? AppColors.red
                      : AppColors.surfaceBlue,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: correct || wrong
                    ? Icon(
                        correct ? Icons.check_rounded : Icons.close_rounded,
                        color: Colors.white,
                        size: 17,
                      )
                    : Text(
                        letter,
                        style: t.labelMedium?.copyWith(color: AppColors.teal),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: t.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: eliminated
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (praise != null)
                      EntranceFade(
                        child: Text(
                          praise!,
                          style: t.labelMedium?.copyWith(
                            color: AppColors.greenDeep,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolsPanel extends StatelessWidget {
  const _ToolsPanel({
    required this.solved,
    required this.correct,
    required this.wrong,
    required this.onPick,
  });

  final bool solved;
  final _Tool correct;
  final _Tool? wrong;
  final ValueChanged<_Tool> onPick;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.construction_rounded,
                color: AppColors.greenDeep,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Herramientas de Mitigación Fluvial',
                  style: t.titleMedium,
                ),
              ),
              const Pill(
                label: 'Elige una',
                color: AppColors.mintSoft,
                foreground: AppColors.greenDeep,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Selecciona la acción ecológica correcta para salvar esta curva del río Malacatos:',
            style: t.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final tool in _Tool.values) ...[
                Expanded(
                  child: Pressable(
                    onTap: () => onPick(tool),
                    semanticLabel: tool.label,
                    child: AnimatedContainer(
                      duration: AppMotion.of(context, AppMotion.fast),
                      height: 118,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: solved && tool == correct
                            ? AppColors.mintSoft
                            : wrong == tool
                            ? AppColors.redSoft
                            : AppColors.surfaceTint,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: solved && tool == correct
                              ? AppColors.green
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconBubble(
                            icon: solved && tool == correct
                                ? Icons.check_rounded
                                : tool.icon,
                            color: solved && tool == correct
                                ? AppColors.green
                                : AppColors.blueSoft,
                            foreground: solved && tool == correct
                                ? Colors.white
                                : AppColors.teal,
                            size: 46,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tool.label,
                            textAlign: TextAlign.center,
                            style: t.labelMedium?.copyWith(
                              color: AppColors.ink,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (tool != _Tool.values.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
