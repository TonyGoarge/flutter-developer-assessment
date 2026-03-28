

// New version 

// =============================================================================
// EXERCISE 3: Debugging & Refactoring — "Room Screen Mini" (FIXED)
// All 8 bugs found and fixed. Each fix annotated with // FIX #N:
// =============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------------
// MOCK DEPENDENCIES (unchanged)
// ---------------------------------------------------------------------------

final di = _MockDI();

class _MockDI {
  T call<T>() => throw UnimplementedError('Mock DI');
}

class ZegoService {
  Stream<Map<String, dynamic>> getCommandStream() =>
      Stream.periodic(const Duration(seconds: 5), (i) => {'type': 'ping'});

  Stream<Map<String, dynamic>> getMessageStream() =>
      Stream.periodic(const Duration(seconds: 3), (i) => {'msg': 'hello $i'});

  Stream<Map<String, dynamic>> getUserJoinStream() =>
      Stream.periodic(const Duration(seconds: 10), (i) => {'user': 'user_$i'});
}

final zegoService = ZegoService();

final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

class RoomState extends Equatable {
  final String roomMode;
  final bool isCommentLocked;
  final List<String> messages;
  final int seatCount;
  final bool isLoading;

  const RoomState({
    this.roomMode = 'normal',
    this.isCommentLocked = false,
    this.messages = const [],
    this.seatCount = 8,
    this.isLoading = false,
  });

  RoomState copyWith({
    String? roomMode,
    bool? isCommentLocked,
    List<String>? messages,
    int? seatCount,
    bool? isLoading,
  }) =>
      RoomState(
        roomMode: roomMode ?? this.roomMode,
        isCommentLocked: isCommentLocked ?? this.isCommentLocked,
        messages: messages ?? this.messages,
        seatCount: seatCount ?? this.seatCount,
        isLoading: isLoading ?? this.isLoading,
      );

  @override
  List<Object?> get props =>
      [roomMode, isCommentLocked, messages, seatCount, isLoading];
}

class RoomEvent extends Equatable {
  const RoomEvent();
  @override
  List<Object?> get props => [];
}

class UpdateModeEvent extends RoomEvent {
  final String mode;
  const UpdateModeEvent(this.mode);
}

class AddMessageEvent extends RoomEvent {
  final String message;
  const AddMessageEvent(this.message);
}

class RoomBloc extends Bloc<RoomEvent, RoomState> {
  RoomBloc() : super(const RoomState()) {
    on<UpdateModeEvent>((event, emit) {
      emit(state.copyWith(roomMode: event.mode));
    });
    on<AddMessageEvent>((event, emit) {
      emit(state.copyWith(
        messages: [...state.messages, event.message],
      ));
    });
  }
}

class BannerState extends Equatable {
  final Map<String, dynamic>? activeBanner;
  final bool isVisible;

  const BannerState({this.activeBanner, this.isVisible = false});

  BannerState copyWith({
    Map<String, dynamic>? activeBanner,
    bool? isVisible,
  }) =>
      BannerState(
        activeBanner: activeBanner ?? this.activeBanner,
        isVisible: isVisible ?? this.isVisible,
      );

  @override
  List<Object?> get props => [activeBanner, isVisible];
}

class BannerEvent extends Equatable {
  const BannerEvent();
  @override
  List<Object?> get props => [];
}

class BannerBloc extends Bloc<BannerEvent, BannerState> {
  BannerBloc() : super(const BannerState());
}

// ---------------------------------------------------------------------------
// FIXED SCREEN
// ---------------------------------------------------------------------------

class RoomScreenMini extends StatefulWidget {
  final int roomId;
  final bool isLocked;

  // FIX #1 (partial): const constructor added — widget is now const-eligible
  // when values are known at compile time, reducing unnecessary rebuilds.
  const RoomScreenMini({super.key, required this.roomId, this.isLocked = false});

  @override
  State<RoomScreenMini> createState() => _RoomScreenMiniState();
}

