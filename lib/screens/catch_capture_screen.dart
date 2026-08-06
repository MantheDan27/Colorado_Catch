import 'dart:async' show unawaited;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/fish_suggestion.dart';
import '../services/auth_service.dart';
import '../services/catch_service.dart';
import '../services/fish_id_service.dart';
import '../utils/points_calculator.dart';
import '../widgets/loading_indicator.dart';

enum _Stage { pickingPhoto, identifying, reviewing, saving }

/// Pushed from the home screen's center camera button: photo -> AI species
/// suggestion (Fishial.AI) -> manual-correction fallback -> log the catch.
/// Catch photos aren't persisted for this MVP (Cloud Storage needs a Blaze
/// upgrade — see SETUP.md); the photo is used transiently for AI ID only.
class CatchCaptureScreen extends StatefulWidget {
  const CatchCaptureScreen({super.key});

  @override
  State<CatchCaptureScreen> createState() => _CatchCaptureScreenState();
}

class _CatchCaptureScreenState extends State<CatchCaptureScreen> {
  _Stage _stage = _Stage.pickingPhoto;
  List<FishSuggestion> _suggestions = [];
  String? _selectedSpecies;
  final _manualSpeciesController = TextEditingController();
  final _lengthController = TextEditingController();
  bool _useManualEntry = false;
  String? _error;
  Position? _position;

  @override
  void initState() {
    super.initState();
    _pickAndIdentify();
  }

  @override
  void dispose() {
    _manualSpeciesController.dispose();
    _lengthController.dispose();
    super.dispose();
  }

  Future<void> _pickAndIdentify() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
    if (!mounted) return;
    if (picked == null) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _stage = _Stage.identifying);
    unawaited(_fetchLocation());

    final fishIdService = Provider.of<FishIdService>(context, listen: false);
    try {
      final suggestions = await fishIdService.identify(File(picked.path));
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

    final lengthInches = double.tryParse(_lengthController.text.trim());
    if (lengthInches == null || lengthInches <= 0) {
      setState(() => _error = 'Enter the fish\'s length in inches.');
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

      await catchService.logCatch(
        userId: user.uid,
        userName: user.displayName ?? user.email ?? 'Angler',
        species: species,
        speciesConfidence: matchedSuggestion?.confidence,
        wasManualOverride: _useManualEntry,
        aiSuggestions: _suggestions
            .map((s) => {'species': s.species, 'confidence': s.confidence})
            .toList(growable: false),
        lengthInches: lengthInches,
        latitude: _position?.latitude,
        longitude: _position?.longitude,
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not save the catch: $e';
        _stage = _Stage.reviewing;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log a Catch')),
      body: switch (_stage) {
        _Stage.pickingPhoto => const LoadingIndicator(),
        _Stage.identifying => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LoadingIndicator(),
                  SizedBox(height: 16),
                  Text('Identifying species…'),
                ],
              ),
            ),
          ),
        _Stage.saving => const LoadingIndicator(),
        _Stage.reviewing => _buildReview(),
      },
    );
  }

  Widget _buildReview() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_suggestions.isNotEmpty) ...[
          const Text('AI species suggestions', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final suggestion in _suggestions)
            RadioListTile<String>(
              value: suggestion.species,
              // ignore: deprecated_member_use
              groupValue: _useManualEntry ? null : _selectedSpecies,
              title: Text(suggestion.species),
              subtitle: suggestion.confidence != null
                  ? Text('${(suggestion.confidence! * 100).toStringAsFixed(0)}% confidence')
                  : null,
              // ignore: deprecated_member_use
              onChanged: (value) => setState(() {
                _selectedSpecies = value;
                _useManualEntry = false;
              }),
            ),
          const SizedBox(height: 8),
        ],
        CheckboxListTile(
          value: _useManualEntry,
          title: const Text("None of these — I'll enter it myself"),
          onChanged: (value) => setState(() => _useManualEntry = value ?? false),
        ),
        if (_useManualEntry)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _manualSpeciesController,
              decoration: const InputDecoration(labelText: 'Species name'),
              onChanged: (_) => setState(() {}),
            ),
          ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _lengthController,
            decoration: const InputDecoration(labelText: 'Length (inches)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 8),
        _buildPointsPreview(),
        const SizedBox(height: 16),
        if (_error != null) ...[
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
        ],
        ElevatedButton(onPressed: _confirm, child: const Text('Log Catch')),
      ],
    );
  }

  Widget _buildPointsPreview() {
    final species = _useManualEntry ? _manualSpeciesController.text.trim() : _selectedSpecies;
    final lengthInches = double.tryParse(_lengthController.text.trim());
    if (species == null || species.isEmpty || lengthInches == null || lengthInches <= 0) {
      return const SizedBox.shrink();
    }

    final points = calculateCatchPoints(species: species, lengthInches: lengthInches);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.monetization_on, color: Colors.amber),
          const SizedBox(width: 8),
          Text('Worth $points points', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
