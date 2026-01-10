# Project Index: Expense Snap

Generated: 2026-01-10

## Overview

**員工報銷收據記錄 App** - Flutter 應用程式，支援即時拍照記錄支出、多幣種自動轉換、月結匯出 Excel 報銷單

- **Version**: 1.2.0
- **SDK**: Flutter 3.10.4+
- **Architecture**: Clean Architecture + Provider
- **Language**: Dart, 繁體中文 / English UI (i18n)

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App 入口點
├── core/                        # 核心基礎設施
│   ├── constants/               # 常數定義
│   ├── di/                      # 依賴注入 (ServiceLocator)
│   ├── errors/                  # 錯誤處理 (Result, AppException)
│   ├── router/                  # 路由配置
│   ├── services/                # 核心服務 (Breadcrumb)
│   ├── theme/                   # 主題配置
│   └── utils/                   # 工具類 (AppLogger, Validators)
├── l10n/                        # 國際化 (i18n)
│   ├── app_zh.arb               # 繁體中文 (source of truth)
│   └── app_en.arb               # English
├── data/                        # 資料層
│   ├── datasources/
│   │   ├── local/               # SQLite, SecureStorage
│   │   └── remote/              # Exchange Rate API, Google Drive
│   ├── models/                  # 資料模型
│   └── repositories/            # Repository 實作
├── domain/                      # 領域層
│   └── repositories/            # Repository 介面
├── presentation/                # 呈現層
│   ├── providers/               # 狀態管理 (ChangeNotifier)
│   ├── screens/                 # 畫面
│   └── widgets/                 # UI 元件
└── services/                    # 應用服務
    ├── background_service.dart  # 背景任務 (WorkManager)
    ├── export_service.dart      # Excel 匯出
    ├── image_service.dart       # 圖片處理
    ├── ocr_service.dart         # OCR 文字識別 (ML Kit)
    └── receipt_parser.dart      # 收據解析 (幣別/金額/描述/日期)
```

---

## 🚀 Entry Points

| File | Purpose |
|------|---------|
| `lib/main.dart` | App 入口，初始化 DI/WorkManager，設置 Provider |
| `lib/core/di/service_locator.dart` | 服務定位器 (`sl` 全域訪問點) |
| `lib/core/router/app_router.dart` | 路由定義與頁面轉場 |

---

## 📦 Core Modules

### Models (`lib/data/models/`)
- `expense.dart` - 支出記錄模型，金額以「分」儲存
- `app_settings.dart` - 應用程式設定
- `exchange_rate_cache.dart` - 匯率快取
- `backup_status.dart` - 雲端備份狀態

### Repositories (`lib/data/repositories/`)
- `expense_repository.dart` - 支出 CRUD，軟刪除，30天清理
- `exchange_rate_repository.dart` - 匯率查詢快取
- `backup_repository.dart` - Google Drive 備份

### Providers (`lib/presentation/providers/`)
- `expense_provider.dart` - 支出列表狀態
- `exchange_rate_provider.dart` - 匯率狀態
- `settings_provider.dart` - 設定狀態
- `connectivity_provider.dart` - 網路狀態
- `theme_provider.dart` - 主題切換
- `showcase_provider.dart` - 功能發現提示
- `locale_provider.dart` - 語言設定 (zh/en/system)

### Screens (`lib/presentation/screens/`)
- `home/` - 首頁支出列表
- `add_expense/` - 新增/編輯支出
- `expense_detail/` - 支出詳情
- `export/` - 匯出 Excel
- `settings/` - 設定頁面
- `deleted_items/` - 已刪除項目 (回收站)
- `onboarding/` - 首次使用引導
- `shell/` - 底部導航殼

---

## 🔧 Configuration

| File | Purpose |
|------|---------|
| `pubspec.yaml` | 依賴與資源配置 |
| `analysis_options.yaml` | Lint 規則 |
| `flutter_launcher_icons.yaml` | App Icon 生成 |
| `flutter_native_splash.yaml` | 啟動畫面配置 |
| `l10n.yaml` | 國際化配置 (ARB files, gen-l10n) |

---

## 🧪 Test Structure

```
test/
├── core/                        # 核心邏輯測試
│   ├── errors/                  # Result, AppException
│   ├── router/                  # 頁面轉場
│   ├── services/                # SmartPrompt, Breadcrumb
│   ├── theme/                   # 深色主題
│   └── utils/                   # Formatters, Validators, Logger, LRU Cache
├── data/                        # 資料層測試
│   ├── datasources/             # API, Database
│   ├── models/                  # Expense model
│   └── repositories/            # Repository 測試
├── presentation/                # UI 測試
│   ├── providers/               # Provider 測試
│   ├── screens/                 # Screen 測試
│   └── widgets/                 # Widget 測試
├── services/                    # 服務測試
│   ├── background_service_test.dart
│   ├── export_service_test.dart
│   ├── image_service_test.dart
│   ├── ocr_service_test.dart
│   └── receipt_parser_test.dart
└── accessibility/               # 無障礙測試
    └── semantics_test.dart
