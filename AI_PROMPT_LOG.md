# AI Prompt Log — OfflineFirst Flutter App

> **Project:** Offline-First Sync Queue (Flutter + Firebase + Provider)
> **Duration:** 1 Day Sprint
> **Tools Used:** Claude (Planning), Antigravity (Primary Coding), Cursor (Debugging/Fixes), Codex (Boilerplate)

---

## PHASE 1 — Project Planning & Architecture

### Prompt 1
**Tool:** Claude
**Prompt:**
> "I have an interview assignment to build an offline-first Flutter app with sync queue, retries, idempotency, and conflict handling in 1 day. Explain how to implement it properly with a comprehensive plan."

**Key Response Summary:**
Provided full architecture diagram (UI → BLoC → Repository → Hive → Firebase), hour-by-hour schedule, tech stack decisions, data models for Article and SyncQueueItem, sync queue logic with deduplication, idempotency via UUID Firestore doc ID, Last-Write-Wins conflict strategy, and observability counters.

**Decision:** Accepted with one modification — switched state management from BLoC to Provider for simplicity.

**Why:** Provider is more approachable for a 1-day sprint. The architecture logic (queue, retry, idempotency) remains identical regardless of state management. BLoC adds boilerplate overhead that would consume valuable time.

---

### Prompt 2
**Tool:** Claude
**Prompt:**
> "Give me the master project prompt to assign to Antigravity and Cursor so it creates the proper folder structure."

**Key Response Summary:**
Delivered a complete copy-paste prompt with full folder tree, all data model field definitions, 6 key behaviors (cache-first reads, offline writes, sync on reconnect, retry with backoff, deduplication, LWW conflict), Firestore collection structure, and pubspec.yaml dependencies.

**Decision:** Accepted.

**Why:** Having a single master context document means all AI tools generate consistent, compatible code across sessions.

---

## PHASE 2 — Project Structure & Models

### Prompt 3
**Tool:** Antigravity
**Prompt:**
> "Create the complete folder structure, pubspec.yaml, all Hive model files (Article typeId:0, SyncQueueItem typeId:1), app_constants.dart, app_logger.dart, and empty placeholder files for everything else. Do NOT implement logic yet."

**Key Response Summary:**
Generated complete folder structure under `lib/`, created both Hive models with proper `@HiveType` and `@HiveField` annotations, `copyWith()` methods, `fromFirestore()` and `toFirestore()` converters, `AppConstants` with TTL/maxRetries/backoff values, and Logger wrapper with prefixed static methods.

**Decision:** Accepted.

**Why:** Clean separation confirmed — models had all required fields including `version` for LWW and `isProcessing` flag to prevent double-processing during concurrent sync.

**Verification:** Ran `dart run build_runner build --delete-conflicting-outputs` → `article.g.dart` and `sync_queue_item.g.dart` generated successfully in ~11.5 seconds with status code 0 and no errors.

---

## PHASE 3 — Data Layer (DAOs + Repository)

### Prompt 4
**Tool:** Cursor
**Prompt:**
> "Implement HiveArticleDao, HiveQueueDao, FirestoreRemote, and ArticleRepository. Cache-first stream for watchArticles() — yield Hive cache instantly, then fetch Firebase in background. FirestoreRemote.applyAction() uses SyncQueueItem.id as Firestore document ID for idempotency."

**Key Response Summary:**
Implemented all 4 files. `watchArticles()` uses async generator pattern yielding cache first. `applyAction()` uses `SetOptions(merge: false)` with UUID as doc ID. `seedArticles()` populates 5 mock articles. `isCacheExpired()` compares `cachedAt` against `AppConstants.cacheTTL`.

**Decision:** Accepted.

**Why:** The idempotency approach (UUID = Firestore document ID) is the cleanest solution — zero server-side logic needed. Retrying the same action 10 times produces exactly one Firestore document.

---

## PHASE 4 — Sync Engine (Core Logic)

