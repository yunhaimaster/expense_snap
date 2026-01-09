# Design: Bootstrap Expense Tracker MVP

## Context

### Background
員工報銷流程現況：手動拍照 → 記事本記錄 → 月底整理 Excel → 人工查匯率。
此 App 目標為簡化此流程至：拍照 → 自動記錄 → 一鍵匯出。

### Constraints
- **Platform**: Android only (Flutter 可後續擴展至 iOS)
- **Offline-first**: 主要功能不依賴網絡
- **Privacy**: 收據圖片為敏感資料，須妥善保護
- **Simplicity**: 單人使用，無需多用戶/團隊功能

### Stakeholders
- 企業員工（Primary user）
- 財務部門（報銷單接收方）

## Goals / Non-Goals

### Goals
- ✅ 3 秒內完成一筆支出記錄（拍照→儲存）
- ✅ 離線可用，網絡恢復後自動更新匯率
- ✅ 一鍵匯出符合報銷需求的 Excel + 收據
- ✅ 可選的雲端備份防止資料遺失

### Non-Goals
- ❌ 多用戶協作
- ❌ OCR 自動識別收據金額
- ❌ 報銷審批流程
- ❌ 即時匯率（24h 快取足夠）
- ❌ iOS 支援（MVP scope）

## Decisions

### 1. Architecture: Clean Architecture with Provider

**Decision**: 採用 UI → Provider → Repository → DataSource 分層架構

**Rationale**:
- Provider 對中小型 App 足夠，無需 BLoC 複雜度
- Repository 抽象化資料來源，便於測試
- 分層清晰，單一職責

**Alternatives Considered**:
- BLoC: 過於複雜，此 App 狀態管理需求簡單
- GetX: 社群爭議，官方不推薦
- Riverpod: 學習曲線較陡，Provider 已足夠

### 2. Error Handling: Result Pattern

**Decision**: 使用 `Result<T>` 封裝成功/失敗，不拋出 exceptions

```dart
class Result<T> {
  final T? data;
  final AppException? error;

  Result.success(this.data) : error = null;
  Result.failure(this.error) : data = null;

  R fold<R>(R Function(AppException) onFailure, R Function(T) onSuccess);
}
```

**Rationale**:
- 強制處理錯誤，無法忽略
- 類型安全，IDE 提示完整
- 符合 functional programming 風格

**Alternatives Considered**:
- try-catch everywhere: 容易遺漏錯誤處理
- Either<L,R> from dartz: 額外依賴，Result 已足夠

### 3. Database: SQLite with sqflite

**Decision**: 使用 sqflite 作為本地資料庫

**Rationale**:
- 成熟穩定，Flutter 官方推薦
- 支援 migration
- 資料量小（月數十筆），無需更複雜方案

**Alternatives Considered**:
- Hive: NoSQL，不適合關聯查詢
- Isar: 較新，生態不如 sqflite
- Drift: 抽象層過多，此 App 不需要

### 4. Image Storage Strategy

**Decision**:
- 原圖壓縮至 1920x1080, 75% quality
- 縮圖 200x200 for list display
- 存於 `getApplicationDocumentsDirectory()/receipts/YYYY-MM/`
- 檔名格式: `{timestamp}_{uuid}_full.jpg`, `{timestamp}_{uuid}_thumb.jpg`

**Rationale**:
- 月份分資料夾便於管理和清理
- UUID 避免同毫秒衝突
- 分開原圖/縮圖，list 載入快速

### 5. Exchange Rate Fallback Chain

**Decision**: 三層 fallback 機制

```
Online API (Primary)
    ↓ fail
Online API (Fallback CDN)
    ↓ fail
SQLite Cache (24h valid)
    ↓ expired
Default Hardcoded Rates
```

**Rationale**:
- 確保任何情況下都能記錄支出
- 使用者可手動覆蓋匯率
- 標記匯率來源供審計

### 6. Soft Delete with Retention