class _RoomScreenMiniState extends State<RoomScreenMini>
    with WidgetsBindingObserver {
  // FIX #7: Changed from static to instance fields.
  // Static mutable maps are shared across ALL instances of this widget —
  // opening a second room overwrites the first room's seat keys and user IDs,
  // causing ghost keys and incorrect seat-to-user mappings.
  final Map<String, GlobalKey> seatKeys = {};
  final Map<int, String> seatUserIds = {};

  final RoomBloc _roomBloc = RoomBloc();
  final BannerBloc _bannerBloc = BannerBloc();

  final List<StreamSubscription<dynamic>?> _subscriptions = [];
  late final ScrollController _chatScrollController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chatScrollController = ScrollController();

    _initializeSubscriptions();
    _loadRoomData();
  }

  void _initializeSubscriptions() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscriptions
        // FIX #3: Message stream listener now processes incoming events.
        // An empty listener silently discards all messages — users never see
        // chat, and the subscription still holds resources without doing work.
        ..add(zegoService.getMessageStream().listen((event) {
          final msg = event['msg'];
          if (msg != null) _roomBloc.add(AddMessageEvent(msg.toString()));
        }))
        ..add(zegoService.getCommandStream().listen(_onCommandReceived))
        ..add(zegoService.getUserJoinStream().listen(_onUserJoined));
    });
  }

  Future<void> _loadRoomData() async {
    await Future.delayed(const Duration(seconds: 2));

    // FIX #1: Guard setState with mounted check before calling after async gap.
    // Without this, if the widget is disposed during the delay (e.g. user
    // navigates away), setState throws a "called after dispose" exception.
    if (!mounted) return;
    setState(() {
      seatKeys.clear();
      for (int i = 0; i < 8; i++) {
        seatKeys['seat_$i'] = GlobalKey();
      }
    });
  }

  void _onCommandReceived(Map<String, dynamic> data) {
    try {
      final String type = data['type'] ?? '';
      switch (type) {
        case 'mode_change':
          _roomBloc.add(UpdateModeEvent(data['mode'] ?? 'normal'));
          break;
        case 'ban_user':
          // FIX #5: Null-check navKey.currentState before accessing its context.
          // The GlobalKey may not yet be attached (e.g. during startup or after
          // hot restart), causing a null-dereference crash on force-unwrap (!).
          final nav = navKey.currentState;
          if (nav != null) {
            Navigator.popUntil(nav.context, (route) => route.isFirst);
          }
          break;
        case 'lock_comments':
          _roomBloc.add(const UpdateModeEvent('locked'));
          break;
      }
    } catch (e) {
      if (kDebugMode) print('Error: $e');
    }
  }

  void _onUserJoined(Map<String, dynamic> data) {
    _roomBloc.add(AddMessageEvent('${data['user']} joined the room'));
  }

  // FIX #8: Removed async from didChangeAppLifecycleState override.
  // The framework signature is `void` — marking it `async` silently converts
  // it to return a `Future<void>` that the framework ignores entirely. Any
  // exception thrown inside an async void is unhandled and swallowed.
  // Fire-and-forget async work should be delegated to a separate method.
  //This means that any exception within the async function will be ignored, and there's no way to track it.
  //Solution: Leave the override void as normal, and if you need to implement async, execute the function in a separate location (like _stopCamera() and _resumeCamera()).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed) {
      _resumeCamera();
    }
  }

  Future<void> _stopCamera() async {
    await Future.delayed(const Duration(milliseconds: 100));
    debugPrint('Camera stopped');
  }

  Future<void> _resumeCamera() async {
    await Future.delayed(const Duration(milliseconds: 100));
    debugPrint('Camera resumed');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // FIX #4: Cancel ALL subscriptions, not just the first two.
    // The third subscription (getUserJoinStream) was left running after dispose,
    // causing it to fire callbacks on a dead widget — a classic memory leak
    // and a source of "setState called after dispose" errors.
    for (final sub in _subscriptions) {
      sub?.cancel();
    }

    _chatScrollController.dispose();
    _roomBloc.close();
    _bannerBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // --- App Bar ---
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Room'),
              background: Container(color: Colors.purple.shade900),
            ),
          ),

          // --- Room Mode Banner ---
          SliverToBoxAdapter(
            child: BlocBuilder<RoomBloc, RoomState>(
              bloc: _roomBloc,
              // FIX #6: buildWhen scoped to each builder's relevant field.
              // Without buildWhen, every BlocBuilder here rebuilds on ANY state
              // change — a new chat message triggers a full mode-banner rebuild,
              // a seat-count change triggers a chat-list rebuild, etc.
              // Each builder now only runs when its own data actually changes.
              buildWhen: (prev, curr) => prev.roomMode != curr.roomMode,
              builder: (context, state) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  color: state.roomMode == 'locked'
                      ? Colors.red.shade100
                      : Colors.green.shade100,
                  child: Text('Mode: ${state.roomMode}'),
                );
              },
            ),
          ),

          // --- Seat Grid ---
          // FIX #2: Replaced shrinkWrap GridView inside CustomScrollView with
          // SliverGrid. shrinkWrap forces ALL grid children to be laid out
          // eagerly (defeating virtualization) and causes double-layout because
          // the CustomScrollView also measures it. SliverGrid integrates
          // natively and stays lazy.
          SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person, color: Colors.grey),
                        const SizedBox(height: 4),
                        Text(
                          'Seat ${index + 1}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              },
              // Drive itemCount from bloc state so it reacts to seatCount changes
              childCount: _roomBloc.state.seatCount,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
          ),

          // --- Banner Section ---
          SliverToBoxAdapter(
            child: BlocBuilder<BannerBloc, BannerState>(
              bloc: _bannerBloc,
              // FIX #6 (continued): banner rebuilds only when visibility or
              // content changes, not on every RoomBloc message event.
              buildWhen: (prev, curr) =>
                  prev.isVisible != curr.isVisible ||
                  prev.activeBanner != curr.activeBanner,
              builder: (context, state) {
                if (!state.isVisible) return const SizedBox.shrink();
                return Container(
                  height: 60,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.amber, Colors.orange],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      state.activeBanner?['text'] ?? 'Special Event!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // --- Chat Messages ---
          SliverToBoxAdapter(
            child: BlocBuilder<RoomBloc, RoomState>(
              bloc: _roomBloc,
              // FIX #6 (continued): chat list rebuilds only when the messages
              // list changes, not on roomMode or seatCount updates.
              buildWhen: (prev, curr) => prev.messages != curr.messages,
              builder: (context, state) {
                return SizedBox(
                  height: 300,
                  child: ListView.separated(
                    controller: _chatScrollController,
                    itemCount: state.messages.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Text(
                          state.messages[index],
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // --- Bottom Action Bar ---
      bottomNavigationBar: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: const Icon(Icons.mic), onPressed: () {}),
            IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: () {}),
            IconButton(icon: const Icon(Icons.card_giftcard), onPressed: () {}),
            IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
