/// Colorado Parks & Wildlife state fishing records — by-weight and
/// by-length, per species. A curated, hand-maintained snapshot sourced from
/// CPW's Fishing Awards & Records page ([stateRecordsSourceUrl]), captured
/// 2026-08-27. This is NOT a live feed — CPW updates records as new catches
/// are certified, so treat this as a snapshot to refresh periodically, the
/// same spirit as species_rarity.dart's curated list.
///
/// Only species with a record CPW's page actually attributes to a named
/// angler/date/location are listed here. A species missing from
/// [stateRecords] doesn't mean there's no state record for it — it means we
/// don't have a verified one on file, so record-breaking checks
/// (see lib/utils/record_checker.dart) simply stay silent for it rather than
/// guessing at a number.
library;

/// General records/rules page — cites the process for both application
/// types (by-weight requires a certified-scale weigh-in and the fish NOT be
/// released beforehand; by-length requires the fish be released, measured
/// on a qualifying device, and photographed).
const stateRecordsSourceUrl = 'https://cpw.state.co.us/activities/fishing/fishing-awards-and-records';

/// CPW's downloadable PDF application forms for each record category.
const byWeightApplicationUrl = 'https://cpw.widencollective.com/assets/share/asset/9wlqbvd384';
const byLengthApplicationUrl = 'https://cpw.widencollective.com/assets/share/asset/c6msbqb1il';

/// One record entry — the current holder in a single category.
class RecordEntry {
  const RecordEntry({
    required this.displayValue,
    required this.angler,
    required this.year,
    required this.location,
  });

  /// Human-readable value as CPW lists it, e.g. "33 lb 8.53 oz" or "38.75 in".
  final String displayValue;
  final String angler;
  final int year;
  final String location;
}

/// A species' current state records. Either field may be null — CPW doesn't
/// list a certified record in every category for every species.
class SpeciesRecord {
  const SpeciesRecord({
    required this.species,
    this.byWeightLbs,
    this.byWeight,
    this.byLengthInches,
    this.byLength,
  });

  final String species;

  /// Decimal-pound value of [byWeight], for record-beaten comparisons.
  final double? byWeightLbs;
  final RecordEntry? byWeight;

  /// Inch value of [byLength], for record-beaten comparisons.
  final double? byLengthInches;
  final RecordEntry? byLength;
}

const stateRecords = <SpeciesRecord>[
  SpeciesRecord(
    species: 'Blue Catfish',
    byWeightLbs: 33.533,
    byWeight: RecordEntry(displayValue: '33 lb 8.53 oz', angler: 'Coy Bowyer', year: 2023, location: 'Pueblo Reservoir'),
    byLengthInches: 38.75,
    byLength: RecordEntry(displayValue: '38.75 in', angler: 'Clarence Iversen', year: 2025, location: 'Pueblo Reservoir'),
  ),
  SpeciesRecord(
    species: 'Channel Catfish',
    byWeightLbs: 43.38,
    byWeight: RecordEntry(displayValue: '43 lb 6.08 oz', angler: 'Jessica Walton', year: 2010, location: 'Aurora Reservoir'),
    byLengthInches: 40,
    byLength: RecordEntry(displayValue: '40 in', angler: 'David Carslay', year: 2025, location: 'Pueblo Reservoir'),
  ),
  SpeciesRecord(
    species: 'Brown Trout',
    byWeightLbs: 30.5,
    byWeight: RecordEntry(displayValue: '30 lb 8 oz', angler: 'Alan Schneider', year: 1988, location: 'Roaring Judy Ponds'),
    byLengthInches: 30,
    byLength: RecordEntry(displayValue: '30 in', angler: 'Dustin Noha', year: 2025, location: 'Dillon Reservoir'),
  ),
  SpeciesRecord(
    species: 'Common Carp',
    byWeightLbs: 35.31,
    byWeight: RecordEntry(displayValue: '35 lb 4.96 oz', angler: 'Adam Wickam', year: 2001, location: 'Glenmere Park'),
    byLengthInches: 36,
    byLength: RecordEntry(displayValue: '36 in', angler: 'Ryan Elliott', year: 2025, location: 'Valco Pond #2'),
  ),
  SpeciesRecord(
    species: 'Cutbow',
    byWeightLbs: 20.3,
    byWeight: RecordEntry(displayValue: '20 lb 4.8 oz', angler: 'Zach Cooper', year: 2025, location: 'Spinney Mountain Reservoir'),
    byLengthInches: 27.75,
    byLength: RecordEntry(displayValue: '27.75 in', angler: 'Peter Erskine', year: 2025, location: 'Spinney Mountain Reservoir'),
  ),
  SpeciesRecord(
    species: 'Cutthroat Trout',
    byWeightLbs: 16,
    byWeight: RecordEntry(displayValue: '16 lb 0 oz', angler: 'George Hranchak', year: 1964, location: 'Twin Lakes'),
  ),
  SpeciesRecord(
    species: 'Kokanee Salmon',
    byWeightLbs: 11,
    byWeight: RecordEntry(displayValue: '11 lb 0 oz', angler: 'Helen Eaton', year: 1989, location: 'Williams Fork Reservoir'),
  ),
  SpeciesRecord(
    species: 'Brook Trout',
    byLengthInches: 22.25,
    byLength: RecordEntry(displayValue: '22.25 in', angler: 'Dylan Roby', year: 2025, location: 'Long Lake'),
  ),
  SpeciesRecord(
    species: 'Arctic Char',
    byLengthInches: 25.38,
    byLength: RecordEntry(displayValue: '25.38 in', angler: 'Travis Divis', year: 2024, location: 'Lake Dillon'),
  ),
  SpeciesRecord(
    species: 'Black Crappie',
    byLengthInches: 18.25,
    byLength: RecordEntry(displayValue: '18.25 in', angler: 'Eric Allee', year: 2023, location: 'McKay Lake'),
  ),
  SpeciesRecord(
    species: 'Bluegill',
    byLengthInches: 11.50,
    byLength: RecordEntry(displayValue: '11.50 in', angler: 'Joseph Yang', year: 2025, location: 'Big Thompson Outfitter Lake'),
  ),
];

/// Case-insensitive lookup, same convention as species_rarity.dart's rarityOf.
SpeciesRecord? recordFor(String species) {
  final key = species.trim().toLowerCase();
  for (final record in stateRecords) {
    if (record.species.toLowerCase() == key) return record;
  }
  return null;
}
