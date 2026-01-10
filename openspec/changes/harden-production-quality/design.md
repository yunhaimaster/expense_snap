# Design: Harden Production Quality

## Context

The expense_snap app has completed 13 polish phases with 757+ tests and is functionally complete. However, a deep code review identified 30 issues that prevent true production excellence. This design document captures architectural decisions for addressing these issues systematically.

### Stakeholders
- **End Users**: Benefit from stability, performance, fewer edge case bugs
- **Developers**: Better debugging, clearer patterns, maintainability
- **Operations**: Observability, structured logs for issue triage

### Constraints
- Must maintain backward compatibility with existing data
- No breaking changes to user-facing behavior
- Offline-first architecture must be preserved
- Performance must not regress

## Goals / Non-Goals

### Goals
1. Eliminate all High priority issues (4)
2. Address all Medium priority issues (19)
3. Improve test coverage to 800+ tests (from 757+)
4. Establish patterns for future development
5. Add observability for production debugging

### Non-Goals
1. Adding new user-facing features
2. Changing UI/UX design
3. Migrating to different state management
4. Adding analytics/telemetry

## Decisions

### Decision 1: Database Thread Safety

**Choice**: Use `synchronized` package for mutex lock on database initialization

**Status**: ✅ Approved - minimal footprint, proven solution

**Rationale**:
- Current `Completer` approach has race window between null check and creation
- Mutex ensures exactly-once initialization regardless of concurrent access
- Minimal performance overhead (only during first access)

**Alternatives Considered**:
| Option | Pros | Cons |
|--------|------|------|
| synchronized package | Simple, proven | New dependency |
| Manual lock with Completer | No dependency | Complex, error-prone |
| Singleton with lazy init | Dart native | Still has race window |

**Implementation**:
```dart
import 'package:synchronized/synchronized.dart';

final _initLock = Lock();

Future<Database> get database async {
  return _initLock.synchronized(() async {
    _database ??= await _initDatabase();
    return _database!;
  });
}
```

### Decision 2: Streaming Export for Large Datasets

**Choice**: Implement chunked processing with progress reporting

**Status**: ✅ Approved with feature flag

**Rationale**:
- Current implementation loads up to 10,000 expenses into memory
- Causes ANR on devices with limited RAM
- Streaming allows processing in 100-item chunks

**Implementation**:
```dart
Stream<ExportProgress> exportLargeDataset(int year, int month) async* {
  final count = await repository.getExpenseCount(year, month);
  for (int offset = 0; offset < count; offset += 100) {
    final chunk = await repository.getExpenses(year, month, offset: offset, limit: 100);
    yield ExportProgress(processed: offset + chunk.length, total: count);
    await _processChunk(chunk);
  }
}
```

**Threshold**: Use streaming for >500 expenses, direct load for smaller sets.

**Feature Flag**: `USE_STREAMING_EXPORT` (default: true) for rollback capability.

### Decision 3: Result Pattern Standardization

**Choice**: Eliminate all type casts, use `fold()` or pattern matching consistently

**Rationale**:
- Current code has dangerous casts: `(result as Failure).error`
- These fail at runtime if result type changes
- `fold()` is type-safe and self-documenting

**Pattern**:
```dart
// BAD - dangerous cast
if (imageResult.isFailure) {
  return Result.failure((imageResult as Failure).error);
}

// GOOD - type-safe fold
return imageResult.fold(
  onFailure: (error) => Result.failure(error),
  onSuccess: (paths) => _processImages(paths),
);
```

### Decision 4: OCR Rate Limiting

**Choice**: Debounce OCR requests with 2-second minimum interval

**Rationale**:
- Rapid OCR requests exhaust device resources
- ML Kit has internal queuing that can cause memory pressure
- 2 seconds allows user to compose request

