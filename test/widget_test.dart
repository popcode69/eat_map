import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/app.dart';
import 'package:client/injection_container.dart' as di;
import 'package:client/features/auth/presentation/screens/splash_screen.dart';
import 'package:client/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    // Initialize dependency locator singletons for the test environment
    await di.init();
  });

  testWidgets('EatMap authentication screen render smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EatMapApp());
    await tester.pump();

    // Verify that the splash screen title and brand text are rendered initially.
    expect(find.text('EatMap'), findsOneWidget);
    expect(find.text('CONQUER ZONES · CLAIM BOUNTIES'), findsOneWidget);

    // Let the 2-second minimum duration run and trigger the navigation
    await tester.pump(const Duration(seconds: 2));
    
    // Advance virtual time to complete the transition animation (300ms transition duration + buffer)
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // Verify that the login screen title and brand text are rendered after transition.
    expect(find.text('Raider Authentication'), findsOneWidget);
    expect(find.text('OR SECURELY ACCESS VIA'), findsOneWidget);
  });
}
