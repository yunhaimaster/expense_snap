---
name: verify
description: 快速驗證程式碼品質 - analyze + test + type check
---

# /verify - Flutter 程式碼驗證

執行完整驗證流程，確保程式碼品質。

## 步驟

1. **靜態分析**
   ```bash
   flutter analyze
   ```
   - 檢查 lint errors 和 warnings
   - 若有 error 必須修復

2. **型別檢查**
   ```bash
   dart analyze --fatal-infos
   ```

3. **執行測試**
   ```bash
   flutter test
   ```
   - 所有測試必須通過
   - 回報失敗測試詳情

4. **結果摘要**
   - 報告 errors / warnings 數量
   - 報告測試通過/失敗數
   - 若全部通過顯示 ✅

## 失敗處理

若任一步驟失敗：
1. 詳細列出問題
2. 提供修復建議
3. 詢問是否自動修復
