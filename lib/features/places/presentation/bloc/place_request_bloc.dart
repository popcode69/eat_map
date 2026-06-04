import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/place_request_repository_impl.dart';
import '../../domain/entities/place_request_entity.dart';

// ── Events ──────────────────────────────────────────────────────────
sealed class PlaceRequestEvent extends Equatable {
  const PlaceRequestEvent();
  @override
  List<Object?> get props => [];
}

final class PlaceRequestSubmitted extends PlaceRequestEvent {
  final PlaceRequestEntity request;
  const PlaceRequestSubmitted(this.request);
  @override
  List<Object?> get props => [request];
}

// ── States ──────────────────────────────────────────────────────────
sealed class PlaceRequestState extends Equatable {
  const PlaceRequestState();
  @override
  List<Object?> get props => [];
}

final class PlaceRequestInitial extends PlaceRequestState {}

final class PlaceRequestLoading extends PlaceRequestState {}

final class PlaceRequestSuccess extends PlaceRequestState {}

final class PlaceRequestFailure extends PlaceRequestState {
  final String message;
  const PlaceRequestFailure(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ─────────────────────────────────────────────────────────────
class PlaceRequestBloc extends Bloc<PlaceRequestEvent, PlaceRequestState> {
  final PlaceRequestRepositoryImpl _repo;

  PlaceRequestBloc({required PlaceRequestRepositoryImpl repo})
      : _repo = repo,
        super(PlaceRequestInitial()) {
    on<PlaceRequestSubmitted>(_onSubmit);
  }

  Future<void> _onSubmit(
    PlaceRequestSubmitted event,
    Emitter<PlaceRequestState> emit,
  ) async {
    emit(PlaceRequestLoading());
    final result = await _repo.submitRequest(event.request);
    result.fold(
      (failure) => emit(PlaceRequestFailure(failure.message)),
      (_) => emit(PlaceRequestSuccess()),
    );
  }
}
