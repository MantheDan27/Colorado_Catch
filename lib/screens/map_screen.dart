import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../services/firestore_service.dart';
import '../theme/colorado_catch_theme.dart';
import '../theme/map_style.dart';
import '../utils/geojson_parser.dart';
import '../utils/marker_icon_builder.dart';
import '../widgets/loading_indicator.dart';
import 'spot_screen.dart';

/// Species filter chips shown over the map. CPW's baked data only gives a
/// coarse STOCKED category per water (trout vs. warmwater vs. mixed — see
/// tool/fetch_fishing_data.py), not exact per-species stocking, so these
/// filters are a reasonable approximation grouped by that category, not a
/// precise "this species is here" guarantee.
const _speciesFilters = ['Cutthroat', 'Rainbow', 'Walleye', 'Pike'];
const _coldwaterFilters = {'Cutthroat', 'Rainbow'};

bool _matchesFilter(FishingLocationDetails loc, String species) {
  final s = (loc.stocked ?? '').toLowerCase();
  final isTrout = s.contains('trout') || s.contains('sub-catchable');
  final isWarmwater = s.contains('warmwater');
  return _coldwaterFilters.contains(species) ? isTrout : isWarmwater;
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _initialCameraPosition = CameraPosition(target: LatLng(39.5, -105.5), zoom: 6);

  FishingMapOverlays _overlays = FishingMapOverlays.empty;
  Set<Marker> _fishingWaterMarkers = {};
  String? _selectedSpecies;
  bool _listView = false;

  List<FishingLocationDetails> get _filteredLocations {
    if (_selectedSpecies == null) return _overlays.fishingWaterLocations;
    return _overlays.fishingWaterLocations.where((l) => _matchesFilter(l, _selectedSpecies!)).toList();
  }

  @override
  void initState() {
    super.initState();
    loadFishingOverlays().then((overlays) async {
      if (!mounted) return;
      setState(() => _overlays = overlays);
      await _rebuildFishingWaterMarkers();
    });
  }

  Future<void> _rebuildFishingWaterMarkers() async {
    final locations = _filteredLocations;
    final filtering = _selectedSpecies != null;
    final markers = <Marker>{};

    for (var i = 0; i < locations.length; i++) {
      final loc = locations[i];
      final isTopMatch = filtering && i < 9;
      final icon = isTopMatch
          ? await buildNumberedMarkerIcon(i + 1, legend: true)
          : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      markers.add(Marker(
        markerId: MarkerId('fw-$i-${loc.name}'),
        position: LatLng(loc.latitude, loc.longitude),
        icon: icon,
        infoWindow: InfoWindow.noText,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SpotScreen(details: loc))),
      ));
    }

    if (mounted) setState(() => _fishingWaterMarkers = markers);
  }

  void _selectSpecies(String? species) {
    setState(() => _selectedSpecies = species == _selectedSpecies ? null : species);
    _rebuildFishingWaterMarkers();
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

        return Stack(
          children: [
            GoogleMap(
              style: mapStyleJson,
              initialCameraPosition: _initialCameraPosition,
              markers: {..._overlays.markers, ..._fishingWaterMarkers, ...liveMarkers},
              polylines: _overlays.polylines,
              polygons: _overlays.polygons,
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              rotateGesturesEnabled: true,
              zoomControlsEnabled: true,
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text('Colorado waters', style: GoogleFonts.instrumentSerif(fontSize: 28, color: AppColors.ink)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _speciesFilters.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 7),
                        itemBuilder: (context, i) {
                          final species = _speciesFilters[i];
                          final selected = species == _selectedSpecies;
                          return ChoiceChip(
                            label: Text(species),
                            selected: selected,
                            onSelected: (_) => _selectSpecies(species),
                            selectedColor: AppColors.ink,
                            labelStyle: TextStyle(
                              color: selected ? AppColors.cream : AppColors.ink,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                            ),
                            backgroundColor: AppColors.ink.withValues(alpha: 0.06),
                            side: BorderSide.none,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _selectedSpecies == null
                          ? '${_overlays.fishingWaterLocations.length} waters mapped statewide'
                          : '${_filteredLocations.length} waters likely hold $_selectedSpecies',
                      style: GoogleFonts.familjenGrotesk(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 20,
              child: _Legend(),
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: _ListViewToggle(
                listView: _listView,
                onToggle: () => setState(() => _listView = !_listView),
              ),
            ),
            if (_listView)
              Positioned.fill(
                child: Container(
                  color: AppColors.cream,
                  child: SafeArea(
                    top: false,
                    child: ListView.separated(
                      padding: const EdgeInsets.only(top: 130),
                      itemCount: _filteredLocations.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final loc = _filteredLocations[i];
                        return ListTile(
                          leading: CircleBorderIndex(index: i + 1),
                          title: Text(loc.name),
                          subtitle: Text(loc.subtitle ?? ''),
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => SpotScreen(details: loc))),
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class CircleBorderIndex extends StatelessWidget {
  const CircleBorderIndex({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: AppColors.paper,
      foregroundColor: AppColors.ink,
      child: Text('$index', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 164,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LEGEND',
            style: GoogleFonts.familjenGrotesk(fontSize: 10.5, letterSpacing: 1.6, color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          _legendRow(color: AppColors.river, label: 'River', isLine: true),
          const SizedBox(height: 6),
          _legendRow(color: AppColors.lake, label: 'Lake / reservoir'),
          const SizedBox(height: 6),
          _legendRow(color: AppColors.tierRare, label: 'Top match', isCircle: true),
        ],
      ),
    );
  }

  Widget _legendRow({required Color color, required String label, bool isLine = false, bool isCircle = false}) {
    return Row(
      children: [
        if (isLine)
          Container(width: 14, height: 3, color: color)
        else
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
              border: Border.all(color: const Color(0xFF6E969B)),
            ),
          ),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.familjenGrotesk(fontSize: 11.5, color: AppColors.ink)),
      ],
    );
  }
}

class _ListViewToggle extends StatelessWidget {
  const _ListViewToggle({required this.listView, required this.onToggle});

  final bool listView;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ink,
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            listView ? 'Map view' : 'List view',
            style: GoogleFonts.familjenGrotesk(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.cream),
          ),
        ),
      ),
    );
  }
}
