import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/remote/activity_log.dart';
import 'data/remote/cloud.dart';
import 'data/repositories/progress_repository.dart';
import 'state/content_revision.dart';
import 'state/explorer_controller.dart';
import 'state/sensor_network.dart';
import 'state/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // App pensada para teléfono en vertical; diseño de borde a borde.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final repository = await PrefsProgressRepository.open();
  final settings = await PrefsSettingsRepository.open();

  // Firebase es opcional: si no se puede iniciar, la app funciona igual con
  // el contenido empaquetado y el avance guardado en el teléfono.
  final cloud = await Cloud.start();
  final container = ProviderContainer(
    overrides: [
      progressRepositoryProvider.overrideWithValue(repository),
      settingsRepositoryProvider.overrideWithValue(settings),
      if (cloud != null) ...[
        activityLogProvider.overrideWithValue(cloud),
        remoteSensorDocsProvider.overrideWith((ref) => cloud.sensorDocs()),
      ],
    ],
  );
  // Contenido editado en Firestore: caché inmediata y servidor en segundo
  // plano. Cuando llega algo nuevo, las pantallas se reconstruyen.
  await cloud?.syncContent(
    onUpdated: () => container.read(contentRevisionProvider.notifier).bump(),
  );

  runApp(
    UncontrolledProviderScope(container: container, child: const RiovaApp()),
  );
}
