import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Descripción declarativa de una escena ilustrada de río.
@immutable
class SceneSpec {
  const SceneSpec({
    this.skyTop = const Color(0xFFBFE4FB),
    this.skyBottom = const Color(0xFFEAF6FE),
    this.mountains = true,
    this.city = false,
    this.willows = 4,
    this.bridge = false,
    this.path = false,
    this.lake = false,
    this.rain = false,
    this.birds = true,
    this.erosion = 0,
    this.waterLevel = 0,
    this.seed = 1,
  });

  final Color skyTop;
  final Color skyBottom;
  final bool mountains;
  final bool city;
  final int willows;
  final bool bridge;
  final bool path;
  final bool lake;
  final bool rain;
  final bool birds;

  /// 0 = orilla protegida, 1 = orilla erosionada (sin árboles, agua turbia).
  final double erosion;

  /// 0 = caudal normal, 1 = crecida máxima.
  final double waterLevel;
  final int seed;

  SceneSpec copyWith({double? erosion, double? waterLevel, bool? rain}) =>
      SceneSpec(
        skyTop: skyTop,
        skyBottom: skyBottom,
        mountains: mountains,
        city: city,
        willows: willows,
        bridge: bridge,
        path: path,
        lake: lake,
        rain: rain ?? this.rain,
        birds: birds,
        erosion: erosion ?? this.erosion,
        waterLevel: waterLevel ?? this.waterLevel,
        seed: seed,
      );

  // Escenas predefinidas
  static const valley = SceneSpec(city: true, willows: 3, seed: 3);
  static const park = SceneSpec(willows: 5, bridge: true, path: true, seed: 7);
  static const river = SceneSpec(willows: 3, seed: 11, birds: true);
  static const nature = SceneSpec(
    willows: 7,
    seed: 5,
    skyTop: Color(0xFFCDEBD9),
    skyBottom: Color(0xFFF0FBF4),
  );
  static const jipiro = SceneSpec(
    lake: true,
    willows: 4,
    bridge: true,
    seed: 9,
  );
  static const storm = SceneSpec(
    rain: true,
    willows: 2,
    city: true,
    waterLevel: 0.6,
    birds: false,
    skyTop: Color(0xFF9DB3C8),
    skyBottom: Color(0xFFD5E2EC),
    seed: 4,
  );
}

/// Widget de conveniencia que pinta una [SceneSpec].
class SceneIllustration extends StatelessWidget {
  const SceneIllustration({super.key, required this.spec, this.child});

  final SceneSpec spec;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: ScenePainter(spec),
        child: child ?? const SizedBox.expand(),
      ),
    );
  }
}

class ScenePainter extends CustomPainter {
  ScenePainter(this.spec);

  final SceneSpec spec;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final e = spec.erosion.clamp(0.0, 1.0);
    final rnd = math.Random(spec.seed);
    canvas.clipRect(Offset.zero & size);

