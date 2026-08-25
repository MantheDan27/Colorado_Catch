import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../data/species_rarity.dart';
import '../services/firestore_service.dart';
import '../theme/colorado_catch_theme.dart';
import '../widgets/loading_indicator.dart';

/// One logged catch, in full — species/tier, where and when, and the real
/// scoring breakdown (length x rarity multiplier, already stored on the
/// catch doc by CatchService.logCatch). Photo stays a placeholder; catch
/// photos aren't persisted yet (Storage still needs the Blaze upgrade).
class CatchDetailScreen extends StatelessWidget {
  const CatchDetailScreen({super.key, required this.catchId});

  final String catchId;

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: StreamBuilder<DocumentSnapshot>(
        stream: firestoreService.catchDetail(catchId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          if (data == null) {
            return const Center(child: Text('Catch not found.'));
          }

          final species = data['species'] as String? ?? 'Unknown';
          final lengthInches = (data['lengthInches'] as num?)?.toDouble() ?? 0;
          final points = data['points'] as int? ?? 0;
          final tier = rarityOf(species);
          final confidence = (data['speciesConfidence'] as num?)?.toDouble();
          final released = data['released'] as bool?;
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          final userName = data['userName'] as String? ?? 'Angler';

          return Column(
            children: [
              SizedBox(
                height: 280,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: AppColors.forest),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Material(
                              color: Colors.white.withValues(alpha: 0.92),
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                                child: const SizedBox(width: 38, height: 38, child: Icon(Icons.arrow_back, size: 18)),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration:
                                  BoxDecoration(color: AppColors.amber, borderRadius: BorderRadius.circular(18)),
                              child: Text('+$points pts', style: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${tier.label.toUpperCase()} · ×${tier.pointsMultiplier} MULTIPLIER',
                        style: GoogleFonts.familjenGrotesk(fontSize: 11, letterSpacing: 1.6, color: tierColor(tier)),
                      ),
                      const SizedBox(height: 8),
                      Text(species, style: GoogleFonts.instrumentSerif(fontSize: 34, color: AppColors.ink)),
                      const SizedBox(height: 6),
                      Text(
                        [
                          userName,
                          if (createdAt != null) _formatDate(createdAt),
                        ].join(' · '),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.ink.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(18),
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('How this scored', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            _scoreRow('Length', '${lengthInches.round()} in'),
                            _scoreRow('Rarity tier', '${tier.label} (×${tier.pointsMultiplier})'),
                            const Divider(height: 22),
                            _scoreRow('Total', '$points points', bold: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              label: 'AI confidence',
                              value: confidence != null ? '${(confidence * 100).round()}%' : 'Manual entry',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatTile(
                              label: 'Released',
                              value: released == null ? 'Not recorded' : (released ? 'Yes' : 'No'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _scoreRow(String label, String value, {bool bold = false}) {
    final style = TextStyle(fontSize: bold ? 15 : 13.5, fontWeight: bold ? FontWeight.w600 : FontWeight.normal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.forest.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11.5, color: AppColors.mutedDark)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.forest)),
        ],
      ),
    );
  }
}
