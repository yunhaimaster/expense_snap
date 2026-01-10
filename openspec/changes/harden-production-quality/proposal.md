# Change: Harden Production Quality

## Why

Deep code review identified **30 issues** across architecture, performance, security, and testing. While the app is functional and has 757+ tests, these issues prevent true production excellence:

- **4 High Priority**: Database threading race, route null safety, keyboard overlap, memory leaks
- **19 Medium Priority**: Result pattern inconsistencies, OCR timeout, orphaned files, weak validation
- **7 Low Priority**: Magic numbers, structured logging, breadcrumb tracking

The app has completed all 13 polish phases but lacks hardening for edge cases, concurrent operations, and observability needed for long-term maintainability.

## What Changes

### Phase 14: Critical Fixes
- **BREAKING**: Database initialization uses mutex lock (behavior change under concurrency)
- Fix route argument null safety in `app_router.dart`
- Fix keyboard overlap using `viewInsets` instead of `viewPadding`
- Implement streaming export for large datasets (>500 expenses)

### Phase 15: Security Hardening
- Add OCR request rate limiting (2-second debounce)
- Verify EXIF metadata removal in image compression
- Enhance path traversal detection in backup restore

### Phase 16: Performance Optimization
- Optimize Provider rebuilds with fine-grained Selectors
- Add timeout with cancellation to image processing isolate
- Reduce OCR timeout from 10s to 5s with progress indicator

### Phase 17: Error Handling Excellence
- Standardize Result pattern usage (eliminate dangerous type casts)
- Add error context preservation in fold() operations
- Implement comprehensive error logging

### Phase 18: Testing Excellence
- Add concurrent database operation tests
- Add network timeout and resilience tests
- Expand UI state tests (keyboard, memory pressure)

### Phase 19: Edge Case Handling
- Implement orphaned image file cleanup
- Enhance duplicate detection with Levenshtein distance
- Add force refresh for exchange rate cache
- Fix decimal truncation warning
- Add proper dispose() cleanup in all providers

### Phase 20: Observability & Polish
- Remove `expenseRepositoryImpl` exposure (interface purity)
- Add structured logging with fields
- Implement breadcrumb tracking for debugging
- Centralize magic numbers to constants

## Impact

### Affected Specs
- `expense-management` - validation enhancements, duplicate detection
- `receipt-capture` - EXIF verification, image processing timeout, orphaned cleanup
- `data-export` - streaming export for large datasets, error recovery
- `currency-conversion` - force refresh rate enhancement
- NEW `core-infrastructure` - database safety, error handling, logging
- NEW `testing-standards` - coverage requirements

### Affected Code
| Area | Key Files |
|------|-----------|
| Database | `database_helper.dart`, `service_locator.dart` |
| Routing | `app_router.dart` |
| UI | `add_expense_screen.dart`, `export_screen.dart` |
| Services | `image_service.dart`, `ocr_service.dart`, `exchange_rate_service.dart` |
| Providers | All providers (dispose cleanup) |
| Testing | New test files for concurrency, network, UI states |

### Risk Assessment
| Change | Risk | Mitigation |
|--------|------|------------|
| DB mutex | Low | Extensive concurrent tests |
| Streaming export | Medium | Feature flag, fallback to current |
| Result pattern refactor | Low | Type-safe refactoring |
| Provider dispose | Low | Audit all subscriptions |

## Success Criteria
- [ ] All 30 identified issues addressed
- [ ] 800+ tests passing (currently 757+)
- [ ] Zero High/Medium issues in re-review
- [ ] `flutter analyze` clean
- [ ] No memory leaks in DevTools profiling
