# core-infrastructure Specification Delta

## ADDED Requirements

### Requirement: Thread-Safe Database Initialization
系統 SHALL 使用互斥鎖確保資料庫僅初始化一次，即使在並發存取情況下。

#### Scenario: Concurrent database access during initialization
- **GIVEN** 多個 isolate 或 async 操作同時請求資料庫
- **WHEN** 資料庫尚未初始化
- **THEN** 系統使用 mutex lock 確保僅執行一次初始化
- **AND** 所有請求者等待初始化完成後獲得相同實例
- **AND** 不發生重複初始化

#### Scenario: Sequential access after initialization
- **GIVEN** 資料庫已初始化
- **WHEN** 後續請求存取資料庫
- **THEN** 直接返回已初始化的實例
- **AND** 不產生額外鎖等待開銷

### Requirement: Route Argument Safety
系統 SHALL 驗證所有路由參數，拒絕 null 或無效類型。

#### Scenario: Valid route argument
- **WHEN** 導航至需要參數的頁面（如支出詳情頁）
- **THEN** 系統驗證參數類型正確
- **AND** 正常顯示目標頁面

#### Scenario: Null route argument
- **WHEN** 導航時傳入 null 參數
- **THEN** 系統顯示錯誤頁面
- **AND** 提供返回首頁選項
- **AND** 記錄錯誤至日誌

#### Scenario: Invalid type route argument
- **WHEN** 導航時傳入錯誤類型參數（如 String 而非 int）
- **THEN** 系統顯示錯誤頁面
- **AND** 不發生 runtime 異常

### Requirement: Structured Logging
系統 SHALL 使用結構化日誌格式以支援錯誤追蹤和分析。

#### Scenario: Log structured error
- **WHEN** 發生錯誤
- **THEN** 日誌包含 level、tag、message、timestamp 欄位
- **AND** 包含 error 物件和 stackTrace（若有）
- **AND** 包含操作上下文 fields

#### Scenario: Log user action breadcrumb
- **WHEN** 使用者執行關鍵操作（新增/刪除/匯出）
- **THEN** 系統記錄動作至 breadcrumb 佇列
- **AND** 保留最近 10 筆動作
- **AND** 錯誤報告時包含 breadcrumb 歷史

### Requirement: Centralized Constants
系統 SHALL 將所有 magic numbers 集中於常數檔案。

#### Scenario: Access application constants
- **WHEN** 程式需要使用設定值（如 timeout、限制、閾值）
- **THEN** 從 `app_constants.dart` 取得
- **AND** 不在程式碼中硬編碼數值

### Requirement: Error Context Preservation
系統 SHALL 在錯誤處理時保留操作上下文。

#### Scenario: Preserve context in fold operations
- **WHEN** 使用 Result.fold() 處理錯誤
- **THEN** 日誌記錄包含操作名稱（如「載入支出列表」）
- **AND** 錯誤訊息包含失敗位置上下文
- **AND** 不僅記錄原始 exception

### Requirement: Provider Resource Cleanup
系統 SHALL 確保所有 Provider 正確清理資源。

#### Scenario: Dispose stream subscriptions
- **GIVEN** Provider 持有 StreamSubscription
- **WHEN** Provider 被 dispose
- **THEN** 取消所有 subscription
- **AND** 不產生 memory leak
- **AND** 不觸發 stale listener 錯誤

#### Scenario: Dispose timers
- **GIVEN** Provider 持有 Timer
- **WHEN** Provider 被 dispose
- **THEN** 取消所有 Timer
- **AND** 不繼續執行背景任務

### Requirement: Exception Type Hierarchy
系統 SHALL 提供完整的異常類型階層以區分不同錯誤情境。

#### Scenario: Sync operation failure
- **WHEN** 雲端同步操作失敗
- **THEN** 拋出 `SyncException` 類型
- **AND** 包含同步操作類型（backup/restore）
- **AND** 可區分於其他異常類型

#### Scenario: File system operation failure
- **WHEN** 檔案系統操作失敗（非儲存空間不足）
- **THEN** 拋出 `FileSystemException` 類型
- **AND** 包含檔案路徑資訊
- **AND** 與 `StorageException` 區分
