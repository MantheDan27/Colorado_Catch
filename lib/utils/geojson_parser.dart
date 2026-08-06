import 'dart:convert';
import 'dart:ui' show Color;

import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Static overlays baked from CPW's Fishing Atlas (see
/// tool/fetch_fishing_data.py and assets/data/colorado_fishing_areas.geojson)
/// — rivers/streams, lakes/ponds, and labeled fishing areas, rendered as
/// Google Maps overlays. Loaded once and cached by MapScreen; not a Provider
/// since it's a pure asset read with no external dependency.
class FishingMapOverlays {
  const FishingMapOverlays({
    this.markers = const {},
    this.polylines = const {},
    this.polygons = const {},
  });

  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Set<Polygon> polygons;

  static const empty = FishingMapOverlays();
}

/// Marker hue / line-and-fill color per CPW category, so the different kinds
/// of fishing-atlas data (a named water body vs. a boat ramp vs. an
/// accessible area vs. a Gold Medal designation) read as distinct on the map.
const _markerHueByCategory = {
  'fishing_water': BitmapDescriptor.hueAzure,
  'boat_ramp': BitmapDescriptor.hueViolet,
  'accessible_area': BitmapDescriptor.hueGreen,
};

const _lineColorByCategory = {
  'gold_medal_stream': Color(0xFFC9A227), // gold
};

const _polygonColorByCategory = {
  'gold_medal_lake': Color(0xFFC9A227),
};

Future<FishingMapOverlays> loadFishingOverlays() async {
  final raw = await rootBundle.loadString('assets/data/colorado_fishing_areas.geojson');
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  final features = (decoded['features'] as List<dynamic>? ?? []);

  final markers = <Marker>{};
  final polylines = <Polyline>{};
  final polygons = <Polygon>{};

  for (var i = 0; i < features.length; i++) {
    final feature = features[i] as Map<String, dynamic>;
    final geometry = feature['geometry'] as Map<String, dynamic>?;
    final properties = feature['properties'] as Map<String, dynamic>? ?? {};
    if (geometry == null) continue;

    final category = properties['category'] as String? ?? 'unknown';
    final name = properties['name'] as String? ?? 'Fishing spot';
    final subtitle = properties['subtitle'] as String?;
    final id = '$category-$i';

    switch (geometry['type']) {
      case 'Point':
        final coords = geometry['coordinates'] as List<dynamic>;
        markers.add(Marker(
          markerId: MarkerId(id),
          position: LatLng((coords[1] as num).toDouble(), (coords[0] as num).toDouble()),
          infoWindow: InfoWindow(title: name, snippet: subtitle),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _markerHueByCategory[category] ?? BitmapDescriptor.hueRed,
          ),
        ));
        break;

      case 'LineString':
        polylines.add(_polylineFrom(id, name, geometry['coordinates'] as List<dynamic>, category));
        break;

      case 'MultiLineString':
        final lines = geometry['coordinates'] as List<dynamic>;
        for (var j = 0; j < lines.length; j++) {
          polylines.add(_polylineFrom('$id-$j', name, lines[j] as List<dynamic>, category));
        }
        break;

      case 'Polygon':
        polygons.add(_polygonFrom(id, geometry['coordinates'] as List<dynamic>, category));
        break;

      case 'MultiPolygon':
        final polys = geometry['coordinates'] as List<dynamic>;
        for (var j = 0; j < polys.length; j++) {
          polygons.add(_polygonFrom('$id-$j', polys[j] as List<dynamic>, category));
        }
        break;
    }
  }

  return FishingMapOverlays(markers: markers, polylines: polylines, polygons: polygons);
}

Polyline _polylineFrom(String id, String name, List<dynamic> coordinates, String category) {
  return Polyline(
    polylineId: PolylineId(id),
    points: _latLngRing(coordinates),
    color: _lineColorByCategory[category] ?? const Color(0xFF1976D2),
    width: 3,
    consumeTapEvents: true,
  );
}

Polygon _polygonFrom(String id, List<dynamic> rings, String category) {
  // First ring is the exterior boundary; interior rings (holes) are ignored
  // for the MVP — none of the current Gold Medal Lakes polygons have holes.
  final exterior = rings.isNotEmpty ? rings.first as List<dynamic> : const [];
  final color = _polygonColorByCategory[category] ?? const Color(0xFF1976D2);
  return Polygon(
    polygonId: PolygonId(id),
    points: _latLngRing(exterior),
    strokeColor: color,
    strokeWidth: 2,
    fillColor: color.withValues(alpha: 0.25),
    consumeTapEvents: true,
  );
}

List<LatLng> _latLngRing(List<dynamic> coordinates) {
  return coordinates
      .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
      .toList(growable: false);
}
