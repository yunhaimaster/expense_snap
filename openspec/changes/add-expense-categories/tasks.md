# Tasks: Add Expense Categories

## Phase 1: Data Layer (Foundation)

### 1.1 Create ExpenseCategory enum
- [ ] Create `lib/core/constants/expense_category.dart`
- [ ] Define 8 predefined categories with i18n keys
- [ ] Add `fromString()` with error logging (use `byName` + try/catch)
- [ ] Add `getColor()` and `getTextColor()` for theme-aware colors
- [ ] Write unit tests for enum parsing (valid, invalid, null)

### 1.2 Update Expense model
- [ ] Add `category: ExpenseCategory?` field to constructor
- [ ] Update `copyWith()` with `clearCategory` flag for nullable clearing
- [ ] Update `toMap()` - serialize as `category?.name`
- [ ] Update `fromMap()` - use `ExpenseCategoryExtension.fromString()`
- [ ] Update `==` operator to include category comparison
- [ ] Update `hashCode` to include category
- [ ] Write unit tests for model changes (including clearCategory)

### 1.3 Database migration
- [ ] Bump `_databaseVersion` from 1 to 2
- [ ] Add migration in `_onUpgrade`: `ALTER TABLE expenses ADD COLUMN category TEXT`
- [ ] Add index: `CREATE INDEX idx_expenses_category ON expenses (category)`
- [ ] Add composite index: `CREATE INDEX idx_expenses_deleted_category ON expenses (is_deleted, category)`
- [ ] Update `_onCreate` to include category column for fresh installs
- [ ] Write integration tests for migration (upgrade from v1)

## Phase 2: Repository & Provider (Data Flow)

> **Note**: Moved earlier because Forms and Export depend on this

### 2.1 Update ExpenseRepository
- [ ] Update `addExpense()` - category included in Expense model
- [ ] Update `updateExpense()` - category included in Expense model
- [ ] No changes to query methods (category comes from model)
- [ ] Write repository tests with category field

### 2.2 Update ExpenseProvider
- [ ] Update `addExpense()` - pass category through
- [ ] Update `updateExpense()` - pass category through
- [ ] Ensure proper state updates with category changes
- [ ] Write provider tests with category

## Phase 3: Category Suggestion Service

### 3.1 Create CategorySuggester service
- [ ] Create `lib/services/category_suggester.dart`
- [ ] Implement two-tier keyword matching (long keywords first, then short)
- [ ] Use `_longKeywords` map for specific matches (≥3 chars)
- [ ] Use `_shortKeywords` map for fallback matches
- [ ] Case-insensitive matching with `toLowerCase()`
- [ ] Register in service locator (`sl.registerLazySingleton`)

### 3.2 Unit tests for suggestion
- [ ] Test each category's long keywords
- [ ] Test priority: long keyword beats short keyword
- [ ] Test case-insensitive matching
- [ ] Test no match returns null
- [ ] Test empty string returns null
- [ ] Test multi-match returns first priority hit

### 3.3 Integrate with ReceiptParser
- [ ] Add `suggestedCategory: ExpenseCategory?` to `ReceiptParseResult`
- [ ] Call `CategorySuggester.suggestFromText(description)` in `parse()`
- [ ] Update `ReceiptParseResult.hasData` to include category check
- [ ] Update receipt_parser_test.dart with category scenarios

## Phase 4: i18n

### 4.1 Add localization keys
- [ ] Add 11 new keys to `app_zh.arb`:
  - `category_label`: "分類（選填）"
  - `category_meals`: "餐飲"
  - `category_transport`: "交通"
  - `category_accommodation`: "住宿"
  - `category_officeSupplies`: "辦公用品"
  - `category_communication`: "通訊"
  - `category_entertainment`: "娛樂"
  - `category_medical`: "醫療"
  - `category_other`: "其他"
  - `category_statistics`: "分類統計"
  - `category_uncategorized`: "未分類"
- [ ] Add 11 new keys to `app_en.arb` with English translations
- [ ] Run `flutter gen-l10n`
- [ ] Verify generated `S` class includes new methods

## Phase 5: UI Components

### 5.1 Create CategoryPicker widget
- [ ] Create `lib/presentation/widgets/category_picker.dart`
- [ ] Horizontal `SingleChildScrollView` with `Row` of chips
- [ ] Use `FilterChip` for each category
- [ ] Single selection: tap selected to deselect (returns null)
- [ ] Color-coded using `category.getColor(context)`
- [ ] **Accessibility**: Wrap each chip in `Semantics` with label
- [ ] Widget tests for selection/deselection

