import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/firestore_service.dart';

/// Small rounded badge showing the signed-in user's total leaderboard
/// points ("coins") — see lib/utils/points_calculator.dart for how points
/// are earned. Lives in HomeScreen's AppBar so it's visible from any tab.
class PointsPill extends StatelessWidget {
  const PointsPill({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return StreamBuilder<DocumentSnapshot>(
      stream: firestoreService.leaderboardEntry(uid),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final points = data?['totalPoints'] as int? ?? 0;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text('$points', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }
}
