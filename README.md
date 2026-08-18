# Flutter Task Manager

An offline-first Task Manager built with Flutter, Cloud Firestore, and Hive
local storage. Tasks are created, edited, and browsed instantly from local
storage; changes sync to Firestore in the background whenever a network
connection is available.

## Features

- Create, edit, delete, and view tasks (title, description, priority, due
  date, completion status, created date)
- Full offline support: the app works with no network at all, and data
  survives app restarts
- Automatic background sync to Firestore when connectivity returns, with a
  visible sync status indicator (Offline / Syncing / Synced / Sync issue)
- Local, in-memory search (by title), filter (All / Pending / Completed),
  and sort (due date / priority / created date) — no extra Firestore reads
- Loading, empty, and error states throughout
- Swipe-to-delete with confirmation, pull-to-refresh to force a manual sync
- Form validation on the add/edit screen
- Light & dark theme toggle
- Unit tests for the model and core filtering/sorting logic

## Architecture

```
lib/
  models/
    task.dart                 # Task + TaskPriority, fromJson/toJson (local),
                               # fromFirestore/toFirestore (remote)
  services/
    local_storage_service.dart# Hive-backed persistent local cache
    firestore_service.dart    # Thin Cloud Firestore data source
    connectivity_service.dart # Online/offline detection stream
    task_repository.dart      # Offline-first sync orchestration (the core)
  providers/
    task_provider.dart        # ChangeNotifier: state, search/filter/sort,
                               # CRUD — all business logic lives here
  screens/
    task_list_screen.dart     # List + search + filter + sort + sync badge
    add_edit_task_screen.dart # Create/edit form with validation
    task_details_screen.dart  # Full task detail view
  widgets/                    # Small, dumb, reusable UI pieces
  utils/                      # Theme + date formatting helpers
  firebase_options.dart       # Placeholder — see Setup below
  main.dart                   # Composition root: wires services -> provider -> UI
test/
  task_model_test.dart        # Unit tests
firestore.rules               # Example security rules
```

**Why this shape:** widgets never talk to Hive or Firestore directly. They
only read from `TaskProvider` and call its methods. `TaskProvider` never
touches Hive/Firestore directly either — it goes through `TaskRepository`,
which is the only place that knows how local storage and Firestore relate to
each other. This keeps business logic out of the UI layer and makes each
piece independently testable.

### How offline-first sync works

1. **Local storage is the source of truth for the UI.** Every screen reads
   from `TaskProvider`, which is backed by `TaskRepository.getLocalTasks()`
   — a synchronous read from Hive. This is why the app opens instantly and
   works with zero connectivity.
2. **Writes go local-first.** `createTask` / `updateTask` / `deleteTask`
   save to Hive immediately (marking the task `isDirty: true`), then attempt
   a Firestore push if online. If offline, the change just sits in Hive,
   flagged as pending.
3. **Reconnecting triggers a sync.** `ConnectivityService` emits a stream of
   online/offline transitions. `TaskRepository` listens for that and calls
   `syncWithFirestore()` automatically when the device comes back online.
4. **Sync is two-way and non-destructive.** `syncWithFirestore()` first
   pushes every locally dirty/deleted task to Firestore, then pulls the
   latest remote snapshot and merges it in — but it never overwrites a local
   task that still has unsynced local changes, so an offline edit can't be
   silently clobbered by a stale remote read.
5. **Deletes** are handled as soft-delete tombstones (`isDeleted: true`)
   when offline, so they can be replayed as real Firestore deletes once
   connectivity returns; when online, deletes go straight to Firestore.

### Search, filter & sort

`TaskProvider.visibleTasks` applies the current search query, filter, and
sort entirely against the in-memory `_allTasks` list (sourced from Hive).
No Firestore queries are issued for these operations, per the requirement.

## Setup

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Configure Firebase

This project ships with a **placeholder** `lib/firebase_options.dart` so it
compiles out of the box, but Firestore calls will fail gracefully until you
connect a real project (the app keeps working — it just won't sync).

To connect your own Firebase project:

```bash
# One-time installs
dart pub global activate flutterfire_cli
npm install -g firebase-tools

firebase login
flutterfire configure
```

`flutterfire configure` will ask you to pick/create a Firebase project and
which platforms to support, then overwrite `lib/firebase_options.dart` with
real values and register the app in the Firebase console automatically.



### 3. Run the app

```bash
flutter run
```

## Bonus ideas (not implemented, natural next steps)

- **Firebase Authentication** — add sign-in and store a `userId` on each
  task; switch `firestore.rules` to the per-user block already stubbed in
  the file.
- **FCM notifications** — reminders for upcoming due dates.
- **Advanced offline sync** — conflict resolution UI when the same task was
  edited on two devices while both were offline (currently: last sync-write
  wins per field-set, local dirty state always takes priority over remote).
- **More tests** — widget tests for `TaskProvider` using a fake
  `TaskRepository`.

## Packages used

| Package | Purpose |
|---|---|
| `cloud_firestore`, `firebase_core` | Remote data source |
| `hive`, `hive_flutter` | Local persistent storage |
| `connectivity_plus` | Online/offline detection |
| `provider` | State management |
| `uuid` | Task ID generation |
| `intl` | Date formatting |
