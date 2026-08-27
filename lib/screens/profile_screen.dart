import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/badges.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/colorado_catch_theme.dart';
import '../widgets/loading_indicator.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Profile photo upload is stubbed out until Cloud Storage is provisioned
  // (requires the Blaze plan) — see StorageService and SETUP.md.
  void _showUploadComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile photo upload is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      return const Center(child: Text('No user available'));
    }

    return SafeArea(
      child: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.leaderboardStream(),
        builder: (context, leaderboardSnapshot) {
          if (leaderboardSnapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          final leaderboardDocs = leaderboardSnapshot.data?.docs ?? [];
          final rankIndex = leaderboardDocs.indexWhere((d) => d.id == user.uid);
          final myEntry = rankIndex >= 0 ? leaderboardDocs[rankIndex].data() as Map<String, dynamic> : null;
          final points = myEntry?['totalPoints'] as int? ?? 0;
          final catchCount = myEntry?['catchCount'] as int? ?? 0;
          final hasRareOrBetter = myEntry?['hasRareCatch'] as bool? ?? false;
          final rankLabel = rankIndex >= 0 ? 'Rank ${rankIndex + 1} of ${leaderboardDocs.length}' : 'Unranked yet';

          return StreamBuilder<QuerySnapshot>(
            stream: firestoreService.userCatchesStream(user.uid),
            builder: (context, catchesSnapshot) {
              final catchDocs = catchesSnapshot.data?.docs ?? [];
              final species = catchDocs.map((d) => (d.data() as Map)['species'] as String? ?? '').toSet()..remove('');
              var biggest = 0.0;
              for (final d in catchDocs) {
                final length = ((d.data() as Map)['lengthInches'] as num?)?.toDouble() ?? 0;
                if (length > biggest) biggest = length;
              }
              final badges = earnedBadges(catchCount: catchCount, hasRareOrBetter: hasRareOrBetter);

              return ListView(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _showUploadComingSoon,
                        child: const CircleAvatar(
                          radius: 36,
                          backgroundColor: AppColors.paper,
                          child: Icon(Icons.person, size: 34, color: AppColors.forest),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName ?? user.email ?? 'Colorado Angler',
                              style: GoogleFonts.instrumentSerif(fontSize: 28, color: AppColors.ink),
                            ),
                            const SizedBox(height: 4),
                            Text(rankLabel, style: TextStyle(color: AppColors.muted, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.ink.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        _statCell('Season points', '$points'),
                        _divider(),
                        _statCell('Catches', '$catchCount'),
                        _divider(),
                        _statCell('Species', '${species.length}'),
                        _divider(),
                        _statCell('Biggest', biggest > 0 ? '${biggest.round()} in' : '—'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Badges', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      Text('${badges.length} of $totalBadgeCount', style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 84,
                    child: badges.isEmpty
                        ? Center(
                            child: Text('Log your first catch to start earning badges.',
                                style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: badges.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 10),
                            itemBuilder: (context, i) {
                              final badge = badges[i];
                              return SizedBox(
                                width: 82,
                                child: Column(
                                  children: [
                                    Container(
                                      width: 58,
                                      height: 58,
                                      decoration: BoxDecoration(
                                        color: AppColors.amber.withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Center(
                                        child: Text(badge.glyph,
                                            style: GoogleFonts.instrumentSerif(fontSize: 22, color: AppColors.forest)),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      badge.name,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 11, color: AppColors.mutedDark),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.ink.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        _settingsRow('Offline packs', 'None'),
                        _settingsRow('Units', 'Inches'),
                        _settingsRow('Catch visibility', 'Public'),
                        _settingsRow(
                          'CPW license',
                          'Get one →',
                          onTap: () => launchUrl(
                            Uri.parse('https://cpw.state.co.us/buyapply/Pages/Buy.aspx'),
                            mode: LaunchMode.externalApplication,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 56, color: AppColors.ink.withValues(alpha: 0.08));

  Widget _statCell(String label, String value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10.5, color: AppColors.muted)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
          ],
        ),
      ),
    );
  }

  Widget _settingsRow(String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.ink.withValues(alpha: 0.07)))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            Text(value, style: TextStyle(fontSize: 13, color: onTap != null ? AppColors.forest : AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
