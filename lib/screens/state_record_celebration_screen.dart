import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/state_records.dart';
import '../theme/colorado_catch_theme.dart';
import '../utils/record_checker.dart';

/// Full-screen interstitial pushed on top of CatchCaptureScreen's Done view
/// when a logged catch meets or beats a CPW state record (see
/// checkForStateRecord in lib/utils/record_checker.dart). Only fires for
/// species we have a verified record for — see state_records.dart for the
/// scope and honesty caveats on that dataset.
///
/// Beating the app's numbers isn't the same as an official record — CPW
/// still requires its own certified weigh-in or measurement — so this screen
/// hands the angler straight to the real application forms rather than
/// implying the catch is already on the books.
class StateRecordCelebrationScreen extends StatelessWidget {
  const StateRecordCelebrationScreen({
    super.key,
    required this.achievement,
    required this.species,
    required this.lengthInches,
    this.weightLbs,
  });

  final RecordAchievement achievement;
  final String species;
  final double lengthInches;
  final double? weightLbs;

  @override
  Widget build(BuildContext context) {
    final categories = achievement.categories;
    final subtitle = switch ((categories.contains(RecordCategory.length), categories.contains(RecordCategory.weight))) {
      (true, true) => 'New length AND weight record',
      (true, false) => 'New length record',
      (false, true) => 'New weight record',
      (false, false) => 'New record', // unreachable — categories is never empty here
    };

    return Scaffold(
      backgroundColor: AppColors.amber,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 36),
                  Text(
                    'COLORADO STATE RECORD',
                    style: GoogleFonts.familjenGrotesk(
                      fontSize: 12,
                      letterSpacing: 3.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(species, style: GoogleFonts.instrumentSerif(fontSize: 46, color: AppColors.forest, height: 1.02)),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: GoogleFonts.familjenGrotesk(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink),
                  ),
                  const SizedBox(height: 26),
                  if (categories.contains(RecordCategory.length) && achievement.record.byLength != null)
                    _RecordCard(
                      label: 'LENGTH RECORD',
                      yourValue: '${lengthInches.round()} in',
                      entry: achievement.record.byLength!,
                      applyUrl: byLengthApplicationUrl,
                      applyLabel: 'Apply — by length record',
                    ),
                  if (categories.contains(RecordCategory.weight) && achievement.record.byWeight != null) ...[
                    const SizedBox(height: 16),
                    _RecordCard(
                      label: 'WEIGHT RECORD',
                      yourValue: '${weightLbs!.toStringAsFixed(2)} lbs',
                      entry: achievement.record.byWeight!,
                      applyUrl: byWeightApplicationUrl,
                      applyLabel: 'Apply — by weight record',
                    ),
                  ],
                  const SizedBox(height: 22),
                  Text(
                    'By-length records require releasing the fish, measured on a qualifying device. '
                    'By-weight records require a certified-scale weigh-in before release — the two processes '
                    "can conflict, so decide which one you're chasing before you let it go.",
                    style: GoogleFonts.familjenGrotesk(fontSize: 12.5, height: 1.5, color: AppColors.ink.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 22),
                  TextButton(
                    onPressed: () => _launch(stateRecordsSourceUrl),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: AppColors.forest),
                    child: const Text('Full rules & the official record book →'),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(foregroundColor: AppColors.ink.withValues(alpha: 0.6)),
                      child: const Text('Not now'),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 12,
              child: Material(
                color: Colors.white.withValues(alpha: 0.5),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: const SizedBox(width: 38, height: 38, child: Icon(Icons.close, size: 18, color: AppColors.ink)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launch(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.label,
    required this.yourValue,
    required this.entry,
    required this.applyUrl,
    required this.applyLabel,
  });

  final String label;
  final String yourValue;
  final RecordEntry entry;
  final String applyUrl;
  final String applyLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(color: AppColors.forest, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.familjenGrotesk(fontSize: 11, letterSpacing: 2, color: Colors.white60)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Your catch', style: GoogleFonts.familjenGrotesk(fontSize: 12, color: Colors.white70)),
              const SizedBox(width: 8),
              Text(yourValue, style: GoogleFonts.instrumentSerif(fontSize: 28, color: AppColors.amber)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Previous best: ${entry.displayValue} — ${entry.angler}, ${entry.location} (${entry.year})',
            style: GoogleFonts.familjenGrotesk(fontSize: 12.5, color: Colors.white70),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => launchUrl(Uri.parse(applyUrl), mode: LaunchMode.externalApplication),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: AppColors.ink),
              child: Text(applyLabel),
            ),
          ),
        ],
      ),
    );
  }
}
