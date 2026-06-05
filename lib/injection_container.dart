import 'package:get_it/get_it.dart';
import 'core/cache/secure_storage.dart';
import 'core/connectivity/connectivity_cubit.dart';
import 'core/network/dio_client.dart';

// Auth Module
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/get_current_user.dart';
import 'features/auth/domain/usecases/sign_in_google.dart';
import 'features/auth/domain/usecases/sign_in_phone.dart';
import 'features/auth/domain/usecases/sign_out.dart';
import 'features/auth/domain/usecases/update_location.dart';
import 'features/auth/domain/usecases/update_profile.dart';
import 'features/auth/domain/usecases/upload_avatar.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

// Profile Module
import 'features/profile/data/repositories/user_profile_repository_impl.dart';
import 'features/profile/domain/repositories/user_profile_repository.dart';
import 'features/profile/domain/usecases/get_user_profile.dart';
import 'features/profile/presentation/bloc/user_profile_bloc.dart';

// Zone & Map Module
import 'features/zone/data/repositories/zone_repository_impl.dart';
import 'features/zone/domain/repositories/zone_repository.dart';
import 'features/zone/domain/usecases/customize_zone.dart';
import 'features/zone/domain/usecases/get_nearby_zones.dart';
import 'features/zone/domain/usecases/get_zone_detail.dart';
import 'features/zone/domain/usecases/get_zone_raiders.dart';
import 'features/zone/presentation/bloc/place_detail_bloc.dart';
import 'features/map/presentation/bloc/map_bloc.dart';

// Raid Module
import 'features/raid/data/repositories/raid_repository_impl.dart';
import 'features/raid/domain/repositories/raid_repository.dart';
import 'features/raid/domain/usecases/start_raid.dart';
import 'features/raid/domain/usecases/verify_raid.dart';
import 'features/raid/presentation/bloc/raid_bloc.dart';

// Wallet Module
import 'features/wallet/data/repositories/wallet_repository_impl.dart';
import 'features/wallet/domain/repositories/wallet_repository.dart';
import 'features/wallet/domain/usecases/get_wallet_balance.dart';
import 'features/wallet/domain/usecases/get_transactions.dart';
import 'features/wallet/domain/usecases/request_withdrawal.dart';
import 'features/wallet/presentation/bloc/wallet_bloc.dart';

