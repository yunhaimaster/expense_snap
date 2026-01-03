# Tasks: Bootstrap Expense Tracker MVP

## Phase 0: Project Initialization (NEW)

### 0.1 Repository Setup
- [ ] 0.1.1 Initialize git repository with `git init`
- [ ] 0.1.2 Create `.gitignore` from Flutter template
- [ ] 0.1.3 Create initial commit

### 0.2 Flutter Project Creation
- [ ] 0.2.1 Create Flutter project: `flutter create --org com.example expense_snap`
- [ ] 0.2.2 Remove iOS/web/desktop directories (Android only for MVP)
- [ ] 0.2.3 Verify project builds: `flutter build apk --debug`

---

## Phase 1: Project Foundation

### 1.1 Dependencies Configuration
- [ ] 1.1.1 Configure `pubspec.yaml` with all dependencies:
  ```yaml
  dependencies:
    provider: ^6.1.1
    sqflite: ^2.3.0
    path_provider: ^2.1.1
    dio: ^5.4.0
    flutter_image_compress: ^2.1.0
    image_picker: ^1.0.5
    excel: ^4.0.3
    archive: ^3.4.9
    google_sign_in: ^6.1.6
    googleapis: ^12.0.0
    flutter_secure_storage: ^9.0.0
    connectivity_plus: ^5.0.2
    share_plus: ^7.2.1
    intl: ^0.18.1
    workmanager: ^0.5.2
    flutter_cache_manager: ^3.3.1
  dev_dependencies:
    mockito: ^5.4.4
    build_runner: ^2.4.7
  ```
- [ ] 1.1.2 Run `flutter pub get` and resolve any conflicts
- [ ] 1.1.3 Set up analysis_options.yaml with recommended lints

### 1.2 Android Configuration
- [ ] 1.2.1 Update `android/app/build.gradle`:
  - minSdkVersion 21
  - targetSdkVersion 34
  - Enable multidex
- [ ] 1.2.2 Configure AndroidManifest.xml permissions (API 33+):
  ```xml
  <uses-permission android:name="android.permission.CAMERA" />
  <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
  <uses-permission android:name="android.permission.INTERNET" />
  <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
  ```
- [ ] 1.2.3 Add `android:requestLegacyExternalStorage="true"` for Android 10

### 1.3 Directory Structure
- [ ] 1.3.1 Create `lib/` directory structure:
  ```
  lib/
  ├── core/
  │   ├── constants/
  │   ├── errors/
  │   ├── theme/
  │   └── utils/
  ├── data/
  │   ├── datasources/
  │   │   ├── local/
  │   │   └── remote/
  │   ├── models/
  │   └── repositories/
  ├── domain/           # 🆕 新增 domain 層
  │   ├── entities/
  │   └── usecases/
  ├── presentation/
  │   ├── providers/
  │   ├── screens/
  │   └── widgets/
  └── services/
  ```
- [ ] 1.3.2 Create `test/` directory structure mirroring `lib/`
- [ ] 1.3.3 Create `test/fixtures/` for test data

### 1.4 Core Infrastructure
- [ ] 1.4.1 Create `lib/core/constants/app_constants.dart`
- [ ] 1.4.2 Create `lib/core/constants/currency_constants.dart`
- [ ] 1.4.3 Create `lib/core/constants/api_config.dart` with URLs and timeouts
- [ ] 1.4.4 Create `lib/core/constants/validation_rules.dart`
- [ ] 1.4.5 Create `lib/core/errors/app_exception.dart` with sealed class
- [ ] 1.4.6 Create `lib/core/errors/result.dart` with Result<T> pattern
- [ ] 1.4.7 Create `lib/core/utils/app_logger.dart`
- [ ] 1.4.8 Create `lib/core/utils/formatters.dart` (date, currency, amount)
- [ ] 1.4.9 Create `lib/core/utils/validators.dart`
- [ ] 1.4.10 Create `lib/core/utils/path_validator.dart` for security
- [ ] 1.4.11 Create `lib/core/theme/app_theme.dart`
- [ ] 1.4.12 Create `lib/core/theme/app_colors.dart`

### 1.5 Data Models
- [ ] 1.5.1 Create `lib/data/models/expense.dart`:
  - 金額以分儲存 (INTEGER)
  - 包含 `deleted_at` 欄位
  - 移除 `needs_sync` 欄位
