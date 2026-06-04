import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/leaderboard_user_entity.dart';
import '../repositories/leaderboard_repository.dart';

class GetCityLeaderboard {
  final LeaderboardRepository repository;

  const GetCityLeaderboard(this.repository);

  Future<Either<Failure, List<LeaderboardUserEntity>>> call(
      String scope, {String? city}) async {
    return await repository.getLeaderboard(scope, city: city);
  }
}
