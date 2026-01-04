---
name: cleanup
description: 程式碼清理 - 移除死碼、未使用 imports、格式化
args: [--fix] [--aggressive]
---

# /cleanup - 程式碼清理

識別並移除無用程式碼，保持專案整潔。

## 用法

```
/cleanup           # 僅報告問題
/cleanup --fix     # 自動修復安全問題
/cleanup --aggressive  # 包含可能有風險的清理
```

## 清理項目

### 1. 未使用的 Imports
```bash
dart fix --apply
```

### 2. 未使用的變數和參數
- 識別未使用的 local variables
- 識別未使用的 private members
- 識別未使用的 parameters

### 3. 死碼 (Dead Code)
- 永遠為 false 的條件
- 無法到達的程式碼
- 空的 catch blocks

### 4. 重複程式碼
- 識別相似的程式碼區塊
- 建議提取為共用函數

### 5. 過時的依賴
```bash
flutter pub outdated
```

### 6. 暫存檔案
- `.dart_tool/`
- `build/`
- `*.g.dart` (generated)

### 7. 格式化
```bash
dart format lib test
```

## --aggressive 模式額外清理

- 移除未使用的 public APIs
- 移除空檔案
- 簡化過度複雜的條件

## 輸出格式

```
## Cleanup Report

### 🗑️ Unused Imports (12)
- lib/screens/home.dart: material.dart
- lib/services/api.dart: http.dart

### 🗑️ Unused Variables (3)
- lib/providers/expense_provider.dart:45 _oldValue

### 📦 Outdated Dependencies (5)
- provider: 6.0.5 → 6.1.0
- dio: 5.3.0 → 5.4.0

### 💾 Disk Space
- build/: 156 MB (可清理)
- .dart_tool/: 23 MB

Total reclaimable: 179 MB

Run `/cleanup --fix` to auto-fix safe issues.
```
