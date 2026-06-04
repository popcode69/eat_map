import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_city_leaderboard.dart';
import 'leaderboard_event.dart';
import 'leaderboard_state.dart';

class LeaderboardBloc extends Bloc<LeaderboardEvent, LeaderboardState> {
  final GetCityLeaderboard getCityLeaderboard;

  LeaderboardBloc({
    required this.getCityLeaderboard,
  }) : super(LeaderboardInitial()) {
    on<LoadLeaderboardRequested>(_onLoadLeaderboardRequested);
  }

  Future<void> _onLoadLeaderboardRequested(
    LoadLeaderboardRequested event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(LeaderboardLoading());

    final result = await getCityLeaderboard(event.scope, city: event.city);

    result.fold(
      (failure) => emit(LeaderboardError(failure.message)),
      (rankings) => emit(LeaderboardLoaded(rankings: rankings, scope: event.scope)),
    );
  }
}
