import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Draws small numbered circular badge markers (matching the redesign's
/// "top matches" map treatment) on the fly via a Canvas, since
/// google_maps_flutter has no built-in numbered-pin marker. Used only for a
/// small filtered subset (e.g. the first several results for a selected
/// species) — not the full ~1,700-point CPW dataset, which keeps its plain
/// colored dot markers. Results are cached by (number, legend) so repeated
/// filtering doesn't regenerate the same handful of bitmaps.
final _cache = <String, BitmapDescriptor>{};

Future<BitmapDescriptor> buildNumberedMarkerIcon(
  int number, {
  bool legend = false,
  double logicalSize = 34,
}) async {
  final key = '$number-$legend-$logicalSize';
  final cached = _cache[key];
  if (cached != null) return cached;

  const dpr = 3.0; // render at 3x for a crisp marker on high-density screens
  final size = logicalSize * dpr;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final center = Offset(size / 2, size / 2);
  final radius = size / 2 - 3 * dpr;

  final fill = legend ? const Color(0xFFB45B3E) : const Color(0xFFEFE7D6);
  final textColor = legend ? const Color(0xFFEFE7D6) : const Color(0xFF3A3428);

  canvas.drawCircle(center, radius, Paint()..color = fill);
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..color = const Color(0xFF3A3428)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * dpr,
  );

  final painter = TextPainter(
    text: TextSpan(
      text: '$number',
      style: TextStyle(color: textColor, fontSize: 13 * dpr, fontWeight: FontWeight.w600),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.round(), size.round());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final descriptor = BitmapDescriptor.bytes(Uint8List.view(bytes!.buffer), imagePixelRatio: dpr);

  _cache[key] = descriptor;
  return descriptor;
}
