import '../data/state_records.dart';

/// Which category (or both) a logged catch met/beat.
enum RecordCategory { weight, length }

class RecordAchievement {
  const RecordAchievement({required this.record, required this.categories});

  final SpeciesRecord record;
  final Set<RecordCategory> categories;
}

/// Checks a logged catch against the curated CPW state-records dataset
/// (state_records.dart). Only species we have a verified record for can
/// trigger this — anything else, or a catch that falls short, returns null
/// rather than guessing. [weightLbs] is optional since not every catch is
/// weighed on the water; when omitted only the length category is checked.
RecordAchievement? checkForStateRecord({
  required String species,
  required double lengthInches,
  double? weightLbs,
}) {
  final record = recordFor(species);
  if (record == null) return null;

  final categories = <RecordCategory>{};
  if (record.byLengthInches != null && lengthInches >= record.byLengthInches!) {
    categories.add(RecordCategory.length);
  }
  if (weightLbs != null && record.byWeightLbs != null && weightLbs >= record.byWeightLbs!) {
    categories.add(RecordCategory.weight);
  }

  if (categories.isEmpty) return null;
  return RecordAchievement(record: record, categories: categories);
}
