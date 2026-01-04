---
name: deps
description: 依賴管理 - 檢查更新、安全漏洞、授權合規
args: [--update] [--security] [--licenses]
---

# /deps - 依賴管理

管理專案依賴，確保安全和最新。

## 用法

```
/deps                 # 顯示依賴狀態
/deps --update        # 更新依賴
/deps --security      # 安全掃描
/deps --licenses      # 授權檢查
```

## 功能

### 1. 依賴狀態
```bash
flutter pub outdated
```

顯示：
- 當前版本 vs 最新版本
- Breaking changes 警告
- 相容性問題

### 2. 依賴更新 (--update)
```bash
flutter pub upgrade --major-versions
```

流程：
1. 顯示可更新項目
2. 確認更新範圍
3. 執行更新
4. 執行測試驗證
5. 若失敗，回滾並報告

### 3. 安全掃描 (--security)
- 檢查已知漏洞
- 檢查過時的依賴
- 檢查不安全的設定

### 4. 授權檢查 (--licenses)
```bash
flutter pub deps --json
```

檢查：
- GPL 授權 (可能不相容商用)
- 未知授權
- 需要歸屬的授權

### 5. 依賴樹分析
- 識別重複依賴
- 識別可移除的間接依賴
- 依賴大小分析

## 輸出格式

```
## Dependencies Report

### 📦 Outdated (5)
| Package | Current | Latest | Breaking |
|---------|---------|--------|----------|
| provider | 6.0.5 | 6.1.0 | No |
| dio | 5.3.0 | 5.4.0 | No |
| sqflite | 2.3.0 | 2.4.0 | Yes |

### 🔒 Security
✅ No known vulnerabilities

### 📜 Licenses
- MIT: 45 packages
- BSD: 12 packages
- Apache 2.0: 8 packages
⚠️ Unknown: flutter_image_compress

### 💾 Size Impact
Total dependencies: 65
Estimated APK impact: ~8.2 MB
```
