# data-export Specification Delta

## ADDED Requirements

### Requirement: Streaming Export for Large Datasets
系統 SHALL 使用串流處理方式匯出大量支出資料以避免記憶體不足。

#### Scenario: Stream export for large month
- **GIVEN** 當月有超過 500 筆支出
- **WHEN** 使用者執行匯出
- **THEN** 系統使用串流處理（每批 100 筆）
- **AND** 顯示匯出進度（已處理/總筆數）
- **AND** 不一次載入所有資料至記憶體

#### Scenario: Direct export for small month
- **GIVEN** 當月少於等於 500 筆支出
- **WHEN** 使用者執行匯出
- **THEN** 系統使用直接載入方式
- **AND** 快速完成匯出
- **AND** 行為與現有相同

#### Scenario: Progress reporting
- **GIVEN** 匯出使用串流處理
- **WHEN** 每批次處理完成
- **THEN** 更新進度指示器
- **AND** 顯示「處理中：150/1200」格式
- **AND** 使用者可看到匯出進度

#### Scenario: Memory efficient processing
- **GIVEN** 當月有 5000 筆支出
- **WHEN** 執行串流匯出
- **THEN** 記憶體使用量不超過 50MB 增量
- **AND** 不發生 OutOfMemoryError
- **AND** 不觸發 ANR

#### Scenario: Streaming export failure
- **GIVEN** 串流匯出進行中
- **WHEN** 發生錯誤（如儲存空間不足）
- **THEN** 停止處理並清理暫存檔案
- **AND** 顯示錯誤訊息和已完成進度
- **AND** 提供重試選項

## MODIFIED Requirements

### Requirement: Export Error Handling
系統 SHALL 優雅處理匯出失敗情況，並提供錯誤恢復選項。

#### Scenario: Export failure
- **WHEN** 匯出過程發生錯誤（如儲存空間不足）
- **THEN** 系統返回 `ExportException` 錯誤
- **AND** 顯示使用者友善錯誤訊息
- **AND** 清理任何部分生成的檔案

#### Scenario: Partial export on error
- **GIVEN** 匯出進行至第 500 筆時發生錯誤
- **WHEN** 系統偵測錯誤
- **THEN** 保留已處理的內容（若可用）
- **AND** 顯示錯誤訊息和已完成進度
- **AND** 提供重試選項

#### Scenario: Cancel long export
- **GIVEN** 匯出正在進行（大量資料）
- **WHEN** 使用者取消匯出
- **THEN** 系統停止處理
- **AND** 清理暫存檔案
- **AND** 返回匯出頁面
