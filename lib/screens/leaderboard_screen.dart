import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/firestore_service.dart';
import '../theme/colorado_catch_theme.dart';
import '../widgets/loading_indicator.dart';

enum _BoardTab { season, all, friends }

/// Ranks anglers by points — coins earned from logged catches, weighted by
/// fish size and species rarity (see lib/utils/points_calculator.dart and
/// CatchService.logCatch). Only "All-time" is backed by real data — there's
/// no season-boundary or friends/social-graph data in this app yet, so
/// those tabs are shown but inert rather than faking scoped results.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  _BoardTab _tab = _BoardTab.all;

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
            child: Text('Leaderboard', style: GoogleFonts.instrumentSerif(fontSize: 32, color: AppColors.ink)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppColors.ink.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  _tabButton('Season', _BoardTab.season),
                  _tabButton('All-time', _BoardTab.all),
                  _tabButton('Friends', _BoardTab.friends),
                ],
              ),
            ),
          ),
          if (_tab != _BoardTab.all)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
              child: Text(
                'Coming soon — showing all-time standings for now.',
                style: TextStyle(fontSize: 12, color: AppColors.muted, fontStyle: FontStyle.italic),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestoreService.leaderboardStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator();
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No catches logged yet — be the first!'));
                }

                final podium = docs.take(3).toList();
                final rows = docs.length > 3 ? docs.sublist(3) : <QueryDocumentSnapshot>[];

                return ListView(
                  children: [
                    const SizedBox(height: 22),
                    _Podium(docs: podium),
                    const SizedBox(height: 8),
                    for (var i = 0; i < rows.length; i++) _BoardRow(rank: i + 4, doc: rows[i]),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, _BoardTab tab) {
    final selected = _tab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = tab),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.ink : AppColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.docs});

  final List<QueryDocumentSnapshot> docs;

  static const _order = [1, 0, 2]; // rank 2, 1, 3 left-to-right, matching design

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final idx in _order)
          if (idx < docs.length) Expanded(child: _podiumColumn(idx, docs[idx].data() as Map<String, dynamic>)),
      ],
    );
  }

  Widget _podiumColumn(int index, Map<String, dynamic> data) {
    final isFirst = index == 0;
    final size = isFirst ? 66.0 : (index == 1 ? 54.0 : 50.0);
    final barHeight = isFirst ? 74.0 : (index == 1 ? 54.0 : 40.0);
    final tint = isFirst ? AppColors.amber : (index == 1 ? const Color(0xFFCBDDD8) : const Color(0xFFDBD6C6));
    final barColor = isFirst ? AppColors.forest : (index == 1 ? AppColors.tierUncommon : const Color(0xFF6A9B8E));
    final name = data['displayName'] as String? ?? 'Angler';
    final points = data['totalPoints'] as int? ?? 0;
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).map((w) => w.isEmpty ? '' : w[0]).take(2).join();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            child: Center(
              child: Text(initials, style: GoogleFonts.instrumentSerif(fontSize: 20, color: AppColors.forest)),
            ),
          ),
          const SizedBox(height: 8),
          Text(name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text('$points', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.amber)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            height: barHeight,
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _BoardRow extends StatelessWidget {
  const _BoardRow({required this.rank, required this.doc});

  final int rank;
  final QueryDocumentSnapshot doc;

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['displayName'] as String? ?? 'Angler';
    final points = data['totalPoints'] as int? ?? 0;
    final catchCount = data['catchCount'] as int? ?? 0;
    final initials =
        name.trim().isEmpty ? '?' : name.trim().split(RegExp(r'\s+')).map((w) => w.isEmpty ? '' : w[0]).take(2).join();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 22, child: Text('$rank', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600))),
          const SizedBox(width: 14),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.paper,
            child: Text(initials, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.forest)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text('$catchCount ${catchCount == 1 ? 'catch' : 'catches'}', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.amber, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('$points', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
