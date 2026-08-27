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
    this.fishingWaterLocations = const [],
  });

  /// Boat ramps, accessible areas — simple categories with no per-location
  /// detail screen. Fishing-water points are NOT included here; MapScreen
  /// builds their markers itself from [fishingWaterLocations] so it can
  /// filter/number them (species chips, "top matches") — see map_screen.dart.
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Set<Polygon> polygons;
  final List<FishingLocationDetails> fishingWaterLocations;

  static const empty = FishingMapOverlays();
}

/// Per-location metadata for a 'fishing_water' point — enough to drive the
/// full-screen Spot detail (see spot_screen.dart). Not needed for the other
/// CPW categories (boat ramps, Gold Medal lines, etc.), which keep their
/// plain InfoWindow tooltip instead.
class FishingLocationDetails {
  const FishingLocationDetails({
    required this.name,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
    this.stocked,
    this.locType,
  });

  final String name;
  final String? subtitle;
  final double latitude;
  final double longitude;
  final String? stocked;
  final String? locType;
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
  final fishingWaterLocations = <FishingLocationDetails>[];

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
        final lat = (coords[1] as num).toDouble();
        final lng = (coords[0] as num).toDouble();

        if (category == 'fishing_water') {
          fishingWaterLocations.add(FishingLocationDetails(
            name: name,
            subtitle: subtitle,
            latitude: lat,
            longitude: lng,
            stocked: properties['stocked'] as String?,
            locType: properties['locType'] as String?,
          ));
          break;
        }

        markers.add(Marker(
          markerId: MarkerId(id),
          position: LatLng(lat, lng),
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

  return FishingMapOverlays(
    markers: markers,
    polylines: polylines,
    polygons: polygons,
    fishingWaterLocations: fishingWaterLocations,
  );
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
