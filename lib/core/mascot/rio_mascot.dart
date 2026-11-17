import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

enum MascotMood { happy, cheer, wow, thinking, sad }

enum MascotAccessory { none, magnifier, glasses }

/// "Río", la gota guardiana. Se dibuja por completo con [CustomPainter], así
/// escala sin pérdida y puede cambiar de expresión según el contexto.
///
/// Animaciones:
/// * Flotación senoidal continua (se apaga con "Quitar animaciones").
/// * Parpadeo en intervalos aleatorios de 2.2–4.6 s.
/// * Salto con [SpringSimulation] al tocarla: el resorte conserva la
///   velocidad, así varios toques seguidos se encadenan sin cortes.
class RioMascot extends StatefulWidget {
  const RioMascot({
    super.key,
    this.size = 140,
    this.mood = MascotMood.happy,
    this.accessory = MascotAccessory.none,
    this.interactive = true,
    this.idle = true,
  });

  final double size;
  final MascotMood mood;
  final MascotAccessory accessory;
  final bool interactive;
  final bool idle;

  @override
  State<RioMascot> createState() => RioMascotState();
}

class RioMascotState extends State<RioMascot> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  );
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
  );
  late final AnimationController _hop = AnimationController.unbounded(
    vsync: this,
  );
  final _rand = math.Random();
  Timer? _blinkTimer;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _scheduleBlink();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = AppMotion.reduced(context);
    if (widget.idle && !_reduced) {
      if (!_idle.isAnimating) _idle.repeat();
    } else {
      _idle.stop();
    }
  }

  void _scheduleBlink() {
    _blinkTimer = Timer(
      Duration(milliseconds: 2200 + _rand.nextInt(2400)),
      () async {
        if (!mounted) return;
        await _blink.forward();
        if (!mounted) return;
        await _blink.reverse();
        if (mounted) _scheduleBlink();
      },
    );
  }

  /// Hace saltar a la mascota. Puede llamarse desde fuera (celebraciones).
  void hop({double strength = 7}) {
    if (_reduced) return;
    _hop.animateWith(
      SpringSimulation(AppMotion.bouncy, _hop.value, 0, strength),
    );
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _idle.dispose();
    _blink.dispose();
    _hop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // `CustomPaint.size` es solo una preferencia: si el padre impone
    // restricciones estrictas (p. ej. el ícono de un AlertDialog, que se
    // estira a todo el ancho) el dibujo se escalaría a ese tamaño. Se fija
    // el tamaño con un SizedBox centrado para que siempre mida `size`.
    final painter = Center(
      widthFactor: 1,
      heightFactor: 1,
      child: SizedBox(
        width: widget.size,
        height: widget.size * 1.18,
        child: AnimatedBuilder(
          animation: Listenable.merge([_idle, _blink, _hop]),
          builder: (context, _) => CustomPaint(
            painter: _RioPainter(
              phase: _idle.value,
              blink: _blink.value,
              hop: _hop.value,
              mood: widget.mood,
              accessory: widget.accessory,
            ),
          ),
        ),
      ),
    );
    return Semantics(
      label: 'Río, la gota guardiana',
      image: true,
      child: widget.interactive
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.lightImpact();
                hop();
              },
              child: painter,
            )
          : painter,
    );
  }
}

class _RioPainter extends CustomPainter {
  _RioPainter({
    required this.phase,
    required this.blink,
    required this.hop,
    required this.mood,
    required this.accessory,
  });

  final double phase;
  final double blink;
  final double hop;
  final MascotMood mood;
  final MascotAccessory accessory;

  static const _ink = Color(0xFF0B2236);

  static Path dropPath() => Path()
    ..moveTo(50, 6)
    ..cubicTo(58, 24, 92, 52, 92, 80)
    ..cubicTo(92, 104, 73, 118, 50, 118)
    ..cubicTo(27, 118, 8, 104, 8, 80)
    ..cubicTo(8, 52, 42, 24, 50, 6)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    // Espacio de diseño: 100 x 118 unidades.
    final s = size.width / 100;
    canvas.scale(s);

