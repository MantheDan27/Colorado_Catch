import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/colorado_catch_theme.dart';

/// First screen shown on launch: full-bleed hero photo with a dark forest
/// gradient (matching the "Colorado Catch, redesigned" onboarding screen),
/// title, tagline, and two calls to action — [onStartFishing] pre-selects
/// account creation on the login screen, [onHaveAccount] pre-selects sign-in.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, required this.onStartFishing, required this.onHaveAccount});

  final VoidCallback onStartFishing;
  final VoidCallback onHaveAccount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/splash.png', fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x8C072520),
                  Color(0x0D072520),
                  Color(0xD1072520),
                  Color(0xFF072520),
                ],
                stops: [0.0, 0.38, 0.78, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 0, 30, 46),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EST. 2026 · CPW ATLAS',
                    style: GoogleFonts.familjenGrotesk(
                      fontSize: 13,
                      letterSpacing: 3.5,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Colorado\nCatch',
                    style: GoogleFonts.instrumentSerif(fontSize: 58, height: 0.95, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Every stocked lake, river and pond in the state. Log what you land, learn what you caught.',
                    style: GoogleFonts.familjenGrotesk(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: onStartFishing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: AppColors.ink,
                      minimumSize: const Size.fromHeight(56),
                    ),
                    child: const Text('Start fishing'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: onHaveAccount,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      minimumSize: const Size.fromHeight(56),
                    ),
                    child: const Text('I already have an account'),
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
