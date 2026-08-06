import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/firestore_service.dart';
import '../widgets/loading_indicator.dart';

/// Ranks anglers by catches logged. Scoring is intentionally simple for the
/// MVP — raw catch count, no species/size weighting yet (see FirestoreService
/// .leaderboardStream and CatchService.logCatch for where that would extend).
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.leaderboardStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No catches logged yet — be the first!'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(data['displayName'] as String? ?? 'Angler'),
              trailing: Text('${data['catchCount'] ?? 0} catches'),
            );
          },
        );
      },
    );
  }
}
