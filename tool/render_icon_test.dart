// Dibuja el ícono de la app a partir de la mascota Río.
//
//   flutter test tool/render_icon_test.dart
//   dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riova/core/mascot/rio_mascot.dart';
import 'package:riova/core/theme/app_colors.dart';

Future<void> _render(WidgetTester tester, Widget child, String path) async {
  final key = GlobalKey();
  await tester.binding.setSurfaceSize(const Size(1024, 1024));
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RepaintBoundary(
        key: key,
        child: SizedBox(width: 1024, height: 1024, child: child),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!);
  await tester.pumpWidget(const SizedBox());
}

void main() {
  const mascot = RioMascot(
    size: 560,
    interactive: false,
    idle: false,
    mood: MascotMood.cheer,
  );

  testWidgets('ícono completo (fondo + mascota)', (tester) async {
    await _render(
      tester,
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFDDF4FD), Color(0xFFA9E3F7)],
          ),
        ),
        child: Center(
          child: Padding(padding: EdgeInsets.only(top: 40), child: mascot),
        ),
      ),
      'assets/icon/icon.png',
    );
  });

  testWidgets('primer plano del ícono adaptable (zona segura 66 %)', (
    tester,
  ) async {
    await _render(
      tester,
      const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 30),
          child: RioMascot(
            size: 400,
            interactive: false,
            idle: false,
            mood: MascotMood.cheer,
          ),
        ),
      ),
      'assets/icon/icon_foreground.png',
    );
  });

  test('color de fondo del ícono adaptable', () {
    expect(AppColors.cyanSoft, isNotNull);
  });
}
