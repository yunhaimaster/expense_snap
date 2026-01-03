# Tasks: Bootstrap Expense Tracker MVP

## Phase 0: Project Initialization (NEW)

### 0.1 Repository Setup
- [x] 0.1.1 Initialize git repository with `git init`
- [x] 0.1.2 Create `.gitignore` from Flutter template
- [x] 0.1.3 Create initial commit

### 0.2 Flutter Project Creation
- [x] 0.2.1 Create Flutter project: `flutter create --org com.example expense_snap`
- [x] 0.2.2 Remove iOS/web/desktop directories (Android only for MVP)
- [x] 0.2.3 Verify project builds: `flutter build apk --debug`

---

## Phase 1: Project Foundation ✅

### 1.1 Dependencies Configuration
- [x] 1.1.1 Configure `pubspec.yaml` with all dependencies (updated versions for Flutter 3.38)
- [x] 1.1.2 Run `flutter pub get` and resolve any conflicts
- [x] 1.1.3 Set up analysis_options.yaml with recommended lints

### 1.2 Android Configuration
- [x] 1.2.1 Update `android/app/build.gradle.kts`:
  - minSdk 21
  - targetSdk 35
  - Enable multidex
- [x] 1.2.2 Configure AndroidManifest.xml permissions (API 33+)
- [x] 1.2.3 Add `android:requestLegacyExternalStorage="true"` for Android 10

### 1.3 Directory Structure
- [x] 1.3.1 Create `lib/` directory structure with core/, data/, domain/, presentation/, services/
- [x] 1.3.2 Create `test/` directory structure mirroring `lib/`
- [x] 1.3.3 Create `test/fixtures/` for test data

### 1.4 Core Infrastructure
- [x] 1.4.1 Create `lib/core/constants/app_constants.dart`
- [x] 1.4.2 Create `lib/core/constants/currency_constants.dart`
- [x] 1.4.3 Create `lib/core/constants/api_config.dart` with URLs and timeouts
- [x] 1.4.4 Create `lib/core/constants/validation_rules.dart`
- [x] 1.4.5 Create `lib/core/errors/app_exception.dart` with sealed class
- [x] 1.4.6 Create `lib/core/errors/result.dart` with Result<T> pattern
- [x] 1.4.7 Create `lib/core/utils/app_logger.dart`
- [x] 1.4.8 Create `lib/core/utils/formatters.dart` (date, currency, amount)
- [x] 1.4.9 Create `lib/core/utils/validators.dart`
- [x] 1.4.10 Create `lib/core/utils/path_validator.dart` for security
- [x] 1.4.11 Create `lib/core/theme/app_theme.dart`
- [x] 1.4.12 Create `lib/core/theme/app_colors.dart`

### 1.5 Data Models
- [x] 1.5.1 Create `lib/data/models/expense.dart`:
  - 金額以分儲存 (INTEGER)
  - 包含 `deleted_at` 欄位
  - 移除 `needs_sync` 欄位
- [x] 1.5.2 Create `lib/data/models/exchange_rate_cache.dart`
- [x] 1.5.3 Create `lib/data/models/backup_status.dart`
- [x] 1.5.4 Create `lib/data/models/app_settings.dart`
- [x] 1.5.5 Write unit tests for model serialization
- [x] 1.5.6 Write unit tests for amount conversion (分 ↔ 元)

### 1.6 Database Layer
- [x] 1.6.1 Create `lib/data/datasources/local/database_helper.dart`
- [x] 1.6.2 Implement `_onCreate` with all tables, indexes, and WAL mode
- [x] 1.6.3 Implement `_onUpgrade` with version strategy
- [x] 1.6.4 Create `lib/data/datasources/local/secure_storage_helper.dart`
- [ ] 1.6.5 Write integration tests for database CRUD operations (deferred to Phase 6)
- [ ] 1.6.6 Write tests for database migration scenarios (deferred to Phase 6)

### 1.7 Dependency Injection Setup (🆕 移至 Phase 1)
- [x] 1.7.1 Create `lib/core/di/service_locator.dart`
- [x] 1.7.2 Register basic infrastructure services (DB, SecureStorage)
- [x] 1.7.3 Create abstract repository interfaces in `lib/domain/`

**Verification**: ✅ `flutter analyze` passes, `flutter test` passes (99 tests)

---

## Phase 2: Core Features

