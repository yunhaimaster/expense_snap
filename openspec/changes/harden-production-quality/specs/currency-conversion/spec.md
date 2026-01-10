# currency-conversion Specification Delta

## MODIFIED Requirements

### Requirement: Rate Refresh
系統 SHALL 允許使用者手動重新取得匯率，包括強制刷新選項。

#### Scenario: Refresh rate button
- **WHEN** 使用者點擊「重新取得」按鈕
- **THEN** 系統嘗試從 API 取得最新匯率
- **AND** 若成功則更新顯示
- **AND** 若失敗則顯示錯誤訊息

#### Scenario: Force refresh bypasses rate limit
- **GIVEN** 使用者需要立即更新匯率（如手動修改後需重新取得）
- **WHEN** 使用者長按「重新取得」按鈕觸發強制刷新
- **THEN** 繞過 30 秒 rate limit
- **AND** 立即發送 API 請求
- **AND** 更新顯示的匯率
- **AND** 顯示「強制刷新」確認提示

#### Scenario: Force refresh button availability
- **WHEN** 使用者在新增支出頁面
- **THEN** 匯率欄位旁顯示刷新按鈕
- **AND** 短按執行一般刷新（受 rate limit 限制）
- **AND** 長按執行強制刷新（繞過 rate limit）
- **AND** 顯示載入指示器

#### Scenario: Force refresh failure
- **GIVEN** 使用者觸發強制刷新
- **WHEN** API 請求失敗
- **THEN** 顯示錯誤訊息「無法取得最新匯率」
- **AND** 保留現有匯率值
- **AND** 不影響使用者繼續編輯
