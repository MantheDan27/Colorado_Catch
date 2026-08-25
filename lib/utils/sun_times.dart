import 'dart:math' as math;

/// Sunrise/sunset for a given coordinate + date, computed with the
/// standard "sunrise equation" (https://en.wikipedia.org/wiki/Sunrise_equation)
/// — no external API/package, accurate to within a minute or two, which is
/// plenty for a bite-window heuristic. Used by lib/utils/bite_window.dart.
class SunTimes {
  const SunTimes({required this.sunrise, required this.sunset});

  /// Both in local time (the device's time zone).
  final DateTime sunrise;
  final DateTime sunset;
}

SunTimes calculateSunTimes({
  required double latitude,
  required double longitude,
  required DateTime date,
}) {
  final jdn = _julianDayNumber(date.year, date.month, date.day);
  final n = jdn - 2451545.0 + 0.0008;

  final jStar = n - longitude / 360.0;
  final m = _mod(357.5291 + 0.98560028 * jStar, 360.0); // solar mean anomaly (deg)
  final mRad = _deg2rad(m);
  final c = 1.9148 * math.sin(mRad) + 0.0200 * math.sin(2 * mRad) + 0.0003 * math.sin(3 * mRad);
  final lambda = _mod(m + 102.9372 + c + 180.0, 360.0); // ecliptic longitude (deg)
  final lambdaRad = _deg2rad(lambda);

  final jTransit = 2451545.0 + jStar + 0.0053 * math.sin(mRad) - 0.0069 * math.sin(2 * lambdaRad);

  final sinDelta = math.sin(lambdaRad) * math.sin(_deg2rad(23.4397));
  final delta = math.asin(sinDelta); // declination (rad)

  final latRad = _deg2rad(latitude);
  final cosOmega0 =
      (math.sin(_deg2rad(-0.833)) - math.sin(latRad) * math.sin(delta)) / (math.cos(latRad) * math.cos(delta));
  final clamped = cosOmega0.clamp(-1.0, 1.0);
  final omega0 = _rad2deg(math.acos(clamped));

  final jRise = jTransit - omega0 / 360.0;
  final jSet = jTransit + omega0 / 360.0;

  return SunTimes(
    sunrise: _julianToLocalDateTime(jRise),
    sunset: _julianToLocalDateTime(jSet),
  );
}

double _mod(double a, double b) => a - b * (a / b).floor();
double _deg2rad(double deg) => deg * math.pi / 180.0;
double _rad2deg(double rad) => rad * 180.0 / math.pi;

int _julianDayNumber(int year, int month, int day) {
  final a = (14 - month) ~/ 12;
  final y = year + 4800 - a;
  final m = month + 12 * a - 3;
  return day + ((153 * m + 2) ~/ 5) + 365 * y + (y ~/ 4) - (y ~/ 100) + (y ~/ 400) - 32045;
}

DateTime _julianToLocalDateTime(double jd) {
  final z = (jd + 0.5).floor();
  final f = (jd + 0.5) - z;
  int a;
  if (z < 2299161) {
    a = z;
  } else {
    final alpha = ((z - 1867216.25) / 36524.25).floor();
    a = z + 1 + alpha - (alpha / 4).floor();
  }
  final b = a + 1524;
  final c = ((b - 122.1) / 365.25).floor();
  final d = (365.25 * c).floor();
  final e = ((b - d) / 30.6001).floor();

  final dayWithFraction = b - d - (30.6001 * e).floor() + f;
  final day = dayWithFraction.floor();
  final dayFraction = dayWithFraction - day;

  final month = e < 14 ? e - 1 : e - 13;
  final year = month > 2 ? c - 4716 : c - 4715;

  final totalSeconds = (dayFraction * 86400).round();
  final hour = totalSeconds ~/ 3600;
  final minute = (totalSeconds % 3600) ~/ 60;
  final second = totalSeconds % 60;

  return DateTime.utc(year, month, day, hour, minute, second).toLocal();
}
