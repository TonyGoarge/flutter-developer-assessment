// =============================================================================
// EXERCISE 2: State Management — "Paginated Room List with BLoC"
// Time: 40 minutes
// =============================================================================
//
// SCENARIO:
// You're working on a social/live-streaming app that displays rooms in a
// paginated list. The architecture uses Clean Architecture with BLoC for state
// management and dartz Either for error handling.
//
// The base architecture is provided below. Your job is to fix bugs in the
// existing BLoC and complete the missing functionality.
//
// TASKS:
// 1. [All Levels] Fix the bugs in RoomListBloc._onFetchRooms
// 2. [All Levels] Implement the LoadMoreRoomsEvent handler (pagination)
// 3. [Mid+] Add buildWhen to the BlocBuilder in RoomListPage
// 4. [Mid+] Implement infinite scroll using handleScrollListener
// 5. [Mid+] Find and fix the subtle bug in RoomListState.copyWith
// 6. [Senior] Review FetchAllDataBloc at the bottom — identify the anti-pattern
//    and propose a refactored architecture (written answer, no code required)
//
// RULES:
// - Do not modify the base classes (RequestState, UseCaseWithParams, etc.)
// - You may add new events, modify state, and fix the BLoC implementation
// - Consider error handling, edge cases, and performance
// =============================================================================

import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ---------------------------------------------------------------------------
// BASE ARCHITECTURE (do not modify)
// ---------------------------------------------------------------------------

/// Request state enum for tracking async operations
enum RequestState { idle, loading, loaded, error, offline, empty }

/// Type aliases for Either-based error handling
typedef ResultFuture<T> = Future<Either<NetworkExceptions, T>>;

/// Base class for network exceptions
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

/// Wrapper that converts futures to Either types
ResultFuture<T> execute<T>(Future<T> Function() fun) async {
  try {
    final result = await fun();
    return Right(result);
  } catch (error) {
    return const Left(ServerError());
  }
}

/// Base use case with parameters
abstract class UseCaseWithParams<T, Params> {
  const UseCaseWithParams();
  ResultFuture<T> call(Params params);
}

/// Paginated response wrapper
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

/// Helper: Convert NetworkExceptions to RequestState
RequestState handleErrorResponse(NetworkExceptions error) {
  return error is NoInternetConnection
      ? RequestState.offline
      : RequestState.error;
}

/// Helper: Determine loaded vs empty state
RequestState handleLoadedResponse<T>(T? result) {
  if (result is List) {
    return result.isEmpty ? RequestState.empty : RequestState.loaded;
  }
  return RequestState.loaded;
}

/// Helper: Merge paginated results
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

/// Helper: Attach scroll listener for pagination
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
// DOMAIN LAYER (do not modify)
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
    // Simulated API call - returns mock data
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
// PRESENTATION LAYER — EVENTS (you may modify/add)
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
// PRESENTATION LAYER — STATE (find and fix the bug)
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
      // ⚠️ SUBTLE BUG: These two are swapped (mirrors real codebase bug)
      popularIndex: globalIndex ?? this.popularIndex,
      globalIndex: popularIndex ?? this.globalIndex,
      scrollController: scrollController,
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
// PRESENTATION LAYER — BLOC (fix bugs and complete implementation)
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
    // BUG 1: Doesn't emit loading state before making API call
    // BUG 2: Always passes page: 1, doesn't reset pagination state

    final result = await _fetchRoomsUC(RoomParams(page: 1));
    result.fold(
      (left) => emit(state.copyWith(
        status: RequestState.error,
        // BUG 3: Doesn't store the error message
      )),
      (right) => emit(state.copyWith(
        // BUG 4: Doesn't use handleLoadedResponse — always sets loaded even if empty
        status: RequestState.loaded,
        rooms: right.data,
        // BUG 5: Doesn't store pagination metadata (lastPage)
      )),
    );
  }

  Future<void> _onLoadMore(
    LoadMoreRoomsEvent event,
    Emitter<RoomListState> emit,
  ) async {
    // TODO: Implement pagination
    // 1. Check if we've reached the last page
    // 2. Increment currentPage
    // 3. Fetch next page
    // 4. Merge results using handlePaginationResponse
    // 5. Update state with merged list and new pagination info
  }
}

// ---------------------------------------------------------------------------
// PRESENTATION LAYER — UI (add buildWhen and scroll listener)
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

    // TODO [Mid+]: Add scroll listener for infinite scroll
    // Use handleScrollListener to trigger LoadMoreRoomsEvent
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
        // TODO [Mid+]: Add buildWhen to prevent unnecessary rebuilds
        // Only rebuild when status or rooms list changes
        builder: (context, state) {
          switch (state.status) {
            case RequestState.idle:
            case RequestState.loading:
              return const Center(child: CircularProgressIndicator());

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
              return RefreshIndicator(
                onRefresh: () async {
                  _bloc.add(const FetchRoomsEvent());
                },
                child: ListView.builder(
                  controller: state.scrollController,
                  itemCount: state.rooms.length,
                  itemBuilder: (context, index) {
                    final room = state.rooms[index];
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
        },
      ),
    );
  }
}

// ===========================================================================
// SENIOR EXERCISE: Review this code and identify the anti-pattern.
// Write a short answer (no code needed) explaining:
// 1. What's wrong with this BLoC?
// 2. What problems does this cause?
// 3. How would you refactor it? (describe the split, not full code)
// ===========================================================================

class FetchAllDataBloc extends Bloc<dynamic, dynamic> {
  FetchAllDataBloc(
    // 15 use case dependencies — each handles a different concern:
    this._fetchMyDataUC,           // User profile data
    this._fetchUserDataUC,         // Other user's data
    this._initPusherUC,            // Pusher WebSocket init
    this._subscribeToChatUC,       // Chat channel subscription
    this._subscribeToMessagesUC,   // Message channel subscription
    this._listenToBannersUC,       // Gift/game banner events
    this._listenToGamesUC,         // Game channel events
    this._subscribeCounterUC,      // Unread message counter
    this._fetchConfigUC,           // App configuration
    this._fetchCountriesUC,        // Country list for filters
    this._updateFCMTokenUC,        // Firebase messaging token
    this._fetchBadgesUC,           // User badges
    this._fetchLevelDataUC,        // User level/XP data
    this._initAnalyticsUC,         // Analytics initialization
    this._fetchWalletUC,           // Wallet/coins balance
  ) : super(null) {
    // Handles: user data, pusher, banners, games, config, badges,
    // level data, analytics, wallet, FCM, countries, chat, messages,
    // counter, and more...
  }

  final dynamic _fetchMyDataUC;
  final dynamic _fetchUserDataUC;
  final dynamic _initPusherUC;
  final dynamic _subscribeToChatUC;
  final dynamic _subscribeToMessagesUC;
  final dynamic _listenToBannersUC;
  final dynamic _listenToGamesUC;
  final dynamic _subscribeCounterUC;
  final dynamic _fetchConfigUC;
  final dynamic _fetchCountriesUC;
  final dynamic _updateFCMTokenUC;
  final dynamic _fetchBadgesUC;
  final dynamic _fetchLevelDataUC;
  final dynamic _initAnalyticsUC;
  final dynamic _fetchWalletUC;
}
