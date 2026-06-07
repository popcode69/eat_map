import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/push_bridge.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase must be initialized first — FirebaseMessaging.instance throws
  // [core/no-app] if called before this.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  // Initialize Dependency Injection Container
  await di.init();

  // Initialize local notification plugin and request permissions.
  // Router is wired in EatMapApp.build so navigation is available post-launch.
  await NotificationService.init();

  // Wire FCM foreground/background handlers → local notifications.
  // Safe to call now that Firebase is initialized.
  await PushBridge.init();

  // Initialize Supabase Client with placeholder credentials for safe compilation
  try {
    await Supabase.initialize(
      url: 'https://placeholder-project.supabase.co',
      anonKey: 'placeholder-anon-key-string-for-compilation-safety-12345',
    );
  } catch (e) {
    debugPrint('Supabase Initialization skipped or failed: $e');
  }

  runApp(const EatMapApp());
}
