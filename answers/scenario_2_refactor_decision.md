# Exercise 8 — Scenario 2: Refactor Decision

**Scenario prompt:**  
> The team wants to migrate from GetIt DI to Riverpod. The app has 200+ screens,
> 50+ BLoCs, and is actively developed by 8 engineers. Should you do it?
> How would you approach it if yes?

---

## My Recommendation: Yes — but incrementally, not as a big-bang rewrite

The migration is worth doing, but **not as a dedicated sprint** and definitely
not all at once. The right approach is a **strangler-fig migration** that runs
alongside feature development over 2–3 quarters, with zero disruption to the
release cadence.

---

## Why It Is Worth Doing

### GetIt's core problem in a large codebase

GetIt is a service locator, not a true DI framework. It stores instances in a
global map accessed by type. This creates three structural problems at scale:

**1. Untestable registration.** You can't inject fakes into a widget test without
calling `di.registerLazySingleton<MyBloc>(() => FakeBloc())` and then cleaning up
afterward. Forget to unregister and the next test gets stale state. With 50+ BLoCs
this becomes a constant source of flaky tests.

**2. Hidden dependencies.** A widget that calls `di<ChatBloc>()` deep inside its
`build()` method has a dependency that is invisible at the call site. You can't
know what a widget needs without reading its entire subtree. Riverpod's
`ref.watch()` / `ref.read()` makes every dependency explicit and compiler-checked.

**3. Lifecycle bugs.** GetIt singletons live until explicitly unregistered. It's
common to forget `di.unregister<SomeBloc>()` when a screen closes, leaking
resources and causing "BLoC already registered" errors on hot restart.

### What Riverpod fixes

- **Providers are compile-time checked.** Accessing a provider that wasn't declared
  is a compile error, not a runtime crash at `di<T>()`.
- **Scoped lifetime.** `Provider.autoDispose` automatically cleans up when the last
  listener leaves — no manual `unregister` calls needed.
- **Testability by design.** `ProviderContainer` lets you override any provider in a
  test with a fake in one line, with no global state pollution between tests.
- **No boilerplate registration.** Providers are declared alongside the code that
  defines them, not in a 2,000-line DI file that everyone touches.

---

## Why a Big-Bang Rewrite Is the Wrong Call

200 screens and 50 BLoCs in active development means:

- A full migration touches essentially every file in the app
- 8 engineers working in parallel create constant merge conflicts during the migration
- Feature branches become impossible to merge cleanly against a rewriting `main`
- QA has to re-test the entire app even if the behaviour didn't change
- One missed registration or wrong provider scope causes a production crash

This is the classic rewrite trap: you spend 3 months migrating, ship nothing to
users, and the product falls behind competitors.

---

## The Incremental Plan

### Phase 0 — Preparation (Week 1–2, no code changes)

1. Write the **migration guide** for the team: how to declare a provider, how to
   consume it in widgets, how to write provider tests. One internal wiki page.
2. Add `flutter_riverpod` to `pubspec.yaml`. GetIt stays. Both coexist.
3. Wrap `MaterialApp` in `ProviderScope`. This is the only "infrastructure" change
   — it takes 5 minutes and is fully reversible.
4. Define the **migration order**: start with leaf BLoCs (no dependents), work
   inward toward the god-class `FetchUserDataBloc` last.

### Phase 1 — New code is Riverpod (ongoing, forever)

**Rule: every new BLoC or repository written from this point forward uses a
Riverpod provider instead of GetIt registration.**

This is zero extra work for engineers — they're writing new code anyway.
It immediately stops the GetIt surface from growing and gives the team practice
with Riverpod patterns on low-risk new screens.

### Phase 2 — Migrate by feature, ticket by ticket (Weeks 3 → N)

Each sprint, one engineer picks up a "migrate X feature" ticket alongside
their normal feature work. The ticket covers:

1. Convert the feature's data sources and repositories to `Provider`
2. Convert the feature's use cases to `Provider`
3. Convert the feature's BLoC to a `StateNotifierProvider` (or keep it as
   a BLoC wrapped in a provider — both are valid)
4. Update the feature's screens to use `ref.watch()` / `ref.read()`
5. Remove the feature's GetIt registrations from the DI file
6. Write provider tests for the feature (replaces the fragile GetIt test setup)

Priority order:
- **First:** Isolated leaf features with no dependents (Reels, Moments, Search)
- **Middle:** Shared repositories (ProfileRepository, MessagesRepository)
- **Last:** App-wide singletons (RealTimeBloc/Pusher, AppConfigBloc, FetchUserDataBloc)

### Phase 3 — Delete GetIt (Quarter 3 or later)

Once the DI file is empty, remove GetIt from `pubspec.yaml`. CI will confirm
nothing imports it. Done.

---

## Trade-offs I Am Accepting

| Trade-off | Mitigation |
|-----------|-----------|
| Two DI systems in the codebase simultaneously | Clear rule: new code = Riverpod, old code = GetIt. Engineers always know which to use. |
| Riverpod learning curve for 8 engineers | Migration guide + one internal lunch-and-learn. Riverpod's docs are excellent. |
| Migration tickets compete with feature work | Each migration ticket is sized at 2–4 hours. They slot into sprint slack time without blocking features. |
| Risk of breaking a migrated screen | Each migrated feature is covered by new provider tests before the PR merges. |

---

## What I Would Not Do

**Reject: "Let's just use GetIt better."**  
Better naming conventions and stricter factory/singleton discipline help, but
they don't fix testability or hidden dependencies. You're patching structural
problems with documentation.

**Reject: "Use both permanently."**  
Two DI systems in production forever doubles onboarding complexity and means
the codebase never reaches a clean state. The end goal must be GetIt removal.

**Reject: "Freeze features for a migration sprint."**  
An 8-person team going dark for a quarter is a business risk the product team
will (correctly) push back on. Incremental migration keeps both tracks moving.

---

## Final Answer

**Do the migration. Do it incrementally. Start this sprint with Phase 0.**

The long-term benefits to testability, compile-time safety, and developer
productivity are significant — especially as the team grows. The cost is
manageable if you don't try to do it all at once.
