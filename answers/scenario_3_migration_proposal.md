# Exercise 8 — Scenario 3: Migration Proposal

**Scenario prompt:**  
> The app currently uses a single `Navigator 1.0` with a static routes map.
> The team wants to migrate to `go_router` to support deep links, web URLs,
> and nested navigation. Write a migration proposal.

---

## Executive Summary

Migrate from `Navigator 1.0` + static routes `Map` to `go_router` over
**three phases** spanning approximately 6 weeks of part-time migration work
alongside normal feature development. The migration is low-risk when done
incrementally because `go_router` wraps `Navigator 1.0` internally — both
can coexist during the transition.

---

## Why Migrate

### What Navigator 1.0 cannot do cleanly

**Deep links** — a push notification tap with payload
`/room/abc123?autoJoin=true` requires manually parsing the raw URL string in
`onGenerateRoute`, extracting the segment and query params by hand, and
constructing the right widget. Every deep link adds bespoke parsing code.

**Web URL support** — Navigator 1.0 has no concept of the browser URL bar.
If the app ever ships a web build, the URL stays at `/` forever regardless
of where the user navigates. Back/forward browser buttons don't work.

**Nested navigation** — the bottom nav bar's tabs ideally maintain independent
back stacks (go to Profile → open a user's room → go back to Profile, not back
to wherever you were in Home). Navigator 1.0 requires a manually managed
`IndexedStack` with per-tab `Navigator` keys and careful `WillPopScope` logic.
This code is fragile and widely misunderstood.

**Declarative redirects** — auth guards (redirect to Login if not authenticated,
redirect to Home if already logged in) require intercepting every route in
`onGenerateRoute`. With `go_router`, a `redirect` callback handles this in 10
lines, tested independently of any widget.

### What go_router gives us

- Type-safe route definitions with `GoRoute` and path parameters (`/room/:id`)
- Query parameter parsing built-in (`/room/abc?autoJoin=true`)
- `ShellRoute` for persistent bottom nav with independent tab back-stacks
- `redirect` for auth guards, expressed declaratively
- Full web URL support out of the box
- `GoRouter.of(context).push()` / `.pop()` / `.go()` — familiar API
- Deep link handling via the platform's intent/universal link system with
  no additional parsing code

---

## Current State

```
MaterialApp(
  initialRoute: Routes.home,
  onGenerateRoute: Routes.onGenerateRoute,  // switch on settings.name
)
```

All 10+ routes are handled by a `switch` in `Routes.onGenerateRoute`.
Route arguments are passed via `settings.arguments` (untyped `Object?`),
requiring casts at the destination. Deep links, web URLs, and tab back-stacks
are not supported.

---

## Target State

```
MaterialApp.router(
  routerConfig: _router,
)

final _router = GoRouter(
  initialLocation: '/home',
  redirect: _authGuard,
  routes: [
    GoRoute(path: '/splash', builder: ...),
    GoRoute(path: '/login',  builder: ...),
    ShellRoute(              // persistent bottom nav
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/home',    builder: ...),
        GoRoute(path: '/chat',    builder: ...),
        GoRoute(path: '/profile', builder: ...),
        GoRoute(path: '/settings',builder: ...),
      ],
    ),
    GoRoute(path: '/room/:id', builder: ...), // full-screen, no nav bar
    GoRoute(path: '/search',   builder: ...),
    GoRoute(path: '/reels',    builder: ...),
  ],
);
```

---

## Migration Plan

### Phase 0 — Setup (Day 1, ~2 hours)

**No behaviour changes. Zero risk.**

1. Add `go_router: ^14.0.0` to `pubspec.yaml`. Keep `onGenerateRoute` unchanged.
2. Create `lib/router/app_router.dart` — empty `GoRouter` instance with only
   the splash route defined.
3. Add `MaterialApp.router` as a **commented-out** block next to the existing
   `MaterialApp`. This will be the swap point in Phase 2.
4. Write the auth redirect function (pure Dart, no widgets — fully testable now).

**Deliverable:** `app_router.dart` exists, CI passes, nothing in the app changed.

---

### Phase 1 — Migrate routes one by one (Weeks 1–3)

For each route, in this order:

**Order (least risky first):**
1. Static pages with no arguments: `/splash`, `/settings`, `/register`
2. Pages with simple typed arguments: `/login`, `/profile/:id`
3. Deep-linkable pages: `/room/:id?autoJoin=bool`, `/search?q=string`
4. The `ShellRoute` bottom nav replacement (most complex — last)

**Per-route checklist:**
- [ ] Add `GoRoute` entry to `app_router.dart`
- [ ] Replace `settings.arguments` cast with typed path/query params
- [ ] Replace `Navigator.pushNamed(context, Routes.X)` callsites with
      `context.go('/x')` or `context.push('/x')`
- [ ] Remove the corresponding `case` from `Routes.onGenerateRoute`
- [ ] Write a route test (see Testing section)

The `onGenerateRoute` switch shrinks by one case per route until it is empty.
At that point it is deleted.

---

### Phase 2 — ShellRoute for bottom nav (Week 4)

This is the highest-complexity step and deserves its own focused effort.

**Current approach:**
```dart
// In _HomeShell
BlocBuilder<LayoutBloc, LayoutState>(
  builder: (context, state) => Scaffold(
    body: IndexedStack(index: state.currentIndex, children: [...]),
    bottomNavigationBar: AppBottomNavBar(currentIndex: state.currentIndex, onTap: ...),
  ),
)
```
`LayoutBloc` manually tracks the tab index. Tab back-stacks are not independent.