### 2.1 Image Service
- [x] 2.1.1 Create `lib/services/image_service.dart`
- [x] 2.1.2 Implement `processReceiptImage()` with compression
- [x] 2.1.3 Implement EXIF metadata stripping (remove GPS/location)
- [x] 2.1.4 Implement thumbnail generation
- [x] 2.1.5 Implement `deleteImages()` cleanup
- [ ] 2.1.6 Write unit tests with mock images (deferred to Phase 6)

### 2.2 Expense Repository
- [x] 2.2.1 Create `lib/data/repositories/expense_repository.dart`
- [x] 2.2.2 Implement `addExpense()` with image processing
- [x] 2.2.3 Implement `getExpensesByMonth()` with pagination
- [x] 2.2.4 Implement `updateExpense()`
- [x] 2.2.5 Implement `softDeleteExpense()` and `restoreExpense()`
- [x] 2.2.6 Implement `cleanupDeletedExpenses()` (30-day retention)
- [x] 2.2.7 Implement `getMonthSummary()`
- [ ] 2.2.8 Write repository unit tests with mocked dependencies (deferred to Phase 6)

### 2.3 Expense Provider
- [x] 2.3.1 Create `lib/presentation/providers/expense_provider.dart`
- [x] 2.3.2 Implement month navigation (previous/next)
- [x] 2.3.3 Implement expense list loading with pagination
- [x] 2.3.4 Implement add/update/delete operations
- [x] 2.3.5 Implement summary calculation

### 2.4 Main UI - Home Screen
- [x] 2.4.1 Create `lib/presentation/screens/home/home_screen.dart`
- [x] 2.4.2 Create `lib/presentation/screens/home/widgets/month_summary.dart`
- [x] 2.4.3 Create `lib/presentation/screens/home/widgets/expense_list.dart`
- [x] 2.4.4 Create `lib/presentation/screens/home/widgets/expense_card.dart`
- [x] 2.4.5 Implement pagination (lazy loading)
- [x] 2.4.6 Create `lib/presentation/widgets/common/empty_state.dart`
- [x] 2.4.7 Create `lib/presentation/widgets/common/loading_overlay.dart`

### 2.5 Add Expense Screen
- [x] 2.5.1 Create `lib/presentation/screens/add_expense/add_expense_screen.dart`
- [x] 2.5.2 Create `lib/presentation/widgets/forms/amount_input.dart` (numeric keyboard)
- [x] 2.5.3 Create `lib/presentation/widgets/forms/currency_dropdown.dart`
- [x] 2.5.4 Create `lib/presentation/widgets/forms/date_picker_field.dart`
- [x] 2.5.5 Implement camera/gallery image picker
- [x] 2.5.6 Implement form validation with error display
- [x] 2.5.7 Implement image preview before save
- [x] 2.5.8 Add loading overlay during save

### 2.6 Expense Detail Screen
- [x] 2.6.1 Create `lib/presentation/screens/expense_detail/expense_detail_screen.dart`
- [x] 2.6.2 Implement full-size image display with zoom/pan
- [x] 2.6.3 Implement edit functionality
- [x] 2.6.4 Implement delete with undo snackbar
- [x] 2.6.5 Implement replace receipt image feature (🆕)

### 2.7 Onboarding Screen (🆕)
- [x] 2.7.1 Create `lib/presentation/screens/onboarding/onboarding_screen.dart`
- [x] 2.7.2 Implement welcome page with app logo
- [x] 2.7.3 Implement user name input field
- [x] 2.7.4 Implement skip button (uses default name)
- [x] 2.7.5 Save onboarding_completed flag

### 2.8 Deleted Items Screen (🆕)
- [x] 2.8.1 Create `lib/presentation/screens/deleted_items/deleted_items_screen.dart`
- [x] 2.8.2 Show deleted expenses with deletion date
- [x] 2.8.3 Show days remaining before permanent deletion
- [x] 2.8.4 Implement restore button
- [x] 2.8.5 Implement permanent delete with confirmation

### 2.9 Navigation Setup (🆕)
- [x] 2.9.1 Create `lib/core/router/app_router.dart` with named routes
- [x] 2.9.2 Create `lib/presentation/screens/shell/app_shell.dart` (bottom nav)
- [x] 2.9.3 Implement bottom navigation: 首頁 | 匯出 | 設定
- [x] 2.9.4 Handle deep linking for expense detail

**Verification**: ✅ `flutter analyze` passes (0 errors), `flutter test` passes (99 tests)

---

## Phase 3: Currency Conversion ✅