- [ ] 1.5.2 Create `lib/data/models/exchange_rate_cache.dart`
- [ ] 1.5.3 Create `lib/data/models/backup_status.dart`
- [ ] 1.5.4 Create `lib/data/models/app_settings.dart`
- [ ] 1.5.5 Write unit tests for model serialization
- [ ] 1.5.6 Write unit tests for amount conversion (分 ↔ 元)

### 1.6 Database Layer
- [ ] 1.6.1 Create `lib/data/datasources/local/database_helper.dart`
- [ ] 1.6.2 Implement `_onCreate` with all tables, indexes, and WAL mode
- [ ] 1.6.3 Implement `_onUpgrade` with version strategy
- [ ] 1.6.4 Create `lib/data/datasources/local/secure_storage_helper.dart`
- [ ] 1.6.5 Write integration tests for database CRUD operations
- [ ] 1.6.6 Write tests for database migration scenarios

### 1.7 Dependency Injection Setup (🆕 移至 Phase 1)
- [ ] 1.7.1 Create `lib/core/di/service_locator.dart`
- [ ] 1.7.2 Register all repositories and services
- [ ] 1.7.3 Create abstract repository interfaces in `lib/domain/`

**Verification**: Run `flutter test` - all Phase 1 tests pass

---

## Phase 2: Core Features

### 2.1 Image Service
- [ ] 2.1.1 Create `lib/services/image_service.dart`
- [ ] 2.1.2 Implement `processReceiptImage()` with compression
- [ ] 2.1.3 Implement EXIF metadata stripping (remove GPS/location)
- [ ] 2.1.4 Implement thumbnail generation
- [ ] 2.1.5 Implement `deleteImages()` cleanup
- [ ] 2.1.6 Write unit tests with mock images

### 2.2 Expense Repository
- [ ] 2.2.1 Create `lib/data/repositories/expense_repository.dart`
- [ ] 2.2.2 Implement `addExpense()` with image processing
- [ ] 2.2.3 Implement `getExpensesByMonth()` with pagination
- [ ] 2.2.4 Implement `updateExpense()`
- [ ] 2.2.5 Implement `softDeleteExpense()` and `restoreExpense()`
- [ ] 2.2.6 Implement `cleanupDeletedExpenses()` (30-day retention)
- [ ] 2.2.7 Implement `getMonthSummary()`
- [ ] 2.2.8 Write repository unit tests with mocked dependencies

### 2.3 Expense Provider
- [ ] 2.3.1 Create `lib/presentation/providers/expense_provider.dart`
- [ ] 2.3.2 Implement month navigation (previous/next)
- [ ] 2.3.3 Implement expense list loading with pagination
- [ ] 2.3.4 Implement add/update/delete operations
- [ ] 2.3.5 Implement summary calculation

### 2.4 Main UI - Home Screen
- [ ] 2.4.1 Create `lib/presentation/screens/home/home_screen.dart`
- [ ] 2.4.2 Create `lib/presentation/screens/home/widgets/month_summary.dart`
- [ ] 2.4.3 Create `lib/presentation/screens/home/widgets/expense_list.dart`
- [ ] 2.4.4 Create `lib/presentation/screens/home/widgets/expense_card.dart`
- [ ] 2.4.5 Implement pagination (lazy loading)
- [ ] 2.4.6 Create `lib/presentation/widgets/common/empty_state.dart`
- [ ] 2.4.7 Create `lib/presentation/widgets/common/loading_overlay.dart`

### 2.5 Add Expense Screen
- [ ] 2.5.1 Create `lib/presentation/screens/add_expense/add_expense_screen.dart`
- [ ] 2.5.2 Create `lib/presentation/widgets/forms/amount_input.dart` (numeric keyboard)
- [ ] 2.5.3 Create `lib/presentation/widgets/forms/currency_dropdown.dart`
- [ ] 2.5.4 Create `lib/presentation/widgets/forms/date_picker_field.dart`
- [ ] 2.5.5 Implement camera/gallery image picker
- [ ] 2.5.6 Implement form validation with error display
- [ ] 2.5.7 Implement image preview before save
- [ ] 2.5.8 Add loading overlay during save

### 2.6 Expense Detail Screen
- [ ] 2.6.1 Create `lib/presentation/screens/expense_detail/expense_detail_screen.dart`
- [ ] 2.6.2 Implement full-size image display with zoom/pan
- [ ] 2.6.3 Implement edit functionality
- [ ] 2.6.4 Implement delete with undo snackbar
- [ ] 2.6.5 Implement replace receipt image feature (🆕)

