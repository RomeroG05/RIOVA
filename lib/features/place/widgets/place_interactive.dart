import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/illustrations/scene_painter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/reward_dialog.dart';
import '../../../data/content/places_content.dart';
import '../../../data/models/place.dart';
import '../../../state/explorer_controller.dart';
import '../../../core/widgets/two_column_grid.dart';
import '../../../data/content/economy.dart';

// ───────────── ¡Investiguemos el río! ─────────────

class ProblemsSection extends StatefulWidget {
  const ProblemsSection({super.key, required this.place});

  final Place place;

  @override
  State<ProblemsSection> createState() => _ProblemsSectionState();
}

class _ProblemsSectionState extends State<ProblemsSection> {
  final _revealed = <int>{};

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: '¡Investiguemos el río!',
          icon: Icons.biotech_outlined,
          iconColor: AppColors.red,
          trailing: Pill(
            label:
                '${_revealed.length}/${widget.place.problems.length} Desafíos',
            color: AppColors.redSoft,
            foreground: AppColors.red,
            dense: true,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Toca cada tarjeta de investigación para descubrir qué problemas afectan este sector:',
          style: t.bodyMedium,
        ),
        const SizedBox(height: 12),
        TwoColumnGrid(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final (i, p) in widget.place.problems.indexed)
              FlipCard(
                onFlip: (showingBack) {
                  if (showingBack) setState(() => _revealed.add(i));
                },
                front: _ProblemFront(problem: p),
                back: _ProblemBack(problem: p),
              ),
          ],
        ),
      ],
    );
  }
}

