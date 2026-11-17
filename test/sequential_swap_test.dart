import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riova/core/widgets/motion_widgets.dart';

double _opacityOf(WidgetTester tester, String text) {
  final fades = tester.widgetList<FadeTransition>(
    find.ancestor(of: find.text(text), matching: find.byType(FadeTransition)),
  );
  return fades.fold(1.0, (o, f) => o * f.opacity.value);
}

void main() {
  testWidgets(
    'al cambiar la frase, la vieja y la nueva nunca se ven a la vez',
    (tester) async {
      Widget app(String text) => MaterialApp(
        home: Scaffold(
          body: SequentialSwap(child: Text(text, key: ValueKey(text))),
        ),
      );
      await tester.pumpWidget(app('Frase A'));
      await tester.pumpWidget(app('Frase B'));

      for (var ms = 0; ms <= 360; ms += 30) {
        final a = find.text('Frase A').evaluate().isEmpty
            ? 0.0
            : _opacityOf(tester, 'Frase A');
        final b = find.text('Frase B').evaluate().isEmpty
            ? 0.0
            : _opacityOf(tester, 'Frase B');
        expect(a > 0.01 && b > 0.01, isFalse, reason: '$ms ms: A=$a B=$b');
        await tester.pump(const Duration(milliseconds: 30));
      }
      await tester.pumpAndSettle();
      expect(find.text('Frase A'), findsNothing);
      expect(_opacityOf(tester, 'Frase B'), 1);
    },
  );
}