### 5.2 Create CategoryBadge widget
- [ ] Create `lib/presentation/widgets/category_badge.dart`
- [ ] Small colored `Container` with rounded corners
- [ ] Use `category.getColor(context)` for background
- [ ] Use `category.getTextColor(context)` for text
- [ ] **Accessibility**: Wrap in `Semantics` with "分類：{name}" label
- [ ] Widget tests for display and colors

### 5.3 Update ExpenseCard
- [ ] Add CategoryBadge below description
- [ ] Only render if `expense.category != null`
- [ ] Wrap in responsive layout to handle overflow
- [ ] Update expense_card_test.dart with/without category

## Phase 6: Form Integration

### 6.1 Update AddExpenseScreen
- [ ] Add CategoryPicker below description field
- [ ] Add `_selectedCategory` state variable
- [ ] Wire `onChanged` to update state
- [ ] Auto-select OCR-suggested category when `ReceiptParseResult` received
- [ ] Pass category to `provider.addExpense()`
- [ ] Allow clearing category (tap selected chip)

### 6.2 Update ExpenseDetailScreen
- [ ] Display CategoryBadge if category exists
- [ ] Add CategoryPicker in edit mode
- [ ] Support clearing category with `clearCategory: true`
- [ ] Pass updated category to `provider.updateExpense()`

### 6.3 Form tests
- [ ] Test category picker appears and functions
- [ ] Test OCR auto-suggestion fills picker
- [ ] Test save expense with category
- [ ] Test save expense without category
- [ ] Test edit expense, change category
- [ ] Test edit expense, remove category

## Phase 7: Export Integration

### 7.1 Update ExportStrings
- [ ] Add `headerCategory` field
- [ ] Add `categoryStatistics` field
- [ ] Add `categoryUncategorized` field
- [ ] Update `fromL10n()` factory to include new fields

### 7.2 Update ExportService
- [ ] Add 「分類」column between 描述 and 原幣
- [ ] Update `_setHeaderRow()` with new column
- [ ] Update `_setDataRow()` to include category (or empty if null)
- [ ] Add `_setCategorySubtotals()` method:
  - Group expenses by category
  - Calculate HKD subtotal per category
  - Sort by subtotal descending
  - Include "未分類" row if any null categories
  - Only show categories with > 0 expenses
- [ ] Call `_setCategorySubtotals()` after total row

### 7.3 Export tests
- [ ] Test Excel with mixed categories
- [ ] Test Excel with all same category
- [ ] Test Excel with all null categories
- [ ] Test category subtotals calculation
- [ ] Test subtotals sort order (descending)
- [ ] Test "未分類" row appears when needed

## Phase 8: Validation & Polish

### 8.1 Run full test suite
- [ ] `flutter test` - all existing + new tests pass
- [ ] `flutter analyze` - no warnings or errors
- [ ] Check test coverage for new code

### 8.2 Accessibility verification
- [ ] VoiceOver (iOS) / TalkBack (Android) test CategoryPicker
- [ ] VoiceOver (iOS) / TalkBack (Android) test CategoryBadge
- [ ] Verify color contrast meets WCAG AA

### 8.3 Manual QA checklist
- [ ] Create expense with category
- [ ] Create expense without category
- [ ] Edit expense, add category
- [ ] Edit expense, change category
- [ ] Edit expense, remove category (clear)
- [ ] OCR auto-suggestion works
- [ ] OCR suggestion can be overridden
- [ ] Export includes categories column
- [ ] Export subtotals correct and sorted
- [ ] Export handles uncategorized
- [ ] i18n correct (zh/en switch)
- [ ] Dark mode colors correct
- [ ] Backup/restore preserves category

---

## Corrected Dependencies

```
Phase 1 (Data Layer)
    ↓
Phase 2 (Repository & Provider) ←── Must be early, others depend on it
    ↓
Phase 3 (Category Suggester) ──┬── Phase 4 (i18n)
                               │       ↓
                               └──→ Phase 5 (UI Components)
                                        ↓
                               ┌────────┴────────┐
                               ↓                 ↓
                        Phase 6 (Forms)    Phase 7 (Export)
                               └────────┬────────┘
                                        ↓
                                Phase 8 (Validation)
```

## Parallelizable Work
- Phase 3 (CategorySuggester) and Phase 4 (i18n) can run in parallel after Phase 2
- Phase 5 (UI Components) needs Phase 4 (i18n) for labels
- Phase 6 (Forms) and Phase 7 (Export) can run in parallel after Phase 5
- Phase 8 must wait for all others

## Estimated Task Count
- Phase 1: 6 tasks
- Phase 2: 4 tasks
- Phase 3: 3 tasks
- Phase 4: 1 task
- Phase 5: 3 tasks
- Phase 6: 3 tasks
- Phase 7: 3 tasks
- Phase 8: 3 tasks
- **Total: 26 implementation tasks**
