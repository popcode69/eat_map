import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/cache/secure_storage.dart';
import '../../domain/usecases/start_raid.dart';
import '../../domain/usecases/verify_raid.dart';
import '../../../../injection_container.dart' as di;
import '../../../zone/data/repositories/zone_repository_impl.dart';
import '../../../zone/domain/repositories/zone_repository.dart';

// ==========================================
// 1. RAID EVENTS
// ==========================================
sealed class RaidEvent extends Equatable {
  const RaidEvent();

  @override
  List<Object?> get props => [];
}

final class RaidStartRequested extends RaidEvent {
  final String zoneId;
  final String zoneName;
  final String colour;
  final double lat;
  final double lng;
  final String deviceId;
  final String userId;
  final String username;

  const RaidStartRequested({
    required this.zoneId,
    required this.zoneName,
    required this.colour,
    required this.lat,
    required this.lng,
    required this.deviceId,
    required this.userId,
    required this.username,
  });

  @override
  List<Object?> get props => [zoneId, zoneName, colour, lat, lng, deviceId, userId, username];
}

/// Restores a previously persisted raid after the app was killed.
/// Dispatched from [MapScreen] when an active raid is found in storage.
final class RaidResumeRequested extends RaidEvent {
  final String raidId;
  final String zoneId;
  final int secondsRemaining;
  final int totalSeconds;

  const RaidResumeRequested({
    required this.raidId,
    required this.zoneId,
    required this.secondsRemaining,
    required this.totalSeconds,
  });

  @override
  List<Object?> get props => [raidId, zoneId, secondsRemaining, totalSeconds];
}

final class RaidVerificationSubmitted extends RaidEvent {
  final String raidId;

  /// Optional presence photo. Verification is presence-time only now — there
  /// is no bill/spend/UPI input.
  final String? photoPath;

  const RaidVerificationSubmitted({
    required this.raidId,
    this.photoPath,
  });

  @override
  List<Object?> get props => [raidId, photoPath];
}

final class RaidTimerTicked extends RaidEvent {
  final int secondsRemaining;

  const RaidTimerTicked(this.secondsRemaining);

  @override
  List<Object?> get props => [secondsRemaining];
}

// ==========================================
// 2. RAID STATES
// ==========================================
sealed class RaidState extends Equatable {
  const RaidState();

  @override
  List<Object?> get props => [];
}

final class RaidInitial extends RaidState {}

final class RaidLoading extends RaidState {}

final class RaidTimerActive extends RaidState {
  final String raidId;
  final String zoneId;
  final int secondsRemaining;
  final int totalSeconds;

  const RaidTimerActive({
    required this.raidId,
    required this.zoneId,
    required this.secondsRemaining,
    required this.totalSeconds,
  });

  @override
  List<Object?> get props => [raidId, zoneId, secondsRemaining, totalSeconds];
}

final class RaidVerifying extends RaidState {}

final class RaidSuccess extends RaidState {
  /// Flat points awarded: 100 (first capture) or 50 (raid on captured zone).
  final double points;

  /// Visit rank — informational only, no longer affects points. May be null.
  final int? rank;

  /// True if this raid made the user the zone's Warlord.
  final bool isWarlord;

  /// Optional server-supplied message.
  final String? message;

  const RaidSuccess({
    required this.points,
    this.rank,
    required this.isWarlord,
    this.message,
  });

  @override
  List<Object?> get props => [points, rank, isWarlord, message];
}

/// Timer reached zero naturally — the user stayed the required time.
/// The screen should navigate to bill verification.
final class RaidTimerCompleted extends RaidState {
  final String raidId;
  final String zoneId;

  const RaidTimerCompleted({required this.raidId, required this.zoneId});

  @override
  List<Object?> get props => [raidId, zoneId];
}

final class RaidFailure extends RaidState {
  final String message;

  const RaidFailure(this.message);

  @override
  List<Object?> get props => [message];
}

// ==========================================
// 3. RAID BLOC
// ==========================================
class RaidBloc extends Bloc<RaidEvent, RaidState> {
  final StartRaid _startRaid;
  final VerifyRaid _verifyRaid;
  final SecureStorage _secureStorage;
  StreamSubscription<int>? _timerSubscription;
  String? _currentUserId;
  String? _currentUsername;

  RaidBloc({
    required StartRaid startRaid,
    required VerifyRaid verifyRaid,
    required SecureStorage secureStorage,
  })  : _startRaid = startRaid,
        _verifyRaid = verifyRaid,
        _secureStorage = secureStorage,
        super(RaidInitial()) {
    on<RaidStartRequested>(_onStartRequested);
    on<RaidResumeRequested>(_onResumeRequested);
    on<RaidVerificationSubmitted>(_onVerificationSubmitted);
    on<RaidTimerTicked>(_onTimerTicked);
  }

