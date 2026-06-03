import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/leaderboard_user_entity.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../models/leaderboard_user_model.dart';

class LeaderboardRepositoryImpl implements LeaderboardRepository {
  final DioClient _dioClient;

  // Local static mock rankings to support completely offline verification of leaderboards!
  final Map<String, List<LeaderboardUserModel>> _mockData = {
    'city': [
      const LeaderboardUserModel(
        rank: 1,
        username: 'warlord_alpha',
        displayName: 'Warlord Alpha 🛡️',
        totalPoints: 8500,
        warlordCount: 12,
        squadName: 'Bravado',
      ),
      const LeaderboardUserModel(
        rank: 2,
        username: 'spice_raider',
        displayName: 'Spice Raider 🌶️',
        totalPoints: 7200,
        warlordCount: 8,
        squadName: 'RedHot',
      ),
      const LeaderboardUserModel(
        rank: 3,
        username: 'cyber_raider_1',
        displayName: 'You (Cyber Raider)',
        totalPoints: 6400,
        warlordCount: 5,
        squadName: 'CyberEats',
      ),
      const LeaderboardUserModel(
        rank: 4,
        username: 'boba_fettish',
        displayName: 'Boba Fettish 🧋',
        totalPoints: 5100,
        warlordCount: 3,
        squadName: 'BobaBoys',
      ),
      const LeaderboardUserModel(
        rank: 5,
        username: 'taco_bout_it',
        displayName: 'Taco Bout It 🌮',
        totalPoints: 4500,
        warlordCount: 2,
        squadName: 'MexiCans',
      ),
    ],
    'global': [
      const LeaderboardUserModel(
        rank: 1,
        username: 'glutton_king',
        displayName: 'Glutton King 👑',
        totalPoints: 24500,
        warlordCount: 45,
        squadName: 'FeastForce',
      ),
      const LeaderboardUserModel(
        rank: 2,
        username: 'nomnom_warlord',
        displayName: 'NomNom Warlord ⚔️',
        totalPoints: 19800,
        warlordCount: 32,
        squadName: 'HungryWolves',
      ),
      const LeaderboardUserModel(
        rank: 3,
        username: 'chopstick_ninja',
        displayName: 'Chopstick Ninja 🥢',
        totalPoints: 18100,
        warlordCount: 28,
        squadName: 'SushiSlayers',
      ),
      const LeaderboardUserModel(
        rank: 4,
        username: 'warlord_alpha',
        displayName: 'Warlord Alpha 🛡️',
        totalPoints: 8500,
        warlordCount: 12,
        squadName: 'Bravado',
      ),
      const LeaderboardUserModel(
        rank: 12,
        username: 'cyber_raider_1',
        displayName: 'You (Cyber Raider)',
        totalPoints: 6400,
        warlordCount: 5,
        squadName: 'CyberEats',
      ),
    ],
    'squad': [
      const LeaderboardUserModel(
        rank: 1,
        username: 'Bravado',
        displayName: 'Bravado Squad 🛡️',
        totalPoints: 45000,
        warlordCount: 28,
      ),
      const LeaderboardUserModel(
        rank: 2,
        username: 'CyberEats',
        displayName: 'CyberEats (Your Squad)',
        totalPoints: 32000,
        warlordCount: 18,
      ),
      const LeaderboardUserModel(
        rank: 3,
        username: 'RedHot',
        displayName: 'RedHot Raiders 🌶️',
        totalPoints: 28000,
        warlordCount: 15,
      ),
      const LeaderboardUserModel(
        rank: 4,
        username: 'Dosa_Dominators',
        displayName: 'Dosa Dominators 🥞',
        totalPoints: 21000,
        warlordCount: 9,
      ),
    ],
  };

  LeaderboardRepositoryImpl({required DioClient dioClient}) : _dioClient = dioClient;

  @override
  Future<Either<Failure, List<LeaderboardUserEntity>>> getLeaderboard(String scope) async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.leaderboard, queryParameters: {'scope': scope});
      final dataList = response.data as List;
      final rankList = dataList
          .map((json) => LeaderboardUserModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right(rankList);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        return Right(_mockData[scope] ?? _mockData['city']!);
      }
      return Left(ErrorHandler.handle(e.error ?? e));
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }
}
