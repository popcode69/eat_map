# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the app
flutter run

# Build release APK
flutter build apk --release

# Analyze for type/lint errors
flutter analyze

# Run all tests
flutter test

# Run a single test file
flutter test test/features/auth/auth_bloc_test.dart

# Fetch dependencies
flutter pub get
```

## Architecture

This is a Flutter frontend for EatMap — a gamified food app where users physically visit restaurants ("raid zones") to capture them and earn rewards.

### Layer Structure (Clean Architecture)

Every feature lives in `lib/features/{feature}/` with three sub-layers:

```
domain/
  entities/          # Pure Dart classes, Equatable, no external deps
  repositories/      # Abstract interfaces only
  usecases/          # Single-call classes wrapping one repository method
data/
  models/            # Extends entity, adds fromJson/toJson
  repositories/      # Implements domain interface, wraps DioClient
presentation/
  bloc/              # Events (sealed), States (sealed), BLoC handler
  screens/
  widgets/
```

### Dependency Injection

Everything is wired in `lib/injection_container.dart` using GetIt (`sl`). Repositories are `registerLazySingleton`, BLoCs are `registerFactory`. The DI container is initialized in `main.dart` before `runApp`.

`MapBloc` is a special case — it receives `ZoneRepositoryImpl` (not the interface) because it calls methods (`getNearbyFoodPlaces`, `mockCaptureZone`) that are outside the `ZoneRepository` interface.

### State Management Pattern

All BLoCs follow this contract:
- `AuthEvent`/`MapEvent`/etc. — `sealed class` with `Equatable`
- `AuthState`/`MapState`/etc. — `sealed class` with `Equatable`
- Use cases return `Either<Failure, T>` (dartz); blocs call `.fold(onFailure, onSuccess)`
- **Critical**: `BlocConsumer.listener` only fires when the new state is not equal to the previous state per Equatable. If a success/failure state shares all the same props as the previous state, the listener silently skips. This has caused bugs (e.g., avatar upload spinner getting stuck) — always ensure state transitions produce a meaningfully different object.

### HTTP Layer

`DioClient` (`lib/core/network/dio_client.dart`) targets `https://dev.gixbot.online/api/v1`. It has three interceptors in order:
1. `ConnectivityInterceptor` — throws `NoInternetException` before making the request if offline
2. `AuthInterceptor` — reads JWT from Supabase session first, falls back to `SecureStorage`
3. `RetryInterceptor` — 2 retries with 1s/2s delays

Token is stored in `SecureStorage` (encrypted shared prefs on Android, Keychain on iOS) under the key `auth_jwt_token`. The sentinel value `'local_mock_token'` means the user is in offline-dev mode — repository implementations check for this and return mock data instead of making API calls.

### Error Handling

Repository impls catch `DioException` and check:
- `connectionError | connectionTimeout | unknown` → return offline fallback (mock data or `Right(unit)`)
- Status 422 → also falls back (hardcoded geohash endpoint returns 422)
- Status 401 → clears token, returns `AuthFailure`
- Other → delegates to `ErrorHandler.handle(e.error ?? e)`

`ErrorHandler` (`lib/core/error/error_handler.dart`) maps exception types to `Failure` subtypes. All `Failure` subtypes are in `lib/core/error/failures.dart`.

### Map & Marker System

`_MapScreenState` (map_screen.dart) owns `Map<String, BitmapDescriptor> _markerIcons`. Markers are generated asynchronously using `dart:ui` `PictureRecorder` + `Canvas` after each `MapLoaded` state arrives in the `BlocConsumer` listener. Until generation completes, `GoogleMap` shows default colored pins as fallback.

Avatar images are loaded via `_loadNetworkImage()` which wraps `NetworkImage` in an `ImageStream` + `Completer`, with a 5-second timeout. **The async image load must complete before `PictureRecorder` starts** — all canvas operations must be synchronous.

The `MapBloc` uses two paths for zone loading:
- No GPS yet → `_getNearbyZones(geohash)` → `GET /zones/nearby?geohash=`
- GPS acquired → `ZoneRepositoryImpl.getNearbyFoodPlaces(lat, lng)` → `GET /zones/nearby?lat=&lng=`

### Auth Flow

1. App start → `AuthCheckRequested` → `GET /auth/me` → `Authenticated(user)` or `Unauthenticated`
2. Google sign-in → `POST /auth/google` → save JWT → `GET /auth/me` → `Authenticated`
3. After GPS acquired in MapScreen → `UpdateLocationRequested(lat, lng)` → `PATCH /auth/me/location` (fire-and-forget, no state change)
4. Avatar upload: POST returns `{avatar_url}` immediately; the returned URL is force-merged into the subsequent `GET /auth/me` response before parsing to guarantee the `Authenticated` state changes (bypasses server propagation lag)

### Navigation

`go_router` is configured in `lib/app.dart`. Routes that need data pass it via `state.extra` (cast explicitly at the route level). The router is a static field on `EatMapApp`.

### Key Non-Obvious Patterns

- `ZoneEntity` is the base class; `ZoneModel extends ZoneEntity` (data layer inherits from domain)
- `ZoneModel.fromJson` uses nullable casts everywhere (`as String?`) with defaults — the API may omit fields
- `RaidBloc` reaches into `di.sl<ZoneRepository>()` after a successful warlord capture to call `mockCaptureZone()` on the impl directly — this mutates the in-memory mock list so the map updates without a network round-trip
- `Supabase` is initialized with placeholder credentials in `main.dart`; actual auth uses the custom backend JWT, not Supabase auth
- Theme is fully custom via `AppColors` (light/dark variants) and `AppTypography`; never use `Theme.of(context).colorScheme` directly — use `AppColors.getPrimary(context)` etc.
