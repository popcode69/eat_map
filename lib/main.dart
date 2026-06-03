import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Dependency Injection Container
  await di.init();

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