/// Tarjeta que gira en 3D sobre el eje Y al tocarla.
class FlipCard extends StatefulWidget {
  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.onFlip,
  });

  final Widget front;
  final Widget back;

  /// Recibe `true` cuando la tarjeta queda mostrando el reverso.
  final ValueChanged<bool>? onFlip;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: AppMotion.easeInOut,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _toggle() {
    final toBack = _c.value < 0.5;
    if (AppMotion.reduced(context)) {
      _c.value = toBack ? 1 : 0;
    } else {
      toBack ? _c.forward() : _c.reverse();
    }
    widget.onFlip?.call(toBack);
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: _toggle,
      scale: 0.98,
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, _) {
          final angle = _t.value * math.pi;
          final showBack = angle > math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(angle),
            child: IndexedStack(
              index: showBack ? 1 : 0,
              sizing: StackFit.passthrough,
              children: [
                widget.front,
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: widget.back,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProblemFront extends StatelessWidget {
  const _ProblemFront({required this.problem});

  final RiverProblem problem;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: problem.color.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100B3B66),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBubble(
                icon: problem.icon,
                color: problem.color.withValues(alpha: 0.12),
                foreground: problem.color,
                size: 44,
              ),
              const Spacer(),
              const Icon(
                Icons.touch_app_outlined,
                color: AppColors.inkMuted,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            problem.title,
            style: t.titleMedium?.copyWith(color: problem.color),
          ),
          const SizedBox(height: 2),
          Text(
            problem.summary,
            style: t.bodySmall?.copyWith(color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}

class _ProblemBack extends StatelessWidget {
  const _ProblemBack({required this.problem});

  final RiverProblem problem;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: problem.color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            problem.title,
            style: t.titleSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            problem.detail,
            style: t.bodySmall?.copyWith(color: Colors.white, height: 1.35),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.volunteer_activism_outlined,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    problem.help,
                    style: t.labelMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────── ¡Mira cómo es este lugar! ─────────────

/// Galería de fotos reales del sector: carrusel deslizable con indicador y
/// visor a pantalla completa con zoom.
class GallerySection extends StatefulWidget {
  const GallerySection({super.key, required this.place});

  final Place place;

  @override
  State<GallerySection> createState() => _GallerySectionState();
}

class _GallerySectionState extends State<GallerySection> {
  final _pages = PageController(viewportFraction: 0.9);
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _open(int start) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: AppMotion.of(context, AppMotion.medium),
        reverseTransitionDuration: AppMotion.of(context, AppMotion.fast),
        pageBuilder: (_, _, _) =>
            _PhotoViewer(photos: widget.place.photos, initial: start),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final photos = widget.place.photos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: '¡Mira cómo es este lugar!',
          icon: Icons.photo_camera_outlined,
          trailing: Pill(
            label: '${photos.length} fotos',
            dense: true,
            color: AppColors.cyanSoft,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: _pages,
            padEnds: false,
            itemCount: photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final photo = photos[i];
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Pressable(
                  scale: 0.98,
                  semanticLabel: 'Ver foto: ${photo.caption}',
                  onTap: () => _open(i),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(
                          color: AppColors.surfaceTint,
                          child: Image.asset(
                            photo.asset,
                            fit: photo.drawing ? BoxFit.contain : BoxFit.cover,
                            cacheWidth: 900,
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(14, 28, 14, 12),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0x000B2236), Color(0xC00B2236)],
                              ),
                            ),
                            child: Text(
                              photo.caption,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: t.labelMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        if (photo.drawing)
                          const Positioned(
                            left: 10,
                            top: 10,
                            child: Pill(
                              label: 'Ilustración',
                              icon: Icons.brush_rounded,
                              dense: true,
                              color: Colors.white,
                            ),
                          ),
                        const Positioned(
                          right: 10,
                          top: 10,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(0x990B2236),
                            child: Icon(
                              Icons.open_in_full_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < photos.length; i++)
              AnimatedContainer(
                duration: AppMotion.of(context, AppMotion.fast),
                curve: AppMotion.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _index ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _index ? AppColors.teal : AppColors.outline,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          periodicalCredit,
          style: t.bodySmall?.copyWith(fontSize: 11, color: AppColors.inkMuted),
        ),
      ],
    );
  }
}

/// Visor de fotos a pantalla completa: deslizar para cambiar, pellizcar
/// para hacer zoom, botón o gesto atrás para cerrar.
class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.photos, required this.initial});

  final List<PlacePhoto> photos;
  final int initial;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _pages = PageController(
    initialPage: widget.initial,
  );
  late int _index = widget.initial;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final photo = widget.photos[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pages,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => InteractiveViewer(
              maxScale: 4,
              child: Center(
                child: Image.asset(widget.photos[i].asset, fit: BoxFit.contain),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Cerrar',
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_index + 1} / ${widget.photos.length}',
                      style: t.labelMedium?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    SequentialSwap(
                      duration: AppMotion.medium,
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        photo.caption,
                        key: ValueKey(_index),
                        style: t.bodyLarge?.copyWith(color: Colors.white),
                      ),
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

// ───────────── Deslizador Antes vs Ahora ─────────────

class BeforeAfterSection extends StatefulWidget {
  const BeforeAfterSection({super.key, required this.place});

  final Place place;

  @override
  State<BeforeAfterSection> createState() => _BeforeAfterSectionState();
}

class _BeforeAfterSectionState extends State<BeforeAfterSection> {
  double _split = 0.5;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final before = widget.place.scene.copyWith(erosion: 1);
    final after = widget.place.scene.copyWith(erosion: 0);
    return AppCard(
      ledgeColor: AppColors.blueSoft,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_rounded, color: AppColors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Deslizador: Antes vs Ahora', style: t.titleSmall),
              ),
              const Flexible(
                child: Pill(
                  label: '¡Desliza con tu dedo!',
                  dense: true,
                  color: AppColors.cyanSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: LayoutBuilder(
                builder: (context, c) {
                  final x = c.maxWidth * _split;
                  void update(Offset local) {
                    setState(
                      () => _split = (local.dx / c.maxWidth).clamp(0.04, 0.96),
                    );
                  }

                  return Semantics(
                    slider: true,
                    value: '${(_split * 100).round()}%',
                    label: 'Comparar orilla erosionada y protegida',
                    child: GestureDetector(
                      onHorizontalDragUpdate: (d) => update(d.localPosition),
                      onTapDown: (d) => update(d.localPosition),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          SceneIllustration(spec: after),
                          ClipRect(
                            clipper: _LeftClipper(x),
                            child: SceneIllustration(spec: before),
                          ),
                          Positioned(
                            left: x - 1.5,
                            top: 0,
                            bottom: 0,
                            child: Container(width: 3, color: Colors.white),
                          ),
                          Positioned(
                            left: x - 22,
                            top: c.maxHeight / 2 - 22,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x330B2236),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.unfold_more_rounded,
                                color: AppColors.blue,
                                size: 24,
                              ),
                            ),
                          ),
                          const Positioned(
                            left: 10,
                            top: 10,
                            child: Pill(
                              label: 'Pasado (Erosión)',
                              color: Color(0xCC0B2236),
                              foreground: Colors.white,
                              dense: true,
                            ),
                          ),
                          const Positioned(
                            right: 10,
                            top: 10,
                            child: Pill(
                              label: 'Hoy (Protegido)',
                              color: AppColors.green,
                              foreground: Colors.white,
                              dense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Mueve la barra para ver cómo los sauces y el cuidado ciudadano recuperaron la orilla del ${widget.place.river.shortLabel}.',
            style: t.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LeftClipper extends CustomClipper<Rect> {
  _LeftClipper(this.x);
  final double x;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, x, size.height);

  @override
  bool shouldReclip(_LeftClipper old) => old.x != x;
}

// ───────────── ¡Sé Guardián del Río! ─────────────

class GuardianChecklist extends ConsumerStatefulWidget {
  const GuardianChecklist({super.key, required this.place});

  final Place place;

  @override
  ConsumerState<GuardianChecklist> createState() => _GuardianChecklistState();
}

class _GuardianChecklistState extends ConsumerState<GuardianChecklist> {
  final _checked = <int>{};

  Future<void> _toggle(int i) async {
    setState(() => _checked.contains(i) ? _checked.remove(i) : _checked.add(i));
    if (_checked.length == guardianActions.length) {
      final outcome = ref
          .read(explorerProvider.notifier)
          .completeChecklist(widget.place);
      await showReward(
        context,
        outcome: outcome,
        title: '¡Eres Guardián del Río!',
        message: 'Prometiste cuidar ${widget.place.shortName}.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final done = ref.watch(
      explorerProvider.select(
        (s) => s.progress.checklists.contains(widget.place.id),
      ),
    );
    return AppCard(
      color: const Color(0xFFEBFBF1),
      borderColor: AppColors.mint,
      ledgeColor: AppColors.mint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBubble(
                icon: Icons.shield_outlined,
                color: AppColors.greenDeep,
                foreground: Colors.white,
                size: 44,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('¡Sé Guardián del Río!', style: t.titleLarge),
                    Text(
                      done
                          ? '¡Lista completada! +${Economy.checklist} gotitas'
                          : 'Marca las 4 acciones cumplidas:',
                      style: t.labelMedium?.copyWith(
                        color: AppColors.greenDeep,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final (i, a) in guardianActions.indexed) ...[
            _CheckRow(
              emoji: a.$1,
              text: a.$2,
              checked: done || _checked.contains(i),
              onTap: done ? null : () => _toggle(i),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            '¡Pequeñas acciones pueden ayudar a cuidar nuestros ríos!',
            style: t.labelMedium?.copyWith(color: AppColors.greenDeep),
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.emoji,
    required this.text,
    required this.checked,
    required this.onTap,
  });

  final String emoji;
  final String text;
  final bool checked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final d = AppMotion.of(context, AppMotion.fast);
    return Semantics(
      checked: checked,
      label: text,
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: d,
          curve: AppMotion.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: checked ? AppColors.mintSoft : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: checked ? AppColors.green : AppColors.mint,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: d,
                curve: AppMotion.easeOut,
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: checked ? AppColors.green : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.green, width: 2),
                ),
                child: AnimatedScale(
                  scale: checked ? 1 : 0.5,
                  duration: d,
                  curve: AppMotion.playful,
                  child: AnimatedOpacity(
                    opacity: checked ? 1 : 0,
                    duration: d,
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: t.labelMedium?.copyWith(
                    color: AppColors.ink,
                    fontSize: 13,
                    decoration: checked ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.greenDark,
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

// ───────────── ¡Demuestra lo que aprendiste! ─────────────

class PlaceQuiz extends ConsumerStatefulWidget {
  const PlaceQuiz({super.key, required this.place});

  final Place place;

  @override
  ConsumerState<PlaceQuiz> createState() => _PlaceQuizState();
}

class _PlaceQuizState extends ConsumerState<PlaceQuiz> {
  int? _wrong;
  int _misses = 0;
  int _shake = 0;

  Future<void> _answer(int i) async {
    final quiz = widget.place.quiz;
    if (i == quiz.answer) {
      HapticFeedback.mediumImpact();
      final outcome = ref
          .read(explorerProvider.notifier)
          .answerQuiz(widget.place, firstTry: _misses == 0);
      await showReward(
        context,
        outcome: outcome,
        title: _misses == 0 ? '¡Respuesta perfecta!' : '¡Lo lograste!',
        message: quiz.explanation,
      );
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _wrong = i;
        _misses++;
        _shake++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final quiz = widget.place.quiz;
    final answered = ref.watch(
      explorerProvider.select(
        (s) => s.progress.quizzes.contains(widget.place.id),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFBFE7FB), Color(0xFFE3F3FD)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFF9CCBE8), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBubble(
                icon: Icons.track_changes_rounded,
                color: AppColors.teal,
                foreground: Colors.white,
                size: 40,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '¡Demuestra lo que aprendiste!',
                  style: t.titleLarge,
                ),
              ),
              Pill(
                label: answered
                    ? 'Completado'
                    : '+${Economy.quizFirstTry} Gotitas',
                dense: true,
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(quiz.question, style: t.titleSmall),
          ),
          const SizedBox(height: 10),
          Shake(
            trigger: _shake,
            child: Column(
              children: [
                for (final (i, o) in quiz.options.indexed) ...[
                  _OptionTile(
                    letter: String.fromCharCode(65 + i),
                    text: o,
                    state: answered && i == quiz.answer
                        ? _OptionState.correct
                        : _wrong == i
                        ? _OptionState.wrong
                        : _OptionState.idle,
                    onTap: answered ? null : () => _answer(i),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          if (_misses > 0 && !answered)
            EntranceFade(
              child: Text(
                'Casi… ¡inténtalo otra vez! 💧',
                style: t.labelMedium?.copyWith(color: AppColors.red),
              ),
            ),
          if (answered)
            EntranceFade(
              child: Text(
                quiz.explanation,
                style: t.bodyMedium?.copyWith(color: AppColors.tealDark),
              ),
            ),
        ],
      ),
    );
  }
}

enum _OptionState { idle, correct, wrong }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.letter,
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String letter;
  final String text;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final (bg, border, badge) = switch (state) {
      _OptionState.correct => (
        AppColors.mint,
        AppColors.greenDark,
        AppColors.greenDeep,
      ),
      _OptionState.wrong => (AppColors.redSoft, AppColors.red, AppColors.red),
      _OptionState.idle => (Colors.white, Colors.white, AppColors.surfaceBlue),
    };
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Opción $letter: $text',
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.fast),
        curve: AppMotion.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: badge, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: state == _OptionState.idle
                  ? Text(
                      letter,
                      style: t.labelMedium?.copyWith(color: AppColors.teal),
                    )
                  : Icon(
                      state == _OptionState.correct
                          ? Icons.check_rounded
                          : Icons.close_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: t.bodyMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