### Prompt 5
**Tool:** Antigravity
**Prompt:**
> "Implement IdempotencyHelper, SyncQueue, SyncEngine, and ConnectivityCubit. SyncQueue handles enqueue with dedup (same actionType+entityId = skip). SyncEngine has re-entrant guard (_isSyncing flag). Retry uses exponential backoff stored as nextRetryAt DateTime in Hive so it survives app restart."

**Key Response Summary:**
Delivered all 4 files. `IdempotencyHelper.generateKey()` returns `Uuid().v4()`. Deduplication in `enqueue()` checks `existsForAction()` before saving. Exponential backoff: `delaySeconds = baseBackoff * pow(2, retryCount - 1)`. `nextRetryAt` persisted to Hive. Re-entrant guard prevents concurrent sync runs.

**Decision:** Modified one part.

**Why:** Changed `Future.delayed` to timestamp-based `nextRetryAt` stored in Hive. `Future.delayed` does not survive app restarts — a timestamp does. This was a critical fix for the "queue must persist across app restart" requirement.

---

### Prompt 6
**Tool:** Antigravity
**Prompt:**
> "Implement last-write-wins strategy in the sync queue. If I change a note twice while offline, only the latest note should be in the queue — replace the existing item instead of adding a duplicate."

**Key Response Summary:**
Updated `SyncQueue.enqueue()` to check for existing items with matching `actionType + entityId`. If found, replaces the existing item with the new one (updating payload and createdAt). Logs "LWW: replaced existing ${actionType} for ${entityId}".

**Decision:** Accepted.

**Why:** Prevents sending redundant intermediate states to Firebase. If a user edits a note 5 times offline, only the final version syncs. Saves bandwidth and eliminates server-side merge complexity.

---

## PHASE 5 — State Management (Provider)

### Prompt 7
**Tool:** Cursor
**Prompt:**
> "Rewrite state management using Provider instead of BLoC. Create ArticleProvider and SyncProvider. ArticleProvider wraps ArticleRepository and exposes articles list, loading state, and methods for like/save/addNote. SyncProvider wraps SyncEngine and exposes sync status, pending count, success count, fail count."

**Key Response Summary:**
Generated `ArticleProvider extends ChangeNotifier` with `loadArticles()`, `likeArticle()`, `saveArticle()`, `addNote()`. Generated `SyncProvider extends ChangeNotifier` with `triggerSync()`, `pendingCount`, `syncSuccessCount`, `syncFailCount`. Both providers call `notifyListeners()` on state change.

**Decision:** Accepted.

**Why:** Provider is simpler to wire up than BLoC for this use case. No boilerplate events/states files needed. `ChangeNotifier` + `notifyListeners()` gives reactive UI updates with minimal code. The core sync logic is unchanged — only the state container changed.

---

### Prompt 8
**Tool:** Cursor
**Prompt:**
> "Update connectivity listener for connectivity_plus ^5.0.2. The onConnectivityChanged stream now emits List<ConnectivityResult> not a single value."

**Key Response Summary:**
Fixed listener to use `results.any((r) => r != ConnectivityResult.none)` to determine online status from the list.

**Decision:** Modified.

**Why:** The original single-value check threw a type error at runtime. The fix checks the full list which is the correct API for connectivity_plus v5+. This is a breaking change in the package that must be handled explicitly.

---

## PHASE 6 — main.dart & App Wiring

### Prompt 9
**Tool:** Antigravity
**Prompt:**
> "Implement main.dart with Firebase init, Hive init with adapter registration, manual dependency wiring (no get_it), MultiProvider with ArticleProvider and SyncProvider, and connectivity listener that triggers sync when coming back online. Log pending queue count on app startup."

**Key Response Summary:**
Wired all dependencies manually. On startup logs `[QUEUE] App started. Pending items in queue: N`. ConnectivityProvider listener calls `syncProvider.triggerSync()` when state transitions from false → true (offline → online).

**Decision:** Accepted.

**Why:** Manual wiring keeps the dependency graph transparent and easy to explain in interview. The startup log of pending count directly satisfies the "queue must persist across app restart" verification requirement.

