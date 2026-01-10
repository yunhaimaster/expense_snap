# Tasks: Harden Production Quality

> **Phase Ordering Note**: While phases are numbered 14-20, the recommended execution order is:
> 1. Phase 14 (Critical) - foundational fixes, must be first
> 2. Phase 17 (Error Handling) - enables better debugging for remaining phases
> 3. Phase 15-16 (Security + Performance) - can run in parallel
> 4. Phase 18 (Testing) - adds tests for all previous changes
> 5. Phase 19 (Edge Cases) - requires stable foundation
> 6. Phase 20 (Observability) - final polish

## Phase 14: Critical Fixes (High Priority)

### 14.1 Database Thread Safety
- [ ] 14.1.1 Add `synchronized` package to pubspec.yaml
- [ ] 14.1.2 Refactor `database_helper.dart` to use mutex lock
- [ ] 14.1.3 Add concurrent initialization tests
- [ ] 14.1.4 Verify no double-initialization in stress test

### 14.2 Route Argument Safety
- [ ] 14.2.1 Add null guards to all route argument parsing in `app_router.dart`
- [ ] 14.2.2 Return error page for null/invalid arguments
- [ ] 14.2.3 Add route argument tests for edge cases

### 14.3 Keyboard Overlap Fix
- [ ] 14.3.1 Change `viewPadding` to `viewInsets.bottom` in `add_expense_screen.dart`
- [ ] 14.3.2 Verify keyboard doesn't overlap input fields
- [ ] 14.3.3 Test on 3 screen sizes: small (5"), medium (6"), large (6.7")

### 14.4 Streaming Export
- [ ] 14.4.1 Add `getExpenseCount()` method to repository
- [ ] 14.4.2 Implement `ExportProgress` stream in export service
- [ ] 14.4.3 Update `export_screen.dart` to use streaming for >500 expenses
- [ ] 14.4.4 Add progress indicator for large exports
- [ ] 14.4.5 Add feature flag `USE_STREAMING_EXPORT` (default: true)
- [ ] 14.4.6 Add export streaming tests

### 14.5 Validation
- [ ] 14.5.1 Run `flutter analyze` - expect clean
- [ ] 14.5.2 Run `flutter test` - expect all passing
- [ ] 14.5.3 Manual test critical flows

---

## Phase 15: Security Hardening

### 15.1 OCR Rate Limiting
- [ ] 15.1.1 Add `_lastOcrRequest` timestamp tracking to `ocr_service.dart`
- [ ] 15.1.2 Implement 2-second minimum interval check
- [ ] 15.1.3 Return rate-limited result type when throttled
- [ ] 15.1.4 Update UI to show "Please wait" when rate limited
- [ ] 15.1.5 Add rate limiting tests

### 15.2 EXIF Verification
- [ ] 15.2.1 Add test that verifies EXIF data removed after compression
- [ ] 15.2.2 If flutter_image_compress doesn't remove EXIF, add explicit removal
- [ ] 15.2.3 Add GPS metadata removal verification test

### 15.3 Path Traversal Enhancement
- [ ] 15.3.1 Review `path_validator.dart` coverage
- [ ] 15.3.2 Apply path validation to all backup restore file extraction
- [ ] 15.3.3 Add path traversal attack tests (../../../etc/passwd patterns)
- [ ] 15.3.4 Log and reject invalid paths during restore

### 15.4 Validation
- [ ] 15.4.1 Run security-focused tests
- [ ] 15.4.2 Manual test backup restore with crafted ZIP

---

## Phase 16: Performance Optimization

### 16.1 Provider Rebuild Optimization
- [ ] 16.1.1 Audit all `Consumer` usages - convert to `Selector` where possible
- [ ] 16.1.2 Add `const` constructors to all stateless widgets
- [ ] 16.1.3 Use `RepaintBoundary` for expense cards (if not already)
- [ ] 16.1.4 Profile with DevTools - verify reduced rebuilds

### 16.2 Image Processing Timeout
- [ ] 16.2.1 Add 5-second timeout to isolate computation in `image_service.dart`
- [ ] 16.2.2 Cancel operation if isolate exceeds timeout (no main-thread fallback)
- [ ] 16.2.3 Show progress indicator during image processing
- [ ] 16.2.4 Add timeout handling tests

### 16.3 OCR Timeout Reduction
- [ ] 16.3.1 Reduce OCR timeout from 10s to 5s in `ocr_service.dart`
- [ ] 16.3.2 Add progress indicator during OCR processing
- [ ] 16.3.3 Update timeout-related tests

### 16.4 Orphaned Image Cleanup
- [ ] 16.4.1 Add `ImageCleanupService` class
- [ ] 16.4.2 Implement filesystem scan for `receipts/` directory
- [ ] 16.4.3 Cross-reference with database image paths
- [ ] 16.4.4 Delete unreferenced images (with logging)
- [ ] 16.4.5 Schedule cleanup on app resume after 24 hours
- [ ] 16.4.6 Add cleanup tests (including failure handling)

### 16.5 Validation
- [ ] 16.5.1 Profile with DevTools - verify performance improvements
- [ ] 16.5.2 Measure cold start time (<2s target)
- [ ] 16.5.3 Run `flutter test`

---

## Phase 17: Error Handling Excellence ✅

### 17.1 Result Pattern Standardization
- [x] 17.1.1 Search for `as Failure` and `as Success` casts
- [x] 17.1.2 Replace all with `fold()` pattern
- [x] 17.1.3 Add type-safe Result helpers if needed
- [x] 17.1.4 Verify no runtime cast errors in tests

### 17.2 Error Context Preservation
- [x] 17.2.1 Add operation context to error logging before fold()
- [x] 17.2.2 Create `ContextualError` wrapper if needed (not needed - using tags)
- [x] 17.2.3 Update error messages to include operation context

### 17.3 Comprehensive Error Logging
- [x] 17.3.1 Audit all catch blocks - ensure errors are logged
- [x] 17.3.2 Add `AppLogger.error()` calls where missing
- [x] 17.3.3 Include stack traces for unexpected errors
- [x] 17.3.4 Add error logging tests (via existing test coverage)

### 17.4 Background Task Error Handling
- [x] 17.4.1 Review `background_service.dart` for silent failures (already has proper logging)
- [x] 17.4.2 Add error handling to all async operations (already implemented)
- [x] 17.4.3 Log background task failures (already implemented)

### 17.5 Validation
- [x] 17.5.1 Run `flutter test` - all pass
- [x] 17.5.2 Verify error scenarios log correctly

---

## Phase 18: Testing Excellence

### 18.1 Concurrent Database Tests
- [x] 18.1.1 Create `test/data/datasources/local/database_concurrent_test.dart`
- [x] 18.1.2 Test simultaneous addExpense() calls (10 concurrent)
- [x] 18.1.3 Test read during write scenarios
- [x] 18.1.4 Test ServiceLocator initialization race

### 18.2 Network Resilience Tests
- [x] 18.2.1 Create `test/data/datasources/remote/network_resilience_test.dart`
- [x] 18.2.2 Test exchange rate API timeout handling
- [x] 18.2.3 Test Google Drive partial upload/download failures
- [x] 18.2.4 Test rate limiting recovery

### 18.3 UI State Tests
- [ ] 18.3.1 Create `test/presentation/screens/keyboard_overlay_test.dart`
- [ ] 18.3.2 Test AddExpenseScreen with keyboard visible
- [x] 18.3.3 Test ExportScreen with large dataset (mock 1000 expenses)
- [ ] 18.3.4 Test error boundary recovery after exceptions

### 18.4 Edge Case Tests
- [ ] 18.4.1 Test maximum expense count per month (10,000)
- [ ] 18.4.2 Test corrupted database recovery
- [ ] 18.4.3 Test app behavior with no storage permission
- [x] 18.4.4 Test timezone edge cases (month boundaries)

### 18.5 Validation
- [ ] 18.5.1 Run `flutter test --coverage`
- [ ] 18.5.2 Verify test count >= 800 (currently 757+)
- [ ] 18.5.3 Review coverage report for gaps

---

## Phase 19: Edge Case Handling

### 19.1 Duplicate Detection Enhancement
- [ ] 19.1.1 Add Levenshtein distance utility function
- [ ] 19.1.2 Update `smart_prompt_service.dart` to use edit distance for description matching
- [ ] 19.1.3 Extend duplicate window from 24h to 48h
- [ ] 19.1.4 Add duplicate detection tests

### 19.2 Exchange Rate Force Refresh
- [ ] 19.2.1 Add `forceRefresh` parameter to rate fetch in `exchange_rate_service.dart`
- [ ] 19.2.2 Bypass 30-second rate limit when force refresh (long-press gesture)
- [ ] 19.2.3 Add force refresh UI (long-press on refresh button)
- [ ] 19.2.4 Add force refresh failure handling
- [ ] 19.2.5 Add cache invalidation tests

### 19.3 Database Migration Enhancement
- [ ] 19.3.1 Add `ANALYZE` statement after v1→v2 migration
- [ ] 19.3.2 Log migration completion with timing
- [ ] 19.3.3 Add migration test

### 19.4 Provider Dispose Cleanup
- [ ] 19.4.1 Audit all providers for StreamSubscription/Timer
- [ ] 19.4.2 Add dispose() cleanup to `ConnectivityProvider`
- [ ] 19.4.3 Add dispose() cleanup to `ExchangeRateProvider`
- [ ] 19.4.4 Add dispose() cleanup to `SettingsProvider`
- [ ] 19.4.5 Add dispose() cleanup to any other providers found in audit
- [ ] 19.4.6 Add dispose verification tests

### 19.5 ShowcaseProvider Race Fix
- [ ] 19.5.1 Wrap showcase context access in try-catch
- [ ] 19.5.2 Add mounted check before context use
- [ ] 19.5.3 Add showcase race condition test

### 19.6 Validation Input Improvements
- [ ] 19.6.1 Add warning when decimal truncated (>2 places)
- [ ] 19.6.2 Fix future date validation to use start-of-day
- [ ] 19.6.3 Add validation edge case tests

### 19.7 Validation
- [ ] 19.7.1 Run `flutter test`
- [ ] 19.7.2 Manual test edge cases

---

## Phase 20: Observability & Polish

### 20.1 ServiceLocator Interface Purity
- [ ] 20.1.1 Remove `expenseRepositoryImpl` getter from `service_locator.dart`
- [ ] 20.1.2 Update any callers to use interface
- [ ] 20.1.3 Verify no direct implementation access

### 20.2 Exception Types
- [ ] 20.2.1 Add `SyncException` type to `app_exception.dart`
- [ ] 20.2.2 Add `FileSystemException` type (distinct from StorageException)
- [ ] 20.2.3 Update exception handling to use new types

### 20.3 Structured Logging
- [ ] 20.3.1 Create `LogEntry` class with structured fields
- [ ] 20.3.2 Update `AppLogger` to produce structured output (console only for now)
- [ ] 20.3.3 Add tag, timestamp, fields to all log calls
- [ ] 20.3.4 Add logging tests

### 20.4 Breadcrumb Tracking
- [ ] 20.4.1 Create `BreadcrumbService` class
- [ ] 20.4.2 Track last 10 user actions
- [ ] 20.4.3 Include breadcrumbs in error reports
- [ ] 20.4.4 Add breadcrumb tests

### 20.5 Magic Number Centralization
- [ ] 20.5.1 Create/update `app_constants.dart`
- [ ] 20.5.2 Move hardcoded values: UUID length (8), large amount (100000), timeouts
- [ ] 20.5.3 Replace all magic numbers with constants
- [ ] 20.5.4 Verify no hardcoded numbers in services

### 20.6 Final Validation
- [ ] 20.6.1 Run `flutter analyze` - expect clean
- [ ] 20.6.2 Run `flutter test` - expect 800+ passing
- [ ] 20.6.3 Profile with DevTools - verify no memory leaks
- [ ] 20.6.4 Re-run code critique - expect 0 High/Medium issues
- [ ] 20.6.5 Update PROJECT_INDEX.md with new test count
- [ ] 20.6.6 Update project-context memory

---

## Open Decisions (To Resolve Before Implementation)

1. **synchronized package** - Acceptable to add new dependency? ✅ Recommended: Yes (proven, minimal footprint)
2. **Orphan cleanup frequency** - Every app launch or periodic? ✅ Decision: On first launch after 24 hours
3. **Structured logging destination** - Console only or file? ✅ Decision: Console for now, file optional later
4. **Test coverage target** - 800 tests (from current 757+)

---

## Summary

| Phase | Tasks | Focus |
|-------|-------|-------|
| 14 | 18 | Critical fixes (DB, routes, keyboard, export) |
| 15 | 14 | Security (rate limiting, EXIF, path traversal) |
| 16 | 18 | Performance (providers, timeouts, cleanup) |
| 17 | 14 | Error handling (Result pattern, logging) |
| 18 | 14 | Testing (concurrent, network, UI, edge cases) |
| 19 | 22 | Edge cases (duplicates, cache, dispose, validation) |
| 20 | 19 | Observability (logging, breadcrumbs, constants) |
| **Total** | **119** | |
