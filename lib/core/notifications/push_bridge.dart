import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../network/api_endpoints.dart';
import '../network/dio_client.dart';
import 'notification_service.dart';

/// Bridges Firebase Cloud Messaging → flutter_local_notifications.
///
/// Call [PushBridge.init] once after the app starts.
/// Call [PushBridge.registerDevice] after every successful login so the FCM
/// token is stored server-side for targeted pushes.
class PushBridge {
  PushBridge._();

  // Notification IDs per category — reusing the same ID replaces the existing
  // notification of that type (e.g. only one "raid result" notification shown).
  static const _idRaid = 10;
  static const _idWarlord = 11;
  static const _idGeneral = 12;

  static Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    // Request permission (iOS; Android 13+ is handled by NotificationService).
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Foreground messages — FCM suppresses system notifications while the app
    // is open, so we display a local notification ourselves.
    FirebaseMessaging.onMessage.listen(_onMessage);

    // Background / terminated → user tapped the system notification.
    // The OS already showed the notification; we just need to navigate.
    FirebaseMessaging.onMessageOpenedApp.listen(_onOpenedApp);

    // Terminated-state tap handled via getInitialMessage.
    final initial = await messaging.getInitialMessage();
    if (initial != null) _onOpenedApp(initial);
  }

  /// Call after login to register the FCM token with your backend.
  /// Fire-and-forget — failures are logged but never surface to the user.
  static Future<void> registerDevice({
    required DioClient dioClient,
    required String userId,
  }) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      await dioClient.dio.post(
        ApiEndpoints.devicesRegister,
        data: {
          'user_id': userId,
          'fcm_token': token,
          'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        },
      );
    } catch (e) {
      debugPrint('[PushBridge] device register failed: $e');
    }
  }

  // ── Handlers ─────────────────────────────────────────────────────

  static void _onMessage(RemoteMessage message) {
    final route = _routeFrom(message);
    final args = _argsFrom(message);
    final title = message.notification?.title ?? 'EatMap';
    final body = message.notification?.body ?? '';

    if (route == null) {
      // No navigation target — show a generic notification that opens home.
      NotificationService.show(
        id: _idGeneral,
        title: title,
        body: body,
        route: '/home',
      );
      return;
    }

    final id = _notifId(message.data['type'] as String?);
    NotificationService.show(
      id: id,
      title: title,
      body: body,
      route: route,
      args: args,
    );
  }

  static void _onOpenedApp(RemoteMessage message) {
    final route = _routeFrom(message);
    if (route == null) return;
    // Router may not be set yet on cold start; short delay lets the app init.
    Future.delayed(const Duration(milliseconds: 500), () {
      NotificationService.navigate(route: route, args: _argsFrom(message));
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────

  /// Extracts a GoRouter route from the FCM data payload.
  ///
  /// Expected FCM data keys (all optional):
  ///   route        → '/place-detail'
  ///   zone_id      → 'ChIJxxx'       (navigates to /place-detail)
  ///   user_id      → 'uuid'          (navigates to /user-profile)
  static String? _routeFrom(RemoteMessage message) {
    final data = message.data;
    if (data.containsKey('route')) return data['route'] as String;
    if (data.containsKey('zone_id')) return '/place-detail';
    if (data.containsKey('user_id')) return '/user-profile';
    return null;
  }

  static Map<String, dynamic>? _argsFrom(RemoteMessage message) {
    final data = message.data;
    if (data.containsKey('zone_id')) {
      return {
        'zoneId': data['zone_id'],
        if (data.containsKey('zone_name')) 'previewName': data['zone_name'],
      };
    }
    if (data.containsKey('user_id')) {
      return {
        'userId': data['user_id'],
        if (data.containsKey('username')) 'previewName': data['username'],
      };
    }
    return null;
  }

  static int _notifId(String? type) {
    return switch (type) {
      'raid_result' => _idRaid,
      'warlord_change' => _idWarlord,
      _ => _idGeneral,
    };
  }
}