  Future<void> _onStartRequested(
    RaidStartRequested event,
    Emitter<RaidState> emit,
  ) async {
    emit(RaidLoading());
    _timerSubscription?.cancel();
    // Store real identity for use when raid is verified
    _currentUserId = event.userId;
    _currentUsername = event.username;

    final result = await _startRaid(
      zoneId: event.zoneId,
      lat: event.lat,
      lng: event.lng,
      deviceId: event.deviceId,
    );

    await result.fold<Future<void>>(
      (failure) async => emit(RaidFailure(failure.message)),
      (raid) async {
        // Persist raid so it survives app kills
        await _secureStorage.saveActiveRaid({
          'raidId': raid.id,
          'zoneId': raid.zoneId,
          'zoneName': event.zoneName,
          'colour': event.colour,
          'startedAt': raid.startedAt.toIso8601String(),
          'durationMins': raid.durationMins,
          'status': 'running',
        });

        final targetEndTime =
            raid.startedAt.add(Duration(minutes: raid.durationMins));
        final totalSeconds = raid.durationMins * 60;
        final initialSecondsRemaining =
            targetEndTime.difference(DateTime.now()).inSeconds;

        emit(RaidTimerActive(
          raidId: raid.id,
          zoneId: raid.zoneId,
          secondsRemaining: initialSecondsRemaining > 0 ? initialSecondsRemaining : 0,
          totalSeconds: totalSeconds,
        ));

        _timerSubscription = Stream.periodic(
          const Duration(seconds: 1),
          (_) {
            final difference = targetEndTime.difference(DateTime.now()).inSeconds;
            return difference > 0 ? difference : 0;
          },
        ).listen((seconds) => add(RaidTimerTicked(seconds)));
      },
    );
  }

  Future<void> _onResumeRequested(
    RaidResumeRequested event,
    Emitter<RaidState> emit,
  ) async {
    _timerSubscription?.cancel();

    emit(RaidTimerActive(
      raidId: event.raidId,
      zoneId: event.zoneId,
      secondsRemaining: event.secondsRemaining,
      totalSeconds: event.totalSeconds,
    ));

    final targetEndTime =
        DateTime.now().add(Duration(seconds: event.secondsRemaining));

    _timerSubscription = Stream.periodic(
      const Duration(seconds: 1),
      (_) {
        final difference = targetEndTime.difference(DateTime.now()).inSeconds;
        return difference > 0 ? difference : 0;
      },
    ).listen((seconds) => add(RaidTimerTicked(seconds)));
  }

  Future<void> _onTimerTicked(
    RaidTimerTicked event,
    Emitter<RaidState> emit,
  ) async {
    if (state is RaidTimerActive) {
      final current = state as RaidTimerActive;
      if (event.secondsRemaining <= 0) {
        _timerSubscription?.cancel();
        // Update persisted status so the bill-upload screen can be resumed
        // if the user closes the app between timer completion and verification.
        final saved = await _secureStorage.getActiveRaid();
        if (saved != null) {
          saved['status'] = 'awaiting_verification';
          await _secureStorage.saveActiveRaid(saved);
        }
        emit(RaidTimerCompleted(raidId: current.raidId, zoneId: current.zoneId));
      } else {
        emit(RaidTimerActive(
          raidId: current.raidId,
          zoneId: current.zoneId,
          secondsRemaining: event.secondsRemaining,
          totalSeconds: current.totalSeconds,
        ));
      }
    }
  }

  Future<void> _onVerificationSubmitted(
    RaidVerificationSubmitted event,
    Emitter<RaidState> emit,
  ) async {
    // zoneId is needed to update the local mock after a successful capture.
    // It lives in both the active and completed timer states.
    String? zoneId;
    if (state is RaidTimerActive) {
      zoneId = (state as RaidTimerActive).zoneId;
    } else if (state is RaidTimerCompleted) {
      zoneId = (state as RaidTimerCompleted).zoneId;
    }

    _timerSubscription?.cancel();
    emit(RaidVerifying());

    final result = await _verifyRaid(
      raidId: event.raidId,
      photoPath: event.photoPath,
    );

    // Clear persisted raid regardless of outcome — the user has attempted
    // verification so there's no need to resume this raid again.
    await _secureStorage.clearActiveRaid();

    result.fold(
      (failure) => emit(RaidFailure(failure.message)),
      (data) {
        final isWarlord = data['is_warlord'] as bool? ?? false;
        if (isWarlord && zoneId != null) {
          final zoneRepo = di.sl<ZoneRepository>();
          if (zoneRepo is ZoneRepositoryImpl) {
            zoneRepo.mockCaptureZone(
              zoneId,
              _currentUserId ?? 'unknown_user',
              _currentUsername ?? 'Raider',
            );
          }
        }
        // Flat points model: prefer `points_earned`, fall back to legacy
        // `points`. Rank is informational only and may be absent.
        final points =
            (data['points_earned'] ?? data['points']) as num? ?? 0;
        final rank = (data['rank_at_zone'] ?? data['rank']) as num?;
        emit(RaidSuccess(
          points: points.toDouble(),
          rank: rank?.toInt(),
          isWarlord: isWarlord,
          message: data['message'] as String?,
        ));
      },
    );
  }

  @override
  Future<void> close() {
    _timerSubscription?.cancel();
    return super.close();
  }
}
