import '../utils/sun_times.dart';

/// A recommended fishing time range, tied to first/last light — the classic
/// angling heuristic that fish feed most actively at dawn and dusk. Computed
/// per-location (coordinates shift sunrise/sunset by minutes across
/// Colorado) and per-day, not stored — see calculateBiteWindows.
class BiteWindow {
  const BiteWindow({required this.label, required this.emoji, required this.start, required this.end});

  final String label;
  final String emoji;
  final DateTime start;
  final DateTime end;
}

/// Dawn window: 30 min before sunrise to 90 min after.
/// Dusk window: 90 min before sunset to 30 min after.
/// These offsets are a simplified stand-in for full solunar theory — see
/// SETUP.md for the tradeoff this was chosen over.
List<BiteWindow> calculateBiteWindows({
  required double latitude,
  required double longitude,
  DateTime? date,
}) {
  final sun = calculateSunTimes(latitude: latitude, longitude: longitude, date: date ?? DateTime.now());

  return [
    BiteWindow(
      label: 'Dawn Bite',
      emoji: '🌅',
      start: sun.sunrise.subtract(const Duration(minutes: 30)),
      end: sun.sunrise.add(const Duration(minutes: 90)),
    ),
    BiteWindow(
      label: 'Dusk Bite',
      emoji: '🌇',
      start: sun.sunset.subtract(const Duration(minutes: 90)),
      end: sun.sunset.add(const Duration(minutes: 30)),
    ),
  ];
}

String formatTimeOfDay(DateTime dt) {
  final hour24 = dt.hour;
  final period = hour24 >= 12 ? 'PM' : 'AM';
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$hour12:$minute $period';
}