### 2.7 Onboarding Screen (🆕)
- [ ] 2.7.1 Create `lib/presentation/screens/onboarding/onboarding_screen.dart`
- [ ] 2.7.2 Implement welcome page with app logo
- [ ] 2.7.3 Implement user name input field
- [ ] 2.7.4 Implement skip button (uses default name)
- [ ] 2.7.5 Save onboarding_completed flag

### 2.8 Deleted Items Screen (🆕)
- [ ] 2.8.1 Create `lib/presentation/screens/deleted_items/deleted_items_screen.dart`
- [ ] 2.8.2 Show deleted expenses with deletion date
- [ ] 2.8.3 Show days remaining before permanent deletion
- [ ] 2.8.4 Implement restore button
- [ ] 2.8.5 Implement permanent delete with confirmation

### 2.9 Navigation Setup (🆕)
- [ ] 2.9.1 Create `lib/core/router/app_router.dart` with named routes
- [ ] 2.9.2 Create `lib/presentation/screens/shell/app_shell.dart` (bottom nav)
- [ ] 2.9.3 Implement bottom navigation: 首頁 | 匯出 | 設定
- [ ] 2.9.4 Handle deep linking for expense detail

**Verification**: Can add/view/edit/delete expenses with images, onboarding works

---

## Phase 3: Currency Conversion

### 3.1 Exchange Rate API
- [ ] 3.1.1 Create `lib/data/datasources/remote/exchange_rate_api.dart`
- [ ] 3.1.2 Implement primary API call with timeout
- [ ] 3.1.3 Implement fallback API call
- [ ] 3.1.4 Implement rate parsing (inverse calculation)

### 3.2 Exchange Rate Repository
- [ ] 3.2.1 Create `lib/data/repositories/exchange_rate_repository.dart`
- [ ] 3.2.2 Implement cache read/write
- [ ] 3.2.3 Implement 24-hour expiry logic
- [ ] 3.2.4 Implement fallback chain (API → cache → default)
- [ ] 3.2.5 Write unit tests for fallback scenarios

### 3.3 Connectivity Provider
- [ ] 3.3.1 Create `lib/presentation/providers/connectivity_provider.dart`
- [ ] 3.3.2 Implement connectivity stream subscription
- [ ] 3.3.3 Create `lib/presentation/widgets/common/connectivity_banner.dart`

### 3.4 UI Integration
- [ ] 3.4.1 Update add_expense_screen with exchange rate display
- [ ] 3.4.2 Add rate refresh button with 30s cooldown (🆕)
- [ ] 3.4.3 Add manual rate override input
- [ ] 3.4.4 Display rate source indicator with icons (🆕):
  - `auto`: ✓ 綠色
  - `offline`: ⚠️ 黃色
  - `default`: ⚠️ 紅色
  - `manual`: ✏️ 藍色
- [ ] 3.4.5 Add offline banner to home screen
- [ ] 3.4.6 Show rate fetch time ("更新於 X 小時前") (🆕)

**Verification**: Currency conversion works online/offline with correct fallback

---

## Phase 4: Data Export

### 4.1 Export Service
- [ ] 4.1.1 Create `lib/services/export_service.dart`
- [ ] 4.1.2 Implement `exportToExcel()` with proper columns
- [ ] 4.1.3 Implement total row calculation
- [ ] 4.1.4 Implement rate source annotations
- [ ] 4.1.5 Implement `exportToZip()` with receipts

### 4.2 Export UI
- [ ] 4.2.1 Create `lib/presentation/screens/export/export_screen.dart`
- [ ] 4.2.2 Implement export preview (count, total)
- [ ] 4.2.3 Implement export options (Excel only / Excel + receipts)
- [ ] 4.2.4 Implement share functionality via share_plus
- [ ] 4.2.5 Create `lib/presentation/widgets/common/error_dialog.dart`
- [ ] 4.2.6 Handle empty month (disable export button) (🆕)
- [ ] 4.2.7 Show export progress indicator (🆕)
- [ ] 4.2.8 Implement temp file cleanup after share (🆕)

**Verification**: Can export month to Excel/ZIP and share

---

## Phase 5: Cloud Backup

### 5.1 Google Sign-In Setup
- [ ] 5.1.1 Configure Google Cloud Console project
- [ ] 5.1.2 Add OAuth 2.0 credentials for Android
- [ ] 5.1.3 Configure `android/app/google-services.json` (if needed)
- [ ] 5.1.4 Test Google Sign-In flow

