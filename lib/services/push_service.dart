import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Must be a top-level (or static) function: FCM invokes it in a separate
/// isolate when a data/notification message arrives while the app is
/// terminated or backgrounded. Registered in main() before runApp().
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase.initializeApp() must be called here too, since this runs in
  // its own isolate — see main.dart. Keep this handler lightweight (e.g.
  // local persistence); heavy work should be deferred to foreground.
  debugPrint('Handling a background message: ${message.messageId}');
}

class PushService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _messaging.setAutoInitEnabled(true);

    FirebaseMessaging.onMessage.listen((message) {
      // TODO: surface foreground notifications, e.g. via flutter_local_notifications.
      debugPrint('Foreground message received: ${message.messageId}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      // TODO: deep-link into the relevant screen (e.g. a chat room) here.
      debugPrint('Notification tapped: ${message.messageId}');
    });
  }

  Future<String?> getDeviceToken() {
    return _messaging.getToken();
  }
}
