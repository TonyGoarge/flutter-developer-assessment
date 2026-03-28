// =============================================================================
// EXERCISE 4: Architecture & DI — "Fix the Dependency Injection Service"
// FIXED & ANSWERED
// =============================================================================

// ignore_for_file: unused_field, unused_local_variable

class _GetIt {
  static final _GetIt instance = _GetIt();
  void registerSingleton<T extends Object>(T instance) {}
  void registerLazySingleton<T extends Object>(T Function() factoryFunc) {}
  void registerFactory<T extends Object>(T Function() factoryFunc,
      {String? instanceName}) {}
  T call<T extends Object>({String? instanceName}) =>
      throw UnimplementedError();
}

final di = _GetIt.instance;

// ---------------------------------------------------------------------------
// MOCK CLASSES (unchanged)
// ---------------------------------------------------------------------------

class DioFactory {}
class HiveManager {}
class SharedPreferences {}

class HomeRemoteDataSource { HomeRemoteDataSource(DioFactory dio); }
class MessagesRemoteDataSource { MessagesRemoteDataSource(DioFactory dio); }
class ProfileRemoteDataSource { ProfileRemoteDataSource(DioFactory dio); }
class PusherRemoteDataSource { PusherRemoteDataSource(dynamic pusher); }

class HomeRepository { HomeRepository(HomeRemoteDataSource ds); }
class MessagesRepository { MessagesRepository(MessagesRemoteDataSource ds); }
class ProfileRepository { ProfileRepository(ProfileRemoteDataSource ds); }
class PusherRepository { PusherRepository(PusherRemoteDataSource ds); }

class FetchRoomsUC { FetchRoomsUC(HomeRepository repo); }
class FetchLiveRoomsUC { FetchLiveRoomsUC(HomeRepository repo); }
class CreateRoomUC { CreateRoomUC(HomeRepository repo); }
class FetchMessagesUC { FetchMessagesUC(MessagesRepository repo); }
class SendMessageUC { SendMessageUC(MessagesRepository repo); }
class DeleteMessageUC { DeleteMessageUC(MessagesRepository repo); }
class FetchUserProfileUC { FetchUserProfileUC(ProfileRepository repo); }
class FetchMyProfileUC { FetchMyProfileUC(ProfileRepository repo); }
class UpdateProfileUC { UpdateProfileUC(ProfileRepository repo); }
class FetchGiftHistoryUC { FetchGiftHistoryUC(ProfileRepository repo); }
class FetchUserBadgesUC { FetchUserBadgesUC(ProfileRepository repo); }
class FetchMyBadgesUC { FetchMyBadgesUC(ProfileRepository repo); }
class FetchCpProfileUC { FetchCpProfileUC(ProfileRepository repo); }
class FetchUserRoomsUC { FetchUserRoomsUC(ProfileRepository repo); }
class FetchSupporterUC { FetchSupporterUC(ProfileRepository repo); }
class FetchUserIntroUC { FetchUserIntroUC(ProfileRepository repo); }
class FetchReelsUC { FetchReelsUC(HomeRepository repo); }
class LikeReelUC { LikeReelUC(HomeRepository repo); }
class ShareReelUC { ShareReelUC(HomeRepository repo); }
class ViewReelUC { ViewReelUC(HomeRepository repo); }
class FetchMomentsUC { FetchMomentsUC(HomeRepository repo); }
class InitPusherUC { InitPusherUC(PusherRepository repo); }
class SubscribeChatUC { SubscribeChatUC(PusherRepository repo); }
class SubscribeMessagesUC { SubscribeMessagesUC(PusherRepository repo); }
class ListenToBannersUC { ListenToBannersUC(PusherRepository repo); }
class ListenToGamesUC { ListenToGamesUC(PusherRepository repo); }
class SubscribeCounterUC { SubscribeCounterUC(PusherRepository repo); }
class FetchConfigUC { FetchConfigUC(HomeRepository repo); }
class FetchCountriesUC { FetchCountriesUC(HomeRepository repo); }
class UpdateFCMTokenUC { UpdateFCMTokenUC(ProfileRepository repo); }
class FetchLevelDataUC { FetchLevelDataUC(ProfileRepository repo); }
class InitAnalyticsUC { InitAnalyticsUC(HomeRepository repo); }
class FetchWalletUC { FetchWalletUC(ProfileRepository repo); }

