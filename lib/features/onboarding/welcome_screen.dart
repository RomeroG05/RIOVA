import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/mascot/rio_mascot.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/chunky_button.dart';
import '../../core/widgets/motion_widgets.dart';
import '../../core/widgets/pressable.dart';
import '../../state/explorer_controller.dart';

const _facts = [
  '¿Sabías que los sauces nativos en el Río Malacatos actúan como esponjas gigantes protegiendo a Loja? 🌱💧',
  '¿Sabías que los ríos Malacatos y Zamora se unen en el norte de Loja y viajan hasta la Amazonía? 🌊',
  '¿Sabías que una sola botella en el río puede tardar cientos de años en desaparecer? ♻️',
  '¿Sabías que las truchas solo viven en aguas frías y limpias? 🐟',
  '¿Sabías que el bosque de Podocarpus guarda el agua que llega a Loja? 🌳',
];

/// Pantalla "Carga y bienvenida".
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sky = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  );
  int _fact = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _sky.stop();
    } else if (!_sky.isAnimating) {
      _sky.repeat();
    }
  }

  @override
  void dispose() {
    _sky.dispose();
    super.dispose();
  }

  void _enter() {
    final hasProfile = ref.read(explorerProvider).profile != null;
    if (hasProfile) {
      ref.read(explorerProvider.notifier).markActiveToday();
      context.go(Routes.home);
    } else {
      context.push(Routes.create);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final name = ref.watch(explorerProvider.select((s) => s.profile?.name));
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // De noche (modo oscuro) el cielo de Loja también oscurece.
            colors: AppColors.dark
                ? const [Color(0xFF0A1626), Color(0xFF123150)]
                : const [Color(0xFFE3F2FD), Color(0xFFC6E4FB)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 300,
              child: AnimatedBuilder(
                animation: _sky,
                builder: (context, _) =>
                    CustomPaint(painter: _SkyPainter(_sky.value)),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 56),
                    const EntranceFade(child: _Logo()),
                    const SizedBox(height: 10),
                    EntranceFade(
                      index: 1,
                      child: Text(
                        '¡Explora, juega y descubre los ríos de Loja!',
                        textAlign: TextAlign.center,
                        style: t.titleMedium?.copyWith(
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                    const Spacer(flex: 3),
                    EntranceFade(
                      index: 3,
                      child: _FactBubble(
                        text: name == null
                            ? _facts[_fact]
                            : '¡Hola de nuevo, $name! ${_facts[_fact]}',
                      ),
                    ),
                    const SizedBox(height: 14),
                    EntranceFade(
                      index: 4,
                      offset: 30,
                      child: SizedBox(
                        width: 300,
                        height: 180,
                        child: Stack(
                          children: [
                            const Center(child: RioMascot(size: 150)),
                            Positioned(
                              right: 4,
                              top: 10,
                              child: Pressable(
                                semanticLabel: 'Otro dato curioso',
                                onTap: () => setState(
                                  () => _fact = (_fact + 1) % _facts.length,
                                ),
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x1A0B3B66),
                                        blurRadius: 14,
                                        offset: Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.travel_explore_rounded,
                                    color: AppColors.teal,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(flex: 4),
                    EntranceFade(
                      index: 6,
                      child: ChunkyButton(
                        label: '¡Entrar a la Aventura!',
                        tone: ChunkyTone.green,
                        leading: Icons.explore_rounded,
                        trailing: Icons.rocket_launch_outlined,
                        height: 60,
                        onPressed: _enter,
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatefulWidget {
  const _Logo();

  @override
  State<_Logo> createState() => _LogoState();
}

class _LogoState extends State<_Logo> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!AppMotion.reduced(context) && !_spin.isAnimating) _spin.repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontFamily: 'Quicksand',
      fontSize: 56,
      fontWeight: FontWeight.w700,
      letterSpacing: 1,
      height: 1,
    );
    return Semantics(
      header: true,
      label: 'RÍOVA',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ExcludeSemantics(
            child: Text.rich(
              TextSpan(
                style: style,
                children: [
                  TextSpan(
                    text: 'RÍ',
                    style: TextStyle(color: AppColors.teal),
                  ),
                  TextSpan(
                    text: 'O',
                    style: TextStyle(color: AppColors.cyan),
                  ),
                  TextSpan(
                    text: 'VA',
                    style: TextStyle(color: AppColors.teal),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: -30,
            top: -16,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.green.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: RotationTransition(
                turns: _spin,
                child: Icon(
                  AppColors.dark
                      ? Icons.nightlight_round
                      : Icons.wb_sunny_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FactBubble extends StatelessWidget {
  const _FactBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x100B3B66),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          // Primero se va la frase anterior y luego entra la nueva: antes se
          // superponían durante el cambio.
          child: SequentialSwap(
            child: Text(
              text,
              key: ValueKey(text),
              textAlign: TextAlign.center,
              style: t.bodyLarge?.copyWith(
                color: AppColors.inkSoft,
                height: 1.4,
              ),
            ),
          ),
        ),
        // Colita de la burbuja
        Transform.translate(
          offset: const Offset(0, -6),
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 18,
              height: 18,
              color: AppColors.surface.withValues(alpha: 0.92),
            ),
          ),
        ),
      ],
    );
  }
}

/// Montañas andinas y nubes que se desplazan lentamente.
class _SkyPainter extends CustomPainter {
  _SkyPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final back = Path()
      ..moveTo(0, h * 0.62)
      ..lineTo(w * 0.05, h * 0.55)
      ..lineTo(w * 0.47, h * 0.18)
      ..lineTo(w * 0.7, h * 0.56)
      ..lineTo(w * 0.92, h * 0.22)
      ..lineTo(w, h * 0.35)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    final night = AppColors.dark;
    if (night) {
      final star = Paint()..color = Colors.white.withValues(alpha: 0.7);
      for (final (x, y, r) in const [
        (0.08, 0.08, 1.4),
        (0.22, 0.2, 1.0),
        (0.36, 0.06, 1.6),
        (0.58, 0.14, 1.1),
        (0.74, 0.05, 1.5),
        (0.88, 0.16, 1.0),
        (0.95, 0.04, 1.2),
      ]) {
        canvas.drawCircle(Offset(w * x, h * y), r * 1.6, star);
      }
    }
    canvas.drawPath(
      back,
      Paint()
        ..color = night ? const Color(0xFF173653) : const Color(0xFFB9E3F8),
    );
    final front = Path()
      ..moveTo(0, h * 0.82)
      ..lineTo(w * 0.12, h * 0.6)
      ..lineTo(w * 0.36, h * 0.85)
      ..lineTo(w * 0.58, h * 0.52)
      ..lineTo(w * 0.84, h * 0.8)
      ..lineTo(w, h * 0.66)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      front,
      Paint()
        ..color = night ? const Color(0xFF1E4A6E) : const Color(0xFF94DCF6),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.92, w, h * 0.08),
      Paint()
        ..color = night ? const Color(0xFF1A4263) : const Color(0xFFB0E0F6),
    );

    final cloud = Paint()
      ..color = Colors.white.withValues(alpha: night ? 0.12 : 0.75);
    void drawCloud(double x, double y, double s) {
      final dx = ((x + t * w * 1.4) % (w + 160)) - 80;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(dx, y, 110 * s, 38 * s),
          Radius.circular(20 * s),
        ),
        cloud,
      );
      canvas.drawCircle(Offset(dx + 40 * s, y + 6 * s), 22 * s, cloud);
      canvas.drawCircle(Offset(dx + 70 * s, y + 10 * s), 17 * s, cloud);
    }

    drawCloud(20, 30, 1);
    drawCloud(w * 0.65, 60, 0.85);
  }

  @override
  bool shouldRepaint(_SkyPainter old) => old.t != t;
}
