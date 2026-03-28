// =============================================================================
// EXERCISE 2: State Management — "Paginated Room List with BLoC" (FIXED)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:flutter_bloc/flutter_bloc.dart';

// ---------------------------------------------------------------------------
// BASE ARCHITECTURE (unchanged)
// ---------------------------------------------------------------------------

enum RequestState { idle, loading, loaded, error, offline, empty }

typedef ResultFuture<T> = Future<Either<NetworkExceptions, T>>;

class NetworkExceptions {
  const NetworkExceptions();

  static String getErrorMessage(NetworkExceptions exception) {
    if (exception is NoInternetConnection) return 'No internet connection';
    if (exception is RequestTimeout) return 'Request timed out';
    if (exception is ServerError) return 'Internal server error';
    if (exception is BadRequest) return exception.message;
    return 'An unexpected error occurred';
  }
}

class NoInternetConnection extends NetworkExceptions {
  const NoInternetConnection();
}

class RequestTimeout extends NetworkExceptions {
  const RequestTimeout();
}

class ServerError extends NetworkExceptions {
  const ServerError();
}

class BadRequest extends NetworkExceptions {
  final String message;
  const BadRequest(this.message);
}

ResultFuture<T> execute<T>(Future<T> Function() fun) async {
  try {
    final result = await fun();
    return Right(result);
  } catch (error) {
    return const Left(ServerError());
  }
}

abstract class UseCaseWithParams<T, Params> {
  const UseCaseWithParams();
  ResultFuture<T> call(Params params);
}

class BaseResponse<T> {
  final T? data;
  final PaginationMeta? paginates;

  const BaseResponse({this.data, this.paginates});
}

class PaginationMeta {
  final int currentPage;
  final int lastPage;
  final int total;

  const PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
}

RequestState handleErrorResponse(NetworkExceptions error) {
  return error is NoInternetConnection
      ? RequestState.offline
      : RequestState.error;
}

RequestState handleLoadedResponse<T>(T? result) {
  if (result is List) {
    return result.isEmpty ? RequestState.empty : RequestState.loaded;
  }
  return RequestState.loaded;
}

List<T> handlePaginationResponse<T>({
  required List<T>? result,
  required List<T> currentList,
  required int currentPage,
}) {
  if (result == null) return currentList;
  if (currentList.isEmpty || currentPage == 1) {
    return result;
  } else {
    final Set<T> uniqueItems = Set<T>.from(currentList);
    uniqueItems.addAll(result);
    return uniqueItems.toList();
  }
}

void handleScrollListener({
  required ScrollController controller,
  required Function() fun,
  required int currentPage,
  required int lastPage,
}) {
  if (controller.position.pixels == controller.position.maxScrollExtent) {
    if (lastPage > currentPage) fun();
  }
}

// ---------------------------------------------------------------------------
// DOMAIN LAYER (unchanged)
// ---------------------------------------------------------------------------

class RoomEntity extends Equatable {
  final int id;
  final String roomName;
  final String? coverUrl;
  final int visitorsCount;
  final bool isLive;

  const RoomEntity({
    required this.id,
    required this.roomName,
    this.coverUrl,
    this.visitorsCount = 0,
    this.isLive = false,
  });

  @override
  List<Object?> get props => [id, roomName, coverUrl, visitorsCount, isLive];
}

class RoomParams {
  final int page;
  final int? countryId;

  const RoomParams({required this.page, this.countryId});
}

class FetchRoomsUseCase
    extends UseCaseWithParams<BaseResponse<List<RoomEntity>>, RoomParams> {
  @override
  ResultFuture<BaseResponse<List<RoomEntity>>> call(RoomParams params) async {
    await Future.delayed(const Duration(seconds: 1));
    final rooms = List.generate(
      20,
      (i) => RoomEntity(
        id: (params.page - 1) * 20 + i,
        roomName: 'Room ${(params.page - 1) * 20 + i}',
        visitorsCount: (i + 1) * 10,
        isLive: i % 3 == 0,
      ),
    );
    return Right(BaseResponse(
      data: rooms,
      paginates: PaginationMeta(
        currentPage: params.page,
        lastPage: 5,
        total: 100,
      ),
    ));
  }
}

