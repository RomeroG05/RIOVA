import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/explorer_controller.dart';
import '../mascot/rio_mascot.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import 'chunky_button.dart';
import 'motion_widgets.dart';

/// Muestra la celebración de una recompensa. Si no hubo nada que celebrar,
/// muestra un aviso discreto (SnackBar) con [emptyMessage].
Future<void> showReward(
  BuildContext context, {
  required RewardOutcome outcome,
  required String title,
  String? message,
  String? emptyMessage,
  String action = '¡Genial!',
}) async {
  if (outcome.isEmpty) {
    if (emptyMessage != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(emptyMessage)));
    }
    return;
  }
  HapticFeedback.mediumImpact();
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: const Color(0x8A0B2236),
    transitionDuration: AppMotion.of(
      context,
      const Duration(milliseconds: 320),
    ),
    pageBuilder: (context, _, _) => _RewardDialog(
      outcome: outcome,
      title: title,
      message: message,
      action: action,
    ),
    transitionBuilder: (context, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: AppMotion.easeOut);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.94, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _RewardDialog extends StatefulWidget {
  const _RewardDialog({
    required this.outcome,
    required this.title,
    required this.message,
    required this.action,
  });

  final RewardOutcome outcome;
  final String title;
  final String? message;
  final String action;

  @override
  State<_RewardDialog> createState() => _RewardDialogState();
}

class _RewardDialogState extends State<_RewardDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confetti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  final _mascot = GlobalKey<RioMascotState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || AppMotion.reduced(context)) return;
      _confetti.forward();
      Future.delayed(
        const Duration(milliseconds: 160),
        () => _mascot.currentState?.hop(strength: 9),
      );
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final o = widget.outcome;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Material(
          color: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: 380,
                  maxHeight: MediaQuery.sizeOf(context).height * 0.8,
                ),
                margin: const EdgeInsets.only(top: 64),
                padding: const EdgeInsets.fromLTRB(22, 86, 22, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: t.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      if (widget.message != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.message!,
                          style: t.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 18),
                      if (o.gotitas > 0)
                        _GotitasLine(value: o.gotitas, label: 'Gotitas XP'),
                      if (o.missionBonus > 0) ...[
                        const SizedBox(height: 8),
                        _GotitasLine(
                          value: o.missionBonus,
                          label: 'Misión del día',
                          color: AppColors.greenDeep,
                        ),
                      ],
                      if (o.levelUp != null) ...[
                        const SizedBox(height: 12),
                        _Banner(
                          icon: Icons.shield_rounded,
                          color: AppColors.blueSoft,
                          foreground: AppColors.blue,
                          text:
                              '¡Subiste al Nivel ${o.levelUp!.level}: ${o.levelUp!.title}!',
                        ),
                      ],
                      for (final m in o.newMedals) ...[
                        const SizedBox(height: 10),
                        _Banner(
                          icon: m.icon,
                          color: AppColors.mintSoft,
                          foreground: AppColors.greenDeep,
                          text: 'Nueva medalla: ${m.title}',
                        ),
                      ],
                      for (final g in o.newGames) ...[
                        const SizedBox(height: 10),
                        _Banner(
                          icon: g.icon,
                          color: AppColors.yellowSoft,
                          foreground: AppColors.amberInk,
                          text: '¡Nuevo minijuego: ${g.title}!',
                        ),
                      ],
                      const SizedBox(height: 20),
                      ChunkyButton(
                        label: widget.action,
                        tone: ChunkyTone.green,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    color: AppColors.cyanSoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 6),
                  ),
                  alignment: Alignment.center,
                  child: RioMascot(
                    key: _mascot,
                    size: 82,
                    mood: MascotMood.cheer,
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _confetti,
                    builder: (context, _) =>
                        CustomPaint(painter: ConfettiPainter(_confetti.value)),
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

class _GotitasLine extends StatelessWidget {
  const _GotitasLine({
    required this.value,
    required this.label,
    this.color = AppColors.teal,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.water_drop_rounded, color: color, size: 26),
          const SizedBox(width: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.toDouble()),
            duration: AppMotion.of(context, const Duration(milliseconds: 900)),
            curve: AppMotion.easeOut,
            builder: (context, v, _) => Text(
              '+${v.round()}',
              style: t.headlineMedium?.copyWith(color: color),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: t.titleSmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.color,
    required this.foreground,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final Color foreground;
  final String text;

  @override
  Widget build(BuildContext context) {
    return EntranceFade(
      index: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: foreground),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ráfaga de confeti en forma de gotas y hojas. `t` va de 0 a 1.
class ConfettiPainter extends CustomPainter {
  ConfettiPainter(this.t);

  final double t;
  static const _colors = [
    AppColors.cyan,
    AppColors.green,
    AppColors.yellow,
    AppColors.blue,
    AppColors.mint,
    Color(0xFFFF8FA3),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final rnd = math.Random(42);
    final origin = Offset(size.width / 2, 64);
    for (var i = 0; i < 46; i++) {
      final angle = -math.pi / 2 + (rnd.nextDouble() - 0.5) * math.pi * 1.4;
      final speed = 260 + rnd.nextDouble() * 260;
      final pos =
          origin +
          Offset(math.cos(angle), math.sin(angle)) * speed * t +
          Offset(0, 520 * t * t); // gravedad
      final paint = Paint()
        ..color = _colors[i % _colors.length].withValues(alpha: 1 - t);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(t * 8 * (rnd.nextBool() ? 1 : -1) + i);
      if (i.isEven) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-4, -2.5, 8, 5),
            const Radius.circular(2),
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, 3.2, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter old) => old.t != t;
}
