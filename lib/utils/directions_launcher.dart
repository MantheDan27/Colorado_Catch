import 'package:url_launcher/url_launcher.dart';

/// Hands off routing to the device's own maps app instead of building
/// turn-by-turn navigation into this app — keeps the in-app map focused on
/// discovery (labeled locations, bite windows) while still getting anglers
/// an actual route. Uses Google's "Universal Maps URL": a plain https link
/// that opens the Google Maps app if installed, or a maps web page
/// otherwise, on both Android and iOS — no platform-specific URL schemes.
Future<bool> launchDirections({required double latitude, required double longitude}) {
  final uri = Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': '$latitude,$longitude',
  });
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
