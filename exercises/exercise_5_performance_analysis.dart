// =============================================================================
// EXERCISE 5: Performance Analysis — "Widget Rebuild Audit"
// Time: 30 minutes
// =============================================================================
//
// SCENARIO:
// You've been asked to audit the main layout of a live-streaming app for
// performance issues. The widget tree below is causing dropped frames and
// excessive rebuilds on mid-range devices.
//
// TASKS:
// 1. [All Levels] Identify all performance issues in the code below
// 2. [All Levels] Rank each issue by impact: HIGH / MEDIUM / LOW
// 3. [All Levels] Write the fix for each issue (inline code)
// 4. [Senior Bonus] Propose migration from static routes map to onGenerateRoute
// 5. [Senior Bonus] How would you split HomeState (50+ fields) into sub-states?
//
// FORMAT:
// For each issue found, write:
//   ISSUE #N: [Description]
//   IMPACT: HIGH / MEDIUM / LOW
//   WHY: [1-line explanation]
//   FIX: [Code snippet]
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------------
// MOCK TYPES (do not modify)
// ---------------------------------------------------------------------------

final di = _MockDI();
class _MockDI { T call<T>() => throw UnimplementedError(); }

// Mock BLoCs
class FetchUserDataState extends Equatable {
  final Map<String, dynamic>? bannerData;
  final dynamic userEntity;
  final bool isOnline;
  final int unreadCount;
  final String? walletBalance;

  const FetchUserDataState({
    this.bannerData,
    this.userEntity,
    this.isOnline = false,
    this.unreadCount = 0,
    this.walletBalance,
  });

  @override
  List<Object?> get props =>
      [bannerData, userEntity, isOnline, unreadCount, walletBalance];
}

class FetchUserDataEvent {}
class FetchUserDataBloc extends Bloc<FetchUserDataEvent, FetchUserDataState> {
  FetchUserDataBloc() : super(const FetchUserDataState());
}

class LayoutState extends Equatable {
  final int currentIndex;
  final bool showBanner;
  const LayoutState({this.currentIndex = 0, this.showBanner = false});
  @override
  List<Object?> get props => [currentIndex, showBanner];
}

class LayoutEvent {}
class LayoutBloc extends Bloc<LayoutEvent, LayoutState> {
  LayoutBloc() : super(const LayoutState());
}

class HomeState extends Equatable {
  // This state has 50+ fields in the real codebase
  final int currentTabIndex;
  final List<dynamic> popularRooms;
  final List<dynamic> liveRooms;
  final List<dynamic> followRooms;
  final List<dynamic> friendsRooms;
  final List<dynamic> lastCreateRooms;
  final List<dynamic> filteredRooms;
  final List<dynamic> globalRooms;
  final int popularCurrentPage;
  final int liveCurrentPage;
  final int globalCurrentPage;
  final int followCurrentPage;
  final int friendsCurrentPage;
  // ... imagine 35+ more fields

  const HomeState({
    this.currentTabIndex = 0,
    this.popularRooms = const [],
    this.liveRooms = const [],
    this.followRooms = const [],
    this.friendsRooms = const [],
    this.lastCreateRooms = const [],
    this.filteredRooms = const [],
    this.globalRooms = const [],
    this.popularCurrentPage = 1,
    this.liveCurrentPage = 1,
    this.globalCurrentPage = 1,
    this.followCurrentPage = 1,
    this.friendsCurrentPage = 1,
  });

  @override
  List<Object?> get props => [
        currentTabIndex, popularRooms, liveRooms, followRooms,
        friendsRooms, lastCreateRooms, filteredRooms, globalRooms,
        popularCurrentPage, liveCurrentPage, globalCurrentPage,
        followCurrentPage, friendsCurrentPage,
      ];
}

class HomeEvent {}
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeState());
}

