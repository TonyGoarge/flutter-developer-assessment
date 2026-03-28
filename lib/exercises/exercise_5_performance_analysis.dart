// =============================================================================
// EXERCISE 5: Performance Analysis — "Widget Rebuild Audit" (FIXED)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------------
// MOCK TYPES (unchanged)
// ---------------------------------------------------------------------------

final di = _MockDI();
class _MockDI {
  final Map<Type, dynamic> _cache = {};
  T call<T>() {
    if (!_cache.containsKey(T)) {
      if (T == FetchUserDataBloc) _cache[T] = FetchUserDataBloc();
      if (T == LayoutBloc) _cache[T] = LayoutBloc();
      if (T == HomeBloc) _cache[T] = HomeBloc();
      if (T == SplashBloc) _cache[T] = SplashBloc();
      if (T == ConfigAppBloc) _cache[T] = ConfigAppBloc();
      if (T == ColorsBloc) _cache[T] = ColorsBloc();
      if (T == LoginBloc) _cache[T] = LoginBloc();
      if (T == RegisterBloc) _cache[T] = RegisterBloc();
      if (T == ProfileBloc) _cache[T] = ProfileBloc();
      if (T == RoomBloc) _cache[T] = RoomBloc();
      if (T == ChatBloc) _cache[T] = ChatBloc();
      if (T == SearchBloc) _cache[T] = SearchBloc();
      if (T == ReelsBloc) _cache[T] = ReelsBloc();
    }
    return _cache[T] as T;
  }
}

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

// ─── Senior Bonus: Split sub-states ─────────────────────────────────────────

/// ISSUE #10 FIX: HomeState split into focused sub-states.
/// Each BlocBuilder subscribes only to the sub-state it needs.

class HomeTabState extends Equatable {
  final int currentTabIndex;
  const HomeTabState({this.currentTabIndex = 0});
  @override
  List<Object?> get props => [currentTabIndex];
}

class PopularRoomsState extends Equatable {
  final List<dynamic> rooms;
  final int currentPage;
  const PopularRoomsState({this.rooms = const [], this.currentPage = 1});
  @override
  List<Object?> get props => [rooms, currentPage];
}

class LiveRoomsState extends Equatable {
  final List<dynamic> rooms;
  final int currentPage;
  const LiveRoomsState({this.rooms = const [], this.currentPage = 1});
  @override
  List<Object?> get props => [rooms, currentPage];
}

class FollowRoomsState extends Equatable {
  final List<dynamic> rooms;
  final int currentPage;
  const FollowRoomsState({this.rooms = const [], this.currentPage = 1});
  @override
  List<Object?> get props => [rooms, currentPage];
}

class FriendsRoomsState extends Equatable {
  final List<dynamic> rooms;
  final int currentPage;
  const FriendsRoomsState({this.rooms = const [], this.currentPage = 1});
  @override
  List<Object?> get props => [rooms, currentPage];
}

// Keeping one HomeBloc that composes the sub-states (or split into per-tab blocs)
class HomeState extends Equatable {
  final HomeTabState tab;
  final PopularRoomsState popular;
  final LiveRoomsState live;
  final FollowRoomsState follow;
  final FriendsRoomsState friends;
  // other sub-states (reels, moments, filters) added similarly

  const HomeState({
    this.tab = const HomeTabState(),
    this.popular = const PopularRoomsState(),
    this.live = const LiveRoomsState(),
    this.follow = const FollowRoomsState(),
    this.friends = const FriendsRoomsState(),
  });

  @override
  List<Object?> get props => [tab, popular, live, follow, friends];
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
    return SizedBox(height: height, width: width, child: const Placeholder());
  }
}

// =============================================================================
// FIXED IMPLEMENTATION
// =============================================================================