### 3.1 Exchange Rate API
- [x] 3.1.1 Create `lib/data/datasources/remote/exchange_rate_api.dart`
- [x] 3.1.2 Implement primary API call with timeout
- [x] 3.1.3 Implement fallback API call
- [x] 3.1.4 Implement rate parsing (inverse calculation)

### 3.2 Exchange Rate Repository
- [x] 3.2.1 Create `lib/data/repositories/exchange_rate_repository.dart`
- [x] 3.2.2 Implement cache read/write
- [x] 3.2.3 Implement 24-hour expiry logic
- [x] 3.2.4 Implement fallback chain (API → cache → default)
- [x] 3.2.5 Write unit tests for fallback scenarios

### 3.3 Connectivity Provider
- [x] 3.3.1 Create `lib/presentation/providers/connectivity_provider.dart`
- [x] 3.3.2 Implement connectivity stream subscription
- [x] 3.3.3 Create `lib/presentation/widgets/common/connectivity_banner.dart`

### 3.4 UI Integration
- [x] 3.4.1 Update add_expense_screen with exchange rate display
- [x] 3.4.2 Add rate refresh button with 30s cooldown (🆕)
- [x] 3.4.3 Add manual rate override input
- [x] 3.4.4 Display rate source indicator with icons (🆕):
  - `auto`: ✓ 綠色
  - `offline`: ⚠️ 黃色
  - `default`: ⚠️ 紅色
  - `manual`: ✏️ 藍色
- [x] 3.4.5 Add offline banner to home screen
- [x] 3.4.6 Show rate fetch time ("更新於 X 小時前") (🆕)

**Verification**: ✅ Currency conversion works online/offline with correct fallback

---

## Phase 4: Data Export ✅

### 4.1 Export Service
- [x] 4.1.1 Create `lib/services/export_service.dart`
- [x] 4.1.2 Implement `exportToExcel()` with proper columns
- [x] 4.1.3 Implement total row calculation
- [x] 4.1.4 Implement rate source annotations
- [x] 4.1.5 Implement `exportToZip()` with receipts

### 4.2 Export UI
- [x] 4.2.1 Create `lib/presentation/screens/export/export_screen.dart`
- [x] 4.2.2 Implement export preview (count, total)
- [x] 4.2.3 Implement export options (Excel only / Excel + receipts)
- [x] 4.2.4 Implement share functionality via share_plus
- [x] 4.2.5 Error snackbar instead of separate dialog (integrated in export_screen)
- [x] 4.2.6 Handle empty month (disable export button) (🆕)
- [x] 4.2.7 Show export progress indicator (🆕)
- [x] 4.2.8 Implement temp file cleanup after share (🆕)

**Verification**: ✅ Can export month to Excel/ZIP and share, 130 tests passed

---

## Phase 5: Cloud Backup ✅

### 5.1 Google Sign-In Setup
- [ ] 5.1.1 Configure Google Cloud Console project (requires manual setup)
- [ ] 5.1.2 Add OAuth 2.0 credentials for Android (requires manual setup)
- [ ] 5.1.3 Configure `android/app/google-services.json` (if needed, manual)
- [ ] 5.1.4 Test Google Sign-In flow (requires manual testing)

### 5.2 Google Drive API
- [x] 5.2.1 Create `lib/data/datasources/remote/google_drive_api.dart`
- [x] 5.2.2 Implement `signIn()` and `signOut()` with drive.file scope
- [x] 5.2.3 Implement `uploadBackup()` with folder creation
- [x] 5.2.4 Implement resumable upload for large files (>5MB) (🆕)
- [x] 5.2.5 Implement `listBackups()`
- [x] 5.2.6 Implement `downloadBackup()`
- [x] 5.2.7 Implement token refresh handling (🆕)

### 5.3 Backup Repository
- [x] 5.3.1 Create `lib/data/repositories/backup_repository.dart`
- [x] 5.3.2 Implement `createBackup()` (DB + images → ZIP)
- [x] 5.3.3 Implement `restoreBackup()` (ZIP → DB + images)
- [x] 5.3.4 Implement backup status tracking
- [x] 5.3.5 Implement backup integrity validation (🆕)
- [x] 5.3.6 Implement path validation during restore (🆕 security)

### 5.4 Settings Provider & UI
- [x] 5.4.1 Create `lib/presentation/providers/settings_provider.dart`
- [x] 5.4.2 Update `lib/presentation/screens/settings/settings_screen.dart`
- [x] 5.4.3 Implement Google account connection UI
- [x] 5.4.4 Implement backup/restore buttons with progress display (🆕)
- [x] 5.4.5 Implement backup status display with size (🆕)
- [x] 5.4.6 Add user name setting for export
- [x] 5.4.7 Add confirmation dialogs for restore and sign-out (🆕)
- [x] 5.4.8 Link to deleted items screen (🆕)
- [x] 5.4.9 Add storage usage display (🆕)

