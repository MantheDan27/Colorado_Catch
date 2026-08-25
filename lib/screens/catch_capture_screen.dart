import 'dart:async' show unawaited;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/badges.dart';
import '../data/species_rarity.dart';
import '../models/fish_suggestion.dart';
import '../services/auth_service.dart';
import '../services/catch_service.dart';
import '../services/fish_id_service.dart';
import '../theme/colorado_catch_theme.dart';
import '../utils/points_calculator.dart';
import '../widgets/loading_indicator.dart';
import 'catch_detail_screen.dart';

enum _Stage { pickingPhoto, identifying, reviewing, saving, done }

/// Pushed from the home screen's center camera button: photo -> AI species
/// suggestion (Fishial.AI) -> manual-correction fallback -> log the catch ->
/// a celebration screen. Catch photos aren't persisted for this MVP (Cloud
/// Storage needs a Blaze upgrade — see SETUP.md); the photo is used
/// transiently for AI ID and the review-screen thumbnail only.
class CatchCaptureScreen extends StatefulWidget {
  const CatchCaptureScreen({super.key});

  @override
  State<CatchCaptureScreen> createState() => _CatchCaptureScreenState();
}

class _CatchCaptureScreenState extends State<CatchCaptureScreen> {
  _Stage _stage = _Stage.pickingPhoto;
  File? _photo;
  List<FishSuggestion> _suggestions = [];
  String? _selectedSpecies;
  final _manualSpeciesController = TextEditingController();
  int _length = 12;
  bool _useManualEntry = false;
  bool _released = true;
  String? _error;
  Position? _position;
  CatchLogResult? _result;
  List<CatchBadge> _newBadges = [];

  @override
  void initState() {
    super.initState();
    _pickAndIdentify();
  }

  @override
  void dispose() {
    _manualSpeciesController.dispose();
    super.dispose();
  }

  Future<void> _pickAndIdentify() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
    if (!mounted) return;
    if (picked == null) {
      Navigator.of(context).pop();
      return;
    }

    final file = File(picked.path);
    setState(() {
      _photo = file;
      _stage = _Stage.identifying;
    });
    unawaited(_fetchLocation());

    final fishIdService = Provider.of<FishIdService>(context, listen: false);
    try {
      final suggestions = await fishIdService.identify(file);
      if (!mounted) return;
      setState(() {
        _suggestions = suggestions;
        _useManualEntry = suggestions.isEmpty;
        _selectedSpecies = suggestions.isNotEmpty ? suggestions.first.species : null;
        _stage = _Stage.reviewing;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not identify the species automatically — enter it manually below.';
        _useManualEntry = true;
        _stage = _Stage.reviewing;
      });
    }
  }

  Future<void> _fetchLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _position = position);
    } catch (_) {
      // Best-effort only — a catch can still be logged without a map pin.
    }
  }

  Future<void> _confirm() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final catchService = Provider.of<CatchService>(context, listen: false);
    final user = authService.currentUser;
    if (user == null) return;

    final species = _useManualEntry ? _manualSpeciesController.text.trim() : _selectedSpecies;
    if (species == null || species.isEmpty) {
      setState(() => _error = 'Enter a species name.');
      return;
    }

    setState(() {
      _stage = _Stage.saving;
      _error = null;
    });

    try {
      final matchedSuggestion = _useManualEntry
          ? null
          : _suggestions.firstWhere((s) => s.species == species, orElse: () => FishSuggestion(species: species));

      final result = await catchService.logCatch(
        userId: user.uid,
        userName: user.displayName ?? user.email ?? 'Angler',
        species: species,
        speciesConfidence: matchedSuggestion?.confidence,
        wasManualOverride: _useManualEntry,
        aiSuggestions: _suggestions
            .map((s) => {'species': s.species, 'confidence': s.confidence})
            .toList(growable: false),
        lengthInches: _length.toDouble(),
        released: _released,
        latitude: _position?.latitude,
        longitude: _position?.longitude,
      );

      if (!mounted) return;
      setState(() {
        _result = result;
        _newBadges = newlyUnlockedBadges(
          priorCatchCount: result.priorCatchCount,
          priorHadRareOrBetter: result.priorHadRareOrBetter,
          newCatchTier: result.tier,
        );
        _stage = _Stage.done;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not save the catch: $e';
        _stage = _Stage.reviewing;
      });
    }
  }

  String get _species => _useManualEntry ? _manualSpeciesController.text.trim() : (_selectedSpecies ?? '');

  @override
  Widget build(BuildContext context) {
    return switch (_stage) {
      _Stage.pickingPhoto => const _BrandedLoading(),
      _Stage.identifying => const _IdentifyingView(),
      _Stage.saving => const _BrandedLoading(dark: false),
      _Stage.reviewing => _ReviewView(
          photo: _photo,
          suggestions: _suggestions,
          selectedSpecies: _selectedSpecies,
          useManualEntry: _useManualEntry,
          manualController: _manualSpeciesController,
          length: _length,
          released: _released,
          error: _error,
          onSelectSuggestion: (s) => setState(() {
            _selectedSpecies = s;
            _useManualEntry = false;
          }),
          onToggleManual: (v) => setState(() => _useManualEntry = v),
          onManualChanged: () => setState(() {}),
          onLengthDelta: (d) => setState(() => _length = (_length + d).clamp(1, 60)),
          onReleasedChanged: (v) => setState(() => _released = v),
          onConfirm: _confirm,
          onCancel: () => Navigator.of(context).pop(),
        ),
      _Stage.done => _DoneView(
          result: _result!,
          species: _species,
          length: _length,
          badges: _newBadges,
        ),
    };
  }
}

