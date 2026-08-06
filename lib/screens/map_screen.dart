import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../services/firestore_service.dart';
import '../utils/geojson_parser.dart';
import '../widgets/loading_indicator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _initialCameraPosition = CameraPosition(target: LatLng(39.5, -105.5), zoom: 6);

  // Static CPW Fishing Atlas overlays (rivers/lakes/ponds/fishing areas),
  // baked at build time — see tool/fetch_fishing_data.py. Loaded once and
  // layered under the live, user/catch-submitted pins below.
  FishingMapOverlays _overlays = FishingMapOverlays.empty;

  @override
  void initState() {
    super.initState();
    loadFishingOverlays().then((overlays) {
      if (mounted) setState(() => _overlays = overlays);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Provider.of<FirestoreService>(context).locations.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }

        final docs = snapshot.data?.docs ?? [];
        final liveMarkers = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final lat = data['latitude'] as double? ?? 39.5;
          final lng = data['longitude'] as double? ?? -105.5;
          return Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(title: data['title'] as String? ?? 'Catch Spot'),
          );
        }).toSet();

        return GoogleMap(
          initialCameraPosition: _initialCameraPosition,
          markers: {..._overlays.markers, ...liveMarkers},
          polylines: _overlays.polylines,
          polygons: _overlays.polygons,
        );
      },
    );
  }
}
