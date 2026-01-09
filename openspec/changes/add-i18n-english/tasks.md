# Tasks: Add Internationalization (English)

## 1. L10n Infrastructure Setup

- [x] 1.1 Add `generate: true` to `flutter:` section in `pubspec.yaml` (REQUIRED for gen-l10n)
- [x] 1.2 Verify `intl` package is in dependencies (should already exist)
- [x] 1.3 Create `l10n.yaml` configuration file in **project root** (not lib/)
- [x] 1.4 Create `lib/l10n/` directory for ARB files
- [x] 1.5 Create `app_zh.arb` as source of truth (Chinese strings)
- [x] 1.6 Create `app_en.arb` with English translations
- [x] 1.7 Run `flutter gen-l10n` to generate `AppLocalizations` class
- [x] 1.8 Verify generated code compiles without errors
- [x] 1.9 Add generated files to `.gitignore` if using synthetic-package: false

## 2. Locale Provider Implementation

- [x] 2.1 Create `LocaleProvider` in `lib/presentation/providers/locale_provider.dart`
- [x] 2.2 Add `getLocalePreference()` and `saveLocalePreference()` to `SettingsRepository` (via DatabaseHelper)
- [x] 2.3 Implement system locale detection using `PlatformDispatcher.instance.locale`
- [x] 2.4 Implement 3-tier fallback: User preference → System locale → ZH-HK default
- [x] 2.5 Register `LocaleProvider` in `main.dart` Provider tree
- [x] 2.6 Call `LocaleProvider.initialize()` during app startup
- [x] 2.7 Write unit tests for `LocaleProvider` (19 test cases covering static constants, initial state, isSelected)

## 3. MaterialApp Localization Configuration

- [x] 3.1 Update `MaterialApp` with `supportedLocales`
- [x] 3.2 Add `AppLocalizations.delegate` to `localizationsDelegates`
- [x] 3.3 Bind `locale` property to `LocaleProvider.locale`
- [x] 3.4 Verify app builds and runs with localization delegates

## 4. String Extraction - Core

- [x] 4.1 Extract core strings to ARB files (~150+ strings)
- [x] 4.2 Update screens to use `S.of(context)` pattern
- [x] 4.3 Extract currency and exchange rate source labels
- [x] 4.4 Extract error messages
- [x] 4.5 Verify error messages display correctly in tests

## 5. String Extraction - Settings

- [x] 5.1 Extract `settings_screen.dart` strings
- [x] 5.2 Add language selector UI to Settings screen
- [x] 5.3 Add language selection dialog

## 6. String Extraction - Screens

- [x] 6.1 Extract `home_screen.dart` strings
- [x] 6.2 Extract `add_expense_screen.dart` strings
- [x] 6.3 Extract `expense_detail_screen.dart` strings
- [x] 6.4 Extract `deleted_items_screen.dart` strings
- [x] 6.5 Extract `export_screen.dart` strings
- [x] 6.6 Extract `onboarding_screen.dart` strings

## 7. String Extraction - Widgets

- [x] 7.1 Extract `empty_state.dart` strings
- [x] 7.2 Extract `connectivity_banner.dart` strings
- [x] 7.3 Extract `smart_prompt_dialogs.dart` strings
- [x] 7.4 Update EmptyStates factory methods to accept context

## 8. Export Localization

- [x] 8.1 Create `ExportStrings` class for passing localized strings to ExportService
- [x] 8.2 Localize Excel column headers in export
- [x] 8.3 Localize "Total" row label
- [x] 8.4 Localize exchange rate source labels
- [x] 8.5 Localize file names and share subject
- [x] 8.6 Update `export_screen.dart` to pass ExportStrings

## 9. Test Updates

- [x] 9.1 Update `empty_state_test.dart` with localization setup
- [x] 9.2 Update `export_service_test.dart` with ExportStrings helper
- [x] 9.3 Update `expense_detail_screen_test.dart` with localization delegates
- [x] 9.4 Update remaining widget tests with localization delegates (56 → 0 failures)
- [x] 9.5 Write LocaleProvider unit tests (19 tests)

## 10. Validation & Documentation

- [x] 10.1 Run `flutter analyze` - all errors fixed
- [x] 10.2 Run `flutter test` - all 656+ tests pass
- [x] 10.3 Update `PROJECT_INDEX.md` with l10n section
- [ ] 10.4 Manual QA testing

---

## Implementation Summary

### Completed
- L10n infrastructure with ARB files and gen-l10n
- LocaleProvider with persistence and system locale fallback
- MaterialApp localization configuration
- String extraction for all screens (home, add_expense, expense_detail, deleted_items, export, onboarding, settings)
- String extraction for widgets (empty_state, connectivity_banner, smart_prompt_dialogs)
- Export service localization with ExportStrings pattern
- Language selection UI in Settings
- All test files updated with localization delegates (656+ tests pass)
- LocaleProvider unit tests (19 test cases)

### Remaining
- Manual QA testing (user responsibility)

### ARB Key Count
- `app_zh.arb`: ~170 keys (Chinese - source of truth)
- `app_en.arb`: ~170 keys (English translations)