class _BrandedLoading extends StatelessWidget {
  const _BrandedLoading({this.dark = true});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: dark ? AppColors.forest : AppColors.cream,
      child: const Center(child: LoadingIndicator()),
    );
  }
}

class _IdentifyingView extends StatelessWidget {
  const _IdentifyingView();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.forest,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.amber),
              ),
              const SizedBox(height: 22),
              Text(
                'Identifying species…',
                textAlign: TextAlign.center,
                style: GoogleFonts.instrumentSerif(fontSize: 26, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                'Matching fin shape and spotting against the Fishial reference set.',
                textAlign: TextAlign.center,
                style: GoogleFonts.familjenGrotesk(fontSize: 14, color: Colors.white.withValues(alpha: 0.65)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewView extends StatelessWidget {
  const _ReviewView({
    required this.photo,
    required this.suggestions,
    required this.selectedSpecies,
    required this.useManualEntry,
    required this.manualController,
    required this.length,
    required this.released,
    required this.error,
    required this.onSelectSuggestion,
    required this.onToggleManual,
    required this.onManualChanged,
    required this.onLengthDelta,
    required this.onReleasedChanged,
    required this.onConfirm,
    required this.onCancel,
  });

  final File? photo;
  final List<FishSuggestion> suggestions;
  final String? selectedSpecies;
  final bool useManualEntry;
  final TextEditingController manualController;
  final int length;
  final bool released;
  final String? error;
  final ValueChanged<String> onSelectSuggestion;
  final ValueChanged<bool> onToggleManual;
  final VoidCallback onManualChanged;
  final ValueChanged<int> onLengthDelta;
  final ValueChanged<bool> onReleasedChanged;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final species = useManualEntry ? manualController.text.trim() : selectedSpecies;
    final hasValidSpecies = species != null && species.isNotEmpty;
    final tier = hasValidSpecies ? rarityOf(species) : null;
    final points = hasValidSpecies ? calculateCatchPoints(species: species, lengthInches: length.toDouble()) : 0;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                children: [
                  IconButton(onPressed: onCancel, icon: const Icon(Icons.close)),
                  const SizedBox(width: 6),
                  Text('Confirm your catch', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: photo != null
                              ? Image.file(photo!, width: 76, height: 76, fit: BoxFit.cover)
                              : Container(width: 76, height: 76, color: AppColors.paper),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Best match below. Pick the right one — points depend on species rarity.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    for (final s in suggestions)
                      _SuggestionCard(
                        suggestion: s,
                        selected: !useManualEntry && selectedSpecies == s.species,
                        onTap: () => onSelectSuggestion(s.species),
                      ),
                    InkWell(
                      onTap: () => onToggleManual(true),
                      child: Container(
                        margin: const EdgeInsets.only(top: 4, bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: useManualEntry ? AppColors.forest : AppColors.ink.withValues(alpha: 0.18),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          "None of these — I'll type it",
                          style: GoogleFonts.familjenGrotesk(fontSize: 13.5, color: AppColors.mutedDark),
                        ),
                      ),
                    ),
                    if (useManualEntry)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextField(
                          controller: manualController,
                          decoration: const InputDecoration(labelText: 'Species name'),
                          onChanged: (_) => onManualChanged(),
                        ),
                      ),
                    const SizedBox(height: 22),
                    Text('Length', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _StepperButton(icon: Icons.remove, onTap: () => onLengthDelta(-1)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.ink.withValues(alpha: 0.12)),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text('$length', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 6),
                                  Text('inches', style: TextStyle(fontSize: 14, color: AppColors.muted)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        _StepperButton(icon: Icons.add, onTap: () => onLengthDelta(1)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: released,
                      onChanged: onReleasedChanged,
                      title: const Text('Released'),
                      subtitle: const Text('Catch & release — many rare/native species require this.'),
                      activeThumbColor: AppColors.forest,
                    ),
                    const SizedBox(height: 6),
                    if (hasValidSpecies)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(color: AppColors.forest, borderRadius: BorderRadius.circular(18)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$length in × ×${tier!.pointsMultiplier}',
                                  style: GoogleFonts.familjenGrotesk(fontSize: 12, color: Colors.white70),
                                ),
                                Text(
                                  '$points points',
                                  style: GoogleFonts.instrumentSerif(fontSize: 26, color: Colors.white),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(color: AppColors.amber, borderRadius: BorderRadius.circular(14)),
                              child: Text(
                                tier.label,
                                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (error != null) ...[
                      const SizedBox(height: 16),
                      Text(error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: hasValidSpecies ? onConfirm : null,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: AppColors.ink),
                        child: const Text('Log catch'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion, required this.selected, required this.onTap});

  final FishSuggestion suggestion;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = suggestion.confidence != null ? (suggestion.confidence! * 100).clamp(0, 100) : 0.0;
    final tier = rarityOf(suggestion.species);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? AppColors.forest : AppColors.ink.withValues(alpha: 0.1), width: 1.5),
          borderRadius: BorderRadius.circular(16),
          color: selected ? AppColors.forest.withValues(alpha: 0.06) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.forest : AppColors.ink.withValues(alpha: 0.3),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(suggestion.species, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                      if (suggestion.confidence != null)
                        Text('${pct.toStringAsFixed(0)}%', style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 4,
                      backgroundColor: AppColors.ink.withValues(alpha: 0.08),
                      color: tierColor(tier),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(side: BorderSide(color: Color(0x24101A17))),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 46, height: 46, child: Icon(icon, color: AppColors.ink)),
      ),
    );
  }
}

class _DoneView extends StatelessWidget {
  const _DoneView({required this.result, required this.species, required this.length, required this.badges});

  final CatchLogResult result;
  final String species;
  final int length;
  final List<CatchBadge> badges;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.forest,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'CATCH LOGGED',
                style: GoogleFonts.familjenGrotesk(fontSize: 12, letterSpacing: 3.5, color: Colors.white60),
              ),
              const SizedBox(height: 14),
              Text('+${result.points}', style: GoogleFonts.instrumentSerif(fontSize: 54, color: AppColors.amber)),
              const SizedBox(height: 8),
              Text('$species, $length in', style: GoogleFonts.instrumentSerif(fontSize: 30, color: Colors.white)),
              const SizedBox(height: 12),
              Text(
                'Added to your log and pinned to the map.',
                style: GoogleFonts.familjenGrotesk(fontSize: 14.5, height: 1.5, color: Colors.white70),
              ),
              for (final badge in badges) ...[
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(color: AppColors.amber, borderRadius: BorderRadius.circular(16)),
                        child: Center(
                          child: Text(badge.glyph, style: GoogleFonts.instrumentSerif(fontSize: 20, color: AppColors.ink)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Badge unlocked — ${badge.name}',
                                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => CatchDetailScreen(catchId: result.catchId)),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: AppColors.ink),
                child: const Text('See the catch'),
              ),
              const SizedBox(height: 11),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop('toMap'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: const Text('Back to the map'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