---

## PHASE 7 — UI Layer

### Prompt 10
**Tool:** Antigravity
**Prompt:**
> "Create ArticleListScreen, ArticleDetailScreen, SyncStatusBanner, ArticleCard, QueueSizeChip. SyncStatusBanner shows amber when offline, blue spinner when syncing, green on success, red on failure. ArticleCard has Like/Save buttons with offline badge. ArticleDetailScreen has note editor with SnackBar confirmation."

**Key Response Summary:**
Generated all 5 UI files. `SyncStatusBanner` uses `Consumer<SyncProvider>` and `Consumer<ConnectivityProvider>`. Cards show "⚠️ Offline" chip when connectivity is false. Note preview shown on card if article.note != null.

**Decision:** Accepted.

**Why:** The SyncStatusBanner directly satisfies the observability requirement — pending count, success count, and fail count are always visible to the user and in logs simultaneously.

---

### Prompt 11
**Tool:** Antigravity
**Prompt:**
> "Add advanced UI features: infinite scrolling with lazy-loading in ArticleListScreen, custom skeleton loading shimmer effect using vanilla Flutter animations (no shimmer package), global connectivity banner, and expand mock dataset to 30+ entries."

**Key Response Summary:**
Implemented pagination with `ScrollController` listening to scroll position. Skeleton shimmer uses `AnimationController` with `CurvedAnimation`. Mock dataset expanded to 30 articles with varied titles, bodies, and tags.

**Decision:** Accepted.

**Why:** Infinite scroll + skeleton loading demonstrates production-readiness. Shimmer built without a package shows Flutter animation competency. 30 articles makes the pagination behavior actually testable.

**Verification:** Scrolling to the bottom triggers a page fetch and shows the skeleton shimmer correctly before articles load in.

---

### Prompt 12
**Tool:** Antigravity
**Prompt:**
> "Enhance UI with Glassmorphism on detail screen's floating action bar (BackdropFilter), redesign Save Insight section to journaling aesthetic, add Hero animations for screen transitions, add haptic feedback for offline actions (like/save), add note badge on article cards."

**Key Response Summary:**
Applied `BackdropFilter` with `ImageFilter.blur` on the FAB. Hero widget wraps article image/title between list and detail screens. `HapticFeedback.mediumImpact()` called on like/save when offline. Note badge (green dot) appears on cards with saved notes.

**Decision:** Accepted.

**Why:** Hero animations and haptic feedback significantly increase perceived app quality. The haptic feedback specifically reinforces to users that their offline action was registered — important UX for an offline-first app. State updates are reactive: saving a note in Detail immediately updates the badge in the Feed.

---

## PHASE 8 — Google Stitch UI Design System

### Prompt 13
**Tool:** Antigravity + Google Stitch
**Prompt:**
> "Use Google Stitch to generate a consistent design system for the app. Create a Material 3 theme with a custom color scheme, typography scale, and component styles. Export as Flutter ThemeData."

**Key Response Summary:**
Google Stitch generated a complete design token set — primary color `#1A1A2E`, secondary `#E94560`, surface `#16213E`. Exported as Flutter `ColorScheme.fromSeed()` with custom `TextTheme` using Google Fonts (Playfair Display for headings, Inter for body).

**Decision:** Modified.

**Why:** Accepted the color tokens and typography scale but replaced Google Fonts with local font assets to avoid network dependency during offline demo. Also adjusted the surface color to a warmer cream (`#FAF8F0`) to match the "Vintage Editorial" newspaper theme implemented earlier.

**Integration Notes:**
- Applied `ThemeData` in `app.dart` using `useMaterial3: true`
- Component themes (CardTheme, AppBarTheme, ElevatedButtonTheme) generated by Stitch and applied globally
- Dark mode variant also generated — toggled via `ThemeProvider`

---

### Prompt 14
**Tool:** Google Stitch
**Prompt:**
> "Generate a card component design for article cards with offline indicator badge, like/save action buttons, and note preview section. Export as Flutter widget code."

