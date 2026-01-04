---
name: release
description: Release 準備 - 版本更新、changelog、build、簽名
args: [version] [--dry-run]
---

# /release - Release 準備流程

執行完整的 release 準備流程。

## 用法

```
/release 1.1.0           # 準備 1.1.0 版本
/release 1.1.0 --dry-run # 預覽不實際執行
```

## 步驟

### 1. 預檢查
- [ ] 確認在 main/master 分支
- [ ] 確認 working tree clean
- [ ] 執行 `/verify` 確保品質

### 2. 版本更新
- [ ] 更新 `pubspec.yaml` version
- [ ] 更新 `android/app/build.gradle.kts` versionCode & versionName
- [ ] 生成 changelog（從上次 tag 到現在的 commits）

### 3. Build 驗證
```bash
flutter clean
flutter pub get
flutter build apk --release
```
- [ ] Build 成功
- [ ] APK 大小合理 (< 50MB)

### 4. 簽名驗證
- [ ] 確認使用 release keystore
- [ ] 驗證簽名正確

### 5. 最終確認
- [ ] 顯示版本資訊
- [ ] 顯示 APK 路徑和大小
- [ ] 顯示 changelog 摘要

## 輸出

```
## Release v1.1.0 準備完成

📦 APK: build/app/outputs/flutter-apk/app-release.apk
📏 Size: 28.5 MB

### Changelog
- feat: 新增 Dark Mode 支援
- fix: 修復匯出時的記憶體問題
- perf: 優化列表滾動效能

### Next Steps
1. 測試 APK 在實機運行
2. git tag v1.1.0
3. 上傳至 Play Store
```
