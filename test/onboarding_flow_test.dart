import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riova/app.dart';
import 'package:riova/data/models/explorer.dart';
import 'package:riova/data/repositories/progress_repository.dart';
import 'package:riova/state/explorer_controller.dart';

void main() {
  testWidgets('bienvenida → crear explorador → inicio', (tester) async {
    final repo = InMemoryProgressRepository();
    await tester.binding.setSurfaceSize(const Size(420, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [progressRepositoryProvider.overrideWithValue(repo)],
        child: const RiovaApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('¡Entrar a la Aventura!'), findsOneWidget);
    await tester.tap(find.text('¡Entrar a la Aventura!'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('¡Crea tu Perfil!'), findsOneWidget);

    // Sin nombre no deja continuar.
    await tester.ensureVisible(find.text('¡Comenzar Aventura!'));
    await tester.tap(find.text('¡Comenzar Aventura!'));
    await tester.pump();
    expect(find.text('¡Escribe tu nombre para tu pasaporte!'), findsOneWidget);

    await tester.ensureVisible(find.text('Nutria de Río'));
    await tester.tap(find.text('Nutria de Río'));
    await tester.enterText(find.byType(TextFormField), 'Anto');
    await tester.ensureVisible(find.text('¡Comenzar Aventura!'));
    await tester.tap(find.text('¡Comenzar Aventura!'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(repo.loadProfile()?.name, 'Anto');
    expect(repo.loadProfile()?.avatar, ExplorerAvatar.nutria);
    expect(find.text('¡BIENVENIDO A RÍOVA!'), findsOneWidget);
    expect(find.text('MISIÓN DEL DÍA'), findsOneWidget);

    // Desmonta para cancelar animaciones en bucle antes de terminar.
    await tester.pumpWidget(const SizedBox());
  });
}
