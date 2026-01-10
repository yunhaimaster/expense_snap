# Design: Add Expense Categories

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────┐
│                      Presentation Layer                       │
├──────────────────────────────────────────────────────────────┤
│  AddExpenseScreen          HomeScreen         ExportScreen   │
│  ├─ CategoryPicker         ├─ CategoryBadge   ├─ Category    │
│  └─ (OCR suggestion)       └─ (in ExpenseCard)   subtotals   │
└──────────────────────────────────────────────────────────────┘
                              │
┌──────────────────────────────────────────────────────────────┐
│                       Domain Layer                            │
├──────────────────────────────────────────────────────────────┤
│  ExpenseCategory (enum)    CategorySuggester (service)       │
│  - meals                   - suggestFromText(String) → cat   │
│  - transport               - keyword matching with priority  │
│  - accommodation           - supports zh/en                  │
│  - officeSupplies                                            │
│  - communication                                             │
│  - entertainment                                             │
│  - medical                                                   │
│  - other                                                     │
└──────────────────────────────────────────────────────────────┘
                              │
┌──────────────────────────────────────────────────────────────┐
│                        Data Layer                             │
├──────────────────────────────────────────────────────────────┤
│  Expense model             DatabaseHelper                    │
│  - category: String?       - expenses.category TEXT          │
│                            - migration v1→v2                 │
│                            - idx_expenses_category index     │
└──────────────────────────────────────────────────────────────┘
```

## Data Model

### ExpenseCategory Enum
```dart
/// 支出分類
enum ExpenseCategory {
  meals,          // 餐飲
  transport,      // 交通
  accommodation,  // 住宿
  officeSupplies, // 辦公用品
  communication,  // 通訊
  entertainment,  // 娛樂
  medical,        // 醫療
  other,          // 其他
}

extension ExpenseCategoryExtension on ExpenseCategory {
  /// 取得 i18n key
  String get i18nKey => 'category_$name';

  /// 取得分類顏色（支援淺色/深色主題）
  Color getColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (this) {
      ExpenseCategory.meals => isDark ? const Color(0xFF81C784) : const Color(0xFF4CAF50),
      ExpenseCategory.transport => isDark ? const Color(0xFF64B5F6) : const Color(0xFF2196F3),
      ExpenseCategory.accommodation => isDark ? const Color(0xFFBA68C8) : const Color(0xFF9C27B0),
      ExpenseCategory.officeSupplies => isDark ? const Color(0xFFFFB74D) : const Color(0xFFFF9800),
      ExpenseCategory.communication => isDark ? const Color(0xFF4DD0E1) : const Color(0xFF00BCD4),
      ExpenseCategory.entertainment => isDark ? const Color(0xFFE57373) : const Color(0xFFF44336),
      ExpenseCategory.medical => isDark ? const Color(0xFFF06292) : const Color(0xFFE91E63),
      ExpenseCategory.other => isDark ? const Color(0xFF90A4AE) : const Color(0xFF607D8B),
    };
  }

  /// 取得文字顏色（確保對比度）
  Color getTextColor(BuildContext context) {
    // 淺色主題使用白字，深色主題使用黑字
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.black87 : Colors.white;
  }

  /// 從字串解析（帶錯誤日誌）
  static ExpenseCategory? fromString(String? value) {
    if (value == null) return null;
    try {
      return ExpenseCategory.values.byName(value);
    } on ArgumentError {
      // 記錄未知分類值，便於除錯
      AppLogger.warning('Unknown expense category: $value, defaulting to other');
      return ExpenseCategory.other;
    }
  }
}
```

### Expense Model Extension
```dart
class Expense {
  // ... existing fields ...

  /// 支出分類（nullable，選填）
  final ExpenseCategory? category;

  // toMap 更新
  Map<String, dynamic> toMap() {
    return {
      // ... existing fields ...
      'category': category?.name,  // 使用 enum name (camelCase)
    };
  }

  // fromMap 更新
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      // ... existing fields ...
      category: ExpenseCategoryExtension.fromString(map['category'] as String?),
    );
  }

  // copyWith 更新 - 支援清除 nullable 欄位
  Expense copyWith({
    // ... existing parameters ...
    ExpenseCategory? category,
    bool clearCategory = false,  // 新增：允許清除分類
  }) {
    return Expense(
      // ... existing fields ...
      category: clearCategory ? null : (category ?? this.category),
    );
  }

  // hashCode/== 更新
  @override
  bool operator ==(Object other) {
    // 如果兩者都有 id，用 id 比較
    if (id != null && other is Expense && other.id != null) {
      return id == other.id;
    }
    // 如果都沒有 id（新建未儲存），比較所有欄位
    if (id == null && other is Expense && other.id == null) {
      return date == other.date &&
          originalAmountCents == other.originalAmountCents &&
          originalCurrency == other.originalCurrency &&
          description == other.description &&
          category == other.category &&  // 新增
          createdAt == other.createdAt;
    }
    return false;
  }

  @override
  int get hashCode {
    if (id != null) return id.hashCode;
    return Object.hash(date, originalAmountCents, originalCurrency,
                       description, category, createdAt);  // 新增 category
  }
}
```

### Database Migration
```sql
-- Version 2: Add category column and index
ALTER TABLE expenses ADD COLUMN category TEXT;

