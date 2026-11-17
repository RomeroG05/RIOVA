import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Aumenta cada vez que llega contenido nuevo desde Firestore. Las pantallas
/// que muestran sectores lo observan para redibujarse con los textos nuevos.
class ContentRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final contentRevisionProvider = NotifierProvider<ContentRevision, int>(
  ContentRevision.new,
);
