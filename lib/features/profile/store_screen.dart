import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/mascot/rio_mascot.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/chunky_button.dart';
import '../../core/widgets/hat.dart';
import '../../core/widgets/motion_widgets.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/profile_banner.dart';
import '../../core/widgets/reward_dialog.dart';
import '../../core/widgets/riova_header.dart';
import '../../core/widgets/two_column_grid.dart';
import '../../data/content/banner_content.dart';
import '../../data/content/hat_content.dart';
import '../../state/explorer_controller.dart';

/// Secciones de la tienda.
enum StoreTab { hats, banners }

/// Datos comunes de algo que se vende en la tienda (sombrero o banner).
typedef _Item = ({
  String id,
  String name,
  String description,
  int price,
  int minLevel,
});

_Item _hatItem(HatInfo h) => (
  id: h.id,
  name: h.name,
  description: h.description,
  price: h.price,
  minLevel: h.minLevel,
);

_Item _bannerItem(BannerInfo b) => (
  id: b.id,
  name: b.name,
  description: b.description,
  price: b.price,
  minLevel: b.minLevel,
);

/// "Tienda": sombreros para el avatar y banners para la tarjeta del perfil.
/// Todo se compra con gotitas DISPONIBLES y algunos artículos piden nivel.
class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key, this.initialTab = StoreTab.hats});

  final StoreTab initialTab;

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confetti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  late StoreTab _tab = widget.initialTab;
  late String _hat;
  late String _banner;
  int _celebrate = 0;

  @override
  void initState() {
    super.initState();
    final p = ref.read(explorerProvider).progress;
    _hat = p.equippedHat ?? hats.first.id;
    _banner = p.equippedBanner ?? banners.first.id;
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  bool get _hats => _tab == StoreTab.hats;

  Future<void> _buy(_Item item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: _hats
            ? HatIcon(hatId: item.id, width: 90)
            : SizedBox(
                width: 150,
                child: BannerSwatch(bannerId: item.id, height: 70),
              ),
        title: Text('¿Comprar ${item.name}?'),
        content: Text(
          'Cuesta ${item.price} gotitas. Tu nivel no baja: solo gastas gotitas disponibles.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Todavía no'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('¡Comprar!'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final ctrl = ref.read(explorerProvider.notifier);
    final result = _hats
        ? ctrl.buyHat(hatById(item.id)!)
        : ctrl.buyBanner(bannerById(item.id)!);
    if (result != Purchase.bought) return;
    HapticFeedback.heavyImpact();
    setState(() => _celebrate++);
    if (!AppMotion.reduced(context)) _confetti.forward(from: 0);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _hats
                ? '¡Nuevo sombrero! Ya llevas puesto: ${item.name}.'
                : '¡Nuevo banner! Tu perfil ahora luce: ${item.name}.',
          ),
        ),
      );
  }

  void _equip(String? id) {
    final ctrl = ref.read(explorerProvider.notifier);
    _hats ? ctrl.equipHat(id) : ctrl.equipBanner(id);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = ref.watch(explorerProvider);
    final p = s.progress;
    final level = s.level.level;

    final items = _hats
        ? [for (final h in hats) _hatItem(h)]
        : [for (final b in banners) _bannerItem(b)];
    final ownedIds = _hats ? p.ownedHats : p.ownedBanners;
    final equippedId = _hats ? p.equippedHat : p.equippedBanner;
    final item = items.firstWhere(
      (i) => i.id == (_hats ? _hat : _banner),
      orElse: () => items.first,
    );

    // Vista previa: tu tarjeta de perfil con lo que estás mirando.
    final previewHat = _hats ? item.id : p.equippedHat;
    final previewBanner = _hats ? p.equippedBanner : item.id;

    return Scaffold(
      appBar: const RiovaBackBar(title: 'Tienda'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          StoreTabs(
            value: _tab,
            onChanged: (tab) {
              if (tab == _tab) return;
              HapticFeedback.selectionClick();
              setState(() => _tab = tab);
            },
          ),
          const SizedBox(height: 14),
          Stack(
            children: [
              ProfileBanner(
                bannerId: previewBanner,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.profile?.name ?? 'Explorador',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.titleLarge?.copyWith(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _WalletPill(wallet: p.wallet),
                      ],
                    ),
                    const SizedBox(height: 46),
                    TweenAnimationBuilder<double>(
                      key: ValueKey(_celebrate),
                      tween: Tween(begin: _celebrate == 0 ? 1 : 1.2, end: 1),
                      duration: AppMotion.of(
                        context,
                        const Duration(milliseconds: 600),
                      ),
                      curve: AppMotion.playful,
                      builder: (context, v, child) =>
                          Transform.scale(scale: v, child: child),
                      child: AnimatedSwitcher(
                        duration: AppMotion.of(context, AppMotion.medium),
                        switchInCurve: AppMotion.playful,
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: Tween(begin: 0.85, end: 1.0).animate(anim),
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: WithHat(
                          key: ValueKey(previewHat),
                          hatId: previewHat,
                          size: 120,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F6FD),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 5),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              s.profile?.avatar.emoji ?? '💧',
                              style: const TextStyle(fontSize: 60),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      item.name,
                      style: t.headlineSmall?.copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      textAlign: TextAlign.center,
                      style: t.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _actionFor(
                      item,
                      owned: ownedIds.contains(item.id),
                      equipped: equippedId == item.id,
                      wallet: p.wallet,
                      level: level,
                    ),
                  ],
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
          const SizedBox(height: 14),
          RioSays(
            message: _hats
                ? '¡Gana gotitas jugando, escaneando tótems y respondiendo preguntas! Comprar no baja tu nivel.'
                : '¡Los banners decoran el fondo de tu tarjeta de perfil! Algunos se desbloquean al subir de nivel.',
          ),
          const SizedBox(height: 18),
          SectionTitle(
            title: _hats ? 'Sombreros' : 'Banners',
            icon: _hats ? Icons.storefront_outlined : Icons.wallpaper_rounded,
            trailing: Pill(
              label: '${ownedIds.length}/${items.length} tuyos',
              dense: true,
              color: AppColors.cyanSoft,
            ),
          ),
          const SizedBox(height: 12),
          TwoColumnGrid(
            key: ValueKey(_tab),
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final (i, it) in items.indexed)
                EntranceFade(
                  index: i.clamp(0, 6),
                  child: _StoreTile(
                    item: it,
                    preview: _hats
                        ? HatIcon(hatId: it.id, width: 84)
                        : BannerSwatch(bannerId: it.id),
                    selected: it.id == item.id,
                    owned: ownedIds.contains(it.id),
                    equipped: equippedId == it.id,
                    affordable: p.wallet >= it.price,
                    levelLocked: level < it.minLevel,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _hats ? _hat = it.id : _banner = it.id);
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            color: AppColors.surfaceTint,
            child: Row(
              children: [
                const RioMascot(size: 40, interactive: false, idle: false),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tienes ${p.gotitas} gotitas ganadas (para tu nivel) y ${p.wallet} disponibles para la tienda.',
                    style: t.bodyMedium?.copyWith(color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Misma lógica para sombreros y banners: quitar · usar · bloqueado por
  /// nivel · faltan gotitas · comprar.
  ChunkyButton _actionFor(
    _Item item, {
    required bool owned,
    required bool equipped,
    required int wallet,
    required int level,
  }) {
    final missing = item.price - wallet;
    if (equipped) {
      return ChunkyButton(
        label: _hats ? 'Quitármelo' : 'Quitar banner',
        tone: ChunkyTone.soft,
        leading: Icons.do_not_disturb_on_outlined,
        onPressed: () => _equip(null),
      );
    }
    if (owned) {
      return ChunkyButton(
        label: _hats ? 'Ponérmelo' : 'Usar en mi perfil',
        tone: ChunkyTone.teal,
        leading: _hats ? Icons.checkroom_rounded : Icons.wallpaper_rounded,
        singleLine: true,
        onPressed: () {
          HapticFeedback.selectionClick();
          _equip(item.id);
        },
      );
    }
    if (level < item.minLevel) {
      return ChunkyButton(
        label: 'Se desbloquea en el Nivel ${item.minLevel}',
        leading: Icons.lock_outline_rounded,
        singleLine: true,
        onPressed: null,
      );
    }
    if (missing > 0) {
      return ChunkyButton(
        label: 'Te faltan $missing gotitas',
        leading: Icons.lock_outline_rounded,
        singleLine: true,
        onPressed: null,
      );
    }
    return ChunkyButton(
      label: 'Comprar por ${item.price} 💧',
      tone: ChunkyTone.green,
      leading: Icons.shopping_bag_outlined,
      singleLine: true,
      onPressed: () => _buy(item),
    );
  }
}

class _WalletPill extends StatelessWidget {
  const _WalletPill({required this.wallet});

  final int wallet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.water_drop_rounded, color: AppColors.teal, size: 18),
          const SizedBox(width: 4),
          CountUpText(
            wallet,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: AppColors.teal),
          ),
        ],
      ),
    );
  }
}

/// Selector "Sombreros | Banners" con indicador deslizante.
class StoreTabs extends StatelessWidget {
  const StoreTabs({super.key, required this.value, required this.onChanged});

  final StoreTab value;
  final ValueChanged<StoreTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    const options = [
      (StoreTab.hats, 'Sombreros', Icons.checkroom_rounded),
      (StoreTab.banners, 'Banners', Icons.wallpaper_rounded),
    ];
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceBlue,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: value == StoreTab.hats
                ? Alignment.centerLeft
                : Alignment.centerRight,
            duration: AppMotion.of(context, AppMotion.medium),
            curve: AppMotion.easeInOut,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x140B3B66),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final (tab, label, icon) in options)
                Expanded(
                  child: Semantics(
                    selected: tab == value,
                    button: true,
                    label: label,
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(tab),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                size: 18,
                                color: tab == value
                                    ? AppColors.blue
                                    : AppColors.inkSoft,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                label,
                                style: t.labelLarge?.copyWith(
                                  color: tab == value
                                      ? AppColors.blue
                                      : AppColors.inkSoft,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoreTile extends StatelessWidget {
  const _StoreTile({
    required this.item,
    required this.preview,
    required this.selected,
    required this.owned,
    required this.equipped,
    required this.affordable,
    required this.levelLocked,
    required this.onTap,
  });

  final _Item item;
  final Widget preview;
  final bool selected;
  final bool owned;
  final bool equipped;
  final bool affordable;

  /// Aún no se alcanza el nivel mínimo del artículo.
  final bool levelLocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final Widget badge = equipped
        ? const Pill(
            label: 'Puesto',
            icon: Icons.check_rounded,
            dense: true,
            color: AppColors.mint,
            foreground: AppColors.greenDeep,
          )
        : owned
        ? const Pill(label: 'Tuyo', dense: true, color: AppColors.cyanSoft)
        : levelLocked
        ? Pill(
            label: 'Nivel ${item.minLevel}',
            icon: Icons.lock_outline_rounded,
            dense: true,
            color: AppColors.surfaceBlue,
            foreground: AppColors.inkSoft,
          )
        : Pill(
            label: '${item.price}',
            icon: Icons.water_drop_rounded,
            dense: true,
            color: affordable ? AppColors.cyan : AppColors.surfaceBlue,
            foreground: affordable ? Colors.white : AppColors.inkSoft,
          );
    return Pressable(
      onTap: onTap,
      semanticLabel:
          '${item.name}, ${owned
              ? 'comprado'
              : levelLocked
              ? 'se desbloquea en el nivel ${item.minLevel}'
              : '${item.price} gotitas'}',
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.fast),
        curve: AppMotion.easeOut,
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.blueSoft : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.teal : AppColors.outline,
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x100B3B66),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Opacity(
              opacity: owned || (affordable && !levelLocked) ? 1 : 0.55,
              child: preview,
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: t.titleSmall,
            ),
            const SizedBox(height: 6),
            badge,
          ],
        ),
      ),
    );
  }
}
