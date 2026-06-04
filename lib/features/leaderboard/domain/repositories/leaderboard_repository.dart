import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/leaderboard_user_entity.dart';

abstract class LeaderboardRepository {
  Future<Either<Failure, List<LeaderboardUserEntity>>> getLeaderboard(
      String scope, {String? city});
}