// ---------------------------------------------------------------------------
// EVENTS (unchanged)
// ---------------------------------------------------------------------------

sealed class RoomListEvent extends Equatable {
  const RoomListEvent();
  @override
  List<Object?> get props => [];
}

final class FetchRoomsEvent extends RoomListEvent {
  const FetchRoomsEvent();
}

final class LoadMoreRoomsEvent extends RoomListEvent {
  const LoadMoreRoomsEvent();
}

// ---------------------------------------------------------------------------
// STATE — BUG FIXED in copyWith
// ---------------------------------------------------------------------------

class RoomListState extends Equatable {
  final RequestState status;
  final List<RoomEntity> rooms;
  final String errorMessage;
  final int currentPage;
  final int lastPage;
  final int popularIndex;
  final int globalIndex;
  final ScrollController scrollController;

  RoomListState({
    this.status = RequestState.idle,
    this.rooms = const [],
    this.errorMessage = '',
    this.currentPage = 1,
    this.lastPage = -1,
    this.popularIndex = 0,
    this.globalIndex = 0,
    ScrollController? scrollController,
  }) : scrollController = scrollController ?? ScrollController();

  RoomListState copyWith({
    RequestState? status,
    List<RoomEntity>? rooms,
    String? errorMessage,
    int? currentPage,
    int? lastPage,
    int? popularIndex,
    int? globalIndex,
  }) {
    return RoomListState(
      status: status ?? this.status,
      rooms: rooms ?? this.rooms,
      errorMessage: errorMessage ?? this.errorMessage,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      // FIX: popularIndex and globalIndex were swapped — each now reads its own param
      popularIndex: popularIndex ?? this.popularIndex,
      globalIndex: globalIndex ?? this.globalIndex,
      scrollController: scrollController, // preserve existing controller instance
    );
  }

  @override
  List<Object?> get props => [
        status,
        rooms,
        errorMessage,
        currentPage,
        lastPage,
        popularIndex,
        globalIndex,
      ];
}

// ---------------------------------------------------------------------------
// BLOC — all 5 bugs fixed + LoadMore implemented
// ---------------------------------------------------------------------------

class RoomListBloc extends Bloc<RoomListEvent, RoomListState> {
  final FetchRoomsUseCase _fetchRoomsUC;

  RoomListBloc(this._fetchRoomsUC) : super(RoomListState()) {
    on<FetchRoomsEvent>(_onFetchRooms);
    on<LoadMoreRoomsEvent>(_onLoadMore);
  }

  Future<void> _onFetchRooms(
    FetchRoomsEvent event,
    Emitter<RoomListState> emit,
  ) async {
    // FIX 1: Emit loading state before the API call
    // FIX 2: Reset pagination to page 1 on fresh fetch
    emit(state.copyWith(
      status: RequestState.loading,
      currentPage: 1,
    ));

    final result = await _fetchRoomsUC(const RoomParams(page: 1));

    result.fold(
      (error) => emit(state.copyWith(
        status: handleErrorResponse(error),
        // FIX 3: Store the human-readable error message
        errorMessage: NetworkExceptions.getErrorMessage(error),
      )),
      (response) => emit(state.copyWith(
        // FIX 4: Use handleLoadedResponse to correctly emit empty vs loaded
        status: handleLoadedResponse(response.data),
        rooms: response.data ?? [],
        // FIX 5: Store pagination metadata so LoadMore knows when to stop
        currentPage: response.paginates?.currentPage ?? 1,
        lastPage: response.paginates?.lastPage ?? 1,
      )),
    );
  }