    // Cielo
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [spec.skyTop, spec.skyBottom],
        ).createShader(Offset.zero & size),
    );
    if (!spec.rain) {
      canvas.drawCircle(
        Offset(w * 0.82, h * 0.16),
        h * 0.09,
        Paint()..color = const Color(0x66FFF3B0),
      );
      canvas.drawCircle(
        Offset(w * 0.82, h * 0.16),
        h * 0.055,
        Paint()..color = const Color(0xCCFFF6C9),
      );
    }

    // Montañas lejanas (Andes)
    if (spec.mountains) {
      final far = Path()..moveTo(0, h * 0.5);
      var x = 0.0;
      var up = true;
      while (x < w) {
        final step = w * (0.12 + rnd.nextDouble() * 0.1);
        x += step;
        far.lineTo(x, up ? h * (0.18 + rnd.nextDouble() * 0.12) : h * 0.42);
        up = !up;
      }
      far
        ..lineTo(w, h * 0.6)
        ..lineTo(0, h * 0.6)
        ..close();
      canvas.drawPath(far, Paint()..color = const Color(0xFFB4D5EC));
    }

    // Colinas
    final hillColor = Color.lerp(
      const Color(0xFF8CCF95),
      const Color(0xFFCBB27E),
      e,
    )!;
    final hills = Path()
      ..moveTo(0, h * 0.5)
      ..quadraticBezierTo(w * 0.25, h * 0.36, w * 0.5, h * 0.48)
      ..quadraticBezierTo(w * 0.78, h * 0.6, w, h * 0.44)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hills, Paint()..color = hillColor);

    if (spec.city) _city(canvas, w, h, rnd);

    // Orilla trasera
    final backBank = Color.lerp(
      const Color(0xFF6DBE7A),
      const Color(0xFFB99A63),
      e,
    )!;
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.56, w, h * 0.44),
      Paint()..color = backBank,
    );

    // Árboles de la orilla trasera (sauces). La erosión los convierte en tocones.
    final trees = (spec.willows * (1 - e)).round();
    for (var i = 0; i < spec.willows; i++) {
      final tx = w * (0.08 + i * (0.84 / math.max(1, spec.willows - 1)));
      final ty = h * (0.6 + rnd.nextDouble() * 0.03);
      if (i < trees) {
        _willow(canvas, Offset(tx, ty), h * (0.17 + rnd.nextDouble() * 0.05));
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(tx, ty),
              width: h * 0.03,
              height: h * 0.035,
            ),
            const Radius.circular(2),
          ),
          Paint()..color = const Color(0xFF7B5A3A),
        );
      }
    }

    // Agua
    final water = Color.lerp(
      const Color(0xFF47C0EA),
      const Color(0xFF8C9A68),
      e * 0.75,
    )!;
    final level = spec.waterLevel.clamp(0.0, 1.0);
    if (spec.lake) {
      final lake = Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.8),
        width: w * 0.95,
        height: h * (0.3 + level * 0.2),
      );
      canvas.drawOval(lake, Paint()..color = water);
      _pagoda(canvas, Offset(w * 0.3, h * 0.66), h * 0.24);
    } else {
      final top = h * (0.68 - level * 0.16);
      final river = Path()
        ..moveTo(0, top + h * 0.04)
        ..cubicTo(w * 0.3, top - h * 0.03, w * 0.6, top + h * 0.07, w, top)
        ..lineTo(w, h * 0.88)
        ..cubicTo(w * 0.6, h * 0.95, w * 0.3, h * 0.84, 0, h * 0.9)
        ..close();
      canvas.drawPath(river, Paint()..color = water);
      final ripple = Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = math.max(1.5, h * 0.008)
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 5; i++) {
        final rx = w * (0.1 + i * 0.19);
        final ry = top + h * (0.08 + (i.isEven ? 0.04 : 0.09));
        canvas.drawLine(Offset(rx, ry), Offset(rx + w * 0.07, ry), ripple);
      }
      if (spec.bridge) _bridge(canvas, w, h, top);
    }

    // Orilla delantera
    final front = Color.lerp(
      const Color(0xFF5FB56B),
      const Color(0xFFA9895A),
      e,
    )!;
    final frontPath = Path()
      ..moveTo(0, h * 0.9)
      ..cubicTo(w * 0.3, h * 0.84, w * 0.6, h * 0.95, w, h * 0.88)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(frontPath, Paint()..color = front);
    if (e > 0.3) {
      // Grietas de erosión en la orilla
      final crack = Paint()
        ..color = const Color(0xFF7B5A3A).withValues(alpha: e)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;
      for (var i = 0; i < 4; i++) {
        final cx = w * (0.15 + i * 0.22);
        canvas.drawPath(
          Path()
            ..moveTo(cx, h * 0.92)
            ..lineTo(cx + 6, h * 0.95)
            ..lineTo(cx + 2, h * 0.99),
          crack,
        );
      }
    }
    if (spec.path) {
      canvas.drawPath(
        Path()
          ..moveTo(w * 0.05, h)
          ..quadraticBezierTo(w * 0.3, h * 0.93, w * 0.62, h * 0.9)
          ..lineTo(w * 0.7, h * 0.91)
          ..quadraticBezierTo(w * 0.4, h * 0.96, w * 0.2, h),
        Paint()..color = const Color(0xFFEBD9B4),
      );
    }

    if (spec.birds && !spec.rain) {
      final bird = Paint()
        ..color = const Color(0xFF3D5368)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 3; i++) {
        final b = Offset(w * (0.2 + i * 0.09), h * (0.14 + i * 0.04));
        final s = h * 0.025;
        canvas.drawPath(
          Path()
            ..moveTo(b.dx - s, b.dy)
            ..quadraticBezierTo(b.dx - s / 2, b.dy - s * 0.7, b.dx, b.dy)
            ..quadraticBezierTo(b.dx + s / 2, b.dy - s * 0.7, b.dx + s, b.dy),
          bird,
        );
      }
    }

    if (spec.rain) {
      final drop = Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 60; i++) {
        final x = rnd.nextDouble() * w;
        final y = rnd.nextDouble() * h * 0.9;
        canvas.drawLine(Offset(x, y), Offset(x - 4, y + 10), drop);
      }
    }
  }

  void _willow(Canvas canvas, Offset base, double height) {
    final trunk = Paint()
      ..color = const Color(0xFF7A5434)
      ..strokeWidth = height * 0.09
      ..strokeCap = StrokeCap.round;
    final top = base.translate(0, -height * 0.75);
    canvas.drawLine(base, top, trunk);
    final crown = Rect.fromCenter(
      center: top,
      width: height * 0.95,
      height: height * 0.6,
    );
    canvas.drawOval(crown, Paint()..color = const Color(0xFF4FAE5C));
    canvas.drawOval(
      crown.shift(Offset(-height * 0.08, -height * 0.06)).deflate(height * 0.1),
      Paint()..color = const Color(0xFF79C978),
    );
    // Ramas colgantes del sauce llorón
    final droop = Paint()
      ..color = const Color(0xFF3F9A4D)
      ..strokeWidth = math.max(1.2, height * 0.035)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = -3; i <= 3; i++) {
      final sx = top.dx + i * height * 0.12;
      canvas.drawPath(
        Path()
          ..moveTo(sx, top.dy + height * 0.05)
          ..quadraticBezierTo(
            sx + i * 2,
            top.dy + height * 0.4,
            sx + i * 3,
            top.dy + height * (0.55 + (i.abs() % 2) * 0.12),
          ),
        droop,
      );
    }
  }

  void _city(Canvas canvas, double w, double h, math.Random rnd) {
    final wall = Paint()..color = const Color(0xFFF4EDE2);
    final roof = Paint()..color = const Color(0xFFD9774B);
    final win = Paint()..color = const Color(0xFF9FB8CC);
    var x = w * 0.18;
    while (x < w * 0.86) {
      final bw = w * (0.05 + rnd.nextDouble() * 0.04);
      final bh = h * (0.08 + rnd.nextDouble() * 0.08);
      final r = Rect.fromLTWH(x, h * 0.56 - bh, bw, bh);
      canvas.drawRect(r, wall);
      canvas.drawPath(
        Path()
          ..moveTo(r.left - 2, r.top)
          ..lineTo(r.center.dx, r.top - bh * 0.3)
          ..lineTo(r.right + 2, r.top)
          ..close(),
        roof,
      );
      canvas.drawRect(
        Rect.fromLTWH(r.left + bw * 0.3, r.top + bh * 0.3, bw * 0.4, bh * 0.25),
        win,
      );
      x += bw + w * 0.01;
    }
    // Torre de la catedral
    final t = Rect.fromLTWH(w * 0.5, h * 0.3, w * 0.045, h * 0.26);
    canvas.drawRect(t, wall);
    canvas.drawPath(
      Path()
        ..moveTo(t.left - 2, t.top)
        ..lineTo(t.center.dx, t.top - h * 0.08)
        ..lineTo(t.right + 2, t.top)
        ..close(),
      Paint()..color = const Color(0xFF3E7FA8),
    );
  }

  void _bridge(Canvas canvas, double w, double h, double waterTop) {
    final wood = Paint()
      ..color = const Color(0xFF8A5A33)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(3, h * 0.025)
      ..strokeCap = StrokeCap.round;
    final l = Offset(w * 0.5, waterTop + h * 0.02);
    final r = Offset(w * 0.86, waterTop + h * 0.0);
    final arc = Path()
      ..moveTo(l.dx, l.dy)
      ..quadraticBezierTo((l.dx + r.dx) / 2, waterTop - h * 0.1, r.dx, r.dy);
    canvas.drawPath(arc, wood);
    canvas.drawPath(
      arc.shift(Offset(0, -h * 0.05)),
      wood..strokeWidth = math.max(2, h * 0.012),
    );
    final post = Paint()
      ..color = const Color(0xFF8A5A33)
      ..strokeWidth = math.max(1.6, h * 0.01);
    for (var i = 1; i < 6; i++) {
      final t = i / 6;
      final x = l.dx + (r.dx - l.dx) * t;
      final y = l.dy + (r.dy - l.dy) * t - math.sin(t * math.pi) * h * 0.05;
      canvas.drawLine(Offset(x, y), Offset(x, y - h * 0.05), post);
    }
  }

  void _pagoda(Canvas canvas, Offset base, double height) {
    final red = Paint()..color = const Color(0xFFC8423B);
    final body = Paint()..color = const Color(0xFFF6E7C8);
    for (var i = 0; i < 3; i++) {
      final lw = height * (0.55 - i * 0.12);
      final y = base.dy - i * height * 0.28;
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(base.dx, y - height * 0.08),
          width: lw * 0.6,
          height: height * 0.16,
        ),
        body,
      );
      canvas.drawPath(
        Path()
          ..moveTo(base.dx - lw / 2, y - height * 0.15)
          ..lineTo(base.dx + lw / 2, y - height * 0.15)
          ..lineTo(base.dx + lw * 0.3, y - height * 0.26)
          ..lineTo(base.dx - lw * 0.3, y - height * 0.26)
          ..close(),
        red,
      );
    }
  }

  @override
  bool shouldRepaint(ScenePainter old) =>
      old.spec.erosion != spec.erosion ||
      old.spec.waterLevel != spec.waterLevel ||
      old.spec.rain != spec.rain ||
      old.spec.seed != spec.seed ||
      old.spec.lake != spec.lake;
}
