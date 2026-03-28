# Exercise 8: Product & Architecture Trade-off Decisions

| Detail     | Value          |
|------------|----------------|
| **Time**   | ~30 minutes    |
| **Points** | 20             |
| **Type**   | Written analysis |

---

## Why This Exercise Exists

Senior developers don't just write code — they make decisions under constraints.
There is **no single right answer** to these scenarios. We want to see how you
think about trade-offs, risks, timelines, and team dynamics.

Generic answers like "it depends on the requirements" score zero.
**Be specific. Be opinionated. Defend your choices.**

---

## Scenario 1: Offline-First Chat Architecture (8 pts)

### Context

Our social app has a 1-on-1 chat feature powered by Pusher (WebSocket) for real-time messaging and a REST API for message history. **It currently requires an internet connection to work at all.** Users in regions with unreliable connectivity (parts of Turkey, Pakistan, and India — our largest markets) are complaining.

### Constraints

- **500K daily active users**, peaks at 200K concurrent
- Messages must be **ordered and consistent** — no duplicates, no gaps
- Backend team has limited bandwidth — you get **1 backend developer** for 2 weeks
- Flutter team is **2 people** (including you)
- Current tech: Dio for HTTP, Pusher for WebSocket, Hive for local caching
- Launch deadline: **6 weeks**

### Your Task

Write a detailed plan in `answers/scenario_1_offline_chat.md`:

1. **Architecture design:** How do you store messages locally? Sync strategy? Conflict resolution?
2. **Sprint 1 (weeks 1-2):** What do you build FIRST? What's the MVP?
3. **Sprint 2 (weeks 3-4):** What comes next?
4. **Sprint 3 (weeks 5-6):** Polish and edge cases
5. **What do you explicitly NOT build?** Why?
6. **Risk analysis:** What could go wrong? How do you mitigate it?
7. **Data model:** Show the local message table schema

---

## Scenario 2: Refactor Under Pressure (6 pts)

### Context

Our `FetchUserDataBloc` has **21 constructor dependencies**. It handles:
- User profile data
- Pusher WebSocket initialization
- Chat/message subscriptions
- Gift/game banner events
- App configuration
- Analytics
- Wallet balance
- Badges and levels
- FCM token updates

The team agrees it's a god-class and needs to be split. **BUT** we have a major product launch in **3 weeks** — a new live-streaming feature that touches this BLoC.

### Your Task

Write your answer in `answers/scenario_2_refactor_decision.md`:

1. **Decision:** Do you refactor now, after launch, or incrementally during the launch sprint?
2. **Justify** your decision with specific risks for each option
3. **If you refactor:** What's your split? Which new BLoCs do you create? Show the dependency diagram.
4. **If you don't refactor now:** What do you do to make the launch safer? What's your post-launch plan?
5. **Team coordination:** How do you avoid merge conflicts if 2 devs are working on the same area?
6. **Testing strategy:** You currently have zero tests. Do you add tests before refactoring? Which ones?

---

## Scenario 3: State Management Migration Proposal (6 pts)

### Context

Your team of **5 Flutter developers** is debating whether to migrate from **BLoC to Riverpod**. The arguments:

**Pro-Riverpod camp:**
- Less boilerplate (no separate Event/State classes)
- Better for composed/derived state
- `ref.watch` is more intuitive than `BlocBuilder`
- Auto-dispose eliminates memory leak issues

**Pro-BLoC camp:**
- 80+ existing BLoCs — migration would take months
- Team already knows BLoC well
- BLoC enforces unidirectional data flow
- More structure is better for a large team

**Current state:** 80+ BLoCs, zero test coverage, 2000-line DI file, some BLoCs are god-classes.

### Your Task

Write your answer in `answers/scenario_3_migration_proposal.md`:

1. **Your recommendation:** Migrate, don't migrate, or hybrid approach?
2. **If migrate:** Write a migration strategy (what order? how do you keep the app working during migration? timeline?)
3. **If don't migrate:** What improvements do you make to the current BLoC setup instead?
4. **Rollback plan:** If migration goes wrong, how do you revert?
5. **Team skills:** How do you train 5 developers on a new state management approach?
6. **Success metrics:** How do you know the migration (or improvement) was worth it?

---

## Evaluation Criteria

| Criterion | Points | What We Look For |
|-----------|--------|------------------|
| Specificity | 6 | Concrete plans with timelines, not vague "we should..." |
| Trade-off awareness | 5 | Acknowledges downsides of chosen approach |
| Realism | 4 | Plan is achievable with the stated constraints |
| Risk analysis | 3 | Identifies what could go wrong and how to handle it |
| Communication | 2 | Well-structured, easy to follow, would convince a tech lead |

---

## Important

- **There is no single right answer.** We're evaluating your reasoning, not a specific conclusion.
- **AI will give you a generic answer.** We can tell. Add your personal experience and opinions.
- **Be opinionated.** "It depends" without a specific recommendation is a weak answer.
- If you've faced a similar situation in a previous job, reference it.