// Mock pages
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});
  @override Widget build(BuildContext context) => const Placeholder();
}
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override Widget build(BuildContext context) => const Placeholder();
}
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});
  @override Widget build(BuildContext context) => const Placeholder();
}
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override Widget build(BuildContext context) => const Placeholder();
}
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override Widget build(BuildContext context) => const Placeholder();
}
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override Widget build(BuildContext context) => const Placeholder();
}
class RoomPage extends StatelessWidget {
  const RoomPage({super.key});
  @override Widget build(BuildContext context) => const Placeholder();
}
class ChatPage extends StatelessWidget {
  const ChatPage({super.key});
  @override Widget build(BuildContext context) => const Placeholder();
}
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});
  @override Widget build(BuildContext context) => const Placeholder();
}
class ReelsPage extends StatelessWidget {
  const ReelsPage({super.key});
  @override Widget build(BuildContext context) => const Placeholder();
}
class SplashBloc extends Bloc<dynamic, dynamic> { SplashBloc() : super(null); }
class ConfigAppBloc extends Bloc<dynamic, dynamic> { ConfigAppBloc() : super(null); }
class ColorsBloc extends Bloc<dynamic, dynamic> { ColorsBloc() : super(null); }
class LoginBloc extends Bloc<dynamic, dynamic> { LoginBloc() : super(null); }
class RegisterBloc extends Bloc<dynamic, dynamic> { RegisterBloc() : super(null); }
class SearchBloc extends Bloc<dynamic, dynamic> { SearchBloc() : super(null); }
class ReelsBloc extends Bloc<dynamic, dynamic> { ReelsBloc() : super(null); }
class ChatBloc extends Bloc<dynamic, dynamic> { ChatBloc() : super(null); }
class RoomBloc extends Bloc<dynamic, dynamic> { RoomBloc() : super(null); }
class ProfileBloc extends Bloc<dynamic, dynamic> { ProfileBloc() : super(null); }

// Mock SVGA widget (heavy animation renderer)
class ShowSVGA extends StatelessWidget {
  final String svgaAssetPath;
  final bool isNeedToRepeat;
  final double height;
  final double width;

  const ShowSVGA({
    super.key,
    required this.svgaAssetPath,
    this.isNeedToRepeat = false,
    this.height = 35,
    this.width = 35,
  });

  @override
  Widget build(BuildContext context) {
    // In real app: loads SVGA binary, creates custom painter,
    // renders animation frames using a ticker
    return SizedBox(height: height, width: width, child: const Placeholder());
  }
}

// ---------------------------------------------------------------------------
// PERFORMANCE ISSUES TO FIND (audit this code)
// ---------------------------------------------------------------------------