/// ════════════════════════════════════════════════════════════════════════════
/// AREA 1: Main Layout — Fixed
/// ════════════════════════════════════════════════════════════════════════════

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    // ISSUE #1 FIX: Removed StreamBuilder from root.
    // Periodic streams that don't affect the widget tree should not drive
    // rebuilds. If truly needed for a side effect, use initState + a timer.
    return Stack(
      children: [
        // ISSUE #2 FIX: Merged all FetchUserDataBloc builders into ONE.
        // A single BlocBuilder reads bannerData, isOnline, and unreadCount
        // together. Each child is extracted into a const-eligible widget
        // with RepaintBoundary to isolate repaints.
        BlocBuilder<FetchUserDataBloc, FetchUserDataState>(
          bloc: di<FetchUserDataBloc>(),
          // ISSUE #3 FIX: buildWhen scoped to only the fields this subtree uses.
          buildWhen: (prev, curr) =>
              prev.bannerData != curr.bannerData ||
              prev.isOnline != curr.isOnline ||
              prev.unreadCount != curr.unreadCount,
          builder: (_, userState) {
            return Stack(
              children: [
                // Gift Banner
                if (userState.bannerData?["gift"] != null)
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: RepaintBoundary(
                      child: Container(
                        height: 80,
                        // ignore: deprecated_member_use
                        color: Colors.amber.withValues(alpha: 0.9),
                        child: const Center(child: Text('Gift Banner')),
                      ),
                    ),
                  ),

                // Game Banner
                if (userState.bannerData?["game"] != null)
                  Positioned(
                    top: 80, left: 0, right: 0,
                    child: RepaintBoundary(
                      child: Container(
                        height: 60,
                        color: Colors.blue.withValues(alpha: 0.9),
                        child: const Center(child: Text('Game Banner')),
                      ),
                    ),
                  ),

                // Lucky Banner
                if (userState.bannerData?["lucky"] != null)
                  Positioned(
                    bottom: 100, left: 0, right: 0,
                    child: RepaintBoundary(
                      child: Container(
                        height: 60,
                        color: Colors.green.withValues(alpha: 0.9),
                        child: const Center(child: Text('Lucky Banner')),
                      ),
                    ),
                  ),

                // Online Badge
                if (userState.isOnline)
                  const Positioned(
                    top: 10, right: 10,
                    child: RepaintBoundary(
                      child: _OnlineBadge(),
                    ),
                  ),

                // Unread counter — nested BlocBuilder only for layout index
                BlocBuilder<LayoutBloc, LayoutState>(
                  bloc: di<LayoutBloc>(),
                  // ISSUE #4 FIX: buildWhen — only rebuild when tab index changes
                  buildWhen: (prev, curr) =>
                      prev.currentIndex != curr.currentIndex,
                  builder: (_, layoutState) {
                    if (layoutState.currentIndex != 1) return const SizedBox.shrink();
                    return Positioned(
                      bottom: 70, right: 20,
                      child: RepaintBoundary(
                        child: _UnreadBadge(count: userState.unreadCount),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),

        // Layout Body — separate BlocBuilder scoped to layout only
        BlocBuilder<LayoutBloc, LayoutState>(
          bloc: di<LayoutBloc>(),
          // ISSUE #4 FIX: buildWhen scoped to currentIndex — showBanner changes
          // do NOT need to rebuild the entire IndexedStack.
          buildWhen: (prev, curr) => prev.currentIndex != curr.currentIndex,
          builder: (context, layoutState) {
            return IndexedStack(
              index: layoutState.currentIndex,
              children: const [
                _HomePageWrapper(),
                ChatPage(),
                ProfilePage(),
                SettingsPage(),
              ],
            );
          },
        ),

        // ISSUE #5 FIX: Wallet — use BlocBuilder scoped to walletBalance
        // instead of a ValueNotifier that's never updated externally.
        BlocBuilder<FetchUserDataBloc, FetchUserDataState>(
          bloc: di<FetchUserDataBloc>(),
          buildWhen: (prev, curr) => prev.walletBalance != curr.walletBalance,
          builder: (_, state) {
            return Positioned(
              top: 50, right: 10,
              child: Text('💰 ${state.walletBalance ?? '0'}'),
            );
          },
        ),
      ],
    );
  }
}

// Extracted const-eligible widgets — ISSUE #6 FIX
class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12, height: 12,
      decoration: const BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;
  const _UnreadBadge({required this.count});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      child: Text(
        '$count',
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }
}

// ISSUE #7 FIX: Extracted home page into its own widget.
// Each tab now has its own BlocBuilder scoped to only its data fields,
// so popularRooms loading does NOT rebuild the Live or Friends tabs.
class _HomePageWrapper extends StatelessWidget {
  const _HomePageWrapper();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar — only needs currentTabIndex
        BlocBuilder<HomeBloc, HomeState>(
          bloc: di<HomeBloc>(),
          buildWhen: (prev, curr) => prev.tab.currentTabIndex != curr.tab.currentTabIndex,
          builder: (context, state) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton(
                  onPressed: () {},
                  child: Text('Popular',
                    style: TextStyle(
                      fontWeight: state.tab.currentTabIndex == 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                const TextButton(onPressed: null, child: Text('Live')),
                const TextButton(onPressed: null, child: Text('Following')),
                const TextButton(onPressed: null, child: Text('Friends')),
              ],
            );
          },
        ),

        // Tab content — each tab is its own BlocBuilder
        Expanded(
          child: BlocBuilder<HomeBloc, HomeState>(
            bloc: di<HomeBloc>(),
            buildWhen: (prev, curr) =>
                prev.tab.currentTabIndex != curr.tab.currentTabIndex,
            builder: (context, state) {
              return IndexedStack(
                index: state.tab.currentTabIndex,
                children: const [
                  _PopularTab(),
                  _LiveTab(),
                  _FollowTab(),
                  _FriendsTab(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PopularTab extends StatelessWidget {
  const _PopularTab();
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      bloc: di<HomeBloc>(),
      buildWhen: (prev, curr) => prev.popular != curr.popular,
      builder: (_, state) => ListView.builder(
        itemCount: state.popular.rooms.length,
        itemBuilder: (_, i) => ListTile(title: Text('Popular $i')),
      ),
    );
  }
}

class _LiveTab extends StatelessWidget {
  const _LiveTab();
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      bloc: di<HomeBloc>(),
      buildWhen: (prev, curr) => prev.live != curr.live,
      builder: (_, state) => ListView.builder(
        itemCount: state.live.rooms.length,
        itemBuilder: (_, i) => ListTile(title: Text('Live $i')),
      ),
    );
  }
}

class _FollowTab extends StatelessWidget {
  const _FollowTab();
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      bloc: di<HomeBloc>(),
      buildWhen: (prev, curr) => prev.follow != curr.follow,
      builder: (_, state) => ListView.builder(
        itemCount: state.follow.rooms.length,
        itemBuilder: (_, i) => ListTile(title: Text('Following $i')),
      ),
    );
  }
}

class _FriendsTab extends StatelessWidget {
  const _FriendsTab();
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      bloc: di<HomeBloc>(),
      buildWhen: (prev, curr) => prev.friends != curr.friends,
      builder: (_, state) => ListView.builder(
        itemCount: state.friends.rooms.length,
        itemBuilder: (_, i) => ListTile(title: Text('Friends $i')),
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════════════════════
/// AREA 2: Bottom Navigation — Fixed
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
    // ISSUE #8 FIX: SVGA only shown for the ACTIVE tab, and wrapped in
    // RepaintBoundary so its animation ticker doesn't invalidate the whole bar.
    // Inactive tabs use lightweight Image.asset — no animation overhead.
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: [
        _navItem(index: 0, label: 'Home',     asset: 'assets/icons/home.png',     svga: 'assets/svga/home_active.svga'),
        _navItem(index: 1, label: 'Chat',     asset: 'assets/icons/chat.png',     svga: 'assets/svga/chat_active.svga'),
        _navItem(index: 2, label: 'Profile',  asset: 'assets/icons/profile.png',  svga: 'assets/svga/profile_active.svga'),
        _navItem(index: 3, label: 'Settings', asset: 'assets/icons/settings.png', svga: 'assets/svga/settings_active.svga'),
      ],
    );
  }

  BottomNavigationBarItem _navItem({
    required int index,
    required String label,
    required String asset,
    required String svga,
  }) {
    return BottomNavigationBarItem(
      icon: Image.asset(asset, height: 28, width: 28),
      activeIcon: RepaintBoundary(
        // Only the active tab's SVGA ticks; others are not in the tree at all
        child: currentIndex == index
            ? ShowSVGA(svgaAssetPath: svga, height: 35, width: 35)
            : Image.asset(asset, height: 35, width: 35),
      ),
      label: label,
    );
  }
}

/// ════════════════════════════════════════════════════════════════════════════
/// AREA 3: Routes — onGenerateRoute (Senior Bonus #1)
/// ════════════════════════════════════════════════════════════════════════════

class Routes {
  static const splash    = '/';
  static const login     = '/login';
  static const register  = '/register';
  static const home      = '/home';
  static const profile   = '/profile';
  static const settings  = '/settings';
  static const room      = '/room';
  static const chat      = '/chat';
  static const search    = '/search';
  static const reels     = '/reels';

  // ISSUE #9 FIX: Replaced static Map with onGenerateRoute.
  // The map allocated closures for all 100+ routes at startup and held them
  // in memory forever. onGenerateRoute builds the widget only when navigated to.
  static Route<dynamic> onGenerateRoute(RouteSettings settings_) {

    Widget page;
    switch (settings_.name) {
      case splash:
        page = MultiBlocProvider(
          providers: [
            BlocProvider.value(value: di<SplashBloc>()),
            BlocProvider.value(value: di<ConfigAppBloc>()),
            BlocProvider.value(value: di<ColorsBloc>()),
          ],
          child: const SplashPage(),
        );
        break;

      case login:
        page = BlocProvider.value(
          value: di<LoginBloc>(),
          child: const LoginPage(),
        );
        break;

      case register:
        page = BlocProvider.value(
          value: di<RegisterBloc>(),
          child: const RegisterPage(),
        );
        break;

      case home:
        page = MultiBlocProvider(
          providers: [
            BlocProvider.value(value: di<HomeBloc>()),
            BlocProvider.value(value: di<FetchUserDataBloc>()),
          ],
          child: const HomePage(),
        );
        break;

      case profile:
        // Args can carry a userId for deep-link / push notification navigation
        page = BlocProvider.value(
          value: di<ProfileBloc>(),
          child: const ProfilePage(),
        );
        break;

      case settings:
        page = const SettingsPage();
        break;

      case room:
        page = MultiBlocProvider(
          providers: [
            BlocProvider.value(value: di<RoomBloc>()),
            BlocProvider.value(value: di<FetchUserDataBloc>()),
          ],
          child: const RoomPage(),
        );
        break;

      case chat:
        page = BlocProvider.value(
          value: di<ChatBloc>(),
          child: const ChatPage(),
        );
        break;

      case search:
        page = BlocProvider.value(
          value: di<SearchBloc>(),
          child: const SearchPage(),
        );
        break;

      case reels:
        page = BlocProvider.value(
          value: di<ReelsBloc>(),
          child: const ReelsPage(),
        );
        break;

      default:
        // Centralised 404 — much cleaner than a missing key in a Map
        page = Scaffold(
          body: Center(child: Text('No route defined for ${settings_.name}')),
        );
    }

    return MaterialPageRoute(builder: (_) => page, settings: settings_);
  }
}

/// ════════════════════════════════════════════════════════════════════════════
/// AREA 4: Misc Anti-patterns — Fixed
/// ════════════════════════════════════════════════════════════════════════════

class MiscIssues {
  static final ValueNotifier<bool> isKeepInRoom = ValueNotifier<bool>(false);

  static void onExitRoom() {
    // ISSUE #11 FIX: Set the final value directly — no need for intermediate true.
    // Setting true then immediately false fires two listener notifications for
    // no reason; only the false value is ever observed.
    isKeepInRoom.value = false;
  }

  // ISSUE #6 FIX: const on all stateless leaf widgets
  static Widget buildDivider() => const SizedBox(height: 1);
  static Widget buildSpacer()  => const Spacer();
  static Widget buildEmpty()   => const SizedBox.shrink();
}