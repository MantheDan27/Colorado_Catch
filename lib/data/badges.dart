import '../data/species_rarity.dart';

/// A small, honestly-computable achievement system — not a literal
/// recreation of the "Colorado Catch, redesigned" mockup's 4 example badges
/// (some, like "Canyon Runner," aren't inferable from real CPW data). Rules
/// here are all derivable from a user's own catch history.
class CatchBadge {
  const CatchBadge({required this.name, required this.glyph});

  final String name;
  final String glyph;
}

const _milestones = [10, 25, 50, 100];

/// Badges newly unlocked by logging this catch — compares "before" counters
/// (from CatchLogResult, already read during the logging transaction) to
/// the state right after. Returns an empty list most of the time.
List<CatchBadge> newlyUnlockedBadges({
  required int priorCatchCount,
  required bool priorHadRareOrBetter,
  required RarityTier newCatchTier,
}) {
  final newCatchCount = priorCatchCount + 1;
  final unlocked = <CatchBadge>[];

  if (priorCatchCount == 0) {
    unlocked.add(const CatchBadge(name: 'First Cast', glyph: '✦'));
  }

  final isRareOrBetter = newCatchTier == RarityTier.rare || newCatchTier == RarityTier.legendary;
  if (!priorHadRareOrBetter && isRareOrBetter) {
    unlocked.add(const CatchBadge(name: 'Rare Water', glyph: '★'));
  }

  for (final milestone in _milestones) {
    if (priorCatchCount < milestone && newCatchCount >= milestone) {
      unlocked.add(CatchBadge(name: '$milestone Catches', glyph: '⬢'));
    }
  }

  return unlocked;
}

/// All badges a user currently holds, given their overall stats — used by
/// ProfileScreen (vs. newlyUnlockedBadges, which is for the Done screen's
/// "just unlocked" moment).
List<CatchBadge> earnedBadges({required int catchCount, required bool hasRareOrBetter}) {
  final earned = <CatchBadge>[];
  if (catchCount >= 1) earned.add(const CatchBadge(name: 'First Cast', glyph: '✦'));
  if (hasRareOrBetter) earned.add(const CatchBadge(name: 'Rare Water', glyph: '★'));
  for (final milestone in _milestones) {
    if (catchCount >= milestone) {
      earned.add(CatchBadge(name: '$milestone Catches', glyph: '⬢'));
    }
  }
  return earned;
}

/// Every badge that exists, for the "X of Y" progress count on Profile.
int get totalBadgeCount => 2 + _milestones.length;
