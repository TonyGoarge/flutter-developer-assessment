// =============================================================================
// EXERCISE 3: Debugging & Refactoring — "Room Screen Mini"
// Time: 30 minutes
// =============================================================================
//
// SCENARIO:
// This is a simplified version of a room screen from a live-streaming app.
// It was hastily written and contains multiple bugs and anti-patterns.
//
// TASK:
// Find ALL bugs (there are 8), fix each one, and write a 1-line comment
// explaining why each fix is necessary.
//
// HINT: Bugs span categories including state management, memory management,
// lifecycle handling, performance, and null safety.
//
// SCORING:
// - 2 points per bug found and fixed correctly
// - 0.5 bonus points per high-quality explanation
// - Maximum: 20 points
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------------
// MOCK DEPENDENCIES (do not modify)
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

// Mock BLoC classes
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
// THE BUGGY SCREEN (find and fix all 8 bugs)
// ---------------------------------------------------------------------------

class RoomScreenMini extends StatefulWidget {
  final int roomId;
  final bool isLocked;

  // ignore: missing const constructor for now
  RoomScreenMini({required this.roomId, this.isLocked = false});

  @override
  State<RoomScreenMini> createState() => _RoomScreenMiniState();
}

class _RoomScreenMiniState extends State<RoomScreenMini>
    with WidgetsBindingObserver {
  // ═══════════════════════════════════════════════════════════════════════════
  // BUG #7: Static mutable map used as instance state
  // ═══════════════════════════════════════════════════════════════════════════
  static Map<String, GlobalKey> seatKeys = {};
  static Map<int, String> seatUserIds = {};

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
        // ═════════════════════════════════════════════════════════════════════
        // BUG #3: Empty stream listener — subscription created but does nothing
        // ═════════════════════════════════════════════════════════════════════
        ..add(zegoService.getMessageStream().listen((event) {}))
        ..add(zegoService.getCommandStream().listen(_onCommandReceived))
        ..add(zegoService.getUserJoinStream().listen(_onUserJoined));
    });
  }

  Future<void> _loadRoomData() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    // ═══════════════════════════════════════════════════════════════════════════
    // BUG #1: setState called after async gap without mounted check
    // ═══════════════════════════════════════════════════════════════════════════
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
          // ═════════════════════════════════════════════════════════════════════
          // BUG #5: Force-unwrap navigator without null check
          // ═════════════════════════════════════════════════════════════════════
          Navigator.popUntil(
            navKey.currentState!.context,
            (route) => route.isFirst,
          );
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

  // ═══════════════════════════════════════════════════════════════════════════
  // BUG #8: Async lifecycle override returning void
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      // Simulate stopping camera/mic
      await Future.delayed(const Duration(milliseconds: 100));
      debugPrint('Camera stopped');
    } else if (state == AppLifecycleState.resumed) {
      // Simulate restarting camera/mic
      await Future.delayed(const Duration(milliseconds: 100));
      debugPrint('Camera resumed');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // ═══════════════════════════════════════════════════════════════════════════
    // BUG #4: Only cancelling first 2 subscriptions, missing the 3rd
    // ═══════════════════════════════════════════════════════════════════════════
    if (_subscriptions.length >= 2) {
      _subscriptions[0]?.cancel();
      _subscriptions[1]?.cancel();
      // Missing: _subscriptions[2]?.cancel();
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
            // ═════════════════════════════════════════════════════════════════
            // BUG #6: BlocBuilder without buildWhen — rebuilds on every state
            // ═════════════════════════════════════════════════════════════════
            child: BlocBuilder<RoomBloc, RoomState>(
              bloc: _roomBloc,
              // Missing: buildWhen: (prev, curr) => prev.roomMode != curr.roomMode,
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
          SliverToBoxAdapter(
            child: BlocBuilder<RoomBloc, RoomState>(
              bloc: _roomBloc,
              // Missing buildWhen here too
              builder: (context, state) {
                return GridView.builder(
                  // ═══════════════════════════════════════════════════════════
                  // BUG #2: shrinkWrap inside CustomScrollView — forces all
                  // children to be laid out at once, defeating lazy rendering
                  // ═══════════════════════════════════════════════════════════
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: state.seatCount,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person, color: Colors.grey),
                            SizedBox(height: 4),
                            Text(
                              'Seat ${index + 1}',
                              style: TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // --- Banner Section ---
          SliverToBoxAdapter(
            child: BlocBuilder<BannerBloc, BannerState>(
              bloc: _bannerBloc,
              // Missing buildWhen
              builder: (context, state) {
                if (!state.isVisible) return const SizedBox.shrink();
                return Container(
                  height: 60,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber, Colors.orange],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      state.activeBanner?['text'] ?? 'Special Event!',
                      style: TextStyle(
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
              // Missing buildWhen
              builder: (context, state) {
                return Container(
                  height: 300,
                  child: ListView.separated(
                    controller: _chatScrollController,
                    // Performance issue: shrinkWrap not needed here since
                    // parent container has fixed height, but it's still bad
                    // practice to leave it (it's not present here though)
                    itemCount: state.messages.length,
                    separatorBuilder: (_, __) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Text(
                          state.messages[index],
                          style: TextStyle(fontSize: 13),
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
        decoration: BoxDecoration(
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
            IconButton(
              icon: Icon(Icons.mic),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.chat_bubble_outline),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.card_giftcard),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.more_horiz),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