**Decision**: 軟刪除 + 30 天保留期

**Rationale**:
- 誤刪可復原
- 30 天後自動清理節省空間
- 清理時一併刪除圖片檔案

### 7. Google Drive Backup Format

**Decision**: 單一 ZIP 檔案包含 SQLite DB + 收據圖片

```
ExpenseTracker/
  └── backup_YYYYMMDD_HHMMSS.zip
       ├── expenses.db
       └── receipts/
           └── YYYY-MM/
               └── *.jpg
```

**Rationale**:
- 單一檔案便於管理
- 包含完整資料可完全還原
- 壓縮後體積更小

## Data Model

### Entity Relationship

```
┌─────────────────────┐
│      Expense        │
├─────────────────────┤
│ id (PK) INTEGER     │
│ date TEXT (ISO8601) │──── 使用者選擇的支出日期
│ original_amount INT │──── 以「分」儲存 (75.50 → 7550)
│ original_currency───────┐
│ exchange_rate INT   │   │ 以 1:1000000 精度儲存
│ exchange_rate_source│   │
│ hkd_amount INTEGER  │   │ 以「分」儲存
│ description TEXT    │   │ 最大 500 字元
│ receipt_image_path  │   │
│ thumbnail_path      │   │
│ is_deleted BOOLEAN  │   │
│ deleted_at TEXT     │───│─ 🆕 軟刪除時間戳（ISO8601）
│ created_at TEXT     │   │
│ updated_at TEXT     │   │
└─────────────────────┘   │
                          │
┌─────────────────────┐   │
│  ExchangeRateCache  │   │
├─────────────────────┤   │
│ currency (PK) ──────────┘
│ rate_to_hkd INTEGER │──── 以 1:1000000 精度儲存
│ fetched_at TEXT     │
│ source TEXT         │──── 🆕 'primary' | 'fallback'
└─────────────────────┘

┌─────────────────────┐
│    BackupStatus     │
├─────────────────────┤
│ id (PK, =1)         │
│ last_backup_at TEXT │
│ last_backup_count   │
│ last_backup_size_kb │──── 🆕 備份大小（KB）
│ google_email TEXT   │
└─────────────────────┘

┌─────────────────────┐
│    AppSettings      │
├─────────────────────┤
│ key (PK) TEXT       │
│ value TEXT          │
└─────────────────────┘

預定義 AppSettings keys:
- user_name: 匯出檔名使用
- onboarding_completed: 首次啟動標記
- last_cleanup_at: 上次清理時間
```

### Data Type Conventions

| 類型 | 儲存格式 | 說明 |
|------|---------|------|
| 日期時間 | TEXT (ISO8601) | `2025-01-03T14:30:00Z` |
| 金額 | INTEGER (分) | 75.50 HKD → 7550 |
| 匯率 | INTEGER (×10⁶) | 7.80 → 7800000 |
| 布林 | INTEGER | 0 = false, 1 = true |

### Exchange Rate Source Values

| Value | Description |
|-------|-------------|
| `auto` | 從 API 自動取得 |
| `offline` | 使用快取（API 失敗時） |
| `default` | 使用預設值（無網絡+快取過期） |
| `manual` | 使用者手動輸入 |

## Risks / Trade-offs

### Risk: Image Storage Space
- **Trade-off**: 壓縮會損失畫質
- **Mitigation**: 75% quality 足以辨識收據，可調整

### Risk: Google OAuth Token Expiry
- **Trade-off**: 需要定期重新授權
- **Mitigation**: 使用 refresh token，僅在失敗時提示重登

### Risk: Database Migration
- **Trade-off**: Schema 變更需 migration script
- **Mitigation**: 預留 `_onUpgrade` 處理，version 管理

### Risk: No Real-time Sync
- **Trade-off**: 多設備間資料不同步
- **Mitigation**: MVP 僅支援單設備，備份為手動觸發

## Migration Plan
N/A - 新專案，無需 migration

