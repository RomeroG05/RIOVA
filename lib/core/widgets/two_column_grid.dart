import 'package:flutter/material.dart';

/// Cuadrícula de 2 columnas cuyas filas miden lo que mide su tarjeta más
/// alta. A diferencia de `GridView` con `childAspectRatio`, no desborda
/// cuando el texto crece (pantallas angostas o fuente del sistema grande).
///
/// Pensada para pocas tarjetas de contenido (4–6); para listas largas usar
/// un `SliverGrid`.
class TwoColumnGrid extends StatelessWidget {
  const TwoColumnGrid({
    super.key,
    required this.children,
    this.spacing = 12,
    this.runSpacing = 12,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      if (i > 0) rows.add(SizedBox(height: runSpacing));
      final hasPair = i + 1 < children.length;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: children[i]),
              SizedBox(width: spacing),
              Expanded(child: hasPair ? children[i + 1] : const SizedBox()),
            ],
          ),
        ),
      );
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}
