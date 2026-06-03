import 'package:equatable/equatable.dart';
import '../../domain/entities/leaderboard_user_entity.dart';

abstract class LeaderboardState extends Equatable {
  const LeaderboardState();

  @override
  List<Object?> get props => [];
}

class LeaderboardInitial extends LeaderboardState {}

class LeaderboardLoading extends LeaderboardState {}

class LeaderboardLoaded extends LeaderboardState {
  final List<LeaderboardUserEntity> rankings;
  final String scope;

  const LeaderboardLoaded({
    required this.rankings,
    required this.scope,
  });

  @override
  List<Object?> get props => [rankings, scope];
}

class LeaderboardError extends LeaderboardState {
  final String message;

  const LeaderboardError(this.message);

  @override
  List<Object> get props => [message];
}
