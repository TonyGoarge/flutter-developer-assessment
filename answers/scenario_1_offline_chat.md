# Exercise 8 — Scenario 1: Offline Chat

**Scenario prompt:**  
> Users report that messages sent while offline are lost. Design a solution
> that queues messages and delivers them when connectivity is restored.

---

## Problem Analysis

The core issue is a missing **outbox queue** — the app fires-and-forgets a
network request when the user hits Send, with no persistence layer underneath.
If the request fails (no signal, server timeout, app killed mid-flight), the
message is silently dropped. The user never knows it wasn't delivered.

Three failure modes need to be handled independently:

1. **Send while offline** — device has no connectivity at the moment of Send
2. **Send while online, delivery fails mid-flight** — request leaves the device
   but the server rejects or drops it (rate limit, 5xx, timeout)
3. **App killed before response** — message was queued in memory but process
   was terminated before it could be sent or persisted

---

## Proposed Architecture

### Layer 1 — Local Outbox (Hive / SQLite)

Persist every outgoing message to local storage **before** attempting the
network call. Each outbox entry carries:

```dart
class OutboxMessage {
  final String localId;       // client-generated UUID
  final String roomId;
  final String content;
  final DateTime createdAt;
  final int retryCount;
  final OutboxStatus status;  // pending | sending | failed
}

enum OutboxStatus { pending, sending, failed }
```

Write order is: **persist first, send second**. This guarantees no message
is ever lost to a process kill.

### Layer 2 — Connectivity-Aware Send Queue

A singleton `MessageQueueService` (registered as `lazySingleton` in DI) owns:

- A reference to the Hive outbox box
- A `StreamSubscription` to `connectivity_plus` network events
- A `Timer`-based retry loop with exponential backoff

```
User taps Send
      │
      ▼
OutboxMessage written to Hive (status: pending)
      │
      ▼
UI shows message with 🕐 "sending" indicator
      │
      ├─── Online? ──YES──► attempt send immediately
      │                          │
      │                    success? ──YES──► delete from outbox, show ✓
      │                          │
      │                          NO ──► increment retryCount, status: failed
      │                                  schedule retry (backoff)
      │
      └─── Offline? ──► leave in outbox, show 📵 "queued" indicator
                             │
                    connectivity restored
                             │
                             ▼
                    flush outbox in order (FIFO)
```

### Layer 3 — BLoC Integration

`ChatBloc` does not own the send logic directly. It delegates to
`MessageQueueService` and listens to its status stream:

```dart
// In ChatBloc
on<SendMessageEvent>((event, emit) async {
  final localId = const Uuid().v4();

  // 1. Optimistic UI update immediately
  emit(state.copyWith(
    messages: [...state.messages, OutboxMessage(localId, event.content, OutboxStatus.pending)],
  ));

  // 2. Hand off to queue service — never awaited here
  _queueService.enqueue(localId, event.roomId, event.content);
});

// React to queue service status changes
on<MessageStatusChangedEvent>((event, emit) {
  final updated = state.messages.map((m) {
    return m.localId == event.localId ? m.copyWith(status: event.status) : m;
  }).toList();
  emit(state.copyWith(messages: updated));
});
```

### Layer 4 — UI Indicators

Each chat bubble reads `OutboxStatus` from the message model:

| Status | Indicator | Meaning |
|--------|-----------|---------|
| `pending` | 🕐 single grey tick | Queued, not yet attempted |
| `sending` | 🔄 spinner | In-flight |
| `delivered` | ✓ single tick | Server ACK received |
| `read` | ✓✓ double tick | Read receipt from recipient |
| `failed` | ⚠️ + Retry button | All retries exhausted |

The "Retry" button on a failed message calls `_queueService.retry(localId)`,
which resets `retryCount` to 0 and re-queues immediately.

---

## Retry Strategy

Use **exponential backoff with jitter** to avoid thundering-herd when
connectivity is restored for many users simultaneously:

```
attempt 1: wait 2s
attempt 2: wait 4s
attempt 3: wait 8s
attempt 4: wait 16s
attempt 5: wait 32s  ← cap here, mark as failed, surface to user
```

Add ±20% random jitter on each delay. After connectivity-restored events,
bypass the timer and flush immediately (backoff resets).

Max retry cap: **5 attempts**. After that, status becomes `failed` and the
user sees the ⚠️ indicator with a manual Retry button. We do not silently
retry forever — that wastes battery and data on messages the server may
be rejecting for a valid reason (content policy, expired auth token, etc.).

---

## What I Would Not Do

**Option rejected: In-memory queue only.**  
Solves case 1 (offline at send time) but not case 3 (process kill). A live-
streaming app that plays audio in the background is routinely killed by the OS.
In-memory queues vanish with the process.

**Option rejected: Retry on every app resume.**  
Without an outbox, we don't know what to retry. Querying the server for
"did my last message arrive?" requires a per-message ACK protocol that adds
significant server complexity.

**Option rejected: Disable the Send button while offline.**  
Poor UX. Users in live rooms expect to keep typing. Queueing is the industry
standard (WhatsApp, Telegram, iMessage all do this).

---

## Packages

| Package | Purpose |
|---------|---------|
| `hive_flutter` | Fast local KV store for the outbox (no SQL overhead for simple message structs) |
| `connectivity_plus` | Stream of network changes |
| `uuid` | Client-side local message IDs |

---

## Testing Plan

| Test | Type | What it verifies |
|------|------|-----------------|
| Send while offline → message persists in Hive | Unit | Outbox write before network call |
| Connectivity restored → outbox flushed in order | Integration | FIFO delivery, no duplicates |
| App killed mid-send → message re-queued on restart | Integration | Hive persistence survives process kill |
| Server 5xx → retry with backoff | Unit | Backoff timing, retry cap |
| All retries exhausted → status = failed | Unit | UI receives `failed` status |
| Manual retry → message re-enters queue | Widget | Retry button triggers re-queue |
