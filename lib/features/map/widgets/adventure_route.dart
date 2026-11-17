import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../data/content/places_content.dart';
import '../../../data/models/place.dart';
import '../../../state/sensor_network.dart';
import 'place_marker.dart';

/// Vista ilustrada del recorrido (como el prototipo): los dos ríos suben
/// por la pantalla, se unen en la confluencia y los sectores aparecen como
/// paradas de un camino de aventura, de sur (abajo) a norte (arriba).
class AdventureRoute extends StatefulWidget {
  const AdventureRoute({
    super.key,
    required this.stateOf,
    required this.statusOf,
    required this.selectedId,
    required this.onSelect,
    required this.river,
    required this.zone,
    required this.bottomInset,
  });

  final PlaceState Function(Place) stateOf;
  final RiverStatus Function(Place) statusOf;
  final String? selectedId;
  final ValueChanged<Place> onSelect;
  final River? river;
  final Zone? zone;
  final double bottomInset;

  @override
  State<AdventureRoute> createState() => _AdventureRouteState();
}

class _AdventureRouteState extends State<AdventureRoute> {
  static const _spacing = 170.0;
  static const _nodeSize = 60.0;
  final _scroll = ScrollController();
  late final List<Place> _ordered = [...places]
    ..sort((a, b) => a.position.latitude.compareTo(b.position.latitude));

  double get _height => _ordered.length * _spacing + 420;

  double _y(int i) => _height - 280 - i * _spacing;

  /// Al norte de la confluencia solo queda el río Zamora: va al centro.
  bool _afterConfluence(Place p) => p.position.latitude > confluence.latitude;