**Implementation**:
```dart
DateTime? _lastOcrRequest;
static const _minOcrInterval = Duration(seconds: 2);

Future<OcrResult> processImage(File image) async {
  final now = DateTime.now();
  if (_lastOcrRequest != null &&
      now.difference(_lastOcrRequest!) < _minOcrInterval) {
    return OcrResult.rateLimited();
  }
  _lastOcrRequest = now;
  // ... process
}
```

### Decision 5: Structured Logging

**Choice**: Add structured fields to AppLogger for aggregation

**Status**: ✅ Console only for now, file logging deferred to future

**Rationale**:
- Current string concatenation loses metadata
- Structured logs enable filtering by tag, user action, error type
- Prepares for future log aggregation service

**Format**:
```dart
class LogEntry {
  final LogLevel level;
  final String tag;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? fields;
  final Object? error;
  final StackTrace? stackTrace;
}
```

### Decision 6: Orphaned Image Cleanup

**Choice**: Periodic filesystem scan with database cross-reference

**Status**: ✅ Run on first app resume after 24 hours

**Rationale**:
- Images can become orphaned if app crashes during expense deletion
- Current cleanup only handles 30-day soft delete
- Filesystem scan catches all orphans

**Implementation**:
- Run during app background/resume cycle (after 24h since last cleanup)
- Scan `receipts/` directory
- Cross-reference with database `image_path` values
- Delete files not referenced by any expense
- Log orphan count for observability
- Continue processing on individual file deletion failures

### Decision 7: Provider Dispose Cleanup

**Choice**: Audit and fix all providers with StreamSubscription or Timer

**Rationale**:
- Some providers hold subscriptions without proper cleanup
- Causes memory leaks and stale listeners
- Standard pattern: cancel in `dispose()`

**Known Affected Providers** (may find more during audit):
- `ConnectivityProvider` - has stream subscription
- `ExchangeRateProvider` - may have refresh timer
- `SettingsProvider` - listener cleanup

### Decision 8: Exchange Rate Force Refresh

**Choice**: Long-press gesture to bypass rate limit

**Rationale**:
- Normal refresh has 30-second rate limit to prevent API abuse
- Users occasionally need immediate refresh (e.g., after manual entry mistake)
- Long-press is discoverable but not accidentally triggered

**Implementation**:
- Short press: normal refresh (respects 30-second rate limit)
- Long press: force refresh (bypasses rate limit, single immediate request)
- Show confirmation toast on force refresh

## Risks / Trade-offs

| Risk | Impact | Mitigation |
|------|--------|------------|
| Mutex adds latency | Low | Only first DB access, <10ms |
| Streaming export complexity | Medium | Feature flag `USE_STREAMING_EXPORT`, extensive tests |
| Result refactor scope | Low | Search-replace with tests |
| Orphan cleanup deletes valid files | High | Double-check DB before delete, log all deletions |

## Migration Plan

### Phase Order
Phases are ordered by dependency and risk:
1. **Phase 14** (Critical) - Must be first, foundational fixes
2. **Phase 17** (Error Handling) - Enables better debugging for remaining phases
3. **Phase 15** (Security) - Independent, can parallel with 16
4. **Phase 16** (Performance) - Independent, can parallel with 15
5. **Phase 18** (Testing) - Add tests for all previous changes
6. **Phase 19** (Edge Cases) - Requires stable foundation
7. **Phase 20** (Observability) - Final polish

### Rollback Strategy
Each phase is independently deployable. If issues arise:
1. Revert phase-specific commits
2. Database schema unchanged (no migration needed)
3. Feature flag for streaming export (`USE_STREAMING_EXPORT=false`)

## Resolved Decisions

The following items were previously open questions, now resolved:

| Question | Decision | Rationale |
|----------|----------|-----------|
| synchronized package dependency | ✅ Accept | Proven, minimal footprint, safer than manual implementation |
| Orphan cleanup frequency | ✅ First resume after 24h | Balance between thoroughness and battery impact |
| Structured logging destination | ✅ Console only | File logging adds complexity; defer until needed |
| Test coverage target | ✅ 800 tests | From current 757+, achievable with planned test additions |
