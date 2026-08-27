/// Curated species -> rarity tier lookup for the leaderboard points formula
/// (see lib/utils/points_calculator.dart). This is a static, hand-maintained
/// list of Colorado gamefish, not a live/authoritative rarity data source —
/// tune freely as the app grows. Lookups are case-insensitive; any species
/// not listed here (including free-typed manual entries) falls back to
/// [RarityTier.common] so scoring never breaks on an unrecognized name.
enum RarityTier {
  common(1, 'Common'),
  uncommon(2, 'Uncommon'),
  rare(4, 'Rare'),
  legendary(8, 'Legendary');

  const RarityTier(this.pointsMultiplier, this.label);

  /// Multiplied against a catch's length (inches) to get its point value.
  final int pointsMultiplier;

  /// Display name, e.g. for tier pills/chips.
  final String label;
}

const Map<String, RarityTier> _speciesRarity = {
  // Common — widespread stocked/self-sustaining species anglers catch often.
  'rainbow trout': RarityTier.common,
  'brown trout': RarityTier.common,
  'brook trout': RarityTier.common,
  'bluegill': RarityTier.common,
  'largemouth bass': RarityTier.common,
  'smallmouth bass': RarityTier.common,
  'yellow perch': RarityTier.common,
  'black crappie': RarityTier.common,
  'white crappie': RarityTier.common,
  'channel catfish': RarityTier.common,
  'common carp': RarityTier.common,
  'green sunfish': RarityTier.common,
  'pumpkinseed': RarityTier.common,

  // Uncommon — present but caught less often, or need specific waters.
  'cutthroat trout': RarityTier.uncommon,
  'northern pike': RarityTier.uncommon,
  'walleye': RarityTier.uncommon,
  'kokanee salmon': RarityTier.uncommon,
  'splake': RarityTier.uncommon,
  'wiper': RarityTier.uncommon,
  'sauger': RarityTier.uncommon,
  'flathead catfish': RarityTier.uncommon,

  // Rare — limited waters, harder to catch, or trophy-class species.
  'lake trout': RarityTier.rare,
  'mackinaw': RarityTier.rare,
  'tiger muskie': RarityTier.rare,
  'arctic grayling': RarityTier.rare,
  'arctic char': RarityTier.rare,
  'golden trout': RarityTier.rare,
  'cutbow': RarityTier.rare,
  'snake river cutthroat': RarityTier.rare,

  // Legendary — Colorado-native, threatened/endangered, or exceptionally
  // rare-to-encounter species. Some of these are catch-and-release-only or
  // protected under CPW regulations; scoring them highly rewards correctly
  // identifying and releasing them, not targeting them.
  'greenback cutthroat trout': RarityTier.legendary,
  'colorado river cutthroat trout': RarityTier.legendary,
  'rio grande cutthroat trout': RarityTier.legendary,
  'paddlefish': RarityTier.legendary,
  'razorback sucker': RarityTier.legendary,
  'bonytail': RarityTier.legendary,
  'humpback chub': RarityTier.legendary,
};

RarityTier rarityOf(String species) {
  return _speciesRarity[species.trim().toLowerCase()] ?? RarityTier.common;
}
