import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_service.dart';

/// Logs a fish catch and keeps the leaderboard's per-user aggregate in sync.
/// Takes FirestoreService as a dependency (the one exception to this app's
/// usual self-instantiate-Firebase pattern) so it can reuse
/// FirestoreService.addLocation rather than duplicating that write.
class CatchService {
  CatchService(this._firestoreService);

  final FirestoreService _firestoreService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> logCatch({
    required String userId,
    required String userName,
    required String species,
    double? speciesConfidence,
    required bool wasManualOverride,
    List<Map<String, dynamic>> aiSuggestions = const [],
    double? latitude,
    double? longitude,
  }) async {
    final catchRef = _firestore.collection('catches').doc();
    final leaderboardRef = _firestoreService.leaderboard.doc(userId);
    final now = Timestamp.now();

    final catchData = {
      'userId': userId,
      'userName': userName,
      'species': species,
      'speciesConfidence': speciesConfidence,
      'wasManualOverride': wasManualOverride,
      'aiSuggestions': aiSuggestions,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': now,
    };

    await _firestore.runTransaction((tx) async {
      final leaderboardSnap = await tx.get(leaderboardRef);
      final leaderboardData = leaderboardSnap.data() as Map<String, dynamic>?;
      final currentCount = (leaderboardData?['catchCount'] as int?) ?? 0;

      tx.set(catchRef, catchData);
      tx.set(leaderboardRef, {
        'displayName': userName,
        'catchCount': currentCount + 1,
        'lastCatchAt': now,
      }, SetOptions(merge: true));
    });

    if (latitude != null && longitude != null) {
      await _firestoreService.addLocation(catchRef.id, {
        'latitude': latitude,
        'longitude': longitude,
        'title': '$species — $userName',
      });
    }
  }
}
