import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Dibuja un sombrero de la tienda. Espacio de diseño: 100 × 64, con la
/// base del sombrero (lo que apoya en la cabeza) cerca de y = 60.
class HatPainter extends CustomPainter {
  HatPainter(this.hatId);

  final String hatId;

  static const _ink = Color(0xFF1B2A38);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 64);
    final outline = Paint()
      ..color = _ink.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    void fill(Path p, Color c) {
      canvas.drawPath(p, Paint()..color = c);
      canvas.drawPath(p, outline);
    }

    switch (hatId) {
      case 'gorra_explorador':
        fill(
          Path()..addOval(const Rect.fromLTWH(48, 48, 50, 12)),
          const Color(0xFF0A7FA2),
        ); // visera
        fill(
          Path()
            ..moveTo(14, 56)
            ..cubicTo(14, 18, 76, 18, 76, 56)
            ..close(),
          const Color(0xFF12BDEA),
        );
        canvas.drawLine(
          const Offset(45, 22),
          const Offset(45, 56),
          Paint()
            ..color = const Color(0x330B2236)
            ..strokeWidth = 2,
        );
        canvas.drawCircle(
          const Offset(45, 22),
          4,
          Paint()..color = const Color(0xFF0A7FA2),
        );
        _drop(canvas, const Offset(33, 42), 5, Colors.white);
      case 'pescador':
        fill(
          Path()
            ..moveTo(6, 58)
            ..quadraticBezierTo(50, 44, 94, 58)
            ..quadraticBezierTo(50, 64, 6, 58),
          const Color(0xFF6E8B3D),
        );
        fill(
          Path()
            ..moveTo(22, 52)
            ..lineTo(28, 24)
            ..quadraticBezierTo(50, 16, 72, 24)
            ..lineTo(78, 52)
            ..close(),
          const Color(0xFF8DAA55),
        );
        canvas.drawRect(
          const Rect.fromLTWH(24, 44, 52, 6),
          Paint()..color = const Color(0xFF4F6B2A),
        );
        // anzuelo de adorno
        canvas.drawArc(
          const Rect.fromLTWH(60, 30, 8, 10),
          0,
          math.pi,
          false,
          Paint()
            ..color = const Color(0xFFB0BEC5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      case 'chullo':
        fill(
          Path()
            ..moveTo(14, 54)
            ..cubicTo(14, 12, 86, 12, 86, 54)
            ..close(),
          const Color(0xFFC8423B),
        );
        for (final (y, c) in [
          (30.0, Colors.white),
          (40.0, const Color(0xFF0B57B8)),
          (48.0, Colors.white),
        ]) {
          final zig = Path()..moveTo(16, y);
          for (var x = 16.0; x <= 84; x += 8) {
            zig.lineTo(x + 4, y - 4);
            zig.lineTo(x + 8, y);
          }
          canvas.drawPath(
            zig,
            Paint()
              ..color = c
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.4,
          );
        }
        fill(
          Path()
            ..moveTo(16, 50)
            ..lineTo(10, 64)
            ..lineTo(24, 56)
            ..close(),
          const Color(0xFFC8423B),
        ); // orejeras
        fill(
          Path()
            ..moveTo(84, 50)
            ..lineTo(90, 64)
            ..lineTo(76, 56)
            ..close(),
          const Color(0xFFC8423B),
        );
        canvas.drawCircle(
          const Offset(50, 12),
          7,
          Paint()..color = const Color(0xFFF6CF4E),
        ); // pompón
      case 'guardaparques':
        fill(
          Path()..addOval(const Rect.fromLTWH(2, 46, 96, 16)),
          const Color(0xFF8A6A3D),
        );
        fill(
          Path()
            ..moveTo(26, 52)
            ..lineTo(32, 18)
            ..lineTo(42, 24)
            ..lineTo(50, 14)
            ..lineTo(58, 24)
            ..lineTo(68, 18)
            ..lineTo(74, 52)
            ..close(),
          const Color(0xFFB08A52),
        );
        canvas.drawRect(
          const Rect.fromLTWH(27, 42, 46, 7),
          Paint()..color = const Color(0xFF2B8A4A),
        );
        canvas.drawCircle(
          const Offset(50, 45.5),
          3.5,
          Paint()..color = const Color(0xFFF6CF4E),
        );
      case 'detective':
        final cap = Path()
          ..moveTo(16, 54)
          ..cubicTo(16, 14, 84, 14, 84, 54)
          ..close();
        fill(cap, const Color(0xFFB98A5E));
        canvas.save();
        canvas.clipPath(cap);
        final check = Paint()
          ..color = const Color(0x55402814)
          ..strokeWidth = 2;
        for (var x = 0.0; x < 100; x += 8) {
          canvas.drawLine(Offset(x, 10), Offset(x, 60), check);
        }
        for (var y = 14.0; y < 60; y += 8) {
          canvas.drawLine(Offset(10, y), Offset(90, y), check);
        }
        canvas.restore();
        fill(
          Path()
            ..moveTo(78, 52)
            ..quadraticBezierTo(98, 52, 96, 60)
            ..lineTo(78, 58)
            ..close(),
          const Color(0xFF9C7048),
        ); // visera delantera
        fill(
          Path()
            ..moveTo(22, 52)
            ..quadraticBezierTo(2, 52, 4, 60)
            ..lineTo(22, 58)
            ..close(),
          const Color(0xFF9C7048),
        ); // visera trasera
        canvas.drawCircle(
          const Offset(50, 18),
          4,
          Paint()..color = const Color(0xFF7A4A00),
        ); // lazo
      case 'corona_sauce':
        final leaf = Paint()..color = const Color(0xFF4CC371);
        final dark = Paint()..color = const Color(0xFF2B8A4A);
        for (var i = 0; i < 9; i++) {
          final t = i / 8;
          final x = 10 + t * 80;
          final y = 54 - math.sin(t * math.pi) * 14;
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(-0.9 + t * 1.8);
          canvas.drawOval(
            const Rect.fromLTWH(-6, -14, 12, 24),
            i.isEven ? leaf : dark,
          );
          canvas.restore();
        }
        canvas.drawArc(
          const Rect.fromLTWH(10, 40, 80, 30),
          math.pi,
          math.pi,
          false,
          Paint()
            ..color = const Color(0xFF7A5434)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      case 'paja_toquilla':
        fill(
          Path()..addOval(const Rect.fromLTWH(0, 46, 100, 16)),
          const Color(0xFFE9D8A6),
        );
        fill(
          Path()
            ..moveTo(24, 52)
            ..lineTo(28, 22)
            ..quadraticBezierTo(50, 12, 72, 22)
            ..lineTo(76, 52)
            ..close(),
          const Color(0xFFF2E3B6),
        );
        canvas.drawLine(
          const Offset(50, 16),
          const Offset(50, 30),
          Paint()
            ..color = const Color(0x55A08040)
            ..strokeWidth = 2,
        ); // pliegue
        final weave = Paint()
          ..color = const Color(0x40A08040)
          ..strokeWidth = 1;
        for (var y = 26.0; y < 52; y += 5) {
          canvas.drawLine(Offset(26, y), Offset(74, y), weave);
        }
        canvas.drawRect(
          const Rect.fromLTWH(26, 42, 48, 7),
          Paint()..color = _ink,
        );
      case 'boina_musical':
        fill(
          Path()..addOval(const Rect.fromLTWH(10, 30, 82, 30)),
          const Color(0xFF7B4FC9),
        );
        canvas.drawRect(
          const Rect.fromLTWH(48, 22, 4, 10),
          Paint()..color = const Color(0xFF5A35A0),
        ); // rabito
        canvas.drawOval(
          const Rect.fromLTWH(18, 50, 64, 10),
          Paint()..color = const Color(0xFF5A35A0),
        );
        // nota musical dorada
        final gold = Paint()..color = const Color(0xFFF6CF4E);
        canvas.drawOval(const Rect.fromLTWH(62, 40, 9, 7), gold);
        canvas.drawRect(const Rect.fromLTWH(69, 26, 2.4, 17), gold);
        canvas.drawPath(
          Path()
            ..moveTo(71.4, 26)
            ..quadraticBezierTo(78, 28, 77, 34)
            ..lineTo(71.4, 31)
            ..close(),
          gold,
        );
      case 'colibri':
        final head = Path()
          ..moveTo(16, 56)
          ..cubicTo(16, 14, 80, 14, 80, 56)
          ..close();
        canvas.drawPath(
          head,
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFF2E9E5B), Color(0xFF12BDEA), Color(0xFF7B4FC9)],
            ).createShader(const Rect.fromLTWH(16, 14, 64, 42)),
        );
        canvas.drawPath(head, outline);
        fill(
          Path()
            ..moveTo(78, 36)
            ..lineTo(99, 40)
            ..lineTo(78, 44)
            ..close(),
          _ink,
        ); // pico
        canvas.drawCircle(
          const Offset(66, 33),
          5,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(const Offset(67, 33), 2.6, Paint()..color = _ink);
        fill(
          Path()
            ..moveTo(20, 40)
            ..quadraticBezierTo(4, 22, 10, 12)
            ..quadraticBezierTo(22, 24, 28, 38)
            ..close(),
          const Color(0xFF8DF0AA),
        ); // alita
      case 'corona_gotitas':
        final crown = Path()
          ..moveTo(14, 58)
          ..lineTo(10, 24)
          ..lineTo(30, 40)
          ..lineTo(50, 16)
          ..lineTo(70, 40)
          ..lineTo(90, 24)
          ..lineTo(86, 58)
          ..close();
        canvas.drawPath(
          crown,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFE27A), Color(0xFFE0A21E)],
            ).createShader(const Rect.fromLTWH(10, 16, 80, 42)),
        );
        canvas.drawPath(crown, outline);
        canvas.drawRect(
          const Rect.fromLTWH(14, 50, 72, 8),
          Paint()..color = const Color(0xFFC98A12),
        );
        for (final o in const [
          Offset(10, 22),
          Offset(50, 13),
          Offset(90, 22),
        ]) {
          _drop(canvas, o, 6, const Color(0xFF12BDEA));
        }
        _drop(canvas, const Offset(50, 46), 5, const Color(0xFF38B7EE));
    }
  }

  /// Gotita (para adornos).
  void _drop(Canvas canvas, Offset c, double r, Color color) {
    final p = Path()
      ..moveTo(c.dx, c.dy - r * 1.4)
      ..quadraticBezierTo(c.dx + r, c.dy - r * 0.2, c.dx + r, c.dy + r * 0.4)
      ..arcToPoint(Offset(c.dx - r, c.dy + r * 0.4), radius: Radius.circular(r))
      ..quadraticBezierTo(c.dx - r, c.dy - r * 0.2, c.dx, c.dy - r * 1.4)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
    canvas.drawCircle(
      c.translate(-r * 0.35, r * 0.05),
      r * 0.25,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(HatPainter old) => old.hatId != hatId;
}

/// Sombrero suelto (para la tienda).
class HatIcon extends StatelessWidget {
  const HatIcon({super.key, required this.hatId, this.width = 80});

  final String hatId;
  final double width;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(width, width * 0.64), painter: HatPainter(hatId));
}

/// Pone un sombrero sobre un avatar circular de diámetro [size]. El
/// sombrero sobresale por arriba (el padre debe dejar espacio o no recortar).
class WithHat extends StatelessWidget {
  const WithHat({
    super.key,
    required this.hatId,
    required this.size,
    required this.child,
  });

  final String? hatId;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (hatId == null) return child;
    final w = size * 0.92;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        child,
        Positioned(
          top: -size * 0.34,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: -0.14,
              child: CustomPaint(
                size: Size(w, w * 0.64),
                painter: HatPainter(hatId!),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
