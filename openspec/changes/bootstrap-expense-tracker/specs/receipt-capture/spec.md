# Receipt Capture

收據圖片擷取與處理功能。

## ADDED Requirements

### Requirement: Camera Capture
系統 SHALL 允許使用者透過相機拍攝收據照片。

#### Scenario: Take photo with camera
- **WHEN** 使用者點擊拍照按鈕
- **THEN** 系統開啟相機介面
- **AND** 使用者拍照後返回 App
- **AND** 顯示照片預覽

#### Scenario: Camera permission denied
- **GIVEN** 使用者未授予相機權限
- **WHEN** 使用者嘗試拍照
- **THEN** 系統顯示權限請求對話框
- **AND** 提供前往設定的選項

### Requirement: Gallery Selection
系統 SHALL 允許使用者從相簿選取現有照片。

#### Scenario: Select from gallery
- **WHEN** 使用者點擊從相簿選取
- **THEN** 系統開啟相簿選擇器
- **AND** 使用者選擇照片後返回 App
- **AND** 顯示照片預覽

### Requirement: Image Compression
系統 SHALL 自動壓縮收據圖片以節省儲存空間。

#### Scenario: Compress large image
- **GIVEN** 原始圖片為 4000x3000 pixels
- **WHEN** 系統處理該圖片
- **THEN** 壓縮至最大 1920x1080 pixels
- **AND** 使用 75% JPEG quality
- **AND** 保持原始長寬比
- **AND** 移除 EXIF metadata（包括 GPS 位置資訊）

#### Scenario: Small image no upscale
- **GIVEN** 原始圖片為 800x600 pixels
- **WHEN** 系統處理該圖片
- **THEN** 不放大圖片
- **AND** 僅套用 75% quality 壓縮

### Requirement: Thumbnail Generation
系統 SHALL 為每張收據生成縮圖供列表顯示。

#### Scenario: Generate thumbnail
- **WHEN** 系統處理收據圖片
- **THEN** 生成 200x200 pixels 縮圖
- **AND** 使用 60% JPEG quality
- **AND** 儲存於相同目錄

### Requirement: Image Storage Organization
系統 SHALL 將收據圖片按月份組織儲存。

#### Scenario: Store image by month
- **GIVEN** 當前日期為 2025-01
- **WHEN** 系統儲存收據圖片
- **THEN** 儲存至 `{app_dir}/receipts/2025-01/`
- **AND** 檔名格式為 `{timestamp}_{uuid}_full.jpg`
- **AND** 縮圖檔名為 `{timestamp}_{uuid}_thumb.jpg`

### Requirement: Image Deletion
系統 SHALL 在支出永久刪除時一併刪除對應圖片。

#### Scenario: Delete images with expense
- **GIVEN** 支出記錄被永久刪除
- **WHEN** 系統執行刪除
- **THEN** 刪除對應的原圖檔案
- **AND** 刪除對應的縮圖檔案
- **AND** 若檔案不存在則忽略（不報錯）

### Requirement: Image Error Handling
系統 SHALL 優雅處理圖片處理失敗的情況。

#### Scenario: Compression failure
- **WHEN** 圖片壓縮過程失敗
- **THEN** 系統返回 `StorageException` 錯誤
- **AND** 不建立不完整的支出記錄
- **AND** 顯示使用者友善錯誤訊息

### Requirement: Image Path Security
系統 SHALL 驗證圖片路徑安全性。

#### Scenario: Validate image path on load
- **WHEN** 系統載入收據圖片
- **THEN** 驗證路徑在 App 私有目錄內
- **AND** 拒絕包含 `..` 的路徑
- **AND** 路徑無效時顯示佔位圖

#### Scenario: Validate restored backup paths
- **GIVEN** 使用者還原雲端備份
- **WHEN** 系統解壓縮圖片
- **THEN** 驗證所有路徑無目錄遍歷
- **AND** 忽略無效路徑的檔案

### Requirement: Image Memory Management
系統 SHALL 有效管理圖片記憶體使用。

#### Scenario: Limit full image memory
- **WHEN** 系統載入原尺寸收據圖片
- **THEN** 使用 ResizeImage 限制記憶體
- **AND** 最大解碼尺寸不超過螢幕解析度

#### Scenario: Cache thumbnails
- **WHEN** 系統載入縮圖
- **THEN** 使用快取避免重複讀取
- **AND** 快取大小限制為 50MB

### Requirement: Corrupted Image Handling
系統 SHALL 優雅處理損壞的圖片檔案。

#### Scenario: Display placeholder for corrupted image
- **GIVEN** 收據圖片檔案已損壞
- **WHEN** 系統嘗試顯示該圖片
- **THEN** 顯示「圖片無法載入」佔位圖
- **AND** 不影響其他功能運作
- **AND** 記錄錯誤至日誌