-- 索引支援未來按分類篩選
CREATE INDEX idx_expenses_category ON expenses (category);

-- 複合索引優化常見查詢
CREATE INDEX idx_expenses_deleted_category ON expenses (is_deleted, category);

-- No data migration needed (nullable)
```

## Category Suggestion Algorithm

### CategorySuggester Service
```dart
class CategorySuggester {
  /// 根據文字建議分類
  ///
  /// 使用優先級匹配：
  /// 1. 先嘗試長關鍵字（更具體）
  /// 2. 短關鍵字優先級較低
  /// 3. 若無匹配返回 null
  ExpenseCategory? suggestFromText(String text) {
    final lowerText = text.toLowerCase();

    // 第一輪：長關鍵字匹配（≥3 字元，更具體）
    for (final entry in _longKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerText.contains(keyword)) {
          return entry.key;
        }
      }
    }

    // 第二輪：短關鍵字匹配（可能有誤判）
    for (final entry in _shortKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerText.contains(keyword)) {
          return entry.key;
        }
      }
    }

    return null;
  }

  /// 長關鍵字（優先匹配，較具體）
  static const _longKeywords = <ExpenseCategory, List<String>>{
    ExpenseCategory.meals: [
      '餐廳', '餐飲', '咖啡', '早餐', '午餐', '晚餐', '宵夜',
      'cafe', 'restaurant', 'dining', 'breakfast', 'lunch', 'dinner',
      '大家樂', '美心', '麥當勞', 'mcdonald', 'starbucks', '星巴克',
    ],
    ExpenseCategory.transport: [
      '的士', 'taxi', 'uber', 'grab', '港鐵', 'mtr', '地鐵',
      '巴士', 'bus', '停車', 'parking', '油站', 'petrol', 'gas station',
      '機場快線', 'airport express', '渡輪', 'ferry',
    ],
    ExpenseCategory.accommodation: [
      '酒店', 'hotel', '旅館', 'airbnb', '民宿', 'hostel',
      '住宿', 'lodging', 'accommodation',
    ],
    ExpenseCategory.officeSupplies: [
      '文具', '辦公', 'office', '影印', '打印', 'printing',
      '辦公用品', 'stationery', 'office supplies',
    ],
    ExpenseCategory.communication: [
      '電話費', '話費', '上網費', '數據', 'data plan', 'mobile plan',
      '寬頻', 'broadband', 'internet',
    ],
    ExpenseCategory.entertainment: [
      '電影', '戲院', 'cinema', 'movie', '遊戲', 'game',
      '演唱會', 'concert', '展覽', 'exhibition',
    ],
    ExpenseCategory.medical: [
      '醫院', '診所', '藥房', 'clinic', 'pharmacy', 'hospital',
      '醫療', 'medical', '看診',
    ],
  };

  /// 短關鍵字（較寬鬆，可能有誤判）
  /// 注意：避免過短的字如「餐」「食」，容易誤判
  static const _shortKeywords = <ExpenseCategory, List<String>>{
    ExpenseCategory.meals: ['cafe', '茶'],  // 保守選擇
    ExpenseCategory.communication: ['sim'],
  };
}
```

### Keyword Matching Priority Rules

1. **長關鍵字優先**：「麥當勞」比「餐」更具體
2. **避免過短關鍵字**：「餐」會匹配「餐車」「用餐」等非餐飲支出
3. **中英文皆支援**：同時支援繁體中文和英文
4. **使用者可覆蓋**：建議僅為預設，使用者可自行選擇

### 已知限制
- 只支援繁體中文和英文，未來新增語言需擴充關鍵字
- 無法處理簡繁轉換（港鐵 vs 港铁）
- 關鍵字匹配可能有誤判，依賴使用者修正

## UI Design

### Category Picker (Add/Edit Screen)
- **Position**: Below description field
- **Style**: Horizontal scrollable chips
- **Behavior**:
  - Single selection
  - Tap selected chip to deselect (clear category)
  - Pre-selected if OCR suggested
  - **Accessibility**: 每個 chip 需有 Semantics label

```
┌─────────────────────────────────────────────┐
│ 分類（選填）                                  │
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐        │
│ │餐飲│ │交通│ │住宿│ │辦公│ │...│ →      │
│ └────┘ └────┘ └────┘ └────┘ └────┘        │
└─────────────────────────────────────────────┘
Semantics: "餐飲分類，已選取" / "交通分類，未選取"
```

### CategoryPicker Widget
```dart
class CategoryPicker extends StatelessWidget {
  final ExpenseCategory? selectedCategory;
  final ValueChanged<ExpenseCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.of(context).category_label),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ExpenseCategory.values.map((category) {
              final isSelected = category == selectedCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Semantics(
                  label: '${S.of(context).categoryName(category)}'
                         '${isSelected ? '，已選取' : ''}',
                  button: true,
                  child: FilterChip(
                    label: Text(S.of(context).categoryName(category)),
                    selected: isSelected,
                    onSelected: (_) {
                      // 點擊已選取的 chip 會取消選取
                      onChanged(isSelected ? null : category);
                    },
                    selectedColor: category.getColor(context),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? category.getTextColor(context)
                          : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
```

### Category Badge (Expense Card)
- **Style**: Small colored chip
- **Position**: Below description, before amount (wrap on small screens)
- **Colors**: Each category has theme-aware color
- **Hide**: Don't show badge if category is null

```
┌─────────────────────────────────────────────┐
│ [縮圖]  辦公室文具                            │
│         [辦公用品]  HKD 128.00              │
│         2025-01-15                          │
└─────────────────────────────────────────────┘
```

### CategoryBadge Widget
```dart
class CategoryBadge extends StatelessWidget {
  final ExpenseCategory category;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '分類：${S.of(context).categoryName(category)}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: category.getColor(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          S.of(context).categoryName(category),
          style: TextStyle(
            fontSize: 12,
            color: category.getTextColor(context),
          ),
        ),
      ),
    );
  }
}
```

### Export Excel Changes
- New column: 「分類」(between 描述 and 原幣)
- Category subtotals section at bottom
- **Subtotals rules**:
  - 只顯示有支出的分類（不顯示 0 元分類）
  - 未分類支出歸入「未分類」行（若有）
  - 按小計金額降序排列

```
| 編號 | 日期 | 描述 | 分類 | 原幣 | 金額 | 匯率 | 港幣金額 |
|------|------|------|------|------|------|------|----------|
| 1    | 1/15 | 午餐 | 餐飲 | HKD  | 45   | 1.0  | 45.00    |
| 2    | 1/16 | 的士 | 交通 | HKD  | 80   | 1.0  | 80.00    |
| 3    | 1/17 | 雜項 |      | HKD  | 20   | 1.0  | 20.00    |
...
| 總計 |      |      |      |      |      |      | 145.00   |
|      |      |      |      |      |      |      |          |
| 分類統計 |   |      |      |      |      |      |          |
| 交通 |      |      |      |      |      |      | 80.00    |
| 餐飲 |      |      |      |      |      |      | 45.00    |
| 未分類 |    |      |      |      |      |      | 20.00    |
```

## Category Colors

| Category | Light Mode | Dark Mode | 說明 |
|----------|------------|-----------|------|
| meals | #4CAF50 | #81C784 | 綠色 - 食物 |
| transport | #2196F3 | #64B5F6 | 藍色 - 移動 |
| accommodation | #9C27B0 | #BA68C8 | 紫色 - 住宿 |
| officeSupplies | #FF9800 | #FFB74D | 橙色 - 辦公 |
| communication | #00BCD4 | #4DD0E1 | 青色 - 通訊 |
| entertainment | #F44336 | #E57373 | 紅色 - 娛樂 |
| medical | #E91E63 | #F06292 | 粉色 - 醫療 |
| other | #607D8B | #90A4AE | 灰色 - 其他 |

所有顏色經過對比度檢查，確保 WCAG AA 標準。

## i18n Keys

New keys needed in `app_zh.arb` / `app_en.arb`:
```json
{
  "category_label": "分類（選填）",
  "category_meals": "餐飲",
  "category_transport": "交通",
  "category_accommodation": "住宿",
  "category_officeSupplies": "辦公用品",
  "category_communication": "通訊",
  "category_entertainment": "娛樂",
  "category_medical": "醫療",
  "category_other": "其他",
  "category_statistics": "分類統計",
  "category_uncategorized": "未分類"
}
```

## Testing Strategy

| Layer | Test Focus |
|-------|------------|
| Unit | ExpenseCategory enum, fromString with invalid values, colors |
| Unit | CategorySuggester: keyword matching, priority, edge cases |
| Repository | CRUD with category field, migration, index usage |
| Widget | CategoryPicker selection/deselection, accessibility |
| Widget | CategoryBadge display, color contrast |
| Integration | OCR → suggestion → form fill → save flow |
| Integration | Export with categories and subtotals |

### Edge Case Tests
- [ ] Clear category via copyWith(clearCategory: true)
- [ ] Unknown category string falls back to 'other' with log
- [ ] Multi-keyword match returns first priority match
- [ ] Empty description returns null suggestion
- [ ] Category survives backup/restore cycle

## Migration Path
1. Bump database version: 1 → 2
2. Add nullable `category` column
3. Add indexes for future filtering
4. Existing expenses have `category = null`
5. Display as empty in badge (don't show)
6. Display as "未分類" in export subtotals
7. No forced migration for existing data
