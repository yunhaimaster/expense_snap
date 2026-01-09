# cloud-backup Specification

## Purpose
TBD - created by archiving change bootstrap-expense-tracker. Update Purpose after archive.
## Requirements
### Requirement: Google Sign-In
系統 SHALL 支援 Google 帳號登入以啟用雲端備份。

#### Scenario: Sign in with Google
- **WHEN** 使用者點擊連結 Google 帳號
- **THEN** 系統顯示 Google 登入流程
- **AND** 使用者授權後返回 App
- **AND** 顯示已連結的 Email 地址

#### Scenario: Sign out
- **WHEN** 使用者選擇登出 Google
- **THEN** 系統清除所有 Google tokens
- **AND** 更新 UI 顯示未連結狀態

#### Scenario: Token secure storage
- **WHEN** 使用者登入成功
- **THEN** 系統將 access token 儲存於 secure storage
- **AND** 若有 refresh token 一併儲存

### Requirement: Backup to Drive
系統 SHALL 將所有資料備份至 Google Drive。

#### Scenario: Manual backup
- **GIVEN** 使用者已連結 Google 帳號
- **WHEN** 使用者點擊「立即備份」
- **THEN** 系統顯示備份進度
- **AND** 將 SQLite DB 和收據圖片打包為 ZIP
- **AND** 上傳至 Google Drive `ExpenseTracker/` 資料夾
- **AND** 成功後更新最後備份時間

#### Scenario: Backup file naming
- **WHEN** 系統執行備份
- **THEN** 備份檔名格式為 `backup_YYYYMMDD_HHMMSS.zip`

#### Scenario: Drive folder creation
- **GIVEN** Google Drive 中無 `ExpenseTracker` 資料夾
- **WHEN** 系統執行首次備份
- **THEN** 自動建立該資料夾
- **AND** 上傳備份至其中

### Requirement: Restore from Drive
系統 SHALL 支援從 Google Drive 還原資料。

#### Scenario: Restore backup
- **GIVEN** Google Drive 有備份檔案
- **WHEN** 使用者選擇還原
- **THEN** 系統顯示可用備份列表
- **AND** 使用者選擇後下載並解壓縮
- **AND** 覆蓋本地資料庫和圖片
- **AND** 重新載入 App 狀態

#### Scenario: Restore warning
- **WHEN** 使用者選擇還原
- **THEN** 系統顯示警告：「還原將覆蓋現有資料，是否繼續？」
- **AND** 使用者確認後才執行

### Requirement: Backup Status Display
系統 SHALL 顯示備份狀態資訊。

#### Scenario: Show backup status
- **WHEN** 使用者進入設定頁面
- **THEN** 顯示已連結的 Google Email（若有）
- **AND** 顯示最後備份時間（若有）
- **AND** 顯示最後備份的記錄筆數

### Requirement: Backup Error Handling
系統 SHALL 優雅處理備份/還原失敗。

#### Scenario: Network error during backup
- **GIVEN** 備份過程中網絡中斷
- **WHEN** 上傳失敗
- **THEN** 系統顯示錯誤訊息
- **AND** 保留本地資料不變

#### Scenario: Auth token expired
- **GIVEN** Google access token 已過期
- **WHEN** 系統嘗試備份
- **THEN** 嘗試使用 refresh token 更新
- **AND** 若失敗則提示使用者重新登入

### Requirement: Backup Progress Display
系統 SHALL 顯示備份/還原進度。

#### Scenario: Show backup progress
- **WHEN** 系統執行備份
- **THEN** 顯示階段進度：「壓縮中...」→「上傳中 (45%)」
- **AND** 顯示預估剩餘時間
- **AND** 允許取消操作

#### Scenario: Show restore progress
- **WHEN** 系統執行還原
- **THEN** 顯示階段進度：「下載中 (30%)」→「解壓縮中...」
- **AND** 完成後提示重啟 App

### Requirement: Large Backup Handling
系統 SHALL 處理大型備份檔案。

#### Scenario: Resumable upload
- **GIVEN** 備份檔案超過 5MB
- **WHEN** 系統上傳至 Google Drive
- **THEN** 使用可恢復上傳 (resumable upload)
- **AND** 網絡中斷後可從斷點續傳

#### Scenario: Storage space warning
- **GIVEN** Google Drive 剩餘空間不足
- **WHEN** 系統嘗試上傳備份
- **THEN** 顯示「雲端儲存空間不足」錯誤
- **AND** 建議使用者清理 Drive 空間

### Requirement: Backup Confirmation Dialogs
系統 SHALL 在重要操作前確認。

#### Scenario: Confirm before restore
- **WHEN** 使用者選擇還原備份
- **THEN** 顯示警告對話框
- **AND** 說明「現有資料將被覆蓋」
- **AND** 需要使用者明確確認

#### Scenario: Confirm before sign out
- **GIVEN** 使用者已連結 Google 帳號
- **WHEN** 使用者選擇登出
- **THEN** 顯示確認對話框
- **AND** 說明「登出後需重新授權才能備份」

### Requirement: Backup Integrity
系統 SHALL 驗證備份檔案完整性。

#### Scenario: Validate backup before restore
- **GIVEN** 使用者選擇還原備份
- **WHEN** 系統下載備份檔案
- **THEN** 驗證 ZIP 檔案完整性
- **AND** 驗證內含 expenses.db 和 receipts/
- **AND** 無效備份顯示錯誤訊息