class HomeBloc { HomeBloc(FetchRoomsUC uc1, FetchLiveRoomsUC uc2); }
class CreateRoomBloc { CreateRoomBloc(CreateRoomUC uc); }
class MessagesBloc { MessagesBloc(FetchMessagesUC uc, SendMessageUC uc2); }
class DeleteMessageBloc { DeleteMessageBloc(DeleteMessageUC uc); }
class GiftHistoryBloc { GiftHistoryBloc({required FetchGiftHistoryUC giftHistoryUseCase}); }
class GetBadgesBloc { GetBadgesBloc({required FetchUserBadgesUC getBadgesUseCase, required FetchMyBadgesUC getMyAllBadgeUC}); }
class UserBadgesBloc { UserBadgesBloc({required FetchUserBadgesUC uc}); }
class GetUserBadgesBloc { GetUserBadgesBloc({required FetchUserBadgesUC uc}); }
class CpProfileBloc { CpProfileBloc({required FetchCpProfileUC uc}); }
class GetUserRoomsBloc { GetUserRoomsBloc({required FetchUserRoomsUC uc}); }
class GetSupporterBloc { GetSupporterBloc({required FetchSupporterUC uc}); }
class GetUserIntroBloc { GetUserIntroBloc({required FetchUserIntroUC uc}); }
class GetReelsBloc { GetReelsBloc(FetchReelsUC uc1, LikeReelUC uc2, ShareReelUC uc3, ViewReelUC uc4); }
class ReelViewerBloc { ReelViewerBloc(ViewReelUC uc); }
class MomentBloc { MomentBloc(FetchMomentsUC uc); }

// ---------------------------------------------------------------------------
// SPLIT BLoCs replacing FetchUserDataBloc (Senior Q3b)
// ---------------------------------------------------------------------------

class UserProfileBloc {
  UserProfileBloc(FetchMyProfileUC uc1, FetchUserProfileUC uc2);
}

class RealTimeBloc {
  RealTimeBloc(
    InitPusherUC uc1,
    SubscribeChatUC uc2,
    SubscribeMessagesUC uc3,
    ListenToBannersUC uc4,
    ListenToGamesUC uc5,
    SubscribeCounterUC uc6,
  );
}

class AppConfigBloc {
  AppConfigBloc(FetchConfigUC uc1, FetchCountriesUC uc2);
}

class NotificationsBloc {
  NotificationsBloc(UpdateFCMTokenUC uc1, FetchUserBadgesUC uc2, FetchMyBadgesUC uc3);
}

class UserProgressBloc {
  UserProgressBloc(FetchLevelDataUC uc1, FetchWalletUC uc2);
}

// Analytics: no BLoC — stateless side-effect, called directly in main()
class AnalyticsService {
  AnalyticsService(InitAnalyticsUC uc);
  Future<void> init() async { /* fire and forget */ }
}

// =============================================================================
// REFACTORED DI SERVICE (Mid — Q2)
// Split into per-feature modules (Senior — Q3a)
// =============================================================================

class DependencyInjectionService {
  static Future<void> init() async {
    await _registerCore();
    await _registerHomeFeature();
    await _registerMessagesFeature();
    await _registerProfileFeature();
    await _registerRealtimeFeature();
    await _registerReelsFeature();
    await _registerMomentsFeature();
  }

  // ── Core: always eager — needed before anything else runs ──────────────────
  static Future<void> _registerCore() async {
    // registerSingleton (eager): DioFactory and HiveManager must exist
    // before any data source is constructed. They have no dependencies
    // themselves, so lazy init offers no benefit.
    di.registerSingleton<DioFactory>(DioFactory());
    di.registerSingleton<HiveManager>(HiveManager());

    // Analytics: fire-and-forget service, not a BLoC.
    // Registered as lazySingleton so it's only initialised once, on first use.
    di.registerLazySingleton(() => AnalyticsService(di()));
  }

