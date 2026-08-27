/// Google Maps custom style JSON, tinting the base map toward the redesign's
/// paper/atlas palette (see colorado_catch_theme.dart). A real GoogleMap
/// can't reproduce the mockup's hand-drawn river illustrations, but this
/// styling API gets the same warm cream/muted-teal feel on real map tiles.
/// Passed to GoogleMap(style: mapStyleJson) — see map_screen.dart.
const mapStyleJson = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#EFE7D6"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#6A6156"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#F6F3ED"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#9BC0C4"}]},
  {"featureType": "landscape.natural", "elementType": "geometry", "stylers": [{"color": "#E3D9C4"}]},
  {"featureType": "poi", "stylers": [{"visibility": "off"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#DCCFB4"}]},
  {"featureType": "road", "elementType": "labels", "stylers": [{"visibility": "simplified"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#D3C4A2"}]},
  {"featureType": "administrative", "elementType": "geometry.stroke", "stylers": [{"color": "#B9AC8F"}]},
  {"featureType": "transit", "stylers": [{"visibility": "off"}]}
]
''';