**Verification**: ✅ 137 tests passed (1 skipped), flutter analyze clean (19 info)

---

## Phase 6: Polish & Testing ✅

### 6.1 Error Handling UI
- [x] 6.1.1 Implement global error handling with error boundary
- [x] 6.1.2 Add error snackbars throughout app
- [x] 6.1.3 Add retry mechanisms where appropriate
- [x] 6.1.4 Create error code mapping for user-friendly messages (🆕)

### 6.2 Loading States
- [x] 6.2.1 Add loading indicators to all async operations
- [x] 6.2.2 Prevent double-tap on buttons during loading
- [x] 6.2.3 Add skeleton loading for expense list (🆕)

### 6.3 Edge Cases
- [x] 6.3.1 Handle empty month states
- [x] 6.3.2 Handle very long descriptions (truncation in list, full in detail)
- [x] 6.3.3 Handle corrupted images gracefully with placeholder
- [x] 6.3.4 Handle database locked errors (🆕)
- [x] 6.3.5 Handle insufficient storage space (🆕)

### 6.4 App Entry
- [x] 6.4.1 Create `lib/main.dart` with DI initialization
- [x] 6.4.2 Create `lib/app.dart` with MaterialApp and Provider setup
- [x] 6.4.3 Implement onboarding check on startup (🆕)
- [x] 6.4.4 Register workmanager for background cleanup (🆕)
- [x] 6.4.5 Remove debug banner for release

### 6.5 Testing
- [x] 6.5.1 Write unit tests for all repositories
- [x] 6.5.2 Write unit tests for all services
- [x] 6.5.3 Write widget tests for critical flows (add, edit, delete)
- [x] 6.5.4 Create test fixtures in `test/fixtures/` (🆕)
- [ ] 6.5.5 Manual testing on real device (requires manual)
- [ ] 6.5.6 Test offline scenarios (🆕) (requires manual)
- [ ] 6.5.7 Test backup/restore cycle (🆕) (requires manual)
- [x] 6.5.8 Fix identified bugs

### 6.6 Background Jobs
- [x] 6.6.1 Implement 30-day cleanup scheduler with workmanager
- [x] 6.6.2 Implement cleanup on app startup if >7 days since last
- [x] 6.6.3 Add manual cleanup button in settings
- [x] 6.6.4 Clean export temp files on app startup (🆕)

### 6.7 App Assets (🆕)
- [x] 6.7.1 Create app launcher icon (uses default Flutter icon)
- [x] 6.7.2 Create splash screen (uses default LaunchTheme)
- [ ] 6.7.3 Add app screenshots for store listing (if needed) (requires manual)

### 6.8 Release Preparation (🆕)
- [x] 6.8.1 Configure ProGuard/R8 rules for release build
- [x] 6.8.2 Set up signing config for release APK
- [ ] 6.8.3 Run `flutter build apk --release` and verify (requires manual)
- [ ] 6.8.4 Test release APK on real device (requires manual)

**Verification**: ✅ 188 tests passed (1 skipped), flutter analyze clean

---

## Dependencies

```
Phase 0 → Phase 1 (project must exist first)
Phase 1 → Phase 2 (models/DB/DI needed for features)
Phase 2 → Phase 3 (expense creation needs rates)
Phase 2 → Phase 4 (export needs expense data)
Phase 2 → Phase 5 (backup needs expense data)
Phases 2-5 → Phase 6 (polish after features)
```

## Parallel Work Opportunities

- Phase 3 (Currency) and Phase 4 (Export) can run in parallel after Phase 2
- Phase 5 (Backup) can also run parallel to Phase 3 and 4
- Within Phase 2: Image Service (2.1) and Expense Repository (2.2) can start together
- Within Phase 2: Onboarding (2.7), Deleted Items (2.8), Navigation (2.9) can run parallel after core screens

## Task Summary

| Phase | Tasks | Description |
|-------|-------|-------------|
| 0 | 6 | Project initialization |
| 1 | 35 | Foundation, models, DB, DI |
| 2 | 45 | Core features, screens, navigation |
| 3 | 12 | Currency conversion |
| 4 | 13 | Data export |
| 5 | 20 | Cloud backup |
| 6 | 28 | Polish, testing, release |
| **Total** | **159** | |