  double _x(Place p, int i, double w) {
    if (_afterConfluence(p)) {
      return w * (0.5 + (i.isEven ? -0.12 : 0.12));
    }
    return p.river == River.malacatos ? w * 0.27 : w * 0.73;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  void didUpdateWidget(AdventureRoute old) {
    super.didUpdateWidget(old);
    if (widget.zone != old.zone && widget.zone != null) {
      _scrollToZone(widget.zone!);
    }
    if (widget.selectedId != old.selectedId && widget.selectedId != null) {
      final i = _ordered.indexWhere((p) => p.id == widget.selectedId);
      if (i >= 0) _scrollTo(_y(i) - 140);
    }
  }

  void _scrollToZone(Zone z) {
    final idx = <int>[
      for (var i = 0; i < _ordered.length; i++)
        if (_ordered[i].zone == z) i,
    ];
    if (idx.isEmpty) return;
    _scrollTo(_y(idx.last) - 120);
  }

  void _scrollTo(double offset) {
    if (!_scroll.hasClients) return;
    final target = offset.clamp(0.0, _scroll.position.maxScrollExtent);
    if (AppMotion.reduced(context)) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(
        target,
        duration: AppMotion.slow,
        curve: AppMotion.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final pts = <String, Offset>{
          for (var i = 0; i < _ordered.length; i++)
            _ordered[i].id: Offset(_x(_ordered[i], i, w), _y(i)),
        };
        // Punto de unión: a medio camino entre la última parada del sur y
        // la primera del norte.
        final firstNorth = _ordered.indexWhere(_afterConfluence);
        final conf = Offset(w * 0.5, _y(firstNorth) + _spacing / 2);
        final mala = [
          Offset(w * 0.27, _height),
          for (final p in _ordered)
            if (p.river == River.malacatos && !_afterConfluence(p)) pts[p.id]!,
          conf,
        ];
        final zam = [
          Offset(w * 0.73, _height),
          for (final p in _ordered)
            if (p.river == River.zamora && !_afterConfluence(p)) pts[p.id]!,
          conf,
          for (final p in _ordered)
            if (_afterConfluence(p)) pts[p.id]!,
          Offset(w * 0.5, 0),
        ];

        final banners = <Widget>[];
        for (final z in Zone.values) {
          final idx = [
            for (var i = 0; i < _ordered.length; i++)
              if (_ordered[i].zone == z) i,
          ];
          if (idx.isEmpty) continue;
          final text = switch (z) {
            Zone.sur => 'ZONA SUR • INICIO DEL RECORRIDO',
            Zone.centro => 'ZONA CENTRO • CORAZÓN URBANO',
            Zone.norte => 'ZONA NORTE • RUTA NATURAL',
          };
          banners.add(
            Positioned(
              // Hueco libre entre el círculo de la última parada de la zona y
              // la etiqueta de la primera parada de la zona siguiente.
              top: _y(idx.last) - 84,
              left: 0,
              right: 0,
              child: Center(
                child: _ZoneBanner(
                  text: text,
                  icon: z.icon,
                  color: z == Zone.centro ? AppColors.blueSoft : AppColors.mint,
                  ledge: z == Zone.centro
                      ? AppColors.blue
                      : AppColors.greenDeep,
                ),
              ),
            ),
          );
        }

        return SingleChildScrollView(
          controller: _scroll,
          padding: EdgeInsets.only(bottom: widget.bottomInset),
          child: SizedBox(
            height: _height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RiversPainter(
                      malacatos: mala,
                      zamora: zam,
                      dimMalacatos: widget.river == River.zamora,
                      dimZamora: widget.river == River.malacatos,
                    ),
                  ),
                ),
                ...banners,
                for (final p in _ordered)
                  Positioned(
                    left: pts[p.id]!.dx - 70,
                    top: pts[p.id]!.dy - (_nodeSize + 4) / 2,
                    width: 140,
                    child: AnimatedOpacity(
                      duration: AppMotion.of(context, AppMotion.fast),
                      opacity: widget.river == null || widget.river == p.river
                          ? 1
                          : 0.35,
                      child: Center(
                        child: PlaceNode(
                          place: p,
                          size: _nodeSize,
                          state: widget.stateOf(p),
                          status: widget.statusOf(p),
                          selected: p.id == widget.selectedId,
                          onTap: () => widget.onSelect(p),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ZoneBanner extends StatelessWidget {
  const _ZoneBanner({
    required this.text,
    required this.icon,
    required this.color,
    required this.ledge,
  });

  final String text;
  final IconData icon;
  final Color color;
  final Color ledge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 3),
      decoration: BoxDecoration(
        color: ledge,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: ledge),
            const SizedBox(width: 6),
            Text(
              text,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: ledge, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiversPainter extends CustomPainter {
  _RiversPainter({
    required this.malacatos,
    required this.zamora,
    required this.dimMalacatos,
    required this.dimZamora,
  });

  final List<Offset> malacatos;
  final List<Offset> zamora;
  final bool dimMalacatos;
  final bool dimZamora;

  Path _smooth(List<Offset> pts) {
    // Ordenados de abajo hacia arriba.
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1];
      final b = pts[i];
      final midY = (a.dy + b.dy) / 2;
      path.cubicTo(a.dx, midY, b.dx, midY, b.dx, b.dy);
    }
    return path;
  }

  void _river(Canvas canvas, List<Offset> pts, Color color, bool dim) {
    final path = _smooth(pts);
    final alpha = dim ? 0.25 : 1.0;
    // Borde del río: blanco de día, azul profundo de noche.
    final edge = AppColors.dark ? const Color(0xFF1D3A55) : Colors.white;
    canvas.drawPath(
      path,
      Paint()
        ..color = edge.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 40
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 30
        ..strokeCap = StrokeCap.round,
    );
    // Línea central discontinua (corriente).
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: 0.85 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final seg = metric.extractPath(d, math.min(d + 14, metric.length));
        canvas.drawPath(seg, dash);
        d += 30;
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Fondo con suaves "islas" de vegetación.
    final night = AppColors.dark;
    final bg = Paint()
      ..color = night ? const Color(0xFF143224) : const Color(0xFFE6F4EA);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = night ? const Color(0xFF0F1E2E) : const Color(0xFFEFF6FE),
    );
    final rnd = math.Random(3);
    for (var i = 0; i < 18; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        20 + rnd.nextDouble() * 40,
        bg,
      );
    }
    _river(canvas, zamora, AppColors.zamora, dimZamora);
    _river(canvas, malacatos, AppColors.malacatos, dimMalacatos);
  }

  @override
  bool shouldRepaint(_RiversPainter old) =>
      old.dimMalacatos != dimMalacatos ||
      old.dimZamora != dimZamora ||
      !_offsetsEqual(old.malacatos, malacatos);
}

bool _offsetsEqual(List<Offset> a, List<Offset> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
