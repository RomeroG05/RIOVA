import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/mascot/rio_mascot.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/riova_header.dart';
import '../../state/explorer_controller.dart';
import '../../state/settings_controller.dart';
import '../../state/tts_service.dart';

/// "Ajustes": tema, tamaño de letra, movimiento, voz y opciones de la
/// aventura. Se guardan solo en este teléfono.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _voiceSample =
      '¡Hola! Soy Río, la gota guardiana. Así sueno cuando te leo los datos curiosos.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final s = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final phoneDisablesMotion = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;

    return Scaffold(
      appBar: const RiovaBackBar(title: 'Ajustes'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          // ── Apariencia ──
          const SectionTitle(
            title: 'Apariencia',
            icon: Icons.palette_outlined,
            subtitle: 'Elige cómo se ve RÍOVA.',
          ),
          const SizedBox(height: 12),
          _ChoiceRow<ThemeMode>(
            value: s.themeMode,
            onChanged: ctrl.setThemeMode,
            options: const [
              (ThemeMode.light, 'Claro', Icons.light_mode_rounded),
              (ThemeMode.dark, 'Oscuro', Icons.dark_mode_rounded),
              (ThemeMode.system, 'Sistema', Icons.phone_android_rounded),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            s.themeMode == ThemeMode.system
                ? 'Sigue el modo claro u oscuro de tu teléfono.'
                : s.themeMode == ThemeMode.dark
                ? 'Colores suaves para la noche.'
                : 'Colores brillantes del río de día.',
            style: t.bodySmall,
          ),
          const SizedBox(height: 26),

          // ── Tamaño de letra ──
          const SectionTitle(
            title: 'Tamaño de letra',
            icon: Icons.format_size_rounded,
            subtitle: 'Para leer más cómodo.',
          ),
          const SizedBox(height: 12),
          _ChoiceRow<TextSize>(
            value: s.textSize,
            onChanged: ctrl.setTextSize,
            options: [
              for (final size in TextSize.values) (size, size.label, null),
            ],
            leadingBuilder: (size, selected) => Text(
              'A',
              // Tamaño fijo: muestra la diferencia sin depender de la escala.
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontFamily: t.titleLarge?.fontFamily,
                fontWeight: FontWeight.w800,
                fontSize: 16 + (size.index * 5),
                height: 1,
                color: selected ? AppColors.blue : AppColors.inkSoft,
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            color: AppColors.surfaceTint,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const RioMascot(size: 44, interactive: false, idle: false),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vista previa', style: t.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        'Así se verá el texto en RÍOVA. ¡Cuidemos juntos los ríos de Loja!',
                        style: t.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),

          // ── Movimiento ──
          const SectionTitle(
            title: 'Movimiento',
            icon: Icons.animation_rounded,
          ),
          const SizedBox(height: 12),
          _SwitchCard(
            title: 'Reducir animaciones',
            subtitle: phoneDisablesMotion
                ? 'Tu teléfono ya tiene las animaciones desactivadas.'
                : 'Menos movimiento y confeti en pantallas y juegos.',
            value: s.reduceMotion || phoneDisablesMotion,
            onChanged: phoneDisablesMotion ? null : ctrl.setReduceMotion,
          ),
          const SizedBox(height: 26),

          // ── Voz ──
          const SectionTitle(
            title: 'Voz de Río',
            icon: Icons.record_voice_over_outlined,
            subtitle: 'Velocidad al leer en voz alta.',
          ),
          const SizedBox(height: 12),
          _ChoiceRow<VoiceSpeed>(
            value: s.voiceSpeed,
            onChanged: ctrl.setVoiceSpeed,
            options: const [
              (VoiceSpeed.slow, 'Lenta', Icons.slow_motion_video_rounded),
              (VoiceSpeed.normal, 'Normal', Icons.play_circle_outline_rounded),
              (VoiceSpeed.fast, 'Rápida', Icons.fast_forward_rounded),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: _VoiceTestButton(text: _voiceSample),
          ),
          const SizedBox(height: 26),

          // ── Más opciones ──
          const SectionTitle(title: 'Más opciones', icon: Icons.tune_rounded),
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _LinkRow(
                  icon: Icons.qr_code_2_rounded,
                  color: AppColors.teal,
                  title: 'Códigos QR de los tótems',
                  subtitle:
                      'Para docentes: imprime los códigos de cada parada.',
                  onTap: () => context.push(Routes.qrCodes),
                ),
                Divider(height: 1, color: AppColors.outline),
                _LinkRow(
                  icon: Icons.restart_alt_rounded,
                  color: AppColors.red,
                  title: 'Reiniciar aventura',
                  subtitle: 'Borra tu perfil, gotitas y medallas.',
                  onTap: () => _confirmReset(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Los ajustes se guardan solo en este teléfono.',
            textAlign: TextAlign.center,
            style: t.bodySmall?.copyWith(color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Reiniciar la aventura?'),
        content: const Text(
          'Se borrarán tu perfil, gotitas, medallas y paradas registradas en este teléfono y su copia en la nube.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(explorerProvider.notifier).reset();
  }
}

/// Fila de opciones grandes (una sola elegida), cómoda para dedos pequeños.
class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.value,
    required this.onChanged,
    required this.options,
    this.leadingBuilder,
  });

  final T value;
  final ValueChanged<T> onChanged;
  final List<(T, String, IconData?)> options;
  final Widget Function(T value, bool selected)? leadingBuilder;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, (v, label, icon)) in options.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Builder(
              builder: (context) {
                final selected = v == value;
                return Semantics(
                  selected: selected,
                  inMutuallyExclusiveGroup: true,
                  child: Pressable(
                    semanticLabel: label,
                    onTap: () {
                      if (selected) return;
                      HapticFeedback.selectionClick();
                      onChanged(v);
                    },
                    child: AnimatedContainer(
                      duration: AppMotion.of(context, AppMotion.fast),
                      curve: AppMotion.easeOut,
                      constraints: const BoxConstraints(minHeight: 84),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.blueSoft
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? AppColors.blue : AppColors.outline,
                          width: selected ? 2.5 : 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 34,
                            child: Center(
                              child:
                                  leadingBuilder?.call(v, selected) ??
                                  Icon(
                                    icon,
                                    size: 28,
                                    color: selected
                                        ? AppColors.blue
                                        : AppColors.inkSoft,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Una palabra por línea; si aun así no cabe
                          // (letra muy grande) se reduce en vez de cortarse.
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label.replaceAll(' ', '\n'),
                              textAlign: TextAlign.center,
                              style: t.labelMedium?.copyWith(
                                color: selected
                                    ? AppColors.blue
                                    : AppColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
      child: MergeSemantics(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.titleSmall),
                  const SizedBox(height: 2),
                  Text(subtitle, style: t.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: value,
              onChanged: onChanged == null
                  ? null
                  : (v) {
                      HapticFeedback.selectionClick();
                      onChanged!(v);
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Pressable(
      semanticLabel: title,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.titleSmall?.copyWith(color: color)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: t.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
          ],
        ),
      ),
    );
  }
}

/// Lee una frase de ejemplo con la velocidad elegida.
class _VoiceTestButton extends ConsumerWidget {
  const _VoiceTestButton({required this.text});

  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tts = ref.watch(ttsProvider);
    return ValueListenableBuilder<String?>(
      valueListenable: tts.speaking,
      builder: (context, speaking, _) {
        final playing = speaking == 'ajustes.voz';
        return TextButton.icon(
          onPressed: () => tts.toggle('ajustes.voz', text),
          icon: Icon(
            playing ? Icons.stop_circle_outlined : Icons.volume_up_rounded,
          ),
          label: Text(playing ? 'Detener' : 'Probar la voz'),
        );
      },
    );
  }
}