### Database Version Strategy
```dart
// 資料庫版本管理
static const int _version = 1;

// 未來 migration 範例
static Future<void> _onUpgrade(Database db, int oldV, int newV) async {
  if (oldV < 2) {
    await db.execute('ALTER TABLE expenses ADD COLUMN category TEXT');
  }
}
```

## Additional Architectural Decisions

### 8. Navigation Architecture

**Decision**: 使用 Bottom Navigation Bar + Named Routes

```
┌─────────────────────────────────────┐
│           App Shell                 │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐    │
│  │       Page Content          │    │
│  └─────────────────────────────┘    │
├─────────────────────────────────────┤
│  [🏠 首頁]  [📊 匯出]  [⚙️ 設定]   │
└─────────────────────────────────────┘

Routes:
- /home (default)
- /add-expense
- /expense/:id
- /export
- /settings
```

### 9. Input Validation Rules

| 欄位 | 規則 |
|------|------|
| amount | 0.01 ~ 9,999,999.99，最多 2 位小數 |
| description | 1-500 字元，必填 |
| exchange_rate | 0.0001 ~ 9999.9999 |
| date | 不可晚於今日 |

### 10. Android Permissions (API 33+)

```xml
<!-- 相機 -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- 圖片（Android 13+） -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<!-- 向下兼容 Android 12 以下 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />

<!-- 網絡 -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### 11. Google OAuth Scope

**Decision**: 使用最小權限範圍

```dart
// 僅存取 App 建立的檔案，不存取其他 Drive 內容
static const driveScope = 'https://www.googleapis.com/auth/drive.file';
```

### 12. Background Task Strategy

**Decision**: 使用 `workmanager` 套件執行定期清理

```dart
// 每週執行一次 30 天清理
Workmanager().registerPeriodicTask(
  'cleanup_deleted_expenses',
  'cleanupTask',
  frequency: Duration(days: 7),
  constraints: Constraints(networkType: NetworkType.not_required),
);
```

### 13. Memory & Performance

| 問題 | 解決方案 |
|------|---------|
| 大圖載入 OOM | 使用 `ResizeImage` 限制記憶體大小 |
| 縮圖快取 | 使用 `flutter_cache_manager` |
| SQLite 並發 | 啟用 WAL mode |
| 清單效能 | 使用 `ListView.builder` + pagination |

### 14. Error Handling Classification

```dart
sealed class AppException {
  const AppException(this.message);
  final String message;
}

class NetworkException extends AppException { ... }
class StorageException extends AppException { ... }
class DatabaseException extends AppException { ... }
class ValidationException extends AppException { ... }
class AuthException extends AppException { ... }
class ExportException extends AppException { ... }
```

### 15. API Configuration

```dart
class ApiConfig {
  // Exchange Rate API
  static const primaryApi = 'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies';
  static const fallbackApi = 'https://latest.currency-api.pages.dev/v1/currencies';
  static const timeout = Duration(seconds: 10);
  static const retryAttempts = 2;

  // Rate limiting
  static const minRefreshInterval = Duration(seconds: 30);
}
```

## Scope Clarifications (Non-Goals)

以下功能明確不在 MVP 範圍內：

1. **備份加密** - 接受未加密 ZIP 的風險
2. **重複偵測** - 不警告相似支出
3. **Excel 匯入** - 不支援從其他來源匯入
4. **圖片裁剪/旋轉** - 僅支援原圖
5. **深色模式** - MVP 僅淺色主題
6. **多語言** - 僅繁體中文

## Open Questions (Resolved)

1. ~~是否需要 biometric lock？~~ → **不需要（MVP 不含）**
2. ~~匯率手動輸入是否需要歷史記錄？~~ → **不需要**
3. ~~備份是否自動執行？~~ → **手動觸發，避免流量消耗**
4. ~~needs_sync 欄位用途？~~ → **🗑️ 已移除，MVP 不含同步功能**