**Key Response Summary:**
Stitch generated a `ArticleCard` design with elevation shadows, rounded corners (12px), action button row with icon + count labels, and a collapsible note preview section with left border accent.

**Decision:** Modified.

**Why:** Accepted the visual design but rewrote the widget implementation to use `Consumer<ArticleProvider>` from Provider instead of the stateful widget Stitch generated. Kept Stitch's design tokens (border radius, shadows, spacing) exactly.

---

## PHASE 9 — WhisperFlow Voice Assistant

### Prompt 15
**Tool:** Antigravity + WhisperFlow
**Prompt:**
> "Integrate WhisperFlow voice assistant into the app. Users should be able to say 'Like this article', 'Save this article', 'Add note: [text]' and have it trigger the corresponding offline-safe action through the existing SyncQueue."

**Key Response Summary:**
WhisperFlow SDK initialized in `main.dart`. Created `VoiceCommandHandler` class that maps transcribed text to ArticleProvider actions. Commands parsed with simple keyword matching: contains('like') → `likeArticle()`, contains('save') → `saveArticle()`, startsWith('add note') → `addNote(transcription after 'add note:')`.

**Decision:** Modified.

**Why:** Accepted the WhisperFlow integration approach but added offline awareness — if connectivity is false, the voice command still executes (queues the action) and speaks back "Action saved offline, will sync when connected." This keeps voice commands consistent with the offline-first philosophy of the whole app.

**Integration Notes:**
- Added `voice_action_fab.dart` — floating mic button on ArticleDetailScreen
- WhisperFlow session starts on FAB press, stops on release (push-to-talk)
- Transcription result fed into `VoiceCommandHandler.handle(transcription, articleId)`
- All voice-triggered actions go through the same `SyncQueue.enqueue()` path as manual taps
- Haptic feedback on voice command recognition (same as manual offline actions)

---

### Prompt 16
**Tool:** Antigravity
**Prompt:**
> "Add visual feedback for WhisperFlow voice recording state. Show a pulsing waveform animation while recording, display the transcription text as it comes in, and show the recognized command before executing it."

**Key Response Summary:**
Created `VoiceRecordingOverlay` widget with animated waveform bars using `AnimationController`. Transcription text streams in real-time. Recognized command shown in a confirmation chip ("Executing: Like Article") before action fires.

**Decision:** Accepted.

**Why:** Visual feedback is critical for voice UX — users need to know the app heard them correctly before an action executes, especially for irreversible actions like adding notes.

---

## PHASE 10 — Unit Tests

### Prompt 17
**Tool:** Codex
**Prompt:**
> "Write unit tests for sync_queue_test.dart. Test 1: deduplication prevents double-enqueue of same actionType+entityId. Test 2: last-write-wins replaces existing note with newer note. Test 3: exponential backoff doubles delay correctly (5s → 10s → 20s). Use mocktail package."

**Key Response Summary:**
Generated 3 tests using `MockHiveQueueDao` and `MockSyncObservability`. Dedup test enqueues same action twice, asserts `pendingCount == 1`. LWW test checks payload of second note replaced first. Backoff test asserts `delaySeconds` doubles each retry.

**Decision:** Accepted.

**Why:** These 3 tests directly prove the 3 most critical requirements the evaluators will test: no duplicates, correct conflict resolution, and correct retry timing. Running them produces green output that goes directly into verification evidence.

---

### Prompt 18
**Tool:** Codex
**Prompt:**
> "Write sync_engine_test.dart. Test: simulate transient Firebase failure on first call, success on second call. Assert item is retried (not dropped), retryCount increments, nextRetryAt is set, and item is eventually removed from queue on success."

**Key Response Summary:**
Generated test using `MockFirestoreRemote` that throws on first `applyAction()` call, succeeds on second. Asserts `retryCount == 1` after first failure, `nextRetryAt != null`, then after second attempt `pendingCount == 0`.

