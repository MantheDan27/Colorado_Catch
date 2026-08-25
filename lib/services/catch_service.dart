import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/species_rarity.dart';
import '../utils/points_calculator.dart';
import 'firestore_service.dart';

/// Everything the UI needs after logging a catch — the Done screen shows
/// points/tier immediately without a re-read, and badge unlocks are derived
/// from the "before" counters the transaction already had in hand.
class CatchLogResult {
  const CatchLogResult({
    required this.catchId,
    required this.points,
    required this.tier,
    required this.priorCatchCount,
    required this.priorHadRareOrBetter,
  });

  final String catchId;
  final int points;
  final RarityTier tier;

  /// Counters *before* this catch was added — for computing which badges
  /// (see lib/data/badges.dart) are newly unlocked, not just currently held.
  final int priorCatchCount;
  final bool priorHadRareOrBetter;
}

/// Logs a fish catch and keeps the leaderboard's per-user aggregate in sync.
/// Takes FirestoreService as a dependency (the one exception to this app's
/// usual self-instantiate-Firebase pattern) so it can reuse
/// FirestoreService.addLocation rather than duplicating that write.
class CatchService {
  CatchService(this._firestoreService);

  final FirestoreService _firestoreService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<CatchLogResult> logCatch({
    required String userId,
    required String userName,
    required String species,
    double? speciesConfidence,
    required bool wasManualOverride,
    List<Map<String, dynamic>> aiSuggestions = const [],
    required double lengthInches,
    required bool released,
    double? latitude,
    double? longitude,
  }) async {
    final catchRef = _firestore.collection('catches').doc();
    final leaderboardRef = _firestoreService.leaderboard.doc(userId);
    final now = Timestamp.now();
    final points = calculateCatchPoints(species: species, lengthInches: lengthInches);
    final tier = rarityOf(species);
    final isRareOrBetter = tier == RarityTier.rare || tier == RarityTier.legendary;

    final catchData = {
      'userId': userId,
      'userName': userName,
      'species': species,
      'speciesConfidence': speciesConfidence,
      'wasManualOverride': wasManualOverride,
      'aiSuggestions': aiSuggestions,
      'lengthInches': lengthInches,
      'points': points,
      'tier': tier.name,
      'released': released,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': now,
    };

    late final int priorCatchCount;
    late final bool priorHadRareOrBetter;

    await _firestore.runTransaction((tx) async {
      final leaderboardSnap = await tx.get(leaderboardRef);
      final leaderboardData = leaderboardSnap.data() as Map<String, dynamic>?;
      priorCatchCount = (leaderboardData?['catchCount'] as int?) ?? 0;
      priorHadRareOrBetter = (leaderboardData?['hasRareCatch'] as bool?) ?? false;
      final currentPoints = (leaderboardData?['totalPoints'] as int?) ?? 0;

      tx.set(catchRef, catchData);
      tx.set(leaderboardRef, {
        'displayName': userName,
        'catchCount': priorCatchCount + 1,
        'totalPoints': currentPoints + points,
        'hasRareCatch': priorHadRareOrBetter || isRareOrBetter,
        'lastCatchAt': now,
      }, SetOptions(merge: true));
    });

    if (latitude != null && longitude != null) {
      await _firestoreService.addLocation(catchRef.id, {
        'latitude': latitude,
        'longitude': longitude,
        'title': '$species ($points pts) — $userName',
      });
    }

    return CatchLogResult(
      catchId: catchRef.id,
      points: points,
      tier: tier,
      priorCatchCount: priorCatchCount,
      priorHadRareOrBetter: priorHadRareOrBetter,
    );
  }
}
