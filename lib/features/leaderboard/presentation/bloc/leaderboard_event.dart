import 'package:equatable/equatable.dart';

abstract class LeaderboardEvent extends Equatable {
  const LeaderboardEvent();

  @override
  List<Object> get props => [];
}

class LoadLeaderboardRequested extends LeaderboardEvent {
  final String scope; // 'city' | 'global' | 'squad'

  const LoadLeaderboardRequested(this.scope);

  @override
  List<Object> get props => [scope];
}