**Decision:** Accepted.

**Why:** This test directly produces the "retry scenario with idempotency" verification evidence required by the assignment.

---

## PHASE 11 — Final Review

### Prompt 19
**Tool:** Claude
**Prompt:**
> "Verify the complete project against all assignment requirements. Check: local-first UX, offline writes, idempotency, conflict strategy, retry + backoff, queue persistence across restart, observability logs + counters."

**Key Response Summary:**
All 7 requirements confirmed met. Flagged one gap: README needed explicit explanation of why LWW was chosen over merge strategy with documented tradeoffs.

**Decision:** Accepted — updated README accordingly.

**Why:** The evaluators explicitly check for "explain why" on conflict strategy. A bare "we use LWW" answer fails. The answer must include: what LWW means, why it's appropriate for a notes/likes app, what the tradeoff is (concurrent edits on two devices overwrite each other), and what the alternative (OT/CRDT merge) would cost in complexity.

---

## Summary Table

| # | Tool | Area | Decision | Key Insight |
|---|------|------|----------|-------------|
| 1 | Claude | Architecture planning | Accepted | Full plan before coding saved hours |
| 2 | Claude | Master prompt creation | Accepted | Single context doc = consistent AI output |
| 3 | Antigravity | Folder structure + models | Accepted | Build runner ran clean first try |
| 4 | Cursor | DAOs + Repository | Accepted | UUID as Firestore doc ID = zero-cost idempotency |
| 5 | Antigravity | Sync Queue + Engine | Modified | Changed Future.delayed → timestamp (survives restart) |
| 6 | Antigravity | Last-Write-Wins | Accepted | Replace not append on same actionType+entityId |
| 7 | Cursor | Provider rewrite | Accepted | Simpler than BLoC for 1-day sprint |
| 8 | Cursor | connectivity_plus fix | Modified | v5 returns List not single value |
| 9 | Antigravity | main.dart wiring | Accepted | Manual DI = transparent, interview-friendly |
| 10 | Antigravity | UI screens + widgets | Accepted | SyncStatusBanner proves observability visually |
| 11 | Antigravity | Infinite scroll + shimmer | Accepted | No external shimmer package needed |
| 12 | Antigravity | Glassmorphism + haptics | Accepted | Haptics reinforce offline action was registered |
| 13 | Google Stitch | Design system + tokens | Modified | Kept tokens, swapped Google Fonts for local assets |
| 14 | Google Stitch | ArticleCard design | Modified | Kept design, rewrote widget to use Provider |
| 15 | WhisperFlow | Voice command integration | Modified | Added offline awareness to voice responses |
| 16 | Antigravity | Voice recording UI | Accepted | Confirmation chip prevents accidental actions |
| 17 | Codex | Sync queue unit tests | Accepted | 3 tests cover dedup + LWW + backoff |
| 18 | Codex | Sync engine retry test | Accepted | Directly produces required verification evidence |
| 19 | Claude | Final requirements check | Accepted | Found README gap on LWW explanation |

---

## Key Decisions Made (Interview Ready)

**Why Provider over BLoC?**
Provider requires less boilerplate for a 1-day sprint. BLoC's explicit events/states are valuable in large teams but add 3-4 extra files per feature. The core sync logic (queue, retry, idempotency) is state-management agnostic.

**Why Last-Write-Wins over Merge?**
For a likes/notes app, the last user action IS the intent. Merging two notes from different offline sessions produces unpredictable output. LWW is predictable, simple to implement, and easy to explain. The tradeoff (concurrent edits on two devices overwrite each other) is acceptable for this use case.

**Why UUID as Firestore document ID?**
Zero server-side logic required for idempotency. The same UUID written 10 times produces exactly 1 document. No need for server functions, transaction checks, or dedup tables.

**Why timestamp-based backoff over Future.delayed?**
`Future.delayed` only lives in memory — it disappears when the app is killed. Storing `nextRetryAt` as a DateTime in Hive means the backoff window is respected even after app restart.