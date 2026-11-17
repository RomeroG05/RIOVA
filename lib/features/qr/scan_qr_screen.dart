import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/mascot/rio_mascot.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/chunky_button.dart';
import '../../core/widgets/motion_widgets.dart';
import '../../core/widgets/reward_dialog.dart';
import '../../core/widgets/riova_header.dart';
import '../../data/content/places_content.dart';
import '../../data/models/place.dart';
import '../../state/explorer_controller.dart';

/// Pantalla "Escanear QR" (Registrar Parada Fluvial).
class ScanQrScreen extends ConsumerStatefulWidget {
  const ScanQrScreen({super.key, this.expectedPlaceId});

  final String? expectedPlaceId;

  @override
  ConsumerState<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends ConsumerState<ScanQrScreen> {
  final _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  Place? _detected;
  int _invalidTick = 0;
  bool _validating = false;

  Place? get _expected => widget.expectedPlaceId == null
      ? null
      : placeById(widget.expectedPlaceId!);

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    for (final b in capture.barcodes) {
      final raw = b.rawValue;
      if (raw == null) continue;
      final place = placeFromCode(raw);
      if (place != null) {
        if (place.id != _detected?.id) {
          HapticFeedback.mediumImpact();
          setState(() => _detected = place);
        }
        return;
      }
      HapticFeedback.heavyImpact();
      setState(() => _invalidTick++);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Ese código no es de un tótem RÍOVA. ¡Busca el letrero verde!',
            ),
          ),
        );
    }
  }

  Future<void> _validate() async {
    final place = _detected;
    if (place == null || _validating) return;
    setState(() => _validating = true);
    final outcome = ref.read(explorerProvider.notifier).registerVisit(place);
    await showReward(
      context,
      outcome: outcome,
      title: '¡Parada registrada!',
      message: 'Ganaste el sello oficial de ${place.shortName}.',
      emptyMessage:
          'Ya habías registrado ${place.shortName}. ¡Sigue explorando!',
      action: 'Explorar el lugar',
    );
    if (!mounted) return;
    context.go(Routes.place(place.id));
  }

  Future<void> _manualEntry() async {
    final place = await showModalBottomSheet<Place>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _ManualCodeSheet(),
    );
    if (place != null && mounted) setState(() => _detected = place);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final expected = _expected;
    return Scaffold(
      appBar: const RiovaBackBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          const Center(
            child: Pill(
              label: 'Misión fluvial activa',
              icon: Icons.qr_code_2_rounded,
              uppercase: true,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Registrar Parada Fluvial',
            textAlign: TextAlign.center,
            style: t.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Apunta tu cámara al código QR del tótem ecológico del sendero',
            textAlign: TextAlign.center,
            style: t.bodyLarge?.copyWith(color: AppColors.inkSoft),
          ),
          const SizedBox(height: 18),
          Shake(
            trigger: _invalidTick,
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: Color(0xFF0B2236)),
                    MobileScanner(
                      controller: _scanner,
                      onDetect: _onDetect,
                      errorBuilder: (context, error) =>
                          _CameraError(error: error, onManual: _manualEntry),
                    ),
                    IgnorePointer(
                      child: _ScanOverlay(found: _detected != null),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Row(
                        children: [
                          ValueListenableBuilder<MobileScannerState>(
                            valueListenable: _scanner,
                            builder: (context, s, _) => _CamButton(
                              icon: s.torchState == TorchState.on
                                  ? Icons.flashlight_off_outlined
                                  : Icons.flashlight_on_outlined,
                              label: 'Linterna',
                              onTap:
                                  s.isRunning &&
                                      s.torchState != TorchState.unavailable
                                  ? _scanner.toggleTorch
                                  : null,
                            ),
                          ),
                          const Spacer(),
                          AnimatedContainer(
                            duration: AppMotion.of(context, AppMotion.fast),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: _detected != null
                                  ? AppColors.green
                                  : const Color(0xCC0B2236),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.circle,
                                  size: 9,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _detected != null ? 'Enfocado' : 'Buscando…',
                                  style: t.labelMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          _CamButton(
                            icon: Icons.flip_camera_android_outlined,
                            label: 'Girar',
                            onTap: () => _scanner.switchCamera(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.medium),
            switchInCurve: AppMotion.easeOut,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween(begin: 0.96, end: 1.0).animate(anim),
                child: child,
              ),
            ),
            child: _detected != null
                ? _StopCard(
                    key: ValueKey(_detected!.id),
                    place: _detected!,
                    detected: true,
                  )
                : expected != null
                ? _StopCard(
                    key: const ValueKey('expected'),
                    place: expected,
                    detected: false,
                  )
                : const SizedBox(key: ValueKey('none'), height: 0),
          ),
          const SizedBox(height: 16),
          const RioSays(
            message: '¡Busca el letrero verde con forma de gota en el sendero del parque y encuádralo aquí!',
          ),
          const SizedBox(height: 22),
          ChunkyButton(
            label: '¡Escanear y Validar Visita! 📸',
            leading: Icons.photo_camera_outlined,
            height: 58,
            onPressed: _detected == null || _validating ? null : _validate,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _manualEntry,
            icon: const Icon(Icons.keyboard_alt_outlined),
            label: const Text(
              '¿Problemas con la cámara? Ingresar código manual',
              textAlign: TextAlign.center,
              style: TextStyle(decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }
}

class _StopCard extends ConsumerWidget {
  const _StopCard({super.key, required this.place, required this.detected});

  final Place place;
  final bool detected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final visited = ref.watch(
      explorerProvider.select((s) => s.progress.visited.contains(place.id)),
    );
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.cyanSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: AppColors.teal,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Pill(
                  label: detected ? 'Parada detectada' : 'Parada esperada',
                  uppercase: true,
                  dense: true,
                  color: detected ? AppColors.cyanSoft : AppColors.surfaceBlue,
                ),
                const SizedBox(height: 6),
                Text('Tótem ${place.shortName}', style: t.titleLarge),
                Row(
                  children: [
                    const Icon(
                      Icons.waves_rounded,
                      size: 18,
                      color: AppColors.teal,
                    ),
                    const SizedBox(width: 4),
                    Text('Sector ${place.river.label}', style: t.bodyMedium),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.blueSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        visited
                            ? Icons.verified_rounded
                            : Icons.military_tech_rounded,
                        color: AppColors.greenDeep,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          visited
                              ? const TextSpan(
                                  text: 'Ya tienes el sello oficial de esta parada',
                                )
                              : const TextSpan(
                                  text: 'Recompensa: ',
                                  children: [
                                    TextSpan(
                                      text: '+30 Gotitas XP',
                                      style: TextStyle(color: AppColors.blue),
                                    ),
                                    TextSpan(text: ' y sello oficial'),
                                  ],
                                ),
                          style: t.labelMedium?.copyWith(
                            color: AppColors.greenDeep,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CamButton extends StatelessWidget {
  const _CamButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xCC0B2236),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: onTap == null ? Colors.white38 : Colors.white,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: onTap == null ? Colors.white38 : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Esquinas animadas del visor + línea de escaneo.
class _ScanOverlay extends StatefulWidget {
  const _ScanOverlay({required this.found});

  final bool found;

  @override
  State<_ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<_ScanOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!AppMotion.reduced(context) && !_c.isAnimating) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) =>
          CustomPaint(painter: _OverlayPainter(_c.value, widget.found)),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  _OverlayPainter(this.t, this.found);

  final double t;
  final bool found;

  @override
  void paint(Canvas canvas, Size size) {
    final color = found ? AppColors.green : AppColors.cyan;
    final inset = size.width * 0.12;
    final r = Rect.fromLTRB(
      inset,
      inset,
      size.width - inset,
      size.height - inset - 30,
    );
    final len = size.width * 0.12;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final glow = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    for (final p in [glow, paint]) {
      canvas.drawPath(
        Path()
          ..moveTo(r.left, r.top + len)
          ..lineTo(r.left, r.top + 10)
          ..quadraticBezierTo(r.left, r.top, r.left + 10, r.top)
          ..lineTo(r.left + len, r.top)
          ..moveTo(r.right - len, r.top)
          ..lineTo(r.right - 10, r.top)
          ..quadraticBezierTo(r.right, r.top, r.right, r.top + 10)
          ..lineTo(r.right, r.top + len)
          ..moveTo(r.left, r.bottom - len)
          ..lineTo(r.left, r.bottom)
          ..lineTo(r.left + len, r.bottom)
          ..moveTo(r.right - len, r.bottom)
          ..lineTo(r.right, r.bottom)
          ..lineTo(r.right, r.bottom - len),
        p,
      );
    }
    if (!found) {
      // Movimiento constante → lineal (barrido de escaneo).
      final sweep = r.top + r.height * (t < 0.5 ? t * 2 : 2 - t * 2);
      canvas.drawLine(
        Offset(r.left + 8, sweep),
        Offset(r.right - 8, sweep),
        Paint()
          ..shader = LinearGradient(
            colors: [
              color.withValues(alpha: 0),
              color,
              color.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTWH(r.left, sweep, r.width, 2))
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => old.t != t || old.found != found;
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.error, required this.onManual});

  final MobileScannerException error;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: const Color(0xFF0B2236),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const RioMascot(size: 70, mood: MascotMood.sad, interactive: false),
            const SizedBox(height: 12),
            Text(
              denied
                  ? 'Necesito permiso para usar la cámara'
                  : 'No pude abrir la cámara',
              textAlign: TextAlign.center,
              style: t.titleMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              denied
                  ? 'Actívalo en Ajustes › Aplicaciones › RÍOVA › Permisos, o escribe el código del tótem.'
                  : 'Puedes escribir el código que aparece bajo el QR del tótem.',
              textAlign: TextAlign.center,
              style: t.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 14),
            ChunkyButton(
              label: 'Ingresar código',
              tone: ChunkyTone.green,
              height: 46,
              expand: false,
              onPressed: onManual,
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualCodeSheet extends StatefulWidget {
  const _ManualCodeSheet();

  @override
  State<_ManualCodeSheet> createState() => _ManualCodeSheetState();
}

class _ManualCodeSheetState extends State<_ManualCodeSheet> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final place = placeFromCode(_controller.text);
    if (place == null) {
      HapticFeedback.heavyImpact();
      setState(() => _error = 'Código no válido. Ejemplo: T04');
      return;
    }
    Navigator.of(context).pop(place);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Código del tótem', style: t.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Está impreso bajo el QR, por ejemplo “T04”.',
            style: t.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            style: t.titleLarge,
            decoration: InputDecoration(
              hintText: 'T04',
              errorText: _error,
              prefixIcon: const Icon(Icons.pin_outlined),
            ),
          ),
          const SizedBox(height: 16),
          ChunkyButton(
            label: 'Validar código',
            tone: ChunkyTone.green,
            height: 52,
            onPressed: _submit,
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push(Routes.qrCodes);
              },
              child: const Text('Ver códigos de los tótems (docentes)'),
            ),
          ),
        ],
      ),
    );
  }
}