    final wave = math.sin(phase * math.pi * 2);
    final bob = wave * 2.4;
    // El resorte oscila alrededor de 0 con picos de ~0.4: se amplifica a
    // ~15 unidades de salto y a ±10 % de estiramiento.
    final lift = hop * 36;
    final squash = (hop * 0.25).clamp(-0.1, 0.1);

    // Sombra en el piso: se encoge cuando la gota sube.
    final shadowScale = 1 - ((-bob + lift) / 40).clamp(-0.2, 0.4);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(50, 116),
        width: 52 * shadowScale,
        height: 7 * shadowScale,
      ),
      Paint()..color = const Color(0x22093A57),
    );

    canvas.save();
    canvas.translate(0, bob - lift - 4);
    // Estirar y aplastar alrededor de la base.
    canvas.translate(50, 118);
    canvas.scale(1 - squash, 1 + squash);
    canvas.translate(-50, -118);

    final body = dropPath();

    // Hoja que se mece sobre la punta.
    _drawLeaf(canvas, wave);

    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF63DAF8), Color(0xFF16B4E6), Color(0xFF0A6E90)],
          stops: [0, 0.55, 1],
        ).createShader(const Rect.fromLTWH(0, 0, 100, 118)),
    );

    // Cinta verde, recortada a la silueta de la gota.
    canvas.save();
    canvas.clipPath(body);
    canvas.drawRect(
      const Rect.fromLTWH(0, 36, 100, 9),
      Paint()..color = AppColors.green,
    );
    canvas.drawRect(
      const Rect.fromLTWH(0, 43, 100, 2),
      Paint()..color = AppColors.greenDark,
    );
    canvas.restore();
    canvas.drawCircle(
      const Offset(50, 40.5),
      2.6,
      Paint()..color = AppColors.mint,
    );

    // Brillo lateral.
    final shine = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(22, 64)
        ..quadraticBezierTo(17, 84, 28, 102),
      shine,
    );
    canvas.drawOval(
      const Rect.fromLTWH(24, 49, 9, 6),
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );

    _drawFace(canvas);
    _drawAccessory(canvas, wave);
    canvas.restore();
  }

  void _drawLeaf(Canvas canvas, double wave) {
    canvas.save();
    canvas.translate(51, 10);
    canvas.rotate(-0.25 + wave * 0.14);
    final leaf = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(4, -16, 19, -20)
      ..quadraticBezierTo(17, -5, 0, 0)
      ..close();
    canvas.drawPath(leaf, Paint()..color = AppColors.green);
    canvas.drawLine(
      Offset.zero,
      const Offset(12, -12),
      Paint()
        ..color = AppColors.greenDark
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  void _drawFace(Canvas canvas) {
    final ink = Paint()..color = _ink;
    final white = Paint()..color = Colors.white;
    const leftEye = Offset(37, 76);
    const rightEye = Offset(63, 76);

    // Rubor
    final blush = Paint()..color = const Color(0xCCFFB4C2);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(27, 87), width: 12, height: 6.5),
      blush,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(73, 87), width: 12, height: 6.5),
      blush,
    );

    if (mood == MascotMood.cheer) {
      // Ojos felices "^ ^"
      final arc = Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round;
      for (final e in [leftEye, rightEye]) {
        canvas.drawPath(
          Path()
            ..moveTo(e.dx - 5, e.dy + 2)
            ..quadraticBezierTo(e.dx, e.dy - 6, e.dx + 5, e.dy + 2),
          arc,
        );
      }
    } else {
      final open = 1 - blink * 0.92;
      final look = mood == MascotMood.thinking
          ? const Offset(2.2, -1.5)
          : Offset.zero;
      for (final e in [leftEye, rightEye]) {
        final c = e + look;
        canvas.drawOval(
          Rect.fromCenter(center: c, width: 10, height: 13 * open),
          ink,
        );
        if (open > 0.5) {
          canvas.drawCircle(c + const Offset(1.8, -3), 2.1, white);
          canvas.drawCircle(c + const Offset(-1.6, 2.6), 1, white);
        }
      }
      if (mood == MascotMood.sad) {
        final brow = Paint()
          ..color = _ink
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(const Offset(31, 66), const Offset(40, 63), brow);
        canvas.drawLine(const Offset(69, 66), const Offset(60, 63), brow);
      }
    }

    switch (mood) {
      case MascotMood.happy:
      case MascotMood.cheer:
        final w = mood == MascotMood.cheer ? 20.0 : 15.0;
        final mouth = Path()
          ..moveTo(50 - w / 2, 87)
          ..quadraticBezierTo(50, 87 + w * 0.95, 50 + w / 2, 87)
          ..close();
        canvas.drawPath(mouth, ink);
        canvas.save();
        canvas.clipPath(mouth);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(50, 87 + w * 0.5),
            width: w * 0.6,
            height: w * 0.4,
          ),
          Paint()..color = const Color(0xFFE5394A),
        );
        canvas.restore();
      case MascotMood.wow:
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(50, 92), width: 8, height: 10),
          ink,
        );
      case MascotMood.thinking:
        canvas.drawLine(
          const Offset(45, 92),
          const Offset(56, 90),
          Paint()
            ..color = _ink
            ..strokeWidth = 2.6
            ..strokeCap = StrokeCap.round,
        );
      case MascotMood.sad:
        canvas.drawPath(
          Path()
            ..moveTo(43, 95)
            ..quadraticBezierTo(50, 88, 57, 95),
          Paint()
            ..color = _ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.8
            ..strokeCap = StrokeCap.round,
        );
    }
  }

  void _drawAccessory(Canvas canvas, double wave) {
    switch (accessory) {
      case MascotAccessory.none:
        return;
      case MascotAccessory.glasses:
        final frame = Paint()..color = const Color(0xFF14202E);
        final lens = Paint()..color = const Color(0xFF243B53);
        for (final cx in [36.0, 64.0]) {
          final r = RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, 75), width: 20, height: 14),
            const Radius.circular(6),
          );
          canvas.drawRRect(r.inflate(1.6), frame);
          canvas.drawRRect(r, lens);
          canvas.drawLine(
            Offset(cx - 5, 71),
            Offset(cx - 1, 71),
            Paint()
              ..color = Colors.white.withValues(alpha: 0.7)
              ..strokeWidth = 1.6
              ..strokeCap = StrokeCap.round,
          );
        }
        canvas.drawLine(
          const Offset(46, 74),
          const Offset(54, 74),
          frame..strokeWidth = 2.6,
        );
      case MascotAccessory.magnifier:
        canvas.save();
        canvas.translate(82, 62);
        canvas.rotate(wave * 0.08);
        canvas.drawLine(
          const Offset(6, 8),
          const Offset(16, 20),
          Paint()
            ..color = AppColors.tealDark
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(
          Offset.zero,
          10,
          Paint()..color = Colors.white.withValues(alpha: 0.55),
        );
        canvas.drawCircle(
          Offset.zero,
          10,
          Paint()
            ..color = AppColors.teal
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.4,
        );
        canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_RioPainter old) =>
      old.phase != phase ||
      old.blink != blink ||
      old.hop != hop ||
      old.mood != mood ||
      old.accessory != accessory;
}

/// Burbuja de diálogo "Río dice: ..." con la mascota en miniatura.
class RioSays extends StatelessWidget {
  const RioSays({
    super.key,
    required this.message,
    this.mood = MascotMood.happy,
    this.label = 'Río dice:',
    this.tag,
    this.accessory = MascotAccessory.none,
  });

  final String message;
  final MascotMood mood;
  final String label;
  final String? tag;
  final MascotAccessory accessory;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.cyanSoft,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: RioMascot(
            size: 38,
            mood: mood,
            accessory: accessory,
            interactive: false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
                topLeft: Radius.circular(6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x100B3B66),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      label,
                      style: t.titleSmall?.copyWith(color: AppColors.teal),
                    ),
                    if (tag != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cyanSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tag!,
                          style: t.labelSmall?.copyWith(
                            color: AppColors.tealDark,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: t.bodyMedium?.copyWith(color: AppColors.ink),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
