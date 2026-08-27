import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../data/species_rarity.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/colorado_catch_theme.dart';
import '../widgets/loading_indicator.dart';
import 'catch_detail_screen.dart';

/// "Log" nav tab — the signed-in user's own catch history, backed by
/// FirestoreService.userCatchesStream. Tapping a row opens CatchDetailScreen.
class CatchLogScreen extends StatelessWidget {
  const CatchLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final uid = authService.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return SafeArea(
      child: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.userCatchesStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          final docs = snapshot.data?.docs ?? [];

          final catchCount = docs.length;
          final totalPoints = docs.fold<int>(0, (total, d) => total + ((d.data() as Map)['points'] as int? ?? 0));
          final species = docs.map((d) => (d.data() as Map)['species'] as String? ?? '').toSet()..remove('');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
                child: Text('Your log', style: GoogleFonts.instrumentSerif(fontSize: 32, color: AppColors.ink)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 4),
                child: Row(
                  children: [
                    _statColumn('$catchCount', 'Catches'),
                    const SizedBox(width: 20),
                    _statColumn('$totalPoints', 'Points'),
                    const SizedBox(width: 20),
                    _statColumn('${species.length}', 'Species'),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: docs.isEmpty
                    ? const Center(child: Text('No catches logged yet — tap the camera button to start.'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        itemCount: docs.length,
                        separatorBuilder: (_, _) => Divider(height: 1, color: AppColors.ink.withValues(alpha: 0.08)),
                        itemBuilder: (context, i) {
                          final data = docs[i].data() as Map<String, dynamic>;
                          final species = data['species'] as String? ?? 'Unknown';
                          final points = data['points'] as int? ?? 0;
                          final lengthInches = (data['lengthInches'] as num?)?.toDouble() ?? 0;
                          final tier = rarityOf(species);
                          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: tierColor(tier).withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.set_meal_outlined, color: tierColor(tier)),
                            ),
                            title: Text(species, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${createdAt != null ? _formatDate(createdAt) : ''} · ${lengthInches.round()} in',
                              style: TextStyle(color: AppColors.muted),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('$points', style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(
                                  tier.label.toUpperCase(),
                                  style: TextStyle(fontSize: 10.5, letterSpacing: 1, color: tierColor(tier)),
                                ),
                              ],
                            ),
                            onTap: () => Navigator.of(context)
                                .push(MaterialPageRoute(builder: (_) => CatchDetailScreen(catchId: docs[i].id))),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statColumn(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.ink)),
        Text(label, style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}