  // ── Home feature ───────────────────────────────────────────────────────────
  static Future<void> _registerHomeFeature() async {
    // Data layer: lazySingleton — one HTTP client wrapper per feature is enough.
    di.registerLazySingleton<HomeRemoteDataSource>(
      () => HomeRemoteDataSource(di()),
    );
    di.registerLazySingleton<HomeRepository>(
      () => HomeRepository(di()),
    );

    // Use cases: lazySingleton — stateless, safe to share.
    di.registerLazySingleton(() => FetchRoomsUC(di()));
    di.registerLazySingleton(() => FetchLiveRoomsUC(di()));
    di.registerLazySingleton(() => CreateRoomUC(di()));
    di.registerLazySingleton(() => FetchConfigUC(di()));
    di.registerLazySingleton(() => FetchCountriesUC(di()));
    di.registerLazySingleton(() => InitAnalyticsUC(di()));

    // HomeBloc: lazySingleton — lives at the app root (bottom nav tab).
    // There's always exactly one home feed; sharing state is intentional.
    di.registerLazySingleton(() => HomeBloc(di(), di()));

    // CreateRoomBloc: factory — each room-creation flow needs a fresh state.
    // A singleton would carry over previous form errors/loading state.
    di.registerFactory(() => CreateRoomBloc(di()));

    // AppConfigBloc: lazySingleton — config and country list are app-wide,
    // fetched once at startup and read by many features.
    di.registerLazySingleton(() => AppConfigBloc(di(), di()));
  }

  // ── Messages feature ───────────────────────────────────────────────────────
  static Future<void> _registerMessagesFeature() async {
    di.registerLazySingleton<MessagesRemoteDataSource>(
      () => MessagesRemoteDataSource(di()),
    );
    di.registerLazySingleton<MessagesRepository>(
      () => MessagesRepository(di()),
    );

    di.registerLazySingleton(() => FetchMessagesUC(di()));
    di.registerLazySingleton(() => SendMessageUC(di()));
    di.registerLazySingleton(() => DeleteMessageUC(di()));

    // MessagesBloc: factory — each conversation screen is independent.
    // A singleton would cause two open chats to share (and corrupt) state.
    di.registerFactory(() => MessagesBloc(di(), di()));

    // DeleteMessageBloc: factory — short-lived confirmation action per message.
    di.registerFactory(() => DeleteMessageBloc(di()));
  }

