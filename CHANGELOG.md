# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
