# Expense Snap (支出易)

<p align="center">
  <img src="assets/icon/icon.png" width="128" height="128" alt="Expense Snap Logo">
</p>

<p align="center">
  <strong>員工報銷收據記錄 App</strong><br>
  即時拍照記錄支出，支援多幣種自動轉換，月結匯出 Excel 報銷單
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10+-blue?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Platform-Android-green?logo=android" alt="Android">
  <img src="https://img.shields.io/badge/License-Proprietary-red" alt="License">
</p>

---

## Features

| Feature | Description |
|---------|-------------|
| 📸 **即影即記** | 拍照或選圖記錄收據，自動壓縮儲存 |
| 💱 **自動換算** | 支援 HKD/CNY/USD，即時匯率轉換港幣 |
| 📊 **Excel 匯出** | 月結報銷單 + 收據圖片 ZIP 打包 |
| ☁️ **雲端備份** | Google Drive 安全同步 |
| 📴 **離線優先** | 無網絡亦可使用，匯率自動快取 |
| 🌙 **深色模式** | 跟隨系統或手動切換 |
| ♿ **無障礙** | 完整 Semantics 支援螢幕閱讀器 |

---

## Screenshots

> TODO: Add screenshots

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  ┌─────────┐  ┌──────────┐  ┌─────────┐  ┌───────────┐ │
│  │ Screens │  │ Widgets  │  │Providers│  │  Router   │ │
│  └────┬────┘  └────┬─────┘  └────┬────┘  └─────┬─────┘ │
└───────┼────────────┼─────────────┼─────────────┼───────┘
        │            │             │             │
┌───────┴────────────┴─────────────┴─────────────┴───────┐
│                      Domain Layer                       │
│              ┌──────────────────────┐                   │
│              │ Repository Interfaces│                   │
│              └──────────┬───────────┘                   │
└─────────────────────────┼───────────────────────────────┘
                          │
┌─────────────────────────┴───────────────────────────────┐
│                       Data Layer                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐  │
│  │ Repositories│  │   Models    │  │   DataSources   │  │
│  └──────┬──────┘  └─────────────┘  └────────┬────────┘  │
│         │                                    │          │
│         │         ┌──────────────────────────┤          │
│         │         │                          │          │
│    ┌────┴────┐  ┌─┴──────────┐  ┌───────────┴────┐     │
│    │ SQLite  │  │ SecureStore│  │  Remote APIs   │     │
│    └─────────┘  └────────────┘  └────────────────┘     │
└─────────────────────────────────────────────────────────┘
```

### Tech Stack

| Layer | Technology |
|-------|------------|
| **UI Framework** | Flutter 3.10+ |
| **State Management** | Provider (ChangeNotifier) |
| **Local Database** | sqflite |
| **HTTP Client** | Dio |
| **Image Processing** | flutter_image_compress |
| **Export** | excel + archive |
| **Cloud Backup** | Google Sign-In + Drive API |
| **Security** | flutter_secure_storage |

---

## Getting Started

### Prerequisites

- Flutter SDK 3.10.4+
- Dart SDK 3.0+
- Android Studio / VS Code
- Android device or emulator (API 21+)

### Installation

```bash
# Clone the repository
git clone https://github.com/user/expense_snap.git
cd expense_snap

# Install dependencies
flutter pub get

# Generate mocks for testing
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

### Build Release APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## Development

### Project Structure

```
lib/
├── main.dart              # App entry point
├── core/                  # Core infrastructure
│   ├── constants/         # App constants
│   ├── di/                # Dependency injection
│   ├── errors/            # Error handling (Result pattern)
│   ├── router/            # Navigation routes
│   ├── services/          # Core services
│   ├── theme/             # App theming
│   └── utils/             # Utilities
├── data/                  # Data layer
│   ├── datasources/       # Local & Remote data sources
│   ├── models/            # Data models
│   └── repositories/      # Repository implementations
├── domain/                # Domain layer
│   └── repositories/      # Repository interfaces
├── presentation/          # UI layer
│   ├── providers/         # State management
│   ├── screens/           # App screens
│   └── widgets/           # Reusable widgets
└── services/              # Application services
```

### Key Conventions

- **Amount Storage**: Cents (分) to avoid floating-point errors
- **Exchange Rate**: ×10⁶ precision for accuracy
- **Error Handling**: `Result<T>` pattern (no exceptions in business logic)
- **Soft Delete**: 30-day retention before permanent deletion
- **Comments**: Traditional Chinese (繁體中文)

### Commands

```bash
# Run tests
flutter test

# Run tests with coverage
flutter test --coverage

# Static analysis
flutter analyze

# Generate mocks
dart run build_runner build --delete-conflicting-outputs

# Generate app icon
dart run flutter_launcher_icons

# Generate splash screen
dart run flutter_native_splash:create
```

---

## Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/data/models/expense_test.dart

# Run with verbose output
flutter test --reporter expanded
```

### Test Coverage

| Category | Files |
|----------|-------|
| Unit Tests | 15 |
| Widget Tests | 14 |
| Integration Tests | 3 |
| Accessibility Tests | 1 |
| **Total** | **35** |

---

## API Reference

### Exchange Rate API

Primary endpoint:
```
GET https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/{base}.json
```

Fallback endpoint:
```
GET https://latest.currency-api.pages.dev/v1/currencies/{base}.json
```

### Google Drive Backup

Uses Google Drive API v3 for backup/restore operations. OAuth 2.0 tokens stored securely via `flutter_secure_storage`.

---

## Contributing

1. Read `CLAUDE.md` for AI assistant instructions
2. Check `openspec/` for feature specifications
3. Follow conventional commits
4. Ensure tests pass before PR

---

## License

Proprietary - All rights reserved

---

## Acknowledgments

- [fawazahmed0/currency-api](https://github.com/fawazahmed0/currency-api) - Free exchange rate API
- Flutter team for the excellent framework
- All open-source package maintainers
