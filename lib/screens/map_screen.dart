import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../services/firestore_service.dart';
import '../widgets/loading_indicator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _initialCameraPosition = CameraPosition(target: LatLng(39.5, -105.5), zoom: 6);

  Set<Marker> _markers = {};

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Provider.of<FirestoreService>(context).locations.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }

        final docs = snapshot.data?.docs ?? [];
        _markers = docs.map((doc) {
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
          markers: _markers,
        );
      },
    );
  }
}