### 5.2 Google Drive API
- [ ] 5.2.1 Create `lib/data/datasources/remote/google_drive_api.dart`
- [ ] 5.2.2 Implement `signIn()` and `signOut()` with drive.file scope
- [ ] 5.2.3 Implement `uploadBackup()` with folder creation
- [ ] 5.2.4 Implement resumable upload for large files (>5MB) (🆕)
- [ ] 5.2.5 Implement `listBackups()`
- [ ] 5.2.6 Implement `downloadBackup()`
- [ ] 5.2.7 Implement token refresh handling (🆕)

### 5.3 Backup Repository
- [ ] 5.3.1 Create `lib/data/repositories/backup_repository.dart`
- [ ] 5.3.2 Implement `createBackup()` (DB + images → ZIP)
- [ ] 5.3.3 Implement `restoreBackup()` (ZIP → DB + images)
- [ ] 5.3.4 Implement backup status tracking
- [ ] 5.3.5 Implement backup integrity validation (🆕)
- [ ] 5.3.6 Implement path validation during restore (🆕 security)

### 5.4 Settings Provider & UI
- [ ] 5.4.1 Create `lib/presentation/providers/settings_provider.dart`
- [ ] 5.4.2 Create `lib/presentation/screens/settings/settings_screen.dart`
- [ ] 5.4.3 Implement Google account connection UI
- [ ] 5.4.4 Implement backup/restore buttons with progress display (🆕)
- [ ] 5.4.5 Implement backup status display with size (🆕)
- [ ] 5.4.6 Add user name setting for export
- [ ] 5.4.7 Add confirmation dialogs for restore and sign-out (🆕)
- [ ] 5.4.8 Link to deleted items screen (🆕)
- [ ] 5.4.9 Add storage usage display (🆕)

**Verification**: Can backup to and restore from Google Drive

---

## Phase 6: Polish & Testing

### 6.1 Error Handling UI
- [ ] 6.1.1 Implement global error handling with error boundary
- [ ] 6.1.2 Add error snackbars throughout app
- [ ] 6.1.3 Add retry mechanisms where appropriate
- [ ] 6.1.4 Create error code mapping for user-friendly messages (🆕)

### 6.2 Loading States
- [ ] 6.2.1 Add loading indicators to all async operations
- [ ] 6.2.2 Prevent double-tap on buttons during loading
- [ ] 6.2.3 Add skeleton loading for expense list (🆕)

### 6.3 Edge Cases
- [ ] 6.3.1 Handle empty month states
- [ ] 6.3.2 Handle very long descriptions (truncation in list, full in detail)
- [ ] 6.3.3 Handle corrupted images gracefully with placeholder
- [ ] 6.3.4 Handle database locked errors (🆕)
- [ ] 6.3.5 Handle insufficient storage space (🆕)

### 6.4 App Entry
- [ ] 6.4.1 Create `lib/main.dart` with DI initialization
- [ ] 6.4.2 Create `lib/app.dart` with MaterialApp and Provider setup
- [ ] 6.4.3 Implement onboarding check on startup (🆕)
- [ ] 6.4.4 Register workmanager for background cleanup (🆕)
- [ ] 6.4.5 Remove debug banner for release

### 6.5 Testing
- [ ] 6.5.1 Write unit tests for all repositories
- [ ] 6.5.2 Write unit tests for all services
- [ ] 6.5.3 Write widget tests for critical flows (add, edit, delete)
- [ ] 6.5.4 Create test fixtures in `test/fixtures/` (🆕)
- [ ] 6.5.5 Manual testing on real device
- [ ] 6.5.6 Test offline scenarios (🆕)
- [ ] 6.5.7 Test backup/restore cycle (🆕)
- [ ] 6.5.8 Fix identified bugs

### 6.6 Background Jobs
- [ ] 6.6.1 Implement 30-day cleanup scheduler with workmanager
- [ ] 6.6.2 Implement cleanup on app startup if >7 days since last
- [ ] 6.6.3 Add manual cleanup button in settings
- [ ] 6.6.4 Clean export temp files on app startup (🆕)

### 6.7 App Assets (🆕)
- [ ] 6.7.1 Create app launcher icon
- [ ] 6.7.2 Create splash screen
- [ ] 6.7.3 Add app screenshots for store listing (if needed)

### 6.8 Release Preparation (🆕)
- [ ] 6.8.1 Configure ProGuard/R8 rules for release build
- [ ] 6.8.2 Set up signing config for release APK
- [ ] 6.8.3 Run `flutter build apk --release` and verify
- [ ] 6.8.4 Test release APK on real device

**Verification**: App is stable, all features work as specified

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
