import 'package:flutter/material.dart';

import '../data/bite_tips.dart';
import '../data/species_rarity.dart';
import '../models/bite_window.dart';
import '../utils/geojson_parser.dart';

/// Opened when a fishing-water marker is tapped on the map. Shows the
/// location name and a horizontal carousel of Bite Window cards (Dawn/Dusk,
/// computed from the location's coordinates); tapping a card opens a second
/// sheet with which species are likely biting and a couple of tips for that
/// window.
class LocationDetailSheet extends StatelessWidget {
  const LocationDetailSheet({super.key, required this.details});

  final FishingLocationDetails details;

  @override
  Widget build(BuildContext context) {
    final windows = calculateBiteWindows(latitude: details.latitude, longitude: details.longitude);
    final tips = tipsFor(category: categorizeStocked(details.stocked), locType: details.locType);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(details.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (details.subtitle != null && details.subtitle!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(details.subtitle!, style: TextStyle(color: Colors.grey[600])),
            ],
            const SizedBox(height: 16),
            const Text('Bite Windows', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: windows.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final window = windows[index];
                  return _BiteWindowCard(
                    window: window,
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => _BiteWindowDetailSheet(
                        locationName: details.name,
                        window: window,
                        tips: tips,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BiteWindowCard extends StatelessWidget {
  const _BiteWindowCard({required this.window, required this.onTap});

  final BiteWindow window;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${window.emoji} ${window.label}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('${formatTimeOfDay(window.start)} – ${formatTimeOfDay(window.end)}'),
            const SizedBox(height: 4),
            Row(
              children: const [
                Text('Tap for details', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BiteWindowDetailSheet extends StatelessWidget {
  const _BiteWindowDetailSheet({required this.locationName, required this.window, required this.tips});

  final String locationName;
  final BiteWindow window;
  final LocationTipContent tips;

  @override
  Widget build(BuildContext context) {
    final tip = window.label == 'Dawn Bite' ? tips.dawnTip : tips.duskTip;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${window.emoji} ${window.label}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              '${formatTimeOfDay(window.start)} – ${formatTimeOfDay(window.end)} · $locationName',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            const Text("What's likely biting", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final species in tips.likelySpecies)
                  Chip(
                    label: Text(species),
                    backgroundColor: _colorForTier(rarityOf(species)).withValues(alpha: 0.15),
                    side: BorderSide(color: _colorForTier(rarityOf(species))),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Professional tip', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(tip),
          ],
        ),
      ),
    );
  }
}

Color _colorForTier(RarityTier tier) {
  switch (tier) {
    case RarityTier.common:
      return Colors.blueGrey;
    case RarityTier.uncommon:
      return Colors.blue;
    case RarityTier.rare:
      return Colors.deepOrange;
    case RarityTier.legendary:
      return Colors.purple;
  }
}
