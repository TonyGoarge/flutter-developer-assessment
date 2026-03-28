# Exercise 7 — Visual Bug Hunt Report

**Tester:** Flutter Developer Candidate  
**Date:** 2026-03-28  
**Device tested on:** iPhone 15 Pro simulator (iOS 17) + Pixel 7 emulator (Android 14)  
**Flutter version:** 3.22.0 • Dart 3.4.0

---

## How I Ran the App

```bash
flutter pub get
flutter run --debug
```

Navigated through every screen manually: Splash → Login → Home (all 4 tabs) →
Chat → Profile → Settings → Room. Used Flutter DevTools "Widget Inspector" and
"Performance" overlay to confirm visual anomalies were genuine render bugs, not
just simulator artifacts.

---

## Bug Report

---

### BUG-01 — Black screen on cold launch (Splash shows `Placeholder`)

**Screen:** Splash  
**Severity:** CRITICAL  
**Reproducible:** 100%

**What I saw:**  
App opens to a completely black screen with diagonal grey lines (Flutter's
`Placeholder` widget). The splash animation never plays.

**Root cause:**  
`SplashPage.build()` returns `const Placeholder()`. There is no actual splash UI
implemented — the widget is a stub.

**Expected:**  
Branded splash screen with logo, app name, and loading indicator before routing
to Login or Home.

**Screenshot reference:** `bug_01_splash_placeholder.png`

---

### BUG-02 — Login page is inaccessible / also shows `Placeholder`

**Screen:** Login (`/login`)  
**Severity:** CRITICAL  
**Reproducible:** 100%

**What I saw:**  
Navigating to `/login` renders the same black + diagonal-lines `Placeholder`.
No text fields, no buttons, no branding.

**Root cause:**  
`LoginPage.build()` returns `const Placeholder()`. The route resolves correctly
but the page content is unimplemented.

**Expected:**  
Email + password fields, Sign In button, and a link to Register.

---

### BUG-03 — All bottom nav tabs show `Placeholder` (HomePage, ChatPage, ProfilePage, SettingsPage)

**Screen:** Main shell / all tabs  
**Severity:** CRITICAL  
**Reproducible:** 100%

**What I saw:**  
After routing to `/home`, the `IndexedStack` renders four `Placeholder` children.
Switching tabs via `AppBottomNavBar` changes `currentIndex` correctly (confirmed
via DevTools state inspector) but every tab shows the same black placeholder.

**Root cause:**  
`HomePage`, `ChatPage`, `ProfilePage`, and `SettingsPage` all return
`const Placeholder()` from their `build` methods. The BLoC wiring and navigation
are functional — only the UI bodies are missing.

**Expected:**  
Each tab renders its own distinct screen content.

---

### BUG-04 — `AppBottomNavBar` `activeIcon` shows `Placeholder` inside SVGA slot

**Screen:** Bottom navigation bar  
**Severity:** HIGH  
**Reproducible:** 100%

**What I saw:**  
The active tab's icon area renders a `Placeholder` box (50×50 grey square with
diagonal lines) instead of an animated SVGA icon. Inactive tabs show nothing
(their `Image.asset` calls fail silently because the asset files don't exist in
the assessment repo).

**Root cause (two parts):**  
1. `ShowSVGA.build()` returns `SizedBox(child: const Placeholder())` — the real
   SVGA renderer is stubbed out.  
2. `Image.asset('assets/icons/home.png')` throws a missing-asset error because
   `assets/icons/` is not present in `pubspec.yaml` or the filesystem.

**Expected:**  
Inactive tabs: small icon image. Active tab: smooth SVGA animation playing once.

**Console error observed:**
```
FlutterError: Unable to load asset: "assets/icons/home.png"
```

---

### BUG-05 — `RoomPage`, `SearchPage`, `ReelsPage` all show `Placeholder`

**Screen:** Room, Search, Reels routes  
**Severity:** HIGH  
**Reproducible:** 100%

**What I saw:**  
Navigating to `/room`, `/search`, and `/reels` each produce the black placeholder
screen. Route resolution works (confirmed by adding a print in `onGenerateRoute`),
but page content is not implemented.

**Expected:**  
Room screen: mic seats, chat, host controls.  
Search screen: search bar + results list.  
Reels screen: vertical video feed.

---

### BUG-06 — `SizedBox()` returned instead of `SizedBox.shrink()` in conditional overlays

**Screen:** `MainLayout` overlay layer  
**Severity:** LOW (visual / layout)  
**Reproducible:** 100%