// Leaderboard Module
import 'features/leaderboard/data/repositories/leaderboard_repository_impl.dart';
import 'features/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'features/leaderboard/domain/usecases/get_city_leaderboard.dart';
import 'features/leaderboard/presentation/bloc/leaderboard_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ==========================================
  // 1. CORE COMPONENTS
  // ==========================================
  
  // Connectivity state cubit
  sl.registerLazySingleton<ConnectivityCubit>(() => ConnectivityCubit());

  // Local Secure key-value storage
  sl.registerLazySingleton<SecureStorage>(() => SecureStorage());

  // Dio Centralized HTTP Network Client
  sl.registerLazySingleton<DioClient>(() => DioClient(
        secureStorage: sl<SecureStorage>(),
        connectivityCubit: sl<ConnectivityCubit>(),
      ));

  // ==========================================
  // 2. FEATURES - AUTH
  // ==========================================
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
        dioClient: sl<DioClient>(),
        secureStorage: sl<SecureStorage>(),
      ));

  sl.registerLazySingleton<GetCurrentUser>(() => GetCurrentUser(sl<AuthRepository>()));
  sl.registerLazySingleton<SignInWithPhone>(() => SignInWithPhone(sl<AuthRepository>()));
  sl.registerLazySingleton<SignInWithGoogle>(() => SignInWithGoogle(sl<AuthRepository>()));
  sl.registerLazySingleton<SignOut>(() => SignOut(sl<AuthRepository>()));
  sl.registerLazySingleton<UploadAvatar>(() => UploadAvatar(sl<AuthRepository>()));
  sl.registerLazySingleton<UpdateLocation>(() => UpdateLocation(sl<AuthRepository>()));
  sl.registerLazySingleton<UpdateProfile>(() => UpdateProfile(sl<AuthRepository>()));

  sl.registerFactory<AuthBloc>(() => AuthBloc(
        getCurrentUser: sl<GetCurrentUser>(),
        signInWithPhone: sl<SignInWithPhone>(),
        signInWithGoogle: sl<SignInWithGoogle>(),
        signOut: sl<SignOut>(),
        uploadAvatar: sl<UploadAvatar>(),
        updateLocation: sl<UpdateLocation>(),
        updateProfile: sl<UpdateProfile>(),
      ));

  // ==========================================
  // 3. FEATURES - USER PROFILE
  // ==========================================
  sl.registerLazySingleton<UserProfileRepository>(
      () => UserProfileRepositoryImpl(dioClient: sl<DioClient>()));
  sl.registerLazySingleton<GetUserProfile>(
      () => GetUserProfile(sl<UserProfileRepository>()));
  sl.registerFactory<UserProfileBloc>(
      () => UserProfileBloc(getUserProfile: sl<GetUserProfile>()));

  // ==========================================
  // 4. FEATURES - ZONE & MAP
  // ==========================================
  sl.registerLazySingleton<ZoneRepository>(() => ZoneRepositoryImpl(
        dioClient: sl<DioClient>(),
      ));

  sl.registerLazySingleton<GetNearbyZones>(() => GetNearbyZones(sl<ZoneRepository>()));
  sl.registerLazySingleton<GetZoneDetail>(() => GetZoneDetail(sl<ZoneRepository>()));
  sl.registerLazySingleton<CustomizeZone>(() => CustomizeZone(sl<ZoneRepository>()));
  sl.registerLazySingleton<GetZoneRaiders>(() => GetZoneRaiders(sl<ZoneRepository>()));

  sl.registerFactory<PlaceDetailBloc>(() => PlaceDetailBloc(
        getZoneDetail: sl<GetZoneDetail>(),
        getZoneRaiders: sl<GetZoneRaiders>(),
      ));

  sl.registerFactory<MapBloc>(() => MapBloc(
        getNearbyZones: sl<GetNearbyZones>(),
        zoneRepo: sl<ZoneRepository>() as ZoneRepositoryImpl,
      ));

  // ==========================================
  // 4. FEATURES - RAID
  // ==========================================
  sl.registerLazySingleton<RaidRepository>(() => RaidRepositoryImpl(
        dioClient: sl<DioClient>(),
      ));

  sl.registerLazySingleton<StartRaid>(() => StartRaid(sl<RaidRepository>()));
  sl.registerLazySingleton<VerifyRaid>(() => VerifyRaid(sl<RaidRepository>()));

  sl.registerFactory<RaidBloc>(() => RaidBloc(
        startRaid: sl<StartRaid>(),
        verifyRaid: sl<VerifyRaid>(),
        secureStorage: sl<SecureStorage>(),
      ));

  // ==========================================
  // 5. FEATURES - WALLET
  // ==========================================
  sl.registerLazySingleton<WalletRepository>(() => WalletRepositoryImpl(
        dioClient: sl<DioClient>(),
      ));

  sl.registerLazySingleton<GetWalletBalance>(() => GetWalletBalance(sl<WalletRepository>()));
  sl.registerLazySingleton<GetTransactions>(() => GetTransactions(sl<WalletRepository>()));
  sl.registerLazySingleton<RequestWithdrawal>(() => RequestWithdrawal(sl<WalletRepository>()));

  sl.registerFactory<WalletBloc>(() => WalletBloc(
        getWalletBalance: sl<GetWalletBalance>(),
        getTransactions: sl<GetTransactions>(),
        requestWithdrawal: sl<RequestWithdrawal>(),
      ));

  // ==========================================
  // 6. FEATURES - LEADERBOARD
  // ==========================================
  sl.registerLazySingleton<LeaderboardRepository>(() => LeaderboardRepositoryImpl(
        dioClient: sl<DioClient>(),
      ));

  sl.registerLazySingleton<GetCityLeaderboard>(() => GetCityLeaderboard(sl<LeaderboardRepository>()));

  sl.registerFactory<LeaderboardBloc>(() => LeaderboardBloc(
        getCityLeaderboard: sl<GetCityLeaderboard>(),
      ));
}
