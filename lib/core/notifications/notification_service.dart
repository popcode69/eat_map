import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

/// Handles local notification display and tap-to-navigate.
///
/// Usage:
///   1. Call [NotificationService.init] once in main().
///   2. Call [NotificationService.setRouter] with the app's GoRouter.
///   3. Call [NotificationService.show] anywhere to display a notification.
///
/// Payload schema (JSON):
///   { "route": "/place-detail", "args": { "key": "value" } }
///
/// On tap the service calls router.push(route, extra: args).
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static GoRouter? _router;

  static const _channelId = 'eatmap_main';
  static const _channelName = 'EatMap Notifications';
  static const _channelDesc = 'Raid results, warlord captures, and rewards';
  static const _accentColor = Color(0xFFE53935);

  /// Call this once — before [show] — passing the app-level GoRouter so
  /// notification taps can push any route.
  static void setRouter(GoRouter router) => _router = router;

  /// Initialize the plugin, request permissions on Android 13+, and handle
  /// the notification that cold-started the app (if any).
  static Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onForegroundTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundTap,
    );

    // Android 13+ needs the POST_NOTIFICATIONS runtime permission.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // If the app was launched by tapping a notification, navigate now.
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final payload = launchDetails?.notificationResponse?.payload;
      if (payload != null) _navigate(payload);
    }
  }

  /// Show a local notification.
  ///
  /// [id] — unique per notification type; reuse the same id to replace.
  /// [route] — GoRouter path navigated on tap (e.g. '/place-detail').
  /// [args] — passed as `state.extra` to the destination route.
  static Future<void> show({
    required int id,
    required String title,
    required String body,
    required String route,
    Map<String, dynamic>? args,
  }) async {
    final payload =
        jsonEncode({'route': route, if (args != null) 'args': args});

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      color: _accentColor,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  // ── Tap handlers ───────────────────────────────────────────────

  static void _onForegroundTap(NotificationResponse response) {
    if (response.payload != null) _navigate(response.payload!);
  }

  /// Top-level-compatible static method required by the plugin for background
  /// notification responses (app alive but in background).
  @pragma('vm:entry-point')
  static void _onBackgroundTap(NotificationResponse response) {
    if (response.payload != null) _navigate(response.payload!);
  }

  /// Navigate directly to [route] — called by [PushBridge] for FCM taps where
  /// the payload is already decoded (no JSON wrapping needed).
  static void navigate({required String route, Map<String, dynamic>? args}) {
    _router?.push(route, extra: args);
  }

  static void _navigate(String payload) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final route = data['route'] as String?;
      final args = data['args'] as Map<String, dynamic>?;
      if (route == null || _router == null) return;
      _router!.push(route, extra: args);
    } catch (_) {
      // Malformed payload — silently ignore.
    }
  }
}
