import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/chunky_button.dart';
import '../../core/widgets/motion_widgets.dart';
import '../../core/widgets/pressable.dart';
import '../../data/models/explorer.dart';
import '../../state/explorer_controller.dart';
import '../../core/widgets/two_column_grid.dart';

/// Pantalla "Crear explorador" (Pasaporte de aventura).
class CreateExplorerScreen extends ConsumerStatefulWidget {
  const CreateExplorerScreen({super.key});

  @override
  ConsumerState<CreateExplorerScreen> createState() =>
      _CreateExplorerScreenState();
}

class _CreateExplorerScreenState extends ConsumerState<CreateExplorerScreen> {
  final _name = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  ExplorerAvatar _avatar = ExplorerAvatar.oso;
  int _age = 7;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() => _saving = true);
    await ref
        .read(explorerProvider.notifier)
        .createProfile(
          ExplorerProfile(name: _name.text.trim(), avatar: _avatar, age: _age),
        );
    if (mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              const EntranceFade(
                child: Center(
                  child: Pill(
                    label: 'Pasaporte de aventura',
                    icon: Icons.explore_outlined,
                    uppercase: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              EntranceFade(
                index: 1,
                child: Text(
                  '¡Crea tu Perfil!',
                  textAlign: TextAlign.center,
                  style: t.displaySmall,
                ),
              ),
              const SizedBox(height: 8),
              EntranceFade(
                index: 2,
                child: Text(
                  'Elige tu guardián animal ecuatoriano y prepárate para explorar la biodiversidad.',
                  textAlign: TextAlign.center,
                  style: t.bodyLarge?.copyWith(color: AppColors.inkSoft),
                ),
              ),
              const SizedBox(height: 24),
              _Label(
                icon: Icons.pets_rounded,
                text: 'Elige tu avatar animal',
                trailing: '4 animales nativos',
              ),
              const SizedBox(height: 12),
              TwoColumnGrid(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final (i, a) in ExplorerAvatar.values.indexed)
                    EntranceFade(
                      index: 3 + i,
                      child: AvatarCard(
                        avatar: a,
                        selected: a == _avatar,
                        onTap: () => setState(() => _avatar = a),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 26),
              _Label(
                icon: Icons.badge_outlined,
                text: 'Nombre de explorador/a',
                trailing: '⌨ Toca y escribe',
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                maxLength: 16,
                textInputAction: TextInputAction.done,
                style: t.titleMedium,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  hintText: 'Explorador',
                  counterText: '',
                  suffixIcon: Icon(Icons.edit_outlined, color: AppColors.teal),
                ),
                validator: (v) => (v == null || v.trim().length < 2)
                    ? '¡Escribe tu nombre para tu pasaporte!'
                    : null,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _Label(
                      icon: Icons.cake_outlined,
                      text: '¿Cuántos años tienes?',
                    ),
                  ),
                  Pill(
                    label: _age >= 9 ? '9+ años' : '$_age años',
                    color: AppColors.cyanSoft,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final age in const [5, 6, 7, 8, 9]) ...[
                    Expanded(
                      child: _AgeChip(
                        label: age == 9 ? '9+' : '$age',
                        selected: _age == age,
                        onTap: () => setState(() => _age = age),
                      ),
                    ),
                    if (age != 9) const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 30),
              ChunkyButton(
                label: '¡Comenzar Aventura!',
                tone: ChunkyTone.teal,
                trailing: Icons.rocket_launch_outlined,
                height: 60,
                radius: 20,
                onPressed: _saving ? null : _submit,
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 16,
                    color: AppColors.greenDark,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Modo seguro para niños y aprendizaje divertido',
                      style: t.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.icon, required this.text, this.trailing});

  final IconData icon;
  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 22, color: AppColors.teal),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        if (trailing != null) Text(trailing!, style: t.bodySmall),
      ],
    );
  }
}

/// Tarjeta seleccionable de avatar animal. Se reutiliza en "Cambiar avatar".
class AvatarCard extends StatelessWidget {
  const AvatarCard({
    super.key,
    required this.avatar,
    required this.selected,
    required this.onTap,
  });

  final ExplorerAvatar avatar;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final d = AppMotion.of(context, AppMotion.fast);
    return Pressable(
      semanticLabel: '${avatar.label}${selected ? ', seleccionado' : ''}',
      onTap: onTap,
      child: AnimatedContainer(
        duration: d,
        curve: AppMotion.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.blueSoft : AppColors.surfaceTint,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.teal : AppColors.outline,
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.teal.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  scale: selected ? 1.08 : 1,
                  duration: AppMotion.of(context, AppMotion.medium),
                  curve: AppMotion.playful,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.cyanSoft,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? AppColors.teal.withValues(alpha: 0.4)
                            : Colors.white,
                        width: 3,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      avatar.emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                Positioned(
                  right: -6,
                  top: -4,
                  child: AnimatedScale(
                    scale: selected ? 1 : 0.6,
                    duration: d,
                    curve: AppMotion.easeOut,
                    child: AnimatedOpacity(
                      opacity: selected ? 1 : 0,
                      duration: d,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppColors.teal,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              avatar.label,
              style: t.titleSmall,
              textAlign: TextAlign.center,
            ),
            Text(avatar.habitat, style: t.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _AgeChip extends StatelessWidget {
  const _AgeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: '$label años',
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.fast),
        curve: AppMotion.easeOut,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.green : AppColors.surfaceTint,
          borderRadius: BorderRadius.circular(18),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.green.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : const [],
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: selected ? AppColors.ink : AppColors.inkSoft),
        ),
      ),
    );
  }
}
