---
name: review
description: Flutter 程式碼審查 - 架構、效能、安全、無障礙
args: [path|--staged|--branch]
---

# /review - Flutter Code Review

針對 Flutter/Dart 程式碼進行全面審查。

## 用法

```
/review                        # 審查 staged changes
/review lib/screens/home.dart  # 審查指定檔案
/review --branch feature/x     # 審查整個分支
```

## 審查面向

### 1. 架構 (Architecture)
- [ ] 遵循 Clean Architecture 分層
- [ ] Provider 正確使用（避免 setState 在複雜狀態）
- [ ] Repository pattern 正確實作
- [ ] 依賴注入正確配置

### 2. Dart/Flutter 最佳實踐
- [ ] 使用 const constructors
- [ ] 正確使用 final vs var
- [ ] Widget 拆分合理（單一職責）
- [ ] 避免 BuildContext 跨 async gap
- [ ] 正確處理 dispose()

### 3. 效能 (Performance)
- [ ] 避免不必要的 rebuild
- [ ] 使用 Selector 替代 Consumer（大型 state）
- [ ] 圖片正確快取和壓縮
- [ ] ListView.builder 用於長列表
- [ ] 使用 RepaintBoundary 優化繪製

### 4. 安全 (Security)
- [ ] 敏感資料使用 secure_storage
- [ ] 無硬編碼 API keys
- [ ] 路徑驗證防 traversal 攻擊
- [ ] 輸入驗證完整

### 5. 無障礙 (Accessibility)
- [ ] Semantics 標籤完整
- [ ] 觸控目標 >= 48x48
- [ ] 顏色對比符合 WCAG AA
- [ ] 支援大字體模式

### 6. 錯誤處理
- [ ] 使用 Result<T> pattern
- [ ] 適當的 try-catch
- [ ] 用戶友善錯誤訊息
- [ ] 網路錯誤正確處理

## 輸出格式

```
## Code Review Summary

### 🔴 Critical (必須修復)
- security/path-traversal: backup_repository.dart:45

### 🟡 Warning (建議修復)
- performance/unnecessary-rebuild: expense_card.dart:23

### 🔵 Info (可選優化)
- style/const-constructor: app_colors.dart:12

### ✅ Good Practices Found
- 正確使用 Result pattern
- 完整的 Semantics 標籤
```