**go_router approach:**
```dart
ShellRoute(
  builder: (context, state, child) {
    // child = whichever tab GoRouter has navigated to
    return Scaffold(
      body: child,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _tabIndexOf(state.location),
        onTap: (i) => context.go(_tabRoutes[i]),
      ),
    );
  },
  routes: [
    GoRoute(path: '/home',     builder: (_, __) => const _HomePageWrapper()),
    GoRoute(path: '/chat',     builder: (_, __) => const ChatPage()),
    GoRoute(path: '/profile',  builder: (_, __) => const ProfilePage()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
  ],
)
```

`LayoutBloc` is retired entirely — `go_router` owns the navigation state.
The active tab is derived from `state.location` (a simple string switch).

For independent tab back-stacks (each tab remembers its own history),
use `StatefulShellRoute.indexedStack` (available in go_router 13+):
```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, shell) => AppShell(shell: shell),
  branches: [
    StatefulShellBranch(routes: [GoRoute(path: '/home', ...)]),
    StatefulShellBranch(routes: [GoRoute(path: '/chat', ...)]),
    // ...
  ],
)
```

---

### Phase 3 — Deep links + redirect (Week 5)

**Auth redirect:**
```dart
String? _authGuard(BuildContext context, GoRouterState state) {
  final isLoggedIn = context.read<AuthBloc>().state.isAuthenticated;
  final isAuthRoute = state.location == '/login' || state.location == '/register';

  if (!isLoggedIn && !isAuthRoute) return '/login';
  if (isLoggedIn  &&  isAuthRoute) return '/home';
  return null; // no redirect
}
```

**Deep link (push notification → Room):**
```dart
// Android: intent filter in AndroidManifest.xml
// iOS: universal link in Associated Domains

// Payload: https://app.example.com/room/abc123?autoJoin=true

GoRoute(
  path: '/room/:id',
  builder: (context, state) {
    final roomId   = state.pathParameters['id']!;
    final autoJoin = state.uri.queryParameters['autoJoin'] == 'true';
    return RoomPage(roomId: roomId, autoJoin: autoJoin);
  },
)
```

No manual URL parsing. The platform hands the URL to go_router; go_router
matches it and populates `pathParameters` and `queryParameters` automatically.

---

### Phase 4 — Cutover and cleanup (Week 6)

1. Swap `MaterialApp(onGenerateRoute: ...)` → `MaterialApp.router(routerConfig: _router)`
2. Delete `Routes.onGenerateRoute` and `Routes.routes`
3. Delete `LayoutBloc` (replaced by go_router's navigation state)
4. Remove any `Navigator.pushNamed` / `Navigator.pop` calls replaced by `context.go` / `context.pop`
5. Full regression test pass

---

## Testing Strategy

### Route unit tests
```dart
testWidgets('navigating to /room/:id passes roomId to RoomPage', (tester) async {
  final router = GoRouter(routes: appRoutes, initialLocation: '/room/abc123');
  await tester.pumpWidget(ProviderScope(child: MaterialApp.router(routerConfig: router)));
  expect(find.byType(RoomPage), findsOneWidget);
  // verify RoomPage received 'abc123'
});
```

### Auth redirect tests
```dart
test('unauthenticated user redirected from /home to /login', () {
  final redirect = authGuard(unauthenticatedContext, GoRouterState(location: '/home'));
  expect(redirect, equals('/login'));
});
```

### Deep link integration tests
```dart
testWidgets('deep link /room/xyz?autoJoin=true opens room with autoJoin', (tester) async {
  // simulate platform deep link
  await tester.binding.handleDeepLink(Uri.parse('https://app.example.com/room/xyz?autoJoin=true'));
  await tester.pumpAndSettle();
  expect(find.byType(RoomPage), findsOneWidget);
});
```

---

## Risk Register

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| `context.go()` vs `context.push()` confusion causes wrong back-stack | Medium | Code review checklist item; lint rule to ban `Navigator.pushNamed` after Phase 1 |
| `ShellRoute` breaks existing tab-switching animations | Low | Spike the `ShellRoute` in a throwaway branch before committing to it in Phase 2 |
| go_router version incompatibility with flutter_bloc | Low | Pin go_router version; check the `flutter_bloc` compatibility matrix |
| Engineers using `Navigator.pop()` on go_router-managed routes | Medium | Add a `NavigatorObserver` that logs warnings in debug mode; replace in Phase 4 cleanup |
| Deep link URI scheme conflicts with other apps | Low | Use a fully-qualified domain (`https://`) universal link, not a custom scheme |

---

## What We Get After Migration

| Capability | Before | After |
|-----------|--------|-------|
| Deep links | Manual URL parsing | Automatic via path/query params |
| Web URL bar | Stuck at `/` | Full URL reflects navigation |
| Tab back-stacks | Shared (incorrect) | Independent per tab |
| Auth guard | Scattered in `onGenerateRoute` | One `redirect` function, tested |
| Type-safe route args | `settings.arguments as MyArgs` cast | Typed path/query params |
| 404 handling | `default` case in switch | `errorBuilder` in GoRouter |
| Testing | Requires full app pump | Route-level unit tests |
