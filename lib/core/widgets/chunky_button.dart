import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

/// Variantes de color del botón 3D del prototipo.
enum ChunkyTone {
  cyan(AppColors.cyan, AppColors.cyanDark, Colors.white),
  green(AppColors.green, AppColors.greenDark, Colors.white),
  teal(AppColors.teal, AppColors.tealDark, Colors.white),
  blue(AppColors.blue, AppColors.blueDark, Colors.white),
  red(AppColors.red, AppColors.redDark, Colors.white),
  forest(AppColors.greenDeep, Color(0xFF0B4520), Colors.white),
  soft(AppColors.blueSoft, Color(0xFFB4C7E4), AppColors.ink);

  const ChunkyTone(this.face, this.ledge, this.foreground);
  final Color face;
  final Color ledge;
  final Color foreground;
}

/// Botón con "repisa" inferior: al presionar, la cara baja y se apoya sobre
/// la repisa, como una tecla física. Es el botón principal del diseño.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = ChunkyTone.cyan,
    this.leading,
    this.trailing,
    this.height = 56,
    this.expand = true,
    this.radius,
    this.fontSize,
    this.singleLine = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final ChunkyTone tone;
  final IconData? leading;
  final IconData? trailing;
  final double height;
  final bool expand;
  final double? radius;
  final double? fontSize;

  /// Mantiene el texto en una línea y lo reduce si no cabe (botones angostos).
  final bool singleLine;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  static const _depth = 5.0;
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final face = enabled ? widget.tone.face : AppColors.disabled;
    final ledge = enabled ? widget.tone.ledge : AppColors.disabledDark;
    final fg = enabled ? widget.tone.foreground : Colors.white;
    final radius = BorderRadius.circular(widget.radius ?? widget.height / 2);
    final pressedOffset = _down ? _depth - 1.5 : 0.0;
    final textStyle = Theme.of(context).textTheme.labelLarge!.copyWith(
      color: fg,
      fontSize: widget.fontSize ?? (widget.height >= 56 ? 18 : 15),
    );

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.leading != null) ...[
          Icon(widget.leading, color: fg, size: 22),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: widget.singleLine
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(widget.label, style: textStyle, maxLines: 1),
                )
              : Text(
                  widget.label,
                  style: textStyle,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
        if (widget.trailing != null) ...[
          const SizedBox(width: 10),
          Icon(widget.trailing, color: fg, size: 22),
        ],
      ],
    );

    return Semantics(
      // Nodo propio: TalkBack enfoca el botón aunque esté dentro de una tarjeta.
      container: true,
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: SizedBox(
          height: widget.height + _depth,
          width: widget.expand ? double.infinity : null,
          child: Stack(
            children: [
              Positioned.fill(
                top: _depth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: ledge,
                    borderRadius: radius,
                    boxShadow: enabled
                        ? [
                            BoxShadow(
                              color: ledge.withValues(alpha: 0.28),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: AppMotion.press,
                curve: AppMotion.easeOut,
                left: 0,
                right: 0,
                top: pressedOffset,
                height: widget.height,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: face, borderRadius: radius),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: content,
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
