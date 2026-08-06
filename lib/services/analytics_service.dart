import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService(this._analytics);

  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> logEvent(String name, Map<String, Object> parameters) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }
}
