import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  final double lat;
  final double lng;
  final String deviceId;
  final String userId;
  final String username;

  const RaidStartRequested({
    required this.zoneId,
    required this.lat,
    required this.lng,
    required this.deviceId,
    required this.userId,
    required this.username,
  });

  @override
  List<Object?> get props => [zoneId, lat, lng, deviceId, userId, username];
}

final class RaidVerificationSubmitted extends RaidEvent {
  final String raidId;
  final double spendAmount;
  final String? upiRef;
  final String? billPhotoPath;

  const RaidVerificationSubmitted({
    required this.raidId,
    required this.spendAmount,
    this.upiRef,
    this.billPhotoPath,
  });

  @override
  List<Object?> get props => [raidId, spendAmount, upiRef, billPhotoPath];
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

  const RaidTimerActive({
    required this.raidId,
    required this.zoneId,
    required this.secondsRemaining,
  });

  @override
  List<Object?> get props => [raidId, zoneId, secondsRemaining];
}

final class RaidVerifying extends RaidState {}

final class RaidSuccess extends RaidState {
  final double points;
  final int rank;
  final bool isWarlord;

  const RaidSuccess({
    required this.points,
    required this.rank,
    required this.isWarlord,
  });

  @override
  List<Object?> get props => [points, rank, isWarlord];
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
  StreamSubscription<int>? _timerSubscription;
  String? _currentUserId;
  String? _currentUsername;

  RaidBloc({
    required StartRaid startRaid,
    required VerifyRaid verifyRaid,
  })  : _startRaid = startRaid,
        _verifyRaid = verifyRaid,
        super(RaidInitial()) {
    on<RaidStartRequested>(_onStartRequested);
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

    result.fold(
      (failure) => emit(RaidFailure(failure.message)),
      (raid) {
        final targetEndTime = raid.startedAt.add(Duration(minutes: raid.durationMins));
        final initialSecondsRemaining = targetEndTime.difference(DateTime.now()).inSeconds;

        emit(RaidTimerActive(
          raidId: raid.id,
          zoneId: raid.zoneId,
          secondsRemaining: initialSecondsRemaining > 0 ? initialSecondsRemaining : 0,
        ));
        
        // Start background-resilient periodic check based on actual system clock difference
        _timerSubscription = Stream.periodic(
          const Duration(seconds: 1),
          (_) {
            final now = DateTime.now();
            final difference = targetEndTime.difference(now).inSeconds;
            return difference > 0 ? difference : 0;
          },
        ).listen((seconds) {
          add(RaidTimerTicked(seconds));
        });
      },
    );
  }

  void _onTimerTicked(
    RaidTimerTicked event,
    Emitter<RaidState> emit,
  ) {
    if (state is RaidTimerActive) {
      final current = state as RaidTimerActive;
      if (event.secondsRemaining <= 0) {
        _timerSubscription?.cancel();
        emit(const RaidFailure('Raid timer expired! Please start a new raid.'));
      } else {
        emit(RaidTimerActive(
          raidId: current.raidId,
          zoneId: current.zoneId,
          secondsRemaining: event.secondsRemaining,
        ));
      }
    }
  }

  Future<void> _onVerificationSubmitted(
    RaidVerificationSubmitted event,
    Emitter<RaidState> emit,
  ) async {
    String? zoneId;
    if (state is RaidTimerActive) {
      zoneId = (state as RaidTimerActive).zoneId;
    }

    _timerSubscription?.cancel();
    emit(RaidVerifying());

    final result = await _verifyRaid(
      raidId: event.raidId,
      spendAmount: event.spendAmount,
      upiRef: event.upiRef,
      billPhotoPath: event.billPhotoPath,
    );

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
        emit(RaidSuccess(
          points: (data['points'] as num).toDouble(),
          rank: (data['rank'] as num).toInt(),
          isWarlord: isWarlord,
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