  Future<void> _onLoadMore(
    LoadMoreRoomsEvent event,
    Emitter<RoomListState> emit,
  ) async {
    // Guard: don't fetch if already on last page or currently loading
    if (state.currentPage >= state.lastPage) return;
    if (state.status == RequestState.loading) return;

    final nextPage = state.currentPage + 1;

    // Emit loading without clearing the existing rooms list
    // so the UI continues showing current items while fetching
    emit(state.copyWith(status: RequestState.loading));

    final result = await _fetchRoomsUC(RoomParams(page: nextPage));

    result.fold(
      (error) => emit(state.copyWith(
        status: handleErrorResponse(error),
        errorMessage: NetworkExceptions.getErrorMessage(error),
      )),
      (response) {
        // Merge new page into existing list, deduplicating by Set
        final merged = handlePaginationResponse(
          result: response.data,
          currentList: state.rooms,
          currentPage: nextPage,
        );

        emit(state.copyWith(
          status: handleLoadedResponse(merged),
          rooms: merged,
          currentPage: response.paginates?.currentPage ?? nextPage,
          lastPage: response.paginates?.lastPage ?? state.lastPage,
        ));
      },
    );
  }
}

// ---------------------------------------------------------------------------
// UI — buildWhen added + scroll listener wired up
// ---------------------------------------------------------------------------

class RoomListPage extends StatefulWidget {
  const RoomListPage({super.key});

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  late final RoomListBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = RoomListBloc(FetchRoomsUseCase());
    _bloc.add(const FetchRoomsEvent());

    // FIX [Mid+]: Wire up scroll listener for infinite scroll.
    // We read the controller from the initial state once and reuse it.
    // handleScrollListener guards against triggering past the last page.
    _bloc.state.scrollController.addListener(() {
      handleScrollListener(
        controller: _bloc.state.scrollController,
        fun: () => _bloc.add(const LoadMoreRoomsEvent()),
        currentPage: _bloc.state.currentPage,
        lastPage: _bloc.state.lastPage,
      );
    });
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rooms')),
      body: BlocBuilder<RoomListBloc, RoomListState>(
        bloc: _bloc,
        // FIX [Mid+]: buildWhen — only rebuild when status or rooms change.
        // Prevents unnecessary rebuilds when unrelated state fields update
        // (e.g. popularIndex, globalIndex, errorMessage without status change).
        buildWhen: (previous, current) =>
            previous.status != current.status ||
            previous.rooms != current.rooms,
        builder: (context, state) {
          switch (state.status) {
            case RequestState.idle:
            case RequestState.loading:
              // Show spinner on first load; for load-more, rooms are still visible
              // (status goes back to loading but rooms list is preserved in state)
              if (state.rooms.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              // Fall through to loaded view with a bottom spinner
              return _RoomListView(
                bloc: _bloc,
                rooms: state.rooms,
                showBottomLoader: true,
              );

            case RequestState.error:
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.errorMessage.isEmpty
                        ? 'Something went wrong'
                        : state.errorMessage),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _bloc.add(const FetchRoomsEvent()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );

            case RequestState.offline:
              return const Center(child: Text('No internet connection'));

            case RequestState.empty:
              return const Center(child: Text('No rooms available'));

            case RequestState.loaded:
              return _RoomListView(
                bloc: _bloc,
                rooms: state.rooms,
                showBottomLoader: false,
              );
          }
        },
      ),
    );
  }
}

/// Extracted to avoid duplicating ListView.builder in multiple switch branches
class _RoomListView extends StatelessWidget {
  final RoomListBloc bloc;
  final List<RoomEntity> rooms;
  final bool showBottomLoader;

  const _RoomListView({
    required this.bloc,
    required this.rooms,
    required this.showBottomLoader,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => bloc.add(const FetchRoomsEvent()),
      child: ListView.builder(
        controller: bloc.state.scrollController,
        // +1 item slot for the bottom loader when paginating
        itemCount: rooms.length + (showBottomLoader ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == rooms.length) {
            // Bottom of list: show a small loading indicator while paginating
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final room = rooms[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text(room.isLive ? '🔴' : '⚪'),
            ),
            title: Text(room.roomName),
            subtitle: Text('${room.visitorsCount} visitors'),
          );
        },
      ),
    );
  }
}