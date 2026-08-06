/// One species candidate returned by FishIdService.identify(), or a
/// wasManualOverride==true entry the angler typed in themselves. Plain class,
/// no codegen — matches UserProfile's convention.
class FishSuggestion {
  const FishSuggestion({required this.species, this.confidence});

  final String species;

  /// 0.0-1.0 confidence from the Fishial API; null for a manual entry.
  final double? confidence;
}
