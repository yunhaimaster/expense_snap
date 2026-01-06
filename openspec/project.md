# Project Context

## Purpose
員工報銷收據記錄 Android App。讓員工即時拍照記錄支出，支援多幣種自動轉換，月結時匯出 Excel 報銷單 + 收據圖片。

## Tech Stack
- **Framework**: Flutter 3.x (Android)
- **Language**: Dart
- **State Management**: Provider
- **Local Database**: sqflite
- **HTTP Client**: Dio
- **Image Processing**: flutter_image_compress, image_picker
- **Export**: excel, archive (ZIP)
- **Cloud Backup**: Google Sign-In + Google Drive API
- **Security**: flutter_secure_storage

## Project Conventions

### Code Style
- 繁體中文 comments
- Dart recommended lint rules
- Named parameters for >2 arguments
- Result pattern for error handling

### Architecture Patterns
- Clean Architecture: UI → Provider → Repository → DataSource
- Repository pattern for data abstraction
- Result<T> pattern for error handling (no exceptions in business logic)
- Soft delete with retention period

### Testing Strategy
- Unit tests for repositories and services
- Widget tests for critical UI flows
- mockito for mocking dependencies

### Git Workflow
- Feature branches from main
- Conventional commits
- PR required for merges

## Domain Context
- **Target Users**: 企業員工需要報銷支出
- **Primary Currency**: HKD (港幣)
- **Supported Currencies**: HKD, CNY, USD
- **Export Format**: Excel (.xlsx) + 收據圖片 ZIP
- **Backup**: Google Drive (optional)

## Important Constraints
- Offline-first: 必須能離線使用，匯率可用 cache/default
- Privacy: 收據圖片存於 app-private directory
- Token Security: OAuth tokens 必須用 secure storage
- Image Size: 壓縮至 1920x1080, 縮圖 200px

## External Dependencies
- **Exchange Rate API**: cdn.jsdelivr.net/npm/@fawazahmed0/currency-api (免費，無限制)
- **Fallback API**: latest.currency-api.pages.dev
- **Google Drive API**: 用於雲端備份

## Project Status
- **All 13 phases complete** - 發布就緒 🎉
- 詳見 `docs/POLISH_PLAN.md` 了解打磨計劃執行歷史
- 520+ tests passing