```

**Total tests**: 1059 (不含 mocks)

---

## 🔗 Key Dependencies

| Package | Purpose |
|---------|---------|
| `provider` | 狀態管理 |
| `sqflite` | 本地資料庫 |
| `dio` | HTTP 請求 |
| `excel` | Excel 匯出 |
| `google_sign_in` | Google 登入 |
| `googleapis` | Google Drive API |
| `flutter_secure_storage` | OAuth tokens 儲存 |
| `connectivity_plus` | 網路狀態偵測 |
| `workmanager` | 背景任務 |
| `image_picker` | 拍照/選圖 |
| `flutter_image_compress` | 圖片壓縮 |
| `showcaseview` | 功能發現提示 |
| `flutter_local_notifications` | 本地通知 |
| `google_mlkit_text_recognition` | 離線 OCR 文字識別 |

---

## 📝 Quick Commands

```bash
# 執行測試
flutter test

# 靜態分析 & 型別檢查
flutter analyze

# 生成 Mocks
dart run build_runner build --delete-conflicting-outputs

# 重新生成國際化檔案
flutter gen-l10n

# 生成 App Icon
dart run flutter_launcher_icons

# 生成 Splash Screen
dart run flutter_native_splash:create

# 建置 APK
flutter build apk --release
```

---

## 🎯 Key Features

1. **支出管理** - CRUD、軟刪除、30天自動清理
2. **收據拍照** - 壓縮儲存、縮圖快取
3. **收據 OCR** - 離線文字識別、自動提取幣別/金額/描述/日期
4. **多幣種轉換** - 即時匯率 API、離線快取
5. **Excel 匯出** - 月結報銷單、圖片附件
6. **雲端備份** - Google Drive 同步
7. **離線支援** - 本地優先、網路恢復同步
8. **深色模式** - 系統/手動切換
9. **無障礙** - Semantics、對比度優化
10. **國際化** - 繁體中文 / English 雙語支援

---

## 📂 Assets

```
assets/
├── icon/                        # App 圖示、Splash 圖
│   ├── icon.png
│   ├── icon_foreground.png
│   ├── icon_background.png
│   └── splash_logo.png
└── illustrations/               # SVG 插圖
    ├── empty_expenses.svg
    ├── empty_trash.svg
    ├── error_state.svg
    ├── offline_mode.svg
    ├── success_export.svg
    ├── welcome.svg
    └── onboarding_*.svg
```

---

## 🗂 OpenSpec Changes

專案使用 OpenSpec 管理規格變更：
- `openspec/project.md` - 專案定義
- `openspec/changes/bootstrap-expense-tracker/` - 初始規格
  - `proposal.md` - 變更提案
  - `design.md` - 設計文件
  - `specs/` - 各功能規格

---

## 🌐 Internationalization (i18n)

```
lib/l10n/
├── app_zh.arb               # 繁體中文 (source of truth, ~170 keys)
└── app_en.arb               # English (~170 keys)
```

**配置**: `l10n.yaml`
**用法**: `S.of(context).keyName` 或 `context.l10n.keyName`
**Provider**: `LocaleProvider` - 支援 zh/en/system (跟隨系統)

---

## 📌 Development Notes

- 金額以「分」儲存，避免浮點誤差
- 匯率以 ×10⁶ 精度儲存
- 使用 Result 型別處理錯誤，不拋出異常
- UI 註解使用繁體中文
- 測試使用 Mockito 生成 mocks
- 國際化使用 ARB files + flutter gen-l10n
