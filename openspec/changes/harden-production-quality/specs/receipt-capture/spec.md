# receipt-capture Specification Delta

## MODIFIED Requirements

### Requirement: Image Compression
系統 SHALL 自動壓縮收據圖片以節省儲存空間，並確保移除隱私資料。

#### Scenario: Compress large image
- **GIVEN** 原始圖片為 4000x3000 pixels
- **WHEN** 系統處理該圖片
- **THEN** 壓縮至最大 1920x1080 pixels
- **AND** 使用 75% JPEG quality
- **AND** 保持原始長寬比
- **AND** 移除 EXIF metadata（包括 GPS 位置資訊）

#### Scenario: Verify EXIF removal
- **GIVEN** 原始圖片包含 EXIF metadata（GPS、相機型號、日期）
- **WHEN** 系統壓縮圖片後
- **THEN** 輸出圖片不包含任何 EXIF metadata
- **AND** 可通過 exif 工具驗證無 metadata

#### Scenario: Small image no upscale
- **GIVEN** 原始圖片為 800x600 pixels
- **WHEN** 系統處理該圖片
- **THEN** 不放大圖片
- **AND** 僅套用 75% quality 壓縮
- **AND** 移除 EXIF metadata

## ADDED Requirements

### Requirement: Image Processing Timeout
系統 SHALL 限制圖片處理時間以避免 UI 凍結。

#### Scenario: Isolate processing with timeout
- **WHEN** 系統在 isolate 中處理圖片
- **THEN** 設定 5 秒超時限制
- **AND** 顯示處理進度指示器
- **AND** 超時後取消操作

#### Scenario: Timeout recovery
- **GIVEN** isolate 處理超過 5 秒
- **WHEN** 系統偵測超時
- **THEN** 取消 isolate 操作
- **AND** 顯示「處理超時，請重試」錯誤
- **AND** 不 fallback 到主執行緒（避免 UI 凍結）

#### Scenario: Progress indication
- **WHEN** 圖片處理進行中
- **THEN** 顯示進度指示器
- **AND** 使用者知道系統正在處理
- **AND** 處理完成後自動關閉指示器

### Requirement: OCR Rate Limiting
系統 SHALL 限制 OCR 請求頻率以保護設備資源。

#### Scenario: Rate limit rapid requests
- **GIVEN** 使用者在 2 秒內連續觸發 OCR
- **WHEN** 第二次 OCR 請求發送
- **THEN** 系統返回 rate-limited 結果
- **AND** 顯示「請稍候再試」提示
- **AND** 不執行 ML Kit 處理

#### Scenario: Allow request after cooldown
- **GIVEN** 距離上次 OCR 請求已超過 2 秒
- **WHEN** 使用者觸發 OCR
- **THEN** 系統正常執行 OCR 處理
- **AND** 更新最後請求時間戳

#### Scenario: OCR timeout reduction
- **WHEN** OCR 處理開始
- **THEN** 系統設定 5 秒超時（原為 10 秒）
- **AND** 顯示處理進度指示器
- **AND** 超時後返回 timeout 錯誤

### Requirement: Orphaned Image Cleanup
系統 SHALL 定期清理未被任何支出記錄引用的孤立圖片。

#### Scenario: Detect orphaned images
- **GIVEN** 檔案系統中存在圖片檔案
- **WHEN** 該圖片不被任何資料庫記錄的 image_path 引用
- **THEN** 標記為孤立檔案
- **AND** 記錄孤立檔案數量至日誌

#### Scenario: Cleanup on app resume
- **GIVEN** App 從背景恢復
- **WHEN** 距離上次清理超過 24 小時
- **THEN** 系統執行孤立圖片掃描
- **AND** 刪除所有孤立圖片
- **AND** 記錄清理結果

#### Scenario: Safe cleanup verification
- **GIVEN** 系統準備刪除疑似孤立圖片
- **WHEN** 執行刪除前
- **THEN** 再次確認資料庫中無引用
- **AND** 若有引用則跳過刪除
- **AND** 記錄跳過原因

#### Scenario: Cleanup failure handling
- **GIVEN** 清理作業進行中
- **WHEN** 刪除檔案失敗（如權限問題）
- **THEN** 記錄錯誤並繼續處理其他檔案
- **AND** 不影響 App 正常運作

### Requirement: Enhanced Path Validation
系統 SHALL 在備份還原時嚴格驗證所有檔案路徑。

#### Scenario: Reject path traversal in restore
- **GIVEN** 備份 ZIP 包含路徑 `../../../etc/passwd`
- **WHEN** 系統解壓縮備份
- **THEN** 拒絕該檔案
- **AND** 記錄安全警告至日誌
- **AND** 繼續處理其他有效檔案

#### Scenario: Reject symlink in restore
- **GIVEN** 備份 ZIP 包含符號連結
- **WHEN** 系統解壓縮備份
- **THEN** 跳過符號連結檔案
- **AND** 僅處理一般檔案

#### Scenario: Whitelist restore paths
- **WHEN** 系統解壓縮備份圖片
- **THEN** 僅允許寫入 `receipts/YYYY-MM/` 目錄
- **AND** 拒絕寫入其他位置
