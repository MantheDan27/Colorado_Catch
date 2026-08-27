import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/bite_tips.dart';
import '../data/species_rarity.dart';
import '../models/bite_window.dart';
import '../theme/colorado_catch_theme.dart';
import '../utils/directions_launcher.dart';
import '../utils/geojson_parser.dart';
import 'catch_capture_screen.dart';

/// Full-screen "Spot" detail, replacing the old bottom-sheet treatment —
/// matches the "Colorado Catch, redesigned" design's isSpot screen. Shown
/// when a fishing-water marker is tapped on the map. All content is real:
/// species/tips from bite_tips.dart, bite windows computed for this exact
/// location, Directions via directions_launcher.dart. The design's
/// Stocked/Access/Regs stats aren't in the CPW fields this app bakes, so
/// this screen shows what's actually known instead (water category, dawn/
/// dusk bite windows) rather than inventing values.
class SpotScreen extends StatelessWidget {
  const SpotScreen({super.key, required this.details});

  final FishingLocationDetails details;

  @override
  Widget build(BuildContext context) {
    final windows = calculateBiteWindows(latitude: details.latitude, longitude: details.longitude);
    final category = categorizeStocked(details.stocked);
    final tips = tipsFor(category: category, locType: details.locType);
    final waterLabel = switch (category) {
      WaterCategory.coldwater => 'Trout water',
      WaterCategory.warmwater => 'Warmwater',
      WaterCategory.mixed => 'Mixed water',
      WaterCategory.general => 'Wild / unstocked',
    };

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          _SpotHero(details: details),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (details.subtitle ?? '').toUpperCase(),
                    style: GoogleFonts.familjenGrotesk(fontSize: 11, letterSpacing: 2, color: AppColors.muted),
                  ),
                  const SizedBox(height: 8),
                  Text(details.name, style: GoogleFonts.instrumentSerif(fontSize: 34, height: 1.05, color: AppColors.ink)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final species in tips.likelySpecies)
                        _SpeciesChip(species: species),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _StatCard(label: 'Water', value: waterLabel)),
                      const SizedBox(width: 1),
                      Expanded(child: _StatCard(label: 'Dawn Bite', value: '${formatTimeOfDay(windows[0].start)}–${formatTimeOfDay(windows[0].end)}')),
                      const SizedBox(width: 1),
                      Expanded(child: _StatCard(label: 'Dusk Bite', value: '${formatTimeOfDay(windows[1].start)}–${formatTimeOfDay(windows[1].end)}')),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('Dawn: ${tips.dawnTip}', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 10),
                  Text('Dusk: ${tips.duskTip}', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CatchCaptureScreen()),
                      ),
                      child: const Text('Log a catch here'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotHero extends StatelessWidget {
  const _SpotHero({required this.details});

  final FishingLocationDetails details;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 212,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Photo isn't persisted anywhere yet (Storage still needs the
          // Blaze upgrade — see SETUP.md) — same honest placeholder
          // treatment as ProfileScreen's stubbed upload button.
          Container(color: AppColors.forest),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66072520), Color(0x0D072520), Color(0x99072520)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _HeroCircleButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  _HeroCircleButton(
                    icon: Icons.directions,
                    onTap: () => launchDirections(latitude: details.latitude, longitude: details.longitude),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCircleButton extends StatelessWidget {
  const _HeroCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 38, height: 38, child: Icon(icon, size: 18, color: AppColors.ink)),
      ),
    );
  }
}

class _SpeciesChip extends StatelessWidget {
  const _SpeciesChip({required this.species});

  final String species;

  @override
  Widget build(BuildContext context) {
    final tier = rarityOf(species);
    final color = tierColor(tier);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
      child: Text(
        '$species · ×${tier.pointsMultiplier}',
        style: GoogleFonts.familjenGrotesk(fontSize: 12.5, fontWeight: FontWeight.w500, color: color),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.familjenGrotesk(fontSize: 11.5, color: AppColors.muted)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.familjenGrotesk(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}
