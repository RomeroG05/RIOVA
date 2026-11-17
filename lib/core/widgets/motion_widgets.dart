import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

/// Entrada escalonada: aparece con opacidad + desplazamiento de 14 px hacia
/// arriba y escala desde 0.97. `index` define el retraso (50 ms por elemento,
/// tope de 8 para que listas largas no tarden en llenarse).
class EntranceFade extends StatefulWidget {
  const EntranceFade({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 14,
    this.duration = const Duration(milliseconds: 380),
  });

  final Widget child;
  final int index;
  final double offset;
  final Duration duration;

  @override
  State<EntranceFade> createState() => _EntranceFadeState();
}

class _EntranceFadeState extends State<EntranceFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: AppMotion.easeOut,
  );
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.status != AnimationStatus.dismissed || _timer != null) return;
    if (AppMotion.reduced(context)) {
      _c.value = 1;
      return;
    }
    final delay = AppMotion.stagger * math.min(widget.index, 8);
    _timer = Timer(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final v = _t.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * widget.offset),
            child: Transform.scale(scale: 0.97 + 0.03 * v, child: child),
          ),
        );
      },
    );
  }
}

/// Barra de progreso redondeada con degradado; anima su valor con
/// ease-out cuando cambia.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.height = 10,
    this._colors,
    this._track,
    this.showKnob = false,
  });

  final double value;
  final double height;
  final List<Color>? _colors;
  List<Color> get colors => _colors ?? [AppColors.blue, AppColors.blue];
  final Color? _track;
  Color get track => _track ?? AppColors.blueSoft;
  final bool showKnob;

  @override
  Widget build(BuildContext context) {
    final target = value.clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: target),
      duration: AppMotion.of(context, const Duration(milliseconds: 700)),
      curve: AppMotion.easeOut,
      builder: (context, v, _) {
        return LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth * v;
            final knob = height + 8;
            return SizedBox(
              height: showKnob ? knob : height,
              child: Stack(
                alignment: Alignment.centerLeft,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: track,
                      borderRadius: BorderRadius.circular(height),
                    ),
                  ),
                  Container(
                    width: math.max(w, v > 0 ? height : 0),
                    height: height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors),
                      borderRadius: BorderRadius.circular(height),
                    ),
                  ),
                  if (showKnob && v > 0)
                    Positioned(
                      left: (w - knob / 2).clamp(0.0, c.maxWidth - knob),
                      child: Container(
                        width: knob,
                        height: knob,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.last, width: 3),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Número que cuenta desde su valor anterior hasta el nuevo.
class CountUpText extends StatelessWidget {
  const CountUpText(this.value, {super.key, this.style, this.suffix = ''});

  final int value;
  final TextStyle? style;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: AppMotion.of(context, const Duration(milliseconds: 900)),
      curve: AppMotion.easeOut,
      builder: (context, v, _) => Text('${v.round()}$suffix', style: style),
    );
  }
}

/// Sacudida horizontal amortiguada para respuestas incorrectas.
/// Cambia `trigger` para disparar la sacudida.
class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(Shake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger && !AppMotion.reduced(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _c.value;
        final dx = math.sin(t * math.pi * 6) * 9 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}

/// Pulso suave en bucle (anillo que se expande y desvanece). Señala
/// "aquí hay algo disponible". Se desactiva con "Quitar animaciones".
class PulseRing extends StatefulWidget {
  const PulseRing({
    super.key,
    required this.child,
    this.color = AppColors.cyan,
    this.size = 56,
    this.active = true,
  });

  final Widget child;
  final Color color;
  final double size;
  final bool active;

  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<PulseRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(PulseRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final run = widget.active && !AppMotion.reduced(context);
    if (run && !_c.isAnimating) {
      _c.repeat();
    } else if (!run && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (widget.active)
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = AppMotion.easeOut.transform(_c.value);
              return IgnorePointer(
                child: Container(
                  width: widget.size * (1 + t * 0.7),
                  height: widget.size * (1 + t * 0.7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: 0.35 * (1 - t)),
                  ),
                ),
              );
            },
          ),
        widget.child,
      ],
    );
  }
}

/// Cambia un contenido (normalmente texto) por otro SIN superponerlos: el
/// anterior se desvanece en la primera mitad y el nuevo aparece en la
/// segunda, con un leve desplazamiento hacia arriba. La altura se ajusta
/// suavemente si el nuevo texto ocupa más o menos líneas.
///
/// El [child] debe tener una `key` distinta para cada contenido.
class SequentialSwap extends StatelessWidget {
  const SequentialSwap({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 360),
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final Duration duration;
  final AlignmentGeometry alignment;

  static const _out = Interval(0.5, 1, curve: Curves.easeIn);
  static const _in = Interval(0.5, 1, curve: AppMotion.easeOut);

  @override
  Widget build(BuildContext context) {
    final d = AppMotion.of(context, duration);
    return AnimatedSize(
      duration: d,
      curve: AppMotion.easeInOut,
      alignment: alignment,
      child: AnimatedSwitcher(
        duration: d,
        // Entrante: espera la primera mitad y luego aparece.
        // Saliente (animación en reversa): se va durante la primera mitad.
        switchInCurve: _in,
        switchOutCurve: _out,
        layoutBuilder: (current, previous) =>
            Stack(alignment: alignment, children: [...previous, ?current]),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.12),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: child,
      ),
    );
  }
}