  // ── Profile feature ────────────────────────────────────────────────────────
  static Future<void> _registerProfileFeature() async {
    di.registerLazySingleton<ProfileRemoteDataSource>(
      () => ProfileRemoteDataSource(di()),
    );
    di.registerLazySingleton<ProfileRepository>(
      () => ProfileRepository(di()),
    );

    // Use cases
    di.registerLazySingleton(() => FetchUserProfileUC(di()));
    di.registerLazySingleton(() => FetchMyProfileUC(di()));
    di.registerLazySingleton(() => UpdateProfileUC(di()));
    di.registerLazySingleton(() => FetchGiftHistoryUC(di()));
    di.registerLazySingleton(() => FetchUserBadgesUC(di()));
    di.registerLazySingleton(() => FetchMyBadgesUC(di()));
    di.registerLazySingleton(() => FetchCpProfileUC(di()));
    di.registerLazySingleton(() => FetchUserRoomsUC(di()));
    di.registerLazySingleton(() => FetchSupporterUC(di()));
    di.registerLazySingleton(() => FetchUserIntroUC(di()));
    di.registerLazySingleton(() => UpdateFCMTokenUC(di()));
    di.registerLazySingleton(() => FetchLevelDataUC(di()));
    di.registerLazySingleton(() => FetchWalletUC(di()));

    // UserProfileBloc: factory — viewing another user's profile opens a new
    // screen instance; each needs its own isolated state.
    di.registerFactory(() => UserProfileBloc(di(), di()));

    // GiftHistoryBloc: factory — opened per user visit, not shared globally.
    di.registerFactory(
      () => GiftHistoryBloc(giftHistoryUseCase: di()),
    );

    // FIX: GetBadgesBloc, UserBadgesBloc, GetUserBadgesBloc all represent
    // the same concern (badge display). Keeping all three suggests unfinished
    // consolidation. Registered as factory — shown per user profile screen.
    di.registerFactory(
      () => GetBadgesBloc(getBadgesUseCase: di(), getMyAllBadgeUC: di()),
    );
    di.registerFactory(() => UserBadgesBloc(uc: di()));
    di.registerFactory(() => GetUserBadgesBloc(uc: di()));

    // CpProfileBloc: factory — CP (content provider?) profile is a drill-down
    // screen, not a persistent global concept.
    di.registerFactory(() => CpProfileBloc(uc: di()));

    // GetUserRoomsBloc, GetSupporterBloc, GetUserIntroBloc: factory —
    // all are profile sub-sections loaded on demand per user.
    di.registerFactory(() => GetUserRoomsBloc(uc: di()));
    di.registerFactory(() => GetSupporterBloc(uc: di()));
    di.registerFactory(() => GetUserIntroBloc(uc: di()));

    // NotificationsBloc: lazySingleton — FCM token and badge count are
    // app-wide concerns; one instance handles all push notification updates.
    di.registerLazySingleton(
      () => NotificationsBloc(di(), di(), di()),
    );

    // UserProgressBloc: lazySingleton — level/XP/wallet shown in the
    // persistent header; must stay alive across navigation.
    di.registerLazySingleton(() => UserProgressBloc(di(), di()));
  }

  // ── Real-time / Pusher feature ─────────────────────────────────────────────
  static Future<void> _registerRealtimeFeature() async {
    di.registerLazySingleton<PusherRemoteDataSource>(
      () => PusherRemoteDataSource(null /* pusher client */),
    );
    di.registerLazySingleton<PusherRepository>(
      () => PusherRepository(di()),
    );

    di.registerLazySingleton(() => InitPusherUC(di()));
    di.registerLazySingleton(() => SubscribeChatUC(di()));
    di.registerLazySingleton(() => SubscribeMessagesUC(di()));
    di.registerLazySingleton(() => ListenToBannersUC(di()));
    di.registerLazySingleton(() => ListenToGamesUC(di()));
    di.registerLazySingleton(() => SubscribeCounterUC(di()));

    // RealTimeBloc: lazySingleton — WebSocket connections are app-wide and
    // must not be duplicated. Creating a second instance would open a second
    // Pusher connection and duplicate all incoming events.
    di.registerLazySingleton(
      () => RealTimeBloc(di(), di(), di(), di(), di(), di()),
    );
  }

  // ── Reels feature ──────────────────────────────────────────────────────────
  static Future<void> _registerReelsFeature() async {
    di.registerLazySingleton(() => FetchReelsUC(di()));
    di.registerLazySingleton(() => LikeReelUC(di()));
    di.registerLazySingleton(() => ShareReelUC(di()));
    di.registerLazySingleton(() => ViewReelUC(di()));

    // GetReelsBloc: lazySingleton — the reel feed is a persistent tab;
    // scroll position and loaded pages should survive navigation.
    di.registerLazySingleton(() => GetReelsBloc(di(), di(), di(), di()));

    // ReelViewerBloc: factory — each reel playback session is independent.
    di.registerFactory(() => ReelViewerBloc(di()));
  }

  // ── Moments feature ────────────────────────────────────────────────────────
  static Future<void> _registerMomentsFeature() async {
    di.registerLazySingleton(() => FetchMomentsUC(di()));

    // MomentBloc: factory — each moment detail screen is ephemeral.
    di.registerFactory(() => MomentBloc(di()));
  }
}