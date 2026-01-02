# 📖 Offline Support - Study & Design Document

## Table of Contents
1. [Design Patterns Used](#design-patterns)
2. [Architecture Decisions](#architecture-decisions)
3. [Offline Strategies](#offline-strategies)
4. [Data Synchronization Models](#sync-models)
5. [Conflict Resolution](#conflict-resolution)
6. [Best Practices](#best-practices)
7. [Performance Considerations](#performance)
8. [Alternative Approaches](#alternatives)

---

## 1. Design Patterns Used

### **A. Repository Pattern**

**Purpose:** Abstract data sources (Firestore + SQLite)

**Benefits:**
- Single source of truth for data access
- Easy to test (mock repositories)
- Flexible data source switching
- Centralized caching logic

**Implementation:**
```dart
class ItemRepository {
  final FirebaseFirestore _firestore;
  final LocalDataSource _localDataSource;
  
  // Single method handles both online and offline
  Future<void> updateItem({required String itemId, String? title}) async {
    if (await _isOnline()) {
      await _firestore.collection('items').doc(itemId).update({...});
      await _localDataSource.updateCachedItem(updatedItem);
    } else {
      await _localDataSource.updateCachedItem(updatedItem);
      await _localDataSource.addPendingOperation(...);
    }
  }
}
```

**Why this pattern?**
- ✅ UI doesn't need to know about Firestore or SQLite
- ✅ Easy to add new data sources (e.g., REST API)
- ✅ Business logic stays in one place

---

### **B. BLoC Pattern (Business Logic Component)**

**Purpose:** Separate business logic from UI

**Benefits:**
- Reactive state management
- Testable business logic
- Clear data flow
- Platform-agnostic

**Implementation:**
```dart
class ItemListBloc extends Bloc<ItemListEvent, ItemListState> {
  final ItemRepository itemRepository;
  final SyncService? syncService;
  
  Future<void> _onLoadItems(LoadItems event, Emitter<ItemListState> emit) async {
    // Sync before fetching
    if (syncService != null) {
      await syncService!.syncPendingOperations();
    }
    
    // Fetch items (repository handles online/offline)
    final items = await itemRepository.fetchItems(...);
    
    emit(state.copyWith(items: items, status: ItemListStatus.success));
  }
}
```

**Why BLoC?**
- ✅ Clear separation: UI → BLoC → Repository → Data
- ✅ Easy to test each layer independently
- ✅ Reactive updates with streams

---

### **C. Service Layer Pattern (SyncService)**

**Purpose:** Encapsulate sync logic separately

**Benefits:**
- Single responsibility (only handles sync)
- Reusable across different features
- Easy to enhance (retry logic, conflict resolution)

**Implementation:**
```dart
class SyncService {
  bool _isSyncing = false; // Prevent concurrent syncs
  
  Future<void> syncPendingOperations() async {
    if (_isSyncing || !await isOnline()) return;
    
    _isSyncing = true;
    try {
      final pendingOps = await _localDataSource.getPendingOperations();
      for (final op in pendingOps) {
        await _executeOperation(op);
        await _localDataSource.removePendingOperation(op['id']);
      }
    } finally {
      _isSyncing = false;
    }
  }
}
```

**Why separate service?**
- ✅ Can be called from anywhere (BLoC, background task)
- ✅ Doesn't clutter repository code
- ✅ Easy to add background sync (WorkManager)

---

### **D. Observer Pattern (ConnectivityBloc)**

**Purpose:** Monitor network changes and react

**Benefits:**
- Automatic sync on reconnection
- Real-time UI updates
- Decoupled from business logic

**Implementation:**
```dart
class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  ConnectivityBloc({this.syncService}) {
    // Subscribe to connectivity changes
    _connectivity.onConnectivityChanged.listen((result) {
      add(ConnectivityChanged(result));
    });
  }
  
  Future<void> _onConnectivityChanged(event, emit) async {
    if (isOnline && _wasOffline) {
      // Trigger sync automatically
      await syncService?.syncPendingOperations();
    }
  }
}
```

**Why Observer?**
- ✅ Automatic sync without user action
- ✅ Loose coupling (connectivity doesn't know about items)
- ✅ Easy to add more observers (analytics, logging)

---

## 2. Architecture Decisions

### **Decision 1: Optimistic Updates**

**What:** Update local cache immediately, sync later

**Why chosen:**
- ✅ Better UX (instant feedback)
- ✅ App feels fast even offline
- ✅ Users don't wait for network

**Trade-offs:**
- ❌ Possible sync failures (need retry)
- ❌ Potential conflicts (if data changes on server)

**Alternative:** Pessimistic updates (wait for server confirmation)
- ✅ No conflicts
- ❌ Poor UX (slow, can't work offline)

**Example:**
```dart
// Optimistic: User sees change immediately
await _localDataSource.updateCachedItem(item); // Local first
await _localDataSource.addPendingOperation(...); // Queue for later
return success; // User sees success

// vs Pessimistic: User waits
await _firestore.update(...); // Wait for server
if (success) {
  await _localDataSource.updateCachedItem(item); // Then cache
}
```

---

### **Decision 2: SQLite for Local Storage**

**Why SQLite over Hive/SharedPreferences?**

| Feature | SQLite | Hive | SharedPreferences |
|---------|--------|------|-------------------|
| Relational queries | ✅ | ❌ | ❌ |
| Complex filtering | ✅ | Limited | ❌ |
| Indexes | ✅ | ❌ | ❌ |
| Large datasets | ✅ | ✅ | ❌ |
| SQL support | ✅ | ❌ | ❌ |
| Transactions | ✅ | ❌ | ❌ |

**Use cases:**
```dart
// SQLite: Complex query with filtering
SELECT * FROM items 
WHERE userId = ? 
  AND category = ? 
  AND isActive = 1 
ORDER BY createdAt DESC 
LIMIT 15

// Hive: Would need to load all and filter in Dart
final allItems = box.values.toList();
final filtered = allItems
  .where((item) => item.userId == userId && ...)
  .toList();
```

**Why not Hive for this project?**
- ❌ No native filtering (need to load all into memory)
- ❌ No indexes (slow for large datasets)
- ❌ No SQL (harder to do complex queries)

**When to use Hive instead:**
- Small datasets (<1000 items)
- Simple key-value storage
- No complex queries needed
- Need extremely fast writes

---

### **Decision 3: Separate Sync Queue Table**

**Why dedicated `pending_operations` table?**

**Design:**
```sql
items (cache)
├── Stores actual item data
└── Optimized for reads (indexes)

pending_operations (queue)
├── Stores operations to execute
└── Optimized for FIFO (first in, first out)
```

**Benefits:**
- ✅ Clear separation of concerns
- ✅ Easy to query pending items: `SELECT * FROM pending_operations`
- ✅ Can add retry logic without touching cache
- ✅ Can implement priority queue (VIP users first)

**Alternative:** Store sync flag in items table
```sql
-- ❌ Messy approach
CREATE TABLE items (
  ...
  needsSync INTEGER, -- 0 or 1
  syncOperation TEXT -- 'create', 'update', 'delete'
)
```
**Why not?**
- ❌ Mixes concerns (cache + queue)
- ❌ Hard to track multiple operations on same item
- ❌ Can't store operation metadata (timestamp, retry count)

---

### **Decision 4: Force Server Fetch After Sync**

**Problem:** Firestore has its own cache layer

```dart
// ❌ Problem: Returns cached data
await query.get();
// Firestore SDK caches responses for performance
// After sync, this returns OLD data from cache
```

**Solution:** Force server fetch
```dart
// ✅ Solution: Bypass Firestore cache
await query.get(const GetOptions(source: Source.server));
// Always fetches from server (Firebase servers)
```

**Why needed?**
1. Sync pushes changes to Firestore server
2. Firestore SDK has local cache (separate from SQLite)
3. Without `Source.server`, SDK returns stale cache
4. User sees old data even after successful sync

**Trade-off:**
- ✅ Always fresh data
- ❌ Slower (network request)
- ❌ Uses more bandwidth

**Optimization:** Use cache for initial load, server for refresh
```dart
// Initial load: Use cache for speed
final cached = await query.get(GetOptions(source: Source.cache));

// Background: Fetch from server
final fresh = await query.get(GetOptions(source: Source.server));
if (fresh != cached) {
  // Update UI
}
```

---

## 3. Offline Strategies

### **Strategy Comparison**

| Strategy | Description | Pros | Cons | Use Case |
|----------|-------------|------|------|----------|
| **Cache-First** | Show cache, fetch in background | Fast, works offline | May show stale data | Social feeds |
| **Network-First** | Try network, fallback to cache | Always fresh | Slow when offline | Banking apps |
| **Cache-Only** | Never fetch from network | Very fast | Always stale | Read-only content |
| **Network-Only** | Never use cache | Always fresh | Doesn't work offline | Real-time data |
| **Stale-While-Revalidate** | Show cache, update in background | Fast + fresh | Complex logic | Our app! |

### **Our Implementation: Stale-While-Revalidate**

```dart
Future<List<ItemModel>> fetchItems() async {
  if (isOnline) {
    // 1. Fetch from server
    final items = await _firestore.get(Source.server);
    
    // 2. Update cache
    await _localDataSource.cacheItems(items);
    
    // 3. Return fresh data
    return items;
  } else {
    // 4. Return cached data
    return await _localDataSource.getCachedItems();
  }
}
```

**Flow:**
```
Online:  Server → Cache → UI (fresh)
Offline: Cache → UI (stale but available)
```

---

## 4. Data Synchronization Models

### **A. Event Sourcing (What We Use)**

**Concept:** Store operations as events, replay them

**Implementation:**
```dart
// Store operation
{
  "operation": "update",
  "itemId": "abc123",
  "itemData": {"title": "New Title"},
  "timestamp": 1735689600
}

// Replay operation
await _firestore.doc(itemId).update(itemData);
```

**Benefits:**
- ✅ Can replay operations in order
- ✅ Audit trail (know what changed when)
- ✅ Can implement undo/redo

**Limitations:**
- ❌ No conflict resolution (last write wins)
- ❌ Can't handle concurrent edits

---

### **B. Operational Transformation (Advanced)**

**Concept:** Transform operations to handle conflicts

**Example:**
```
User A offline: title = "Hello"
User B offline: title = "World"

Sync conflict!

OT solution:
1. Detect conflict (both changed title)
2. Apply transformation rules
3. Merge: title = "Hello World" (or show conflict UI)
```

**Not implemented because:**
- ❌ Complex to implement
- ❌ Our use case: Single user per device (no conflicts)
- ❌ If needed, Firestore transactions handle it server-side

---

### **C. CRDT (Conflict-Free Replicated Data Types)**

**Concept:** Data structures that merge automatically

**Example:**
```dart
// Counter CRDT
User A offline: count++ → 5
User B offline: count++ → 5
Merge: count = 6 (both increments applied)

// vs Regular counter
User A: count = 5
User B: count = 5
Merge: count = 5 (last write wins, one increment lost!)
```

**Not implemented because:**
- ❌ Overkill for simple CRUD
- ❌ Firestore doesn't natively support CRDTs
- ✅ Good for collaborative apps (Google Docs)

---

## 5. Conflict Resolution

### **Our Approach: Last Write Wins**

**Strategy:**
```dart
// Latest timestamp wins
if (localTimestamp > serverTimestamp) {
  // Local version is newer, push to server
  await _firestore.update(localData);
} else {
  // Server version is newer, update local
  await _localDataSource.updateCache(serverData);
}
```

**Why this works:**a
- Single user per device (no concurrent edits)
- Operations have timestamps
- Server is source of truth

**Limitation:**
```
Device A: Edit title at 10:00 AM
Device B: Edit title at 10:05 AM
Both sync at 10:10 AM

Result: Device B's edit wins (newer timestamp)
Device A's edit is lost!
```

---

### **Alternative: Vector Clocks**

**Concept:** Track causality, not just time

**Implementation:**
```dart
{
  "title": "New Title",
  "version": {
    "deviceA": 3, // Device A made 3 changes
    "deviceB": 2  // Device B made 2 changes
  }
}

// On sync, compare versions
if (localVersion > serverVersion) {
  // Local is newer
} else if (serverVersion > localVersion) {
  // Server is newer
} else {
  // Concurrent edits! Need to resolve
}
```

**Not implemented because:**
- ❌ Complex to implement
- ❌ Firestore doesn't support vector clocks natively
- ❌ Our use case doesn't need it (single user)

---

## 6. Best Practices

### **✅ DO**

**1. Always check connectivity before operations**
```dart
final isOnline = await _connectivity.checkConnectivity();
if (isOnline.contains(ConnectivityResult.wifi) || 
    isOnline.contains(ConnectivityResult.mobile)) {
  // Execute online operation
}
```

**2. Update cache immediately (optimistic)**
```dart
await _localDataSource.updateCache(item); // Fast!
await _queueForSync(item); // Background
```

**3. Use transactions for atomic operations**
```dart
final db = await database;
await db.transaction((txn) async {
  await txn.update('items', item);
  await txn.insert('pending_operations', operation);
});
```

**4. Add retry logic with exponential backoff**
```dart
int retryCount = 0;
while (retryCount < maxRetries) {
  try {
    await _executeOperation(op);
    break; // Success!
  } catch (e) {
    retryCount++;
    await Future.delayed(Duration(seconds: pow(2, retryCount)));
  }
}
```

**5. Validate data before sync**
```dart
if (operation['itemData'] == null || operation['itemData'].isEmpty) {
  // Skip invalid operation
  await _localDataSource.removePendingOperation(operation['id']);
}
```

---

### **❌ DON'T**

**1. Don't use .toString() for JSON**
```dart
// ❌ WRONG
'itemData': itemData.toString() // "{key: value}"

// ✅ CORRECT
'itemData': jsonEncode(itemData) // '{"key":"value"}'
```

**2. Don't ignore sync failures**
```dart
// ❌ WRONG
try {
  await sync();
} catch (e) {
  // Ignore
}

// ✅ CORRECT
try {
  await sync();
} catch (e) {
  await _incrementRetryCount(operation);
  if (retryCount > maxRetries) {
    await _logFailedOperation(operation);
  }
}
```

**3. Don't sync on every state change**
```dart
// ❌ WRONG: Syncs too often
_connectivity.onConnectivityChanged.listen((result) {
  syncService.sync(); // Triggered multiple times!
});

// ✅ CORRECT: Sync only on offline → online
if (isOnline && _wasOffline) {
  await syncService.sync();
}
```

**4. Don't expose implementation details to UI**
```dart
// ❌ WRONG
class HomeScreen {
  void saveItem() {
    if (isOnline) {
      firestore.save(item);
    } else {
      sqlite.save(item);
    }
  }
}

// ✅ CORRECT
class HomeScreen {
  void saveItem() {
    itemRepository.save(item); // Repository handles offline/online
  }
}
```

---

## 7. Performance Considerations

### **Database Optimization**

**1. Indexes for frequent queries**
```sql
CREATE INDEX idx_userId_category ON items(userId, category);
CREATE INDEX idx_createdAt ON items(createdAt DESC);

-- Query now uses index (fast)
SELECT * FROM items 
WHERE userId = ? AND category = ? 
ORDER BY createdAt DESC;
```

**2. Limit query results**
```dart
// ✅ Pagination
final items = await query.limit(15).get();

// ❌ Load everything (slow for large datasets)
final items = await query.get();
```

**3. Batch operations**
```dart
// ✅ Batch insert (fast)
await db.transaction((txn) async {
  for (var item in items) {
    await txn.insert('items', item.toMap());
  }
});

// ❌ Individual inserts (slow)
for (var item in items) {
  await db.insert('items', item.toMap());
}
```

---

### **Network Optimization**

**1. Compress data before storing**
```dart
import 'dart:convert';
import 'package:gzip/gzip.dart';

// Store compressed JSON
final compressed = gzip.encode(utf8.encode(jsonEncode(data)));
await db.insert('items', {'data': compressed});
```

**2. Debounce sync operations**
```dart
Timer? _syncTimer;

void scheduleSyncDebounced() {
  _syncTimer?.cancel();
  _syncTimer = Timer(Duration(seconds: 5), () {
    syncService.sync();
  });
}
```

**3. Use incremental sync**
```dart
// Only sync items changed after last sync
final lastSync = await _getLastSyncTimestamp();
final query = _firestore
    .where('updatedAt', isGreaterThan: lastSync)
    .get();
```

---

### **Memory Optimization**

**1. Stream large datasets**
```dart
// ✅ Stream (memory efficient)
Stream<List<ItemModel>> watchItems() {
  return _firestore
      .snapshots()
      .map((snapshot) => snapshot.docs.map(...).toList());
}

// ❌ Load all at once
Future<List<ItemModel>> getAllItems() {
  return _firestore.get(); // All in memory!
}
```

**2. Clear old cache periodically**
```dart
Future<void> clearOldCache() async {
  final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
  await db.delete(
    'items',
    where: 'updatedAt < ?',
    whereArgs: [thirtyDaysAgo.millisecondsSinceEpoch],
  );
}
```

---

## 8. Alternative Approaches

### **A. Firebase Offline Persistence (Built-in)**

**What:** Firestore has built-in offline cache

```dart
// Enable offline persistence
FirebaseFirestore.instance.settings = Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);

// That's it! Firestore handles offline automatically
```

**Pros:**
- ✅ Zero code (Firebase does it all)
- ✅ Automatic sync
- ✅ Handles conflicts

**Cons:**
- ❌ No control over sync logic
- ❌ Can't customize retry behavior
- ❌ Can't queue custom operations
- ❌ Cache size limits (100 MB default)

**Why we didn't use it:**
- Need custom sync queue for specific operations
- Want full control over when sync happens
- Need to store additional metadata (retry count)

---

### **B. Background Sync (WorkManager)**

**What:** Sync even when app is closed

```dart
import 'package:workmanager/workmanager.dart';

void main() {
  Workmanager().initialize(callbackDispatcher);
  Workmanager().registerPeriodicTask(
    "sync-task",
    "syncPendingOperations",
    frequency: Duration(hours: 1),
  );
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await SyncService().syncPendingOperations();
    return true;
  });
}
```

**Pros:**
- ✅ Syncs even when app closed
- ✅ Battery efficient
- ✅ Reliable

**Cons:**
- ❌ Complex setup
- ❌ Platform-specific (iOS restrictions)

**When to use:**
- Long-running sync tasks
- Critical data that must sync
- Background uploads/downloads

---

### **C. Delta Sync (Only Changed Data)**

**What:** Only sync differences, not entire documents

```dart
// Track changes
{
  "itemId": "abc123",
  "changes": {
    "title": {"old": "Hello", "new": "World"},
    "isActive": {"old": true, "new": false}
  }
}

// Apply deltas
await _firestore.doc(itemId).update({
  "title": changes["title"]["new"],
  "isActive": changes["isActive"]["new"]
});
```

**Pros:**
- ✅ Saves bandwidth
- ✅ Faster sync
- ✅ Can implement undo/redo

**Cons:**
- ❌ Complex to implement
- ❌ Need to track every change
- ❌ Merge conflicts more complex

---

## Summary: Our Architecture Choices

| Component | Choice | Why |
|-----------|--------|-----|
| **Offline Strategy** | Optimistic Updates | Best UX |
| **Local DB** | SQLite | Complex queries, indexes |
| **Sync Model** | Event Sourcing | Simple, audit trail |
| **Conflict Resolution** | Last Write Wins | Single user per device |
| **Pattern** | Repository + BLoC | Clean separation |
| **Cache Strategy** | Stale-While-Revalidate | Fast + fresh |

---

## Next Steps for Production

### **1. Add Conflict Detection**
```dart
if (localVersion != serverVersion) {
  // Show conflict resolution UI
  showDialog(
    title: "Conflict Detected",
    options: ["Keep Local", "Use Server", "Merge"]
  );
}
```

### **2. Implement Background Sync**
```dart
Workmanager().registerPeriodicTask(
  "background-sync",
  "sync",
  frequency: Duration(hours: 1),
);
```

### **3. Add Sync Status UI**
```dart
if (syncService.isSyncing) {
  return LinearProgressIndicator();
}
```

### **4. Analytics & Monitoring**
```dart
await analytics.logEvent(
  name: 'sync_completed',
  parameters: {
    'items_synced': pendingCount,
    'duration_ms': syncDuration,
  }
);
```

---

🎓 **You now understand the complete design and architecture of offline support!**
