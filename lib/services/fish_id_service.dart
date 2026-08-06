import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/fish_suggestion.dart';

/// Wraps the Fishial.AI species-identification API.
///
/// CONFIRMED against the live API during implementation (2026-08):
///  - `https://api.fishial.ai/v1/recognition/image` is real and JSON:API
///    shaped; it takes the photo reference as a query param `q`
///    (`GET /v1/recognition/image?q=<value>`), returning a 422
///    "Invalid signature" error for an arbitrary value — `q` must be a
///    signed identifier for an image Fishial already has, not a random URL.
///
/// NOT independently confirmed (Fishial's docs site was unreachable from
/// this environment) — the auth + upload steps below follow Fishial's
/// publicly documented flow (OAuth2 client-credentials token, then a signed
/// upload slot, then recognition against the resulting signed id). Verify
/// this against the real dashboard/docs at portal.fishial.ai once you have
/// an account — endpoint paths or field names may need small corrections.
class FishIdService {
  FishIdService({required this.clientId, required this.clientSecret, http.Client? client})
      : _client = client ?? http.Client();

  final String clientId;
  final String clientSecret;
  final http.Client _client;

  static final _base = Uri.parse('https://api.fishial.ai/v1');

  String? _accessToken;

  Future<String> _ensureAccessToken() async {
    final token = _accessToken;
    if (token != null) return token;

    final response = await _client.post(
      _base.resolve('auth/token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'client_id': clientId, 'client_secret': clientSecret}),
    );
    if (response.statusCode != 200) {
      throw FishIdException('Fishial auth failed (${response.statusCode}): ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final accessToken = data['access_token'] as String?;
    if (accessToken == null) {
      throw FishIdException('Fishial auth response missing access_token');
    }
    _accessToken = accessToken;
    return accessToken;
  }

  /// Uploads [imageFile] and returns the AI's ranked species suggestions
  /// (highest confidence first). Throws [FishIdException] on any failure —
  /// callers should catch this and fall back to manual species entry.
  Future<List<FishSuggestion>> identify(File imageFile) async {
    final token = await _ensureAccessToken();
    final authHeader = {'Authorization': 'Bearer $token'};

    final uploadSlotResponse = await _client.get(
      _base.resolve('recognition/upload'),
      headers: authHeader,
    );
    if (uploadSlotResponse.statusCode != 200) {
      throw FishIdException(
          'Fishial upload-slot request failed (${uploadSlotResponse.statusCode}): ${uploadSlotResponse.body}');
    }
    final uploadSlot =
        (jsonDecode(uploadSlotResponse.body) as Map<String, dynamic>)['data']['attributes'] as Map<String, dynamic>;
    final uploadUrl = uploadSlot['url'] as String;
    final signedImageId = uploadSlot['q'] as String;

    final putResponse = await _client.put(Uri.parse(uploadUrl), body: await imageFile.readAsBytes());
    if (putResponse.statusCode >= 300) {
      throw FishIdException('Fishial image upload failed (${putResponse.statusCode})');
    }

    final recognitionResponse = await _client.get(
      _base.resolve('recognition/image').replace(queryParameters: {'q': signedImageId}),
      headers: authHeader,
    );
    if (recognitionResponse.statusCode != 200) {
      throw FishIdException(
          'Fishial recognition failed (${recognitionResponse.statusCode}): ${recognitionResponse.body}');
    }

    final body = jsonDecode(recognitionResponse.body) as Map<String, dynamic>;
    final results = (body['data'] as List<dynamic>? ?? []);
    final suggestions = <FishSuggestion>[];
    for (final result in results) {
      final attrs = (result as Map<String, dynamic>)['attributes'] as Map<String, dynamic>? ?? {};
      final species = attrs['species'] as String? ?? attrs['name'] as String?;
      final confidence = (attrs['confidence'] as num?)?.toDouble();
      if (species != null) {
        suggestions.add(FishSuggestion(species: species, confidence: confidence));
      }
    }
    suggestions.sort((a, b) => (b.confidence ?? 0).compareTo(a.confidence ?? 0));
    return suggestions;
  }
}

class FishIdException implements Exception {
  FishIdException(this.message);
  final String message;

  @override
  String toString() => 'FishIdException: $message';
}
