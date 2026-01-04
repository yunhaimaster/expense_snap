---
name: refactor
description: 安全重構 - 重命名、提取、移動，確保測試通過
args: <action> <target> [options]
---

# /refactor - 安全重構

執行程式碼重構，確保不破壞現有功能。

## 用法

```
/refactor rename OldClass NewClass
/refactor extract method expense_card.dart:45-60 buildHeader
/refactor move ExpenseCard lib/presentation/widgets/expense/
/refactor split large_file.dart
```

## 重構類型

### 1. Rename - 重命名
```
/refactor rename <old_name> <new_name> [--type class|method|variable]
```
- 更新所有引用
- 更新 imports
- 更新測試

### 2. Extract - 提取
```
/refactor extract method <file>:<lines> <new_name>
/refactor extract widget <file>:<lines> <new_widget_name>
/refactor extract class <file>:<lines> <new_class_name>
```
- 提取為獨立單元
- 自動處理依賴

### 3. Move - 移動
```
/refactor move <symbol> <new_path>
```
- 移動檔案或符號
- 更新所有 imports

### 4. Split - 拆分
```
/refactor split <large_file>
```
- 分析檔案結構
- 建議拆分方案
- 逐步執行拆分

### 5. Inline - 內聯
```
/refactor inline <symbol>
```
- 將函數/變數內聯到使用處
- 移除原定義

## 安全保證

1. **預檢查**
   - 確認測試通過
   - 確認 analyze 無錯誤

2. **執行重構**
   - 使用 Dart/IDE 重構工具
   - 逐步變更，每步驗證

3. **驗證**
   - 執行 `flutter analyze`
   - 執行 `flutter test`
   - 顯示變更摘要

4. **回滾**
   - 若驗證失敗，自動回滾
   - 報告失敗原因

## 輸出格式

```
## Refactor: Rename ExpenseCard → ExpenseListItem

### Changes
- lib/presentation/widgets/expense_card.dart → expense_list_item.dart
- Updated 12 imports
- Updated 5 test files

### Verification
✅ flutter analyze: 0 errors
✅ flutter test: 188/188 passed

### Git
Changes staged. Run `git commit -m "refactor: rename ExpenseCard to ExpenseListItem"` to commit.
```
