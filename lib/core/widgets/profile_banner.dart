import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Dibuja el fondo (banner) de la tarjeta del perfil. `null` = el banner
/// azul original de la app. Todos dejan el texto blanco legible.
class BannerPainter extends CustomPainter {
  BannerPainter(this.bannerId);

  final String? bannerId;

  static const _default = [
    Color(0xFF3FC6F1),
    Color(0xFF1E6FD9),
    Color(0xFF0B57B8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    final w = size.width, h = size.height;
    // Escala de las siluetas: 1 ≈ tarjeta de perfil, ~0.35 en miniaturas.
    final k = (h / 180).clamp(0.35, 1.3);
    void gradient(
      List<Color> colors, {
      Alignment begin = Alignment.topLeft,
      Alignment end = Alignment.bottomRight,
    }) {
      canvas.drawRect(
        r,
        Paint()
          ..shader = LinearGradient(
            begin: begin,
            end: end,
            colors: colors,
          ).createShader(r),
      );
    }

    switch (bannerId) {
      case 'cielo_andino':
        gradient(
          const [Color(0xFF5DB8F0), Color(0xFF2A7FD4), Color(0xFF1B5FAF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        final cloud = Paint()..color = Colors.white.withValues(alpha: 0.22);
        for (final (x, y, s) in [
          (0.15, 0.18, 1.0),
          (0.7, 0.12, 0.8),
          (0.5, 0.32, 0.6),
        ]) {
          final c = Offset(w * x, h * y);
          canvas.drawOval(
            Rect.fromCenter(center: c, width: 90 * s, height: 30 * s),
            cloud,
          );
          canvas.drawCircle(c.translate(-14 * s, -10 * s), 18 * s, cloud);
          canvas.drawCircle(c.translate(14 * s, -12 * s), 14 * s, cloud);
        }
        _mountains(
          canvas,
          size,
          const Color(0x332A5F9E),
          const Color(0x44173F70),
        );
      case 'rio_malacatos':
        gradient(const [
          Color(0xFF1FB3E6),
          Color(0xFF0B6FB8),
          Color(0xFF094A86),
        ]);
        for (var i = 0; i < 6; i++) {
          final y = h * (0.15 + i * 0.16);
          final wave = Path()..moveTo(0, y);
          for (var x = 0.0; x <= w; x += 20) {
            wave.lineTo(x, y + math.sin(x / 26 + i) * 6);
          }
          canvas.drawPath(
            wave,
            Paint()
              ..color = Colors.white.withValues(
                alpha: 0.10 + (i.isEven ? 0.06 : 0),
              )
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5
              ..strokeCap = StrokeCap.round,
          );
        }
      case 'bosque_sauces':
        gradient(const [
          Color(0xFF2E9E5B),
          Color(0xFF1F7A45),
          Color(0xFF135C33),
        ]);
        final rnd = math.Random(7);
        for (var i = 0; i < 26; i++) {
          canvas.save();
          canvas.translate(rnd.nextDouble() * w, rnd.nextDouble() * h);
          canvas.rotate(rnd.nextDouble() * math.pi);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: 10 + rnd.nextDouble() * 8,
              height: 28 + rnd.nextDouble() * 12,
            ),
            Paint()
              ..color = const Color(0xFF8DF0AA)
                  .withValues(alpha: 0.14 + rnd.nextDouble() * 0.12),
          );
          canvas.restore();
        }
      case 'atardecer_loja':
        gradient(
          const [Color(0xFFFFB25B), Color(0xFFE5577B), Color(0xFF6A3FA8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        canvas.drawCircle(
          Offset(w * 0.78, h * 0.42),
          h * 0.16,
          Paint()..color = const Color(0x66FFF3B0),
        );
        _mountains(
          canvas,
          size,
          const Color(0x55462075),
          const Color(0x77301553),
        );
      case 'laguna_jipiro':
        gradient(
          const [Color(0xFF34C4B4), Color(0xFF14808F), Color(0xFF0B5566)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        final ripple = Paint()
          ..color = Colors.white.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        for (final (x, y) in [
          (0.2, 0.75),
          (0.55, 0.62),
          (0.82, 0.85),
          (0.4, 0.9),
        ]) {
          for (var k = 1; k <= 3; k++) {
            canvas.drawOval(
              Rect.fromCenter(
                center: Offset(w * x, h * y),
                width: 20.0 * k,
                height: 6.0 * k,
              ),
              ripple,
            );
          }
        }
        // pagoda de Jipiro en silueta
        final p = Paint()..color = const Color(0x33052E38);
        final bx = w * 0.82, by = h * 0.5 + 10 * k;
        for (var i = 0; i < 3; i++) {
          final lw = (46.0 - i * 12) * k, y = by - i * 16 * k;
          canvas.drawPath(
            Path()
              ..moveTo(bx - lw / 2, y)
              ..lineTo(bx + lw / 2, y)
              ..lineTo(bx + lw * 0.3, y - 10 * k)
              ..lineTo(bx - lw * 0.3, y - 10 * k)
              ..close(),
            p,
          );
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(bx, y + 4 * k),
              width: lw * 0.5,
              height: 8 * k,
            ),
            p,
          );
        }
      case 'noche_estrellada':
        gradient(
          const [Color(0xFF1B2A6B), Color(0xFF101A47), Color(0xFF070D2B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        final rnd = math.Random(11);
        for (var i = 0; i < 46; i++) {
          canvas.drawCircle(
            Offset(rnd.nextDouble() * w, rnd.nextDouble() * h),
            0.8 + rnd.nextDouble() * 1.8,
            Paint()
              ..color = Colors.white.withValues(
                alpha: 0.4 + rnd.nextDouble() * 0.6,
              ),
          );
        }
        final moon = Offset(w * 0.84, h * 0.2);
        canvas.drawCircle(moon, 20, Paint()..color = const Color(0xFFFFF3C4));
        canvas.drawCircle(
          moon.translate(8, -5),
          18,
          Paint()..color = const Color(0xFF16235C),
        );
      case 'puerta_ciudad':
        gradient(const [
          Color(0xFFF0A23B),
          Color(0xFFC8423B),
          Color(0xFF7A2346),
        ]);
        // Castillo de la Puerta de la Ciudad en silueta, escalado al alto
        // del banner para que también quepa entero en las miniaturas.
        final c = Paint()..color = const Color(0x40300A1C);
        final base = h, cx = w - 76 * k;
        canvas.drawRect(
          Rect.fromLTRB(cx - 60 * k, base - 70 * k, cx + 60 * k, base),
          c,
        );
        for (final dx in [-60.0, 40.0]) {
          canvas.drawRect(
            Rect.fromLTWH(cx + dx * k, base - 100 * k, 20 * k, 100 * k),
            c,
          );
          for (var i = 0; i < 3; i++) {
            canvas.drawRect(
              Rect.fromLTWH(
                cx + (dx + i * 7) * k,
                base - 108 * k,
                5 * k,
                8 * k,
              ),
              c,
            );
          }
        }
        canvas.drawPath(
          Path()
            ..moveTo(cx - 18 * k, base)
            ..lineTo(cx - 18 * k, base - 34 * k)
            ..arcToPoint(
              Offset(cx + 18 * k, base - 34 * k),
              radius: Radius.circular(18 * k),
            )
            ..lineTo(cx + 18 * k, base)
            ..close(),
          Paint()..color = const Color(0x30FFFFFF),
        );
      case 'aurora_gotitas':
        gradient(const [
          Color(0xFF7B4FC9),
          Color(0xFF1E88E5),
          Color(0xFF12BDEA),
          Color(0xFF4CC371),
        ]);
        final rnd = math.Random(23);
        const colors = [
          Color(0xFFFFE27A),
          Color(0xFFFF8FA3),
          Color(0xFF8DF0AA),
          Colors.white,
          Color(0xFFB9F0FF),
        ];
        for (var i = 0; i < 22; i++) {
          _drop(
            canvas,
            Offset(rnd.nextDouble() * w, rnd.nextDouble() * h),
            4 + rnd.nextDouble() * 6,
            colors[i % colors.length].withValues(
              alpha: 0.35 + rnd.nextDouble() * 0.35,
            ),
          );
        }
      default:
        gradient(_default);
    }
    // Velo inferior: asegura contraste del texto blanco en todos los banners.
    canvas.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0x22000000)],
        ).createShader(r),
    );
  }

  void _mountains(Canvas canvas, Size size, Color back, Color front) {
    final w = size.width, h = size.height;
    canvas.drawPath(
      Path()
        ..moveTo(0, h)
        ..lineTo(0, h * 0.62)
        ..lineTo(w * 0.22, h * 0.42)
        ..lineTo(w * 0.42, h * 0.6)
        ..lineTo(w * 0.66, h * 0.36)
        ..lineTo(w, h * 0.58)
        ..lineTo(w, h)
        ..close(),
      Paint()..color = back,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, h)
        ..lineTo(0, h * 0.8)
        ..lineTo(w * 0.3, h * 0.66)
        ..lineTo(w * 0.55, h * 0.82)
        ..lineTo(w * 0.8, h * 0.64)
        ..lineTo(w, h * 0.78)
        ..lineTo(w, h)
        ..close(),
      Paint()..color = front,
    );
  }

  void _drop(Canvas canvas, Offset c, double r, Color color) {
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - r * 1.4)
        ..quadraticBezierTo(c.dx + r, c.dy - r * 0.2, c.dx + r, c.dy + r * 0.4)
        ..arcToPoint(
          Offset(c.dx - r, c.dy + r * 0.4),
          radius: Radius.circular(r),
        )
        ..quadraticBezierTo(c.dx - r, c.dy - r * 0.2, c.dx, c.dy - r * 1.4)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(BannerPainter old) => old.bannerId != bannerId;
}

/// Caja con el banner de fondo y bordes redondeados. Al cambiar de banner
/// el fondo se funde con el nuevo sin mover el contenido.
class ProfileBanner extends StatelessWidget {
  const ProfileBanner({
    super.key,
    required this.bannerId,
    required this.child,
    this.radius = 30,
    this.padding = const EdgeInsets.all(18),
  });

  final String? bannerId;
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: const [
          BoxShadow(
            color: Color(0x400B57B8),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: AppMotion.of(context, AppMotion.slow),
                switchInCurve: AppMotion.easeOut,
                layoutBuilder: (current, previous) => Stack(
                  fit: StackFit.expand,
                  children: [...previous, ?current],
                ),
                child: CustomPaint(
                  key: ValueKey(bannerId),
                  painter: BannerPainter(bannerId),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// Muestra pequeña del banner para las fichas de la tienda.
class BannerSwatch extends StatelessWidget {
  const BannerSwatch({super.key, required this.bannerId, this.height = 64});

  final String? bannerId;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: BannerPainter(bannerId)),
      ),
    );
  }
}
