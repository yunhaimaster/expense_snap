# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.0] - 2026-01-23

### Added
- **Configurable Primary Currency** - Users can now choose their primary/base currency during onboarding or in Settings
  - 10 supported currencies: USD, EUR, GBP, JPY, CNY, HKD, TWD, KRW, SGD, AUD
  - All expenses convert to selected primary currency
  - JPY/KRW display with 0 decimal places (no cents)
  - Currency selection persisted to database
- **Dynamic Exchange Rates** - Exchange rates now use selected primary currency as base
  - Rate display shows "1 USD = X.XX [primary]" format
  - Historical expenses preserve their original conversion rate
- **Onboarding Currency Selection** - New onboarding step for currency preference
  - Accessible currency chips with proper Semantics labels
  - Visual feedback for selected currency

### Changed
- Expense model now stores `targetCurrency` field for historical accuracy
- Export headers dynamically use primary currency (e.g., "Amount (EUR)" instead of hardcoded "HKD")
- Exchange rate provider accepts dynamic `baseCurrency` parameter
- All UI components use dynamic currency instead of hardcoded 'HKD'

### Fixed
- Removed all hardcoded 'HKD' references from UI components
- Added missing accessibility Semantics to currency selection chips
- Test coverage updated for new currency parameters (1086 tests passing)

## [1.2.2] - 2026-01-14

### Changed
- **Performance optimization**: Replaced `Consumer<ExpenseProvider>` with targeted `Selector` widgets in HomeScreen
  - MonthSummaryCard only rebuilds when summary or isCurrentMonth changes
  - Error banner only rebuilds when error state changes
  - ExpenseList only rebuilds when expenses/isLoading/hasMore change
  - Reduces unnecessary widget rebuilds and improves UI responsiveness

### Fixed
- **i18n improvements**: Replaced hardcoded Chinese strings with proper localization keys
  - exchange_rate_display.dart: "匯率已強制更新", "正在取得匯率..."
  - date_picker_field.dart: "選擇月份", "取消", "確定"
  - error_boundary.dart: "重試" in ErrorBanner and showErrorSnackBar
- **Test stability**: Fixed locale-dependent test in formatters_test.dart
  - Test now properly verifies locale-aware month formatting for all supported languages

## [1.2.1] - 2026-01-14

### Added
- **Privacy Policy & Terms of Service pages** - Legal documents accessible from Settings
- **Language expansion** - Now supports 6 languages:
  - 繁體中文 (Traditional Chinese)
  - 简体中文 (Simplified Chinese)
  - English
  - 日本語 (Japanese)
  - 한국어 (Korean)
  - Español (Spanish)
- **Export walkthrough** - Interactive tutorial for first-time export users

### Changed
- LocaleProvider now handles Simplified Chinese with proper scriptCode matching
- Language selection dialog dynamically generates options from supported locales

### Fixed
- Timer cleanup in ExportScreen to prevent memory leaks
- Added `mounted` checks for async safety in showcase callbacks
- Proper accessibility labels on legal screens with Semantics widgets

## [1.1.0] - 2026-01-07

### Added
- **Receipt OCR**: Offline text recognition using Google ML Kit
  - Auto-detect currency (HKD/CNY/USD) from receipt text
  - Extract total amount with keyword-based and position-based strategies
  - Extract store name from receipt header
  - Shimmer loading effect during OCR processing
  - 5-second timeout to prevent UI blocking
- 64 new unit tests for OCR functionality

### Changed
- OcrService uses lazy initialization to reduce startup overhead
- Updated app icons and splash screens

### Fixed
- Added missing `mounted` check before SnackBar in OCR flow

## [1.0.0] - 2026-01-06

### Added
- Initial release
- Expense tracking with photo capture
- Multi-currency support (HKD/CNY/USD) with real-time exchange rates
- Monthly Excel export with receipt images (ZIP)
- Google Drive cloud backup
- Offline-first architecture with automatic sync
- Dark mode support
- Full accessibility with Semantics
- 520+ unit and widget tests
