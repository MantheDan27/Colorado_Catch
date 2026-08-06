import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/firestore_service.dart';
import '../widgets/loading_indicator.dart';

/// Ranks anglers by points — coins earned from logged catches, weighted by
/// fish size and species rarity (see lib/utils/points_calculator.dart and
/// CatchService.logCatch).
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
            final points = data['totalPoints'] as int? ?? 0;
            final catches = data['catchCount'] as int? ?? 0;
            return ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(data['displayName'] as String? ?? 'Angler'),
              subtitle: Text('$catches ${catches == 1 ? 'catch' : 'catches'}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text('$points', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
