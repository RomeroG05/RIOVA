import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Tarjeta blanca redondeada con sombra suave y, opcionalmente, una repisa
/// inferior de color (como las tarjetas del mapa en el prototipo).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = Colors.white,
    this.radius = 24,
    this.ledgeColor,
    this.borderColor,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final Color? ledgeColor;
  final Color? borderColor;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: r,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120B3B66),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
    if (ledgeColor == null) return card;
    return DecoratedBox(
      decoration: BoxDecoration(color: ledgeColor, borderRadius: r),
      child: Padding(padding: const EdgeInsets.only(bottom: 5), child: card),
    );
  }
}

/// Etiqueta pequeña tipo "chip" del prototipo (p. ej. "MISIÓN DEL DÍA").
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    this.icon,
    this.color = AppColors.blueSoft,
    this.foreground = AppColors.teal,
    this.uppercase = false,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final Color foreground;
  final bool uppercase;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium!.copyWith(
      color: foreground,
      fontWeight: FontWeight.w800,
      fontSize: dense ? 11 : 12,
      letterSpacing: uppercase ? 0.7 : 0,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 9 : 12,
          vertical: dense ? 4 : 6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: dense ? 13 : 15, color: foreground),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                uppercase ? label.toUpperCase() : label,
                style: style,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Círculo con icono, usado en listas y encabezados de sección.
class IconBubble extends StatelessWidget {
  const IconBubble({
    super.key,
    required this.icon,
    this.color = AppColors.cyanSoft,
    this.foreground = AppColors.teal,
    this.size = 48,
  });

  final IconData icon;
  final Color color;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: foreground, size: size * 0.48),
    );
  }
}

/// Título de sección con icono a la izquierda y un elemento opcional a la
/// derecha (contador, enlace).
class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.icon,
    this.iconColor = AppColors.teal,
    this.trailing,
    this.subtitle,
  });

  final String title;
  final IconData? icon;
  final Color iconColor;
  final Widget? trailing;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(title, style: t.headlineSmall)),
            ?trailing,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: t.bodyMedium),
        ],
      ],
    );
  }
}
