# expense-management Specification Delta

## MODIFIED Requirements

### Requirement: Input Validation
系統 SHALL 驗證所有使用者輸入，並在截斷時提供警告。

#### Scenario: Validate amount range
- **WHEN** 使用者輸入金額
- **THEN** 系統驗證金額介於 0.01 ~ 9,999,999.99
- **AND** 最多接受 2 位小數
- **AND** 不接受負數或零

#### Scenario: Warn on decimal truncation
- **WHEN** 使用者輸入超過 2 位小數的金額（如 123.456）
- **THEN** 系統顯示警告訊息「金額將四捨五入至 2 位小數」
- **AND** 顯示截斷後的金額預覽
- **AND** 使用者可選擇接受或修改

#### Scenario: Validate description length
- **WHEN** 使用者輸入描述
- **THEN** 系統驗證描述長度為 1-500 字元
- **AND** 移除首尾空白

#### Scenario: Validate date not in future
- **WHEN** 使用者選擇日期
- **THEN** 系統驗證日期不晚於今日開始時間（00:00:00）
- **AND** 不接受未來日期
- **AND** 邊界日期（今天）允許選擇

#### Scenario: Show validation errors
- **GIVEN** 使用者輸入無效資料
- **WHEN** 使用者嘗試儲存
- **THEN** 系統顯示具體錯誤訊息
- **AND** 標記有問題的欄位
- **AND** 不關閉表單

## ADDED Requirements

### Requirement: Enhanced Duplicate Detection
系統 SHALL 使用編輯距離演算法偵測相似描述的重複支出。

#### Scenario: Detect exact duplicate
- **GIVEN** 48 小時內已存在相同金額、日期、描述的支出
- **WHEN** 使用者嘗試新增支出
- **THEN** 系統顯示「可能重複」警告
- **AND** 顯示疑似重複的支出資訊
- **AND** 使用者可選擇繼續新增或取消

#### Scenario: Detect similar description duplicate
- **GIVEN** 48 小時內已存在相同金額、相似描述（編輯距離 <= 3）的支出
- **WHEN** 使用者嘗試新增支出
- **THEN** 系統顯示「描述相似」提示
- **AND** 顯示相似的支出記錄
- **AND** 使用者可選擇繼續或修改

#### Scenario: No duplicate warning for different amounts
- **GIVEN** 描述相同但金額不同
- **WHEN** 使用者新增支出
- **THEN** 不顯示重複警告
- **AND** 正常儲存

### Requirement: Keyboard Overlay Prevention
系統 SHALL 確保鍵盤不遮擋輸入欄位。

#### Scenario: Scroll to focused field
- **GIVEN** 使用者正在填寫支出表單
- **WHEN** 鍵盤彈出
- **THEN** 表單自動滾動使當前輸入欄位可見
- **AND** 欄位不被鍵盤遮擋
- **AND** 使用者可看到輸入內容

#### Scenario: Bottom padding adjustment
- **WHEN** 鍵盤可見
- **THEN** 表單底部 padding 使用 `viewInsets.bottom`
- **AND** 確保最後一個欄位可完整顯示