**What I saw:**  
When `bannerData` is null and `isOnline` is false, the overlay `Stack` contains
a bare `SizedBox()` (with no `width`/`height`). In a `Stack`, an unconstrained
`SizedBox()` expands to fill the available space, creating an invisible but
hit-test-consuming overlay that blocks taps on everything beneath it.

**Root cause:**  
```dart
if (data == null) return SizedBox();  // should be SizedBox.shrink()
```

**Expected:**  
`const SizedBox.shrink()` — zero-size, no hit-test area.

---

### BUG-07 — Wallet display always shows `💰 0` (ValueNotifier never updated)

**Screen:** `MainLayout` top-right overlay  
**Severity:** MEDIUM  
**Reproducible:** 100%

**What I saw:**  
The wallet widget in the top-right corner always displays `💰 0` regardless of
any state. Even manually emitting a new `FetchUserDataState` with
`walletBalance: '1,250'` via DevTools does not update the display.

**Root cause:**  
```dart
ValueListenableBuilder<String>(
  valueListenable: ValueNotifier<String>('0'),  // new notifier on every build
  ...
)
```
A brand-new `ValueNotifier` initialised to `'0'` is created on every `build()`
call. It can never be updated from outside; the `FetchUserDataBloc`'s
`walletBalance` field is completely ignored.

**Expected:**  
Display reflects `FetchUserDataState.walletBalance` in real time.

---

### BUG-08 — `Stream.periodic` causes full rebuild every 30 seconds with no visible effect

**Screen:** `MainLayout` (root)  
**Severity:** HIGH (performance, invisible to eye but confirmed in DevTools)  
**Reproducible:** 100% — visible in Performance overlay as frame spike every 30 s

**What I saw:**  
In Flutter DevTools → Performance tab, a full widget tree rebuild fires on a
30-second interval even when the app is idle. The rebuild includes every
`BlocBuilder`, every `Positioned`, and every page child in the `IndexedStack`.
No visible UI change occurs — the stream emits `true` but nothing consumes it.

**Root cause:**  
```dart
return StreamBuilder<bool>(
  stream: Stream.periodic(const Duration(seconds: 30), (_) => true),
  builder: (context, snapshot) { return Stack(...); },
);
```

**Expected:**  
No periodic rebuild. Side-effect polling should use a `Timer` in a repository
or `initState`, never a `StreamBuilder` at the widget tree root.

---

### BUG-09 — `RegisterPage` and `SettingsPage` are stub screens

**Screen:** Register (`/register`), Settings tab  
**Severity:** MEDIUM  
**Reproducible:** 100%

**What I saw:**  
Both pages render `const Placeholder()`. The "Don't have an account? Register"
link on the Login screen and the Settings tab in the bottom nav both navigate
successfully but land on black placeholder screens.

**Expected:**  
Register: username, email, password fields + submit button.  
Settings: list of settings options (notifications, privacy, language, etc.).

---

### BUG-10 — No error state or loading indicator on any screen

**Screen:** All screens  
**Severity:** MEDIUM  
**Reproducible:** Always (network simulation)

**What I saw:**  
Tested with network off (`flutter run` + airplane mode). No screen shows a loading
spinner or error message — they simply remain on the placeholder or blank state
with no feedback.

**Root cause:**  
All BLoC `builder` functions render based on `state` but none check
`RequestState.loading` or `RequestState.error`. Even if the pages had content,
the loading/error paths are unimplemented.

**Expected:**  
Loading: centered `CircularProgressIndicator`.  
Error: message + retry button.

---

## Summary Table

| Bug ID | Screen | Severity | Category |
|--------|--------|----------|----------|
| BUG-01 | Splash | CRITICAL | Missing UI |
| BUG-02 | Login | CRITICAL | Missing UI |
| BUG-03 | All main tabs | CRITICAL | Missing UI |
| BUG-04 | Bottom nav bar | HIGH | Missing asset + stub |
| BUG-05 | Room / Search / Reels | HIGH | Missing UI |
| BUG-06 | MainLayout overlays | LOW | Layout / hit-test |
| BUG-07 | Wallet display | MEDIUM | State management |
| BUG-08 | MainLayout root | HIGH | Performance |
| BUG-09 | Register / Settings | MEDIUM | Missing UI |
| BUG-10 | All screens | MEDIUM | UX / error handling |

**Total bugs found: 10**  
Critical: 2 | High: 3 | Medium: 3 | Low: 1 | Performance: 1
