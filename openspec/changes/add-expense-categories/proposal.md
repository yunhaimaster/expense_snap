# Proposal: Add Expense Categories

## Change ID
`add-expense-categories`

## Summary
為支出記錄新增分類功能，讓使用者能將支出歸類（如餐飲、交通、住宿、辦公用品等），並在匯出報表時按類別統計。系統預設提供常用分類，支出分類為選填，並透過 OCR 智能建議分類。

## Problem Statement
目前支出記錄只有描述欄位，無法：
- 按類別篩選或分組顯示
- 在月結報告中顯示各類別小計
- 分析支出分佈情況

## Proposed Solution

### Category System
- **Predefined Categories**: 系統提供 8 個常用分類，不可自訂
  - 餐飲 (meals)
  - 交通 (transport)
  - 住宿 (accommodation)
  - 辦公用品 (officeSupplies) — 注意：使用 camelCase 以匹配 Dart enum
  - 通訊 (communication)
  - 娛樂 (entertainment)
  - 醫療 (medical)
  - 其他 (other)

- **Optional Field**: 分類為選填，現有支出無需強制遷移

- **Smart Suggestion**: 基於 OCR 提取的描述，自動建議分類
  - 「大家樂餐廳」→ 餐飲
  - 「的士」「Uber」→ 交通
  - 「酒店」「Hotel」→ 住宿
  - 若文字同時匹配多個分類，優先返回較具體的匹配（見 design.md 優先級規則）

### Data Model Changes
- `expenses` 表新增 `category TEXT` 欄位（nullable）
- Database migration: v1 → v2（目前版本為 v1）
- 新增 `idx_expenses_category` 索引以支援未來按分類篩選
- 無需新建分類表（predefined 直接用 enum）

### UI Changes
1. **Add/Edit Expense Screen**: 新增分類選擇器（可選）
2. **Home Screen**: 每筆支出顯示分類 badge（帶無障礙標籤）
3. **Export Excel**: 新增「分類」欄位，按分類小計

## Scope

### In Scope
- Predefined category enum
- Category field in expense model
- Category picker UI (horizontal scrollable chips)
- OCR-based category suggestion (keyword matching)
- Excel export with category column and subtotals
- Accessibility support (Semantics labels)

### Out of Scope (Deferred)
- Filter by category — 索引已建立，UI 留待未來版本
- Custom user categories
- Category budgets/limits
- Category icons customization
- Analytics dashboard

## Success Criteria
- [ ] 使用者可為支出選擇分類（選填）
- [ ] 使用者可移除已設定的分類（設為 null）
- [ ] OCR 處理後自動建議分類
- [ ] 匯出 Excel 包含分類欄位及各類別小計
- [ ] 現有支出資料無需遷移（category = null）
- [ ] 所有現有測試通過
- [ ] CategoryPicker 有完整的 Semantics 標籤

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Database migration | 新增 nullable column，無需 data migration；版本 v1→v2 |
| i18n complexity | Categories use i18n keys like `category_meals`；命名與 enum 一致 |
| OCR suggestion accuracy | Suggestion only, user can override；關鍵字優先級避免誤判 |
| copyWith cannot clear nullable | 使用 clearCategory flag 或 Optional wrapper 模式 |

## Dependencies
- `receipt-ocr` spec (for category suggestion integration)
- `expense-management` spec (extending Expense model)
- `data-export` spec (Excel category column)