/// ════════════════════════════════════════════════════════════════════════════
/// AREA 1: Main Layout — Widget Rebuild Hotspot
/// ════════════════════════════════════════════════════════════════════════════

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder at root — rebuilds everything on stream events
    return StreamBuilder<bool>(
      stream: Stream.periodic(const Duration(seconds: 30), (_) => true),
      builder: (context, snapshot) {
        return Stack(
          children: [
            // --- Banner Layer 1: Gift Banner ---
            // ISSUE: BlocBuilder without buildWhen
            BlocBuilder<FetchUserDataBloc, FetchUserDataState>(
              bloc: di<FetchUserDataBloc>(),
              builder: (_, state) {
                final data = state.bannerData?["gift"];
                if (data == null) return SizedBox();
                return Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 80,
                    color: Colors.amber.withOpacity(0.9),
                    child: Center(child: Text('Gift Banner')),
                  ),
                );
              },
            ),

            // --- Banner Layer 2: Game Banner ---
            // ISSUE: ANOTHER BlocBuilder on same BLoC, no buildWhen
            BlocBuilder<FetchUserDataBloc, FetchUserDataState>(
              bloc: di<FetchUserDataBloc>(),
              builder: (_, state) {
                final data = state.bannerData?["game"];
                if (data == null) return SizedBox();
                return Positioned(
                  top: 80,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    color: Colors.blue.withOpacity(0.9),
                    child: Center(child: Text('Game Banner')),
                  ),
                );
              },
            ),

            // --- Banner Layer 3: Lucky Banner ---
            // ISSUE: Yet another BlocBuilder on same BLoC
            BlocBuilder<FetchUserDataBloc, FetchUserDataState>(
              bloc: di<FetchUserDataBloc>(),
              builder: (_, state) {
                final data = state.bannerData?["lucky"];
                if (data == null) return SizedBox();
                return Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    color: Colors.green.withOpacity(0.9),
                    child: Center(child: Text('Lucky Banner')),
                  ),
                );
              },
            ),

            // --- Online Badge ---
            // ISSUE: BlocBuilder for single boolean, no buildWhen
            BlocBuilder<FetchUserDataBloc, FetchUserDataState>(
              bloc: di<FetchUserDataBloc>(),
              builder: (_, state) {
                if (!state.isOnline) return SizedBox();
                return Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),

            // --- Layout Body ---
            BlocBuilder<LayoutBloc, LayoutState>(
              bloc: di<LayoutBloc>(),
              // ISSUE: No buildWhen
              builder: (context, layoutState) {
                return IndexedStack(
                  index: layoutState.currentIndex,
                  children: [
                    _buildHomePage(),
                    ChatPage(),
                    ProfilePage(),
                    SettingsPage(),
                  ],
                );
              },
            ),

            // --- Unread Counter ---
            // ISSUE: Two nested BlocBuilders, no buildWhen on either
            BlocBuilder<FetchUserDataBloc, FetchUserDataState>(
              bloc: di<FetchUserDataBloc>(),
              builder: (_, userState) {
                return BlocBuilder<LayoutBloc, LayoutState>(
                  bloc: di<LayoutBloc>(),
                  builder: (_, layoutState) {
                    if (layoutState.currentIndex != 1) return SizedBox();
                    return Positioned(
                      bottom: 70,
                      right: 20,
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${userState.unreadCount}',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // --- Wallet Display ---
            ValueListenableBuilder<String>(
              valueListenable: ValueNotifier<String>('0'),
              builder: (_, value, __) {
                return Positioned(
                  top: 50,
                  right: 10,
                  child: Text('💰 $value'),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildHomePage() {
    // ISSUE: BlocBuilder wraps ENTIRE TabBarView
    return BlocBuilder<HomeBloc, HomeState>(
      bloc: di<HomeBloc>(),
      // No buildWhen — rebuilds ALL tabs when ANY HomeState field changes
      builder: (context, state) {
        return Column(
          children: [
            // Tab bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton(
                  onPressed: () {},
                  child: Text('Popular',
                      style: TextStyle(
                        fontWeight: state.currentTabIndex == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      )),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text('Live'),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text('Following'),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text('Friends'),
                ),
              ],
            ),
            // Tab content — ALL tabs rebuild when any state changes
            Expanded(
              child: IndexedStack(
                index: state.currentTabIndex,
                children: [
                  // Each of these rebuilds even when only popularRooms changed
                  ListView.builder(
                    itemCount: state.popularRooms.length,
                    itemBuilder: (_, i) => ListTile(title: Text('Popular $i')),
                  ),
                  ListView.builder(
                    itemCount: state.liveRooms.length,
                    itemBuilder: (_, i) => ListTile(title: Text('Live $i')),
                  ),
                  ListView.builder(
                    itemCount: state.followRooms.length,
                    itemBuilder: (_, i) => ListTile(title: Text('Following $i')),
                  ),
                  ListView.builder(
                    itemCount: state.friendsRooms.length,
                    itemBuilder: (_, i) => ListTile(title: Text('Friends $i')),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// ════════════════════════════════════════════════════════════════════════════
/// AREA 2: Bottom Navigation — Heavy Animation Usage
/// ════════════════════════════════════════════════════════════════════════════

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          // ISSUE: SVGA animation for simple tab icon — heavy CPU/memory
          icon: Image.asset('assets/icons/home.png', height: 28, width: 28),
          activeIcon: ShowSVGA(
            svgaAssetPath: 'assets/svga/home_active.svga',
            isNeedToRepeat: false,
            height: 35,
            width: 35,
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('assets/icons/chat.png', height: 28, width: 28),
          activeIcon: ShowSVGA(
            svgaAssetPath: 'assets/svga/chat_active.svga',
            isNeedToRepeat: false,
            height: 35,
            width: 35,
          ),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('assets/icons/profile.png', height: 28, width: 28),
          activeIcon: ShowSVGA(
            svgaAssetPath: 'assets/svga/profile_active.svga',
            isNeedToRepeat: false,
            height: 35,
            width: 35,
          ),
          label: 'Profile',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('assets/icons/settings.png', height: 28, width: 28),
          activeIcon: ShowSVGA(
            svgaAssetPath: 'assets/svga/settings_active.svga',
            isNeedToRepeat: false,
            height: 35,
            width: 35,
          ),
          label: 'Settings',
        ),
      ],
    );
  }
}

/// ════════════════════════════════════════════════════════════════════════════
/// AREA 3: Static Routes Map
/// ════════════════════════════════════════════════════════════════════════════

class Routes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const profile = '/profile';
  static const settings = '/settings';
  static const room = '/room';
  static const chat = '/chat';
  static const search = '/search';
  static const reels = '/reels';

  // ISSUE: Static map holds all route closures in memory permanently.
  // Each closure captures the DI container and BlocProvider creation.
  static Map<String, Widget Function(BuildContext)> routes = {
    splash: (context) {
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(value: di<SplashBloc>()),
          BlocProvider.value(value: di<ConfigAppBloc>()),
          BlocProvider.value(value: di<ColorsBloc>()),
        ],
        child: SplashPage(),
      );
    },
    login: (context) {
      return BlocProvider.value(
        value: di<LoginBloc>(),
        child: LoginPage(),
      );
    },
    register: (context) {
      return BlocProvider.value(
        value: di<RegisterBloc>(),
        child: RegisterPage(),
      );
    },
    home: (context) {
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(value: di<HomeBloc>()),
          BlocProvider.value(value: di<FetchUserDataBloc>()),
        ],
        child: HomePage(),
      );
    },
    profile: (context) {
      return BlocProvider.value(
        value: di<ProfileBloc>(),
        child: ProfilePage(),
      );
    },
    settings: (context) {
      return SettingsPage();
    },
    room: (context) {
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(value: di<RoomBloc>()),
          BlocProvider.value(value: di<FetchUserDataBloc>()),
        ],
        child: RoomPage(),
      );
    },
    chat: (context) {
      return BlocProvider.value(
        value: di<ChatBloc>(),
        child: ChatPage(),
      );
    },
    search: (context) {
      return BlocProvider.value(
        value: di<SearchBloc>(),
        child: SearchPage(),
      );
    },
    reels: (context) {
      return BlocProvider.value(
        value: di<ReelsBloc>(),
        child: ReelsPage(),
      );
    },
    // In the real app, there are 100+ more routes here...
  };
}

/// ════════════════════════════════════════════════════════════════════════════
/// AREA 4: Miscellaneous Anti-patterns
/// ════════════════════════════════════════════════════════════════════════════

class MiscIssues {
  // ISSUE: ValueNotifier set twice in immediate succession — first value is wasted
  static ValueNotifier<bool> isKeepInRoom = ValueNotifier<bool>(false);

  static void onExitRoom() {
    isKeepInRoom.value = true;
    isKeepInRoom.value = false; // Immediately overwrites previous assignment
  }

  // ISSUE: Missing const on widgets that could be const
  static Widget buildDivider() {
    return SizedBox(height: 1); // Should be: const SizedBox(height: 1)
  }

  static Widget buildSpacer() {
    return Spacer(); // Should be: const Spacer()
  }

  static Widget buildEmpty() {
    return SizedBox.shrink(); // Should be: const SizedBox.shrink()
  }
}

// =============================================================================
// YOUR ANALYSIS
// =============================================================================

// List all issues found below:
//
// ISSUE #1:
// IMPACT:
// WHY:
// FIX:
//
// ISSUE #2:
// IMPACT:
// WHY:
// FIX:
//
// (continue for all issues found...)
//
//
// SENIOR BONUS #1: onGenerateRoute migration
// -------------------------------------------
// Write the onGenerateRoute method that replaces the static routes map:
//
//
//
// SENIOR BONUS #2: HomeState split proposal
// -------------------------------------------
// How would you split the 50+ field HomeState into focused sub-states?
// List the new states and what fields each would contain:
//
//
//
