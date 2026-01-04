---
name: test
description: 執行測試套件，可選覆蓋率報告
args: [path] [--coverage] [--watch]
---

# /test - Flutter 測試執行

執行指定或全部測試，支援覆蓋率分析。

## 用法

```
/test                     # 執行全部測試
/test path/to/test.dart   # 執行指定測試
/test --coverage          # 含覆蓋率報告
/test --watch             # 監聽模式
```

## 步驟

1. **解析參數**
   - 若有 path，只執行該測試
   - 若有 --coverage，加入覆蓋率收集

2. **執行測試**
   ```bash
   flutter test [path] [--coverage]
   ```

3. **覆蓋率分析** (若 --coverage)
   ```bash
   # 生成 HTML 報告
   genhtml coverage/lcov.info -o coverage/html
   ```
   - 報告整體覆蓋率百分比
   - 列出覆蓋率 < 80% 的檔案

4. **失敗測試處理**
   - 顯示失敗原因
   - 顯示相關程式碼片段
   - 提供修復建議

## 輸出格式

```
✅ 188/188 tests passed
📊 Coverage: 82.5%

低覆蓋率檔案：
- lib/services/backup_service.dart: 45%
- lib/presentation/screens/settings.dart: 67%
```
