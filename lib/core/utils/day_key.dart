/// Utilidades de fecha para la racha y la misión del día.
/// Se trabaja con claves `yyyy-MM-dd` en hora local.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dayFromKey(String key) {
  final p = key.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

/// Días seguidos con actividad terminando hoy (o ayer, si hoy aún no hay
/// actividad: la racha sigue viva hasta que termine el día).
int currentStreak(Set<String> activeDays, DateTime today) {
  var day = DateTime(today.year, today.month, today.day);
  if (!activeDays.contains(dayKey(day))) {
    day = DateTime(day.year, day.month, day.day - 1);
  }
  var count = 0;
  while (activeDays.contains(dayKey(day))) {
    count++;
    day = DateTime(day.year, day.month, day.day - 1);
  }
  return count;
}

/// Lunes de la semana de [d].
DateTime startOfWeek(DateTime d) =>
    DateTime(d.year, d.month, d.day - (d.weekday - DateTime.monday));
