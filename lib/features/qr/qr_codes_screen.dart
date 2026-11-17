import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/riova_header.dart';
import '../../data/content/places_content.dart';
import '../../data/models/place.dart';

/// Códigos QR oficiales de los 13 tótems. Sirven para imprimirlos en los
/// letreros reales o para probar el escaneo desde otro teléfono.
class QrCodesScreen extends StatelessWidget {
  const QrCodesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: const RiovaBackBar(title: 'Tótems QR'),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            sliver: SliverToBoxAdapter(
              child: AppCard(
                color: AppColors.yellowSoft,
                borderColor: AppColors.yellow,
                child: Text(
                  'Para docentes y guías: imprime cada código y colócalo en el tótem del sector. '
                  'Toca uno para verlo en grande y escanearlo desde otro dispositivo.',
                  style: t.bodyMedium?.copyWith(color: AppColors.amberInk),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 220,
              ),
              itemCount: places.length,
              itemBuilder: (context, i) => _QrTile(place: places[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrTile extends StatelessWidget {
  const _QrTile({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Pressable(
      semanticLabel: 'Código QR de ${place.name}',
      onTap: () => showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('RÍOVA • LOJA', style: t.labelSmall),
                const SizedBox(height: 8),
                QrImageView(
                  data: place.qrPayload,
                  size: 260,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tótem #${place.totem.toString().padLeft(2, '0')} • ${place.shortName}',
                  style: t.titleMedium,
                ),
                Text('Código manual: ${place.totemCode}', style: t.bodyMedium),
              ],
            ),
          ),
        ),
      ),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: QrImageView(
                data: place.qrPayload,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.ink,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tótem #${place.totem.toString().padLeft(2, '0')}',
              style: t.labelSmall,
            ),
            Text(
              place.shortName,
              style: t.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
