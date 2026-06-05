import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_user_profile.dart';
import 'user_profile_event.dart';
import 'user_profile_state.dart';

class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  final GetUserProfile _getUserProfile;

  UserProfileBloc({required GetUserProfile getUserProfile})
      : _getUserProfile = getUserProfile,
        super(const UserProfileInitial()) {
    on<LoadUserProfile>(_onLoad);
  }

  Future<void> _onLoad(
    LoadUserProfile event,
    Emitter<UserProfileState> emit,
  ) async {
    emit(const UserProfileLoading());
    final result = await _getUserProfile(userId: event.userId);
    result.fold(
      (failure) => emit(UserProfileError(failure.message)),
      (profile) => emit(UserProfileLoaded(profile)),
    );
  }
}
