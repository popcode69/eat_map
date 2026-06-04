import 'package:equatable/equatable.dart';

abstract class LeaderboardEvent extends Equatable {
  const LeaderboardEvent();

  @override
  List<Object> get props => [];
}

class LoadLeaderboardRequested extends LeaderboardEvent {
  final String scope; // 'city' | 'global' | 'squad'
  final String? city; // only relevant for scope == 'city'

  const LoadLeaderboardRequested(this.scope, {this.city});

  @override
  List<Object> get props => [scope, city ?? ''];
}
