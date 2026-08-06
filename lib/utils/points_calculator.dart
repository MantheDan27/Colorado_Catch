import '../data/species_rarity.dart';

/// MVP scoring formula: points = length (inches, rounded) x rarity
/// multiplier (see species_rarity.dart). A 12" Rainbow Trout is 12 points;
/// a 12" Greenback Cutthroat is 96. Tune freely — this is the one place the
/// formula lives, used by both CatchService (to award points) and anywhere
/// that wants to preview a score before logging.
int calculateCatchPoints({required String species, required double lengthInches}) {
  final tier = rarityOf(species);
  return (lengthInches.round()) * tier.pointsMultiplier;
}
