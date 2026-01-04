---
name: perf
description: 效能分析 - Widget rebuild、記憶體、啟動時間、APK 大小
args: [--profile] [--memory] [--size]
---

# /perf - 效能分析

分析 Flutter App 效能瓶頸。

## 用法

```
/perf              # 靜態分析
/perf --profile    # Profile 模式建議
/perf --memory     # 記憶體分析
/perf --size       # APK 大小分析
```

## 分析項目

### 1. Widget Rebuild 分析
檢查程式碼中可能導致不必要 rebuild 的模式：

- [ ] Consumer vs Selector 使用
- [ ] const constructors
- [ ] StatelessWidget 可行性
- [ ] shouldRebuild 實作
- [ ] context.watch vs context.read

### 2. 圖片與資源
- [ ] 圖片壓縮設定
- [ ] 快取策略
- [ ] 記憶體快取大小限制
- [ ] 縮圖生成效率

### 3. 列表效能
- [ ] ListView.builder 使用
- [ ] itemExtent 設定
- [ ] RepaintBoundary 使用
- [ ] 分頁載入實作

### 4. 啟動效能
- [ ] 延遲初始化
- [ ] 首幀渲染時間
- [ ] DI 初始化順序

### 5. APK 大小分析 (--size)
```bash
flutter build apk --analyze-size
```

分析：
- 各 package 佔用大小
- 資源檔案大小
- 原生程式碼大小
- 可優化項目

### 6. 記憶體使用 (--memory)
- 常見記憶體洩漏模式
- Stream subscription 清理
- Controller dispose
- 大物件參考

## 優化建議模板

```dart
// ❌ 避免
Consumer<ExpenseProvider>(
  builder: (_, provider, __) => Text(provider.total),
)

// ✅ 建議
Selector<ExpenseProvider, String>(
  selector: (_, p) => p.total,
  builder: (_, total, __) => Text(total),
)
```

## 輸出格式

```
## Performance Analysis Report

### 🔴 Critical
- Unnecessary rebuilds: expense_list.dart
  - Consumer rebuilds on any change (→ use Selector)

### 🟡 Warning
- Large image loading: image_service.dart
  - No memory cache limit set

### 📦 APK Size Breakdown
- Flutter engine: 4.2 MB
- Dart code: 2.1 MB
- Assets: 1.8 MB
- Native libs: 3.5 MB
- Total: 11.6 MB

### 💡 Optimization Opportunities
1. 使用 Selector 減少 rebuild (-15% CPU)
2. 設定圖片快取限制 (-20 MB RAM)
3. 延遲載入設定頁面 (-0.3s 啟動)
```
