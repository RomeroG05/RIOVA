import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/motion_widgets.dart';
import '../../core/widgets/riova_header.dart';
import '../../data/content/places_content.dart';
import '../../data/models/place.dart';
import '../../state/explorer_controller.dart';
import '../../state/sensor_network.dart';
import 'widgets/adventure_route.dart';
import 'widgets/map_filters.dart';
import 'widgets/place_card.dart';
import 'widgets/place_marker.dart';
import 'widgets/semaforo_panel.dart';
import '../../state/content_revision.dart';

/// Pantalla "Mapa de aventura": mapa real (teselas de OpenStreetMap) con los
/// ríos Malacatos y Zamora, sectores, semáforo fluvial y ubicación real.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key, this.focusPlaceId});

  final String? focusPlaceId;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  static const _nodeSize = 48.0;
  static const _compactNodeSize = 34.0;

  /// Por debajo de este zoom los marcadores se compactan (sin etiqueta)
  /// para que no se amontonen al ver todo el valle.
  static const _labelZoom = 13.8;
  static const _maxZoom = 18.0;

  final _map = MapController();
  late final AnimationController _camera = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  )..addListener(_onCameraTick);
  Animation<double>? _camCurve;
  LatLngTween? _centerTween;
  Tween<double>? _zoomTween;

  bool _ready = false;
  bool _compact = false;

  /// `true` cuando el usuario ya movió el mapa o se enfocó un lugar: a
  /// partir de ahí no se vuelve a encuadrar automáticamente.
  bool _userMoved = false;
  Size? _framedFor;

  static final _startFit = CameraFit.coordinates(
    coordinates: [for (final p in placesInZone(Zone.sur)) p.position],
    padding: const EdgeInsets.fromLTRB(56, 110, 72, 56),
    maxZoom: 15.5,
  );
  bool _routeView = false;
  bool _semaforoOpen = false;
  River? _river;
  Zone? _zone;
  String? _selectedId;

  LatLng? _me;
  bool _locating = false;
  bool _centerOnMeWhenReady = false;
  StreamSubscription<Position>? _positionSub;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.focusPlaceId;
  }

  @override
  void didUpdateWidget(MapScreen old) {
    super.didUpdateWidget(old);
    if (widget.focusPlaceId != null &&
        widget.focusPlaceId != old.focusPlaceId) {
      _select(placeById(widget.focusPlaceId!));
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _camera.dispose();
    _map.dispose();
    super.dispose();
  }

  // ───────────── Cámara animada ─────────────

  void _onCameraTick() {
    final t = _camCurve?.value ?? 0;
    if (_centerTween == null || _zoomTween == null) return;
    _map.move(_centerTween!.transform(t), _zoomTween!.transform(t));
  }

  void _animateTo(LatLng center, double zoom) {
    if (!_ready) return;
    _userMoved = true;
    final cam = _map.camera;
    if (AppMotion.reduced(context)) {
      _map.move(center, zoom);
      return;
    }
    _centerTween = LatLngTween(begin: cam.center, end: center);
    _zoomTween = Tween(begin: cam.zoom, end: zoom);
    _camCurve = CurvedAnimation(parent: _camera, curve: AppMotion.easeInOut);
    _camera.forward(from: 0);
  }

  void _fit(List<LatLng> points, {double maxZoom = 16}) {
    if (!_ready || points.isEmpty) return;
    final fitted = CameraFit.coordinates(
      coordinates: points,
      padding: EdgeInsets.fromLTRB(48, 90, 48, _selectedId == null ? 48 : 280),
      maxZoom: maxZoom,
    ).fit(_map.camera);
    _animateTo(fitted.center, fitted.zoom);
  }

  /// Centra el lugar dejando sitio para la tarjeta inferior.
  void _focus(Place p) {
    if (!_ready) return;
    final zoom = math.max(_map.camera.zoom, 15.0);
    // Desplaza el centro ~110 px hacia el sur para que el marcador quede
    // por encima de la tarjeta.
    final degPerPx = 360 / (256 * math.pow(2, zoom));
    _animateTo(
      LatLng(p.position.latitude - 110 * degPerPx, p.position.longitude),
      zoom,
    );
  }

  // ───────────── Acciones ─────────────

  List<Place> get _visible => places
      .where(
        (p) =>
            (_river == null || p.river == _river) &&
            (_zone == null || p.zone == _zone),
      )
      .toList();

  void _select(Place p) {
    setState(() => _selectedId = p.id);
    if (!_routeView) _focus(p);
  }

  void _setZone(Zone? z) {
    setState(() {
      _zone = z;
      if (_selectedId != null &&
          z != null &&
          placeById(_selectedId!).zone != z) {
        _selectedId = null;
      }
    });
    if (!_routeView) _fit(_visible.map((p) => p.position).toList());
  }

  void _setRiver(River? r) {
    setState(() {
      _river = r;
      if (_selectedId != null &&
          r != null &&
          placeById(_selectedId!).river != r) {
        _selectedId = null;
      }
    });
    if (!_routeView) _fit(_visible.map((p) => p.position).toList());
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _locate() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _snack('Activa la ubicación del teléfono para verte en el mapa.');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _snack('Sin permiso de ubicación. Puedes activarlo en Ajustes.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      final me = LatLng(pos.latitude, pos.longitude);
      setState(() => _me = me);
      if (_routeView || !_ready) {
        // El mapa aún no existe: se centrará en onMapReady.
        setState(() {
          _routeView = false;
          _centerOnMeWhenReady = true;
        });
      } else {
        _animateTo(me, 16);
      }
      _positionSub ??=
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 8,
            ),
          ).listen((p) {
            if (mounted) setState(() => _me = LatLng(p.latitude, p.longitude));
          });
    } on TimeoutException {
      _snack('No pudimos encontrar tu ubicación. Intenta al aire libre.');
    } catch (_) {
      _snack('No pudimos obtener tu ubicación.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  // ───────────── UI ─────────────

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    ref.watch(contentRevisionProvider); // textos editados en Firestore
    final explorer = ref.watch(explorerProvider);
    final readings = ref.watch(sensorNetworkProvider);
    final visited = explorer.progress.visited.length;
    final selected = _selectedId == null ? null : placeById(_selectedId!);

    // Todos los sectores están abiertos; escanear su tótem lo marca visitado.
    PlaceState stateOf(Place p) => explorer.progress.visited.contains(p.id)
        ? PlaceState.visited
        : PlaceState.available;
    RiverStatus statusOf(Place p) => readings[p.id]!.status;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          SizedBox(
            height: 60,
            child: Row(
              children: [
                const SizedBox(width: 16),
                const RiovaLogo(section: 'Mapa'),
                const Spacer(),
                const GotitasBadge(),
                const SizedBox(width: 6),
                const ProfileButton(),
                const SizedBox(width: 10),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: AppCard(
              ledgeColor: AppColors.cyanSoft,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const IconBubble(icon: Icons.map_outlined, size: 40),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Valle de Loja',
                              style: t.titleLarge?.copyWith(height: 1.1),
                            ),
                            Text('Ríos Malacatos & Zamora', style: t.bodySmall),
                          ],
                        ),
                      ),
                      Pill(
                        label: '$visited/${places.length} Sectores',
                        icon: Icons.verified_outlined,
                        dense: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ProgressBar(
                        value: visited / places.length,
                        height: 16,
                        colors: [AppColors.cyan, AppColors.blue],
                      ),
                      Text(
                        '${(visited / places.length * 100).round()}% EXPLORADO',
                        style: t.labelSmall?.copyWith(
                          color: AppColors.ink,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: RiverFilter(value: _river, onChanged: _setRiver),
          ),
          const SizedBox(height: 8),
          ZoneChips(value: _zone, onChanged: _setZone),
          const SizedBox(height: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedSwitcher(
                      duration: AppMotion.of(context, AppMotion.medium),
                      child: _routeView
                          ? AdventureRoute(
                              key: const ValueKey('route'),
                              stateOf: stateOf,
                              statusOf: statusOf,
                              selectedId: _selectedId,
                              onSelect: _select,
                              river: _river,
                              zone: _zone,
                              bottomInset: selected == null ? 24 : 300,
                            )
                          : _buildMap(stateOf, statusOf),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    right: _semaforoOpen ? 12 : null,
                    child: SemaforoPanel(
                      expanded: _semaforoOpen,
                      onToggle: () =>
                          setState(() => _semaforoOpen = !_semaforoOpen),
                    ),
                  ),
                  if (!_semaforoOpen)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: ViewToggle(
                        routeView: _routeView,
                        onChanged: (v) => setState(() {
                          _routeView = v;
                          // El mapa se reconstruye al volver; espera a onMapReady.
                          if (v) _ready = false;
                        }),
                      ),
                    ),
                  if (!_routeView && !_semaforoOpen)
                    Positioned(
                      right: 12,
                      top: 68,
                      child: Column(
                        children: [
                          MapControlButton(
                            icon: Icons.add_rounded,
                            label: 'Acercar',
                            onTap: () => _animateTo(
                              _map.camera.center,
                              math.min(_map.camera.zoom + 1, _maxZoom),
                            ),
                          ),
                          const SizedBox(height: 8),
                          MapControlButton(
                            icon: Icons.remove_rounded,
                            label: 'Alejar',
                            onTap: () => _animateTo(
                              _map.camera.center,
                              _map.camera.zoom - 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          MapControlButton(
                            icon: Icons.my_location_rounded,
                            label: 'Mi ubicación',
                            busy: _locating,
                            onTap: _locate,
                          ),
                          const SizedBox(height: 8),
                          MapControlButton(
                            icon: Icons.zoom_out_map_rounded,
                            label: 'Ver todo el valle',
                            onTap: () =>
                                _fit(_visible.map((p) => p.position).toList()),
                          ),
                        ],
                      ),
                    ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: AnimatedSwitcher(
                      duration: AppMotion.of(context, AppMotion.medium),
                      switchInCurve: AppMotion.easeOut,
                      switchOutCurve: AppMotion.easeOut,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, 0.25),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: selected == null
                          ? const SizedBox.shrink()
                          : PlaceCard(
                              key: ValueKey(selected.id),
                              place: selected,
                              state: stateOf(selected),
                              me: _me,
                              onClose: () => setState(() => _selectedId = null),
                              onLearnMore: () =>
                                  context.go(Routes.place(selected.id)),
                              onRegister: () => context.push(
                                Routes.scan(placeId: selected.id),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(
    PlaceState Function(Place) stateOf,
    RiverStatus Function(Place) statusOf,
  ) {
    final size = _compact ? _compactNodeSize : _nodeSize;
    final nodeHeight = _compact ? size + 4 : PlaceNode.heightFor(size);
    // Ancla: el centro del círculo cae exactamente sobre la coordenada.
    final anchorY = 1 - 2 * ((size + 4) / 2) / nodeHeight;
    final dimMala = _river == River.zamora;
    final dimZam = _river == River.malacatos;

    Polyline river(List<LatLng> pts, Color color, bool dim) => Polyline(
      points: pts,
      color: color.withValues(alpha: dim ? 0.25 : 0.9),
      strokeWidth: 9,
      borderColor: Colors.white.withValues(alpha: dim ? 0.3 : 0.9),
      borderStrokeWidth: 3,
      strokeCap: StrokeCap.round,
      strokeJoin: StrokeJoin.round,
    );

    // Si el mapa cambia de tamaño antes de que el usuario lo toque (p. ej.
    // se cerró el teclado al venir de crear el perfil), se vuelve a encuadrar
    // la Zona Sur; si no, quedaría el encuadre calculado con el tamaño viejo.
    final map = FlutterMap(
      key: const ValueKey('map'),
      mapController: _map,
      options: MapOptions(
        // El recorrido empieza en la Zona Sur: se abre encuadrando sus paradas.
        initialCameraFit: _startFit,
        onPositionChanged: (camera, hasGesture) {
          if (hasGesture) _userMoved = true;
          final compact = camera.zoom < _labelZoom;
          if (compact != _compact) setState(() => _compact = compact);
        },
        minZoom: 11,
        maxZoom: _maxZoom,
        backgroundColor: AppColors.dark
            ? const Color(0xFF00081A)
            : const Color(0xFFEAF2FB),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onTap: (_, _) {
          if (_selectedId != null) setState(() => _selectedId = null);
        },
        onMapReady: () {
          _ready = true;
          final focus = _selectedId;
          if (_centerOnMeWhenReady && _me != null) {
            _centerOnMeWhenReady = false;
            _animateTo(_me!, 16);
          } else if (focus != null) {
            _focus(placeById(focus));
          }
        },
      ),
      children: [
        TileLayer(
          // Teselas estándar de OpenStreetMap: sin API key. Su política de uso
          // pide identificar la app (userAgentPackageName) y mostrar atribución.
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.riova.riova',
          maxNativeZoom: 19,
          tileBuilder: (context, tile, _) => ColorFiltered(
            colorFilter: AppColors.dark ? _night : _tint,
            child: tile,
          ),
        ),
        PolylineLayer(
          polylines: [
            river(zamoraPath, AppColors.zamora, dimZam),
            river(malacatosPath, AppColors.malacatos, dimMala),
            Polyline(
              points: zamoraPath,
              color: Colors.white.withValues(alpha: dimZam ? 0.2 : 0.85),
              strokeWidth: 2,
              pattern: StrokePattern.dashed(segments: const [10, 12]),
            ),
            Polyline(
              points: malacatosPath,
              color: Colors.white.withValues(alpha: dimMala ? 0.2 : 0.85),
              strokeWidth: 2,
              pattern: StrokePattern.dashed(segments: const [10, 12]),
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            for (final p in _visible)
              Marker(
                point: p.position,
                width: 132,
                height: nodeHeight,
                alignment: Alignment(0, anchorY),
                child: PlaceNode(
                  place: p,
                  size: size,
                  showLabel: !_compact,
                  state: stateOf(p),
                  status: statusOf(p),
                  selected: p.id == _selectedId,
                  onTap: () => _select(p),
                ),
              ),
            if (_me != null)
              Marker(point: _me!, width: 48, height: 48, child: const MeDot()),
          ],
        ),
        RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          showFlutterMapAttribution: false,
          attributions: [
            TextSourceAttribution('© OpenStreetMap contributors', onTap: () {}),
          ],
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, c) {
        final size = c.biggest;
        if (_ready &&
            !_userMoved &&
            _selectedId == null &&
            _framedFor != size) {
          _framedFor = size;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_userMoved && _selectedId == null) {
              _map.fitCamera(_startFit);
            }
          });
        }
        _framedFor ??= size;
        return map;
      },
    );
  }

  /// Leve desaturación + tinte azul para que el mapa combine con la app.
  /// Modo oscuro: invierte el brillo y gira el tono 180° (el agua sigue
  /// azul y los parques verdes) con un fondo azul noche.
  static const _night = ColorFilter.matrix(<double>[
    0.488, -1.216, -0.122, 0, 217, //
    -0.362, -0.366, -0.122, 0, 225, //
    -0.362, -1.216, 0.728, 0, 237, //
    0, 0, 0, 1, 0,
  ]);

  static const _tint = ColorFilter.matrix(<double>[
    0.86, 0.06, 0.04, 0, 6, //
    0.04, 0.88, 0.06, 0, 8, //
    0.04, 0.08, 0.92, 0, 16, //
    0, 0, 0, 1, 0,
  ]);
}

/// Interpolación lineal de coordenadas para animar la cámara.
class LatLngTween extends Tween<LatLng> {
  LatLngTween({required LatLng begin, required LatLng end})
    : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) => LatLng(
    begin!.latitude + (end!.latitude - begin!.latitude) * t,
    begin!.longitude + (end!.longitude - begin!.longitude) * t,
  );
}
