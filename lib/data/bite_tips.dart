/// Curated "which fish are biting" + "professional tips" content for the
/// location-detail bite-window sheet. Static and hand-maintained, same
/// approach as species_rarity.dart — CPW's data gives a rough stocking
/// category per water (see STOCKED in tool/fetch_fishing_data.py), not a
/// full species list or angling advice, so this fills that gap with
/// general, defensible guidance rather than claiming per-water precision.
library;

/// Coarse water category derived from CPW's free-text STOCKED field (e.g.
/// "Catchable trout and Warmwater"). "No" or missing data falls back to
/// [general] rather than guessing.
enum WaterCategory { coldwater, warmwater, mixed, general }

WaterCategory categorizeStocked(String? stocked) {
  final s = (stocked ?? '').toLowerCase();
  final hasTrout = s.contains('trout') || s.contains('sub-catchable');
  final hasWarmwater = s.contains('warmwater');
  if (hasTrout && hasWarmwater) return WaterCategory.mixed;
  if (hasTrout) return WaterCategory.coldwater;
  if (hasWarmwater) return WaterCategory.warmwater;
  return WaterCategory.general;
}

class LocationTipContent {
  const LocationTipContent({required this.likelySpecies, required this.dawnTip, required this.duskTip});

  final List<String> likelySpecies;
  final String dawnTip;
  final String duskTip;
}

const _coldwaterSpecies = ['Rainbow Trout', 'Brown Trout', 'Brook Trout', 'Cutthroat Trout'];
const _warmwaterSpecies = ['Largemouth Bass', 'Smallmouth Bass', 'Bluegill', 'Channel Catfish'];

LocationTipContent tipsFor({required WaterCategory category, String? locType}) {
  final isStream = (locType ?? '').toLowerCase().contains('stream') || (locType ?? '').toLowerCase().contains('river');

  switch (category) {
    case WaterCategory.coldwater:
      return LocationTipContent(
        likelySpecies: _coldwaterSpecies,
        dawnTip: isStream
            ? 'Trout key on low light — drift nymphs or small streamers through riffles and current seams as the water starts to warm.'
            : 'Work shallow flats and inlets at first light, where trout cruise for baitfish before the sun pushes them deeper.',
        duskTip: isStream
            ? 'Match the evening hatch: watch slower pools for rising fish and swing soft-hackles or dries as insects emerge.'
            : 'Fish shoreline drop-offs as the water cools — trout often push shallow again to feed in the last hour of light.',
      );

    case WaterCategory.warmwater:
      return LocationTipContent(
        likelySpecies: _warmwaterSpecies,
        dawnTip:
            'Target bass and panfish around weed beds and shallow cover before the sun climbs — topwater lures shine in low light.',
        duskTip: 'Fish push toward structure and shallows as the sun sets — slow-roll a spinnerbait or jig along drop-offs.',
      );

    case WaterCategory.mixed:
      return LocationTipContent(
        likelySpecies: [..._coldwaterSpecies.take(2), ..._warmwaterSpecies.take(2)],
        dawnTip: 'Both trout and warmwater species feed hardest in the first hour of light — start shallow and adjust to what\'s working.',
        duskTip: 'As light fades, trout often move shallow while bass/panfish tuck near structure — cover water to find which is active.',
      );

    case WaterCategory.general:
      return const LocationTipContent(
        likelySpecies: ['Rainbow Trout', 'Brown Trout', 'Largemouth Bass', 'Bluegill'],
        dawnTip: 'Low light is prime time regardless of species — fish are typically more active and less wary in the first hour after sunrise.',
        duskTip: 'The last hour before sunset is usually the day\'s second-best window — many species feed up before nightfall.',
      );
  }
}
