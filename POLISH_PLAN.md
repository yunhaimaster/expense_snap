# expense_snap Polish & Refinement Plan

> 版本: 1.0
> 建立日期: 2026-01-03
> 狀態: 待執行

---

## 概述

本計劃將 expense_snap App 從功能完成提升至發布品質。共分為 **7 個 Phase**，每個 Phase 設計為一個 session 可完成。

### 當前狀態
- Phase 0-6 功能開發完成
- 188 tests passing
- 基本 UI 完成，缺乏動畫與細節打磨

### 目標
- 專業級視覺體驗
- 流暢的微互動
- 完善的無障礙支援
- 全面的測試覆蓋
- 發布就緒的品質

---

## Phase 7: 視覺基礎 - App Icon & Splash Screen ✅

### 目標
建立品牌識別，每次啟動都有專業印象

### 任務清單

- [x] 7.1 設計並生成 App Icon
  - [x] 7.1.1 建立 1024x1024 主圖標設計（收據+相機概念）
  - [x] 7.1.2 使用 flutter_launcher_icons 生成各尺寸
  - [x] 7.1.3 配置 adaptive icon (Android)
  - [x] 7.1.4 驗證不同啟動器顯示效果

- [x] 7.2 實作原生 Splash Screen
  - [x] 7.2.1 加入 flutter_native_splash 依賴
  - [x] 7.2.2 設計 splash 畫面（品牌色 + logo）
  - [x] 7.2.3 配置 flutter_native_splash.yaml
  - [x] 7.2.4 生成原生 splash 資源
  - [x] 7.2.5 測試冷啟動體驗

- [ ] 7.3 優化狀態列（移至 Phase 12）
  - [ ] 7.3.1 AppBar 頁面使用主色狀態列
  - [ ] 7.3.2 全螢幕頁面透明狀態列
  - [ ] 7.3.3 統一 SystemUiOverlayStyle

- [x] 7.4 Play Store 素材
  - [x] 7.4.1 Feature Graphic (1024x500)
  - [x] 7.4.2 香港繁體中文上架描述
  - [x] 7.4.3 建立 store_listing/play_store_hk.md

### 新增依賴
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.3
  flutter_native_splash: ^2.4.4
```

### 設計決策
- **風格**: 簡約現代扁平設計
- **主色**: #2196F3 (Material Blue)
- **圖案**: 白色收據 + 相機快門圈
- **語言**: 香港繁體字/廣東話風格

### 生成檔案
- `assets/icon/icon.png` - 主圖標 1024x1024
- `assets/icon/icon_foreground.png` - Adaptive Icon 前景
- `assets/icon/icon_background.png` - Adaptive Icon 背景
- `assets/icon/splash_logo.png` - Splash Logo 512x512
- `assets/icon/feature_graphic.png` - Play Store 1024x500
- `store_listing/play_store_hk.md` - 上架描述

### 驗收標準
- [x] App icon 在啟動器清晰顯示
- [x] Splash screen 顯示品牌 logo
- [x] 冷啟動無白屏閃爍

---

## Phase 8: 載入狀態 - Skeleton Loading ✅

### 目標
用現代化 shimmer 效果取代傳統 spinner，提升感知效能

### 任務清單

- [x] 8.1 建立 Skeleton 元件庫
  - [x] 8.1.1 加入 shimmer 依賴
  - [x] 8.1.2 建立 `lib/presentation/widgets/common/skeleton.dart`
  - [x] 8.1.3 實作 SkeletonBox（基礎矩形）
  - [x] 8.1.4 實作 SkeletonCircle（圓形）
  - [x] 8.1.5 實作 SkeletonText（文字行）

- [x] 8.2 實作業務 Skeleton
  - [x] 8.2.1 ExpenseCardSkeleton（支出卡片骨架）
  - [x] 8.2.2 MonthSummarySkeleton（月份摘要骨架）
  - [x] 8.2.3 SettingsItemSkeleton（設定項目骨架）
  - [x] 8.2.4 ImageThumbnailSkeleton（縮圖骨架）
  - [x] 8.2.5 ExportPreviewSkeleton（匯出預覽骨架）

- [x] 8.3 替換現有 Loading
  - [x] 8.3.1 HomeScreen 列表載入 (expense_list.dart)
  - [x] 8.3.2 SettingsScreen 載入
  - [x] 8.3.3 ExportScreen 預覽狀態
  - [x] 8.3.4 DeletedItemsScreen 載入

- [x] 8.4 撰寫測試
  - [x] 8.4.1 Skeleton widgets 單元測試 (22 tests)

### 新增依賴
```yaml
dependencies:
  shimmer: ^3.0.0
```

### 驗收標準
- [x] 所有載入狀態使用 shimmer 效果
- [x] Skeleton 形狀符合實際內容
- [x] 動畫流暢無卡頓

---

## Phase 9: 空白狀態 - 插圖與引導 ✅

### 目標
用精美插圖取代純 icon，增加情感連結

### 任務清單

- [x] 9.1 準備 SVG 插圖資源
  - [x] 9.1.1 創建自訂 SVG 插圖（品牌色 #2196F3）
  - [x] 9.1.2 建立 `assets/illustrations/` 目錄
  - [x] 9.1.3 加入 flutter_svg 依賴

- [x] 9.2 升級 EmptyState 元件
  - [x] 9.2.1 支援 SVG 插圖 (illustrationAsset)
  - [x] 9.2.2 加入進場動畫 (FadeIn + SlideUp)
  - [x] 9.2.3 新增 EmptyStates 工廠類別

- [x] 9.3 更新各場景空白狀態
  - [x] 9.3.1 無支出記錄 - empty_expenses.svg
  - [x] 9.3.2 無已刪除項目 - empty_trash.svg
  - [x] 9.3.3 載入失敗 - error_state.svg
  - [x] 9.3.4 無網路連線 - offline_mode.svg
  - [x] 9.3.5 匯出完成 - success_export.svg

- [x] 9.4 Onboarding 插圖
  - [x] 9.4.1 歡迎頁面使用 welcome.svg
  - [x] 9.4.2 18 個新測試通過

### 新增依賴
```yaml
dependencies:
  flutter_svg: ^2.0.17
```

### 資源檔案
```
assets/
  illustrations/
    empty_expenses.svg
    empty_trash.svg
    error_state.svg
    offline_mode.svg
    success_export.svg
    welcome.svg
```

### 驗收標準
- [ ] 所有空白狀態有對應插圖
- [ ] 插圖風格統一
- [ ] 空白狀態有進場動畫

---

## Phase 10: 動畫系統 - 轉場與微互動 ✅

### 目標
加入 Hero 動畫、列表動畫、觸覺回饋，提升操作手感

### 任務清單

- [x] 10.1 Hero 轉場動畫
  - [x] 10.1.1 ExpenseCard 縮圖 → ExpenseDetail 大圖
  - [x] 10.1.2 處理無圖片情況的 fallback
  - [x] 10.1.3 優化動畫曲線 (Curves.easeInOut)

- [x] 10.2 頁面轉場動畫
  - [x] 10.2.1 建立 `lib/core/router/page_transitions.dart`
  - [x] 10.2.2 實作 SlidePageRoute（左右滑動）
  - [x] 10.2.3 實作 FadePageRoute（淡入淡出）
  - [x] 10.2.4 實作 BottomSlidePageRoute（從底部滑入）
  - [x] 10.2.5 實作 ScalePageRoute（縮放）
  - [x] 10.2.6 更新 AppRouter 使用自訂轉場

- [x] 10.3 列表動畫
  - [x] 10.3.1 首次載入 staggered 進場
  - [x] 10.3.2 新增項目 slide-in 動畫
  - [x] 10.3.3 建立 AnimatedListItem 組件
  - [x] 10.3.4 建立 AnimatedRemoveItem 組件

- [x] 10.4 月份切換動畫
  - [x] 10.4.1 MonthSummary 使用 AnimatedSwitcher
  - [x] 10.4.2 左右滑動切換效果
  - [x] 10.4.3 數字變化動畫 (AnimatedIntCount, AnimatedAmount)

- [x] 10.5 按鈕與表單動畫
  - [x] 10.5.1 FAB 進場 scale 動畫
  - [x] 10.5.2 空列表時 FAB 脈動提示
  - [x] 10.5.3 建立 AnimatedFab 組件
  - [x] 10.5.4 建立 ExpandableFab 組件

- [x] 10.6 觸覺回饋
  - [x] 10.6.1 儲存成功 - lightImpact
  - [x] 10.6.2 刪除確認 - mediumImpact
  - [x] 10.6.3 拍照 - selectionClick
  - [x] 10.6.4 錯誤發生 - heavyImpact

- [x] 10.7 撰寫測試
  - [x] 10.7.1 動畫元件測試 (animation_test.dart)
  - [x] 10.7.2 頁面轉場測試 (page_transitions_test.dart)

### 新增檔案
```
lib/core/utils/animation_utils.dart
lib/core/router/page_transitions.dart
lib/presentation/widgets/common/animated_list_item.dart
lib/presentation/widgets/common/animated_count.dart
lib/presentation/widgets/common/animated_fab.dart
test/presentation/widgets/common/animation_test.dart
test/core/router/page_transitions_test.dart
```

### 驗收標準
- [x] 頁面轉場流暢自然
- [x] Hero 動畫正確追蹤元素
- [x] 列表操作有動畫回饋
- [x] 關鍵操作有觸覺回饋

---

## Phase 11: 使用者體驗 - Onboarding 與快捷功能

### 目標
增強新手引導，加入快捷輸入功能

### 任務清單

- [ ] 11.1 增強 Onboarding
  - [ ] 11.1.1 設計 3 步驟 carousel
    - Step 1: 歡迎 + 拍照記錄介紹
    - Step 2: 多幣種轉換介紹
    - Step 3: 一鍵匯出介紹
  - [ ] 11.1.2 實作 PageView + 指示器
  - [ ] 11.1.3 Skip 按鈕 + 完成按鈕
  - [ ] 11.1.4 頁面切換動畫

- [ ] 11.2 功能發現提示
  - [ ] 11.2.1 加入 showcaseview 依賴
  - [ ] 11.2.2 首次使用 FAB 提示
  - [ ] 11.2.3 首筆支出滑動刪除提示
  - [ ] 11.2.4 5 筆支出後匯出功能提示
  - [ ] 11.2.5 提示狀態持久化

- [ ] 11.3 快捷輸入功能
  - [ ] 11.3.1 「今天」「昨天」日期快捷按鈕
  - [ ] 11.3.2 常用描述自動完成（最近 10 筆）
  - [ ] 11.3.3 最近使用幣種優先顯示
  - [ ] 11.3.4 儲存常用描述列表

- [ ] 11.4 智慧提示
  - [ ] 11.4.1 重複支出偵測警告
  - [ ] 11.4.2 大金額確認提示
  - [ ] 11.4.3 月底匯出提醒 (本地通知)

- [ ] 11.5 撰寫測試
  - [ ] 11.5.1 Onboarding flow 測試
  - [ ] 11.5.2 快捷功能測試

### 新增依賴
```yaml
dependencies:
  showcaseview: ^3.0.0
  flutter_local_notifications: ^18.0.1
```

### 驗收標準
- [ ] 新手有完整功能導覽
- [ ] 關鍵功能有發現提示
- [ ] 快捷輸入減少操作步驟

---

## Phase 12: 無障礙與 Dark Mode

### 目標
確保所有用戶都能順暢使用，支援深色模式

### 任務清單

- [ ] 12.1 語意標籤 (Semantics)
  - [ ] 12.1.1 ExpenseCard 完整語意描述
  - [ ] 12.1.2 MonthSummary 語意結構
  - [ ] 12.1.3 表單欄位語意標籤
  - [ ] 12.1.4 按鈕與圖示 tooltip
  - [ ] 12.1.5 裝飾性元素 excludeSemantics

- [ ] 12.2 對比度優化
  - [ ] 12.2.1 檢查 textHint 顏色對比
  - [ ] 12.2.2 檢查 badge 顏色對比
  - [ ] 12.2.3 確保所有文字符合 WCAG AA

- [ ] 12.3 觸控目標
  - [ ] 12.3.1 確保所有可點擊區域 >= 48x48
  - [ ] 12.3.2 增加小按鈕的點擊區域

- [ ] 12.4 動態字體
  - [ ] 12.4.1 測試大字體模式 (1.5x, 2x)
  - [ ] 12.4.2 修復溢出問題
  - [ ] 12.4.3 關鍵文字使用 maxLines + ellipsis

- [ ] 12.5 Dark Mode
  - [ ] 12.5.1 定義深色調色板 (AppColors.dark)
  - [ ] 12.5.2 建立 AppTheme.dark
  - [ ] 12.5.3 加入主題切換開關 (設定頁)
  - [ ] 12.5.4 跟隨系統設定選項
  - [ ] 12.5.5 主題持久化儲存
  - [ ] 12.5.6 測試所有頁面深色顯示

- [ ] 12.6 減少動畫選項
  - [ ] 12.6.1 偵測系統 reduceMotion 設定
  - [ ] 12.6.2 提供 App 內動畫開關
  - [ ] 12.6.3 條件性停用動畫

- [ ] 12.7 撰寫測試
  - [ ] 12.7.1 無障礙測試 (semantics)
  - [ ] 12.7.2 Dark mode 渲染測試

### 驗收標準
- [ ] TalkBack/VoiceOver 可完整操作
- [ ] 所有顏色對比 >= 4.5:1
- [ ] 大字體模式無溢出
- [ ] Dark mode 完整支援

---

## Phase 13: 測試完善與效能優化

### 目標
達到高測試覆蓋率，確保效能穩定

### 任務清單

- [ ] 13.1 Provider 單元測試
  - [ ] 13.1.1 ExpenseProvider 完整測試
  - [ ] 13.1.2 ExchangeRateProvider 測試
  - [ ] 13.1.3 ConnectivityProvider 測試

- [ ] 13.2 Service 單元測試
  - [ ] 13.2.1 ImageService 測試
  - [ ] 13.2.2 BackgroundService 測試
  - [ ] 13.2.3 DatabaseHelper 測試

- [ ] 13.3 Widget 測試
  - [ ] 13.3.1 HomeScreen 測試
  - [ ] 13.3.2 AddExpenseScreen 測試
  - [ ] 13.3.3 ExpenseDetailScreen 測試
  - [ ] 13.3.4 SettingsScreen 測試
  - [ ] 13.3.5 ExportScreen 測試
  - [ ] 13.3.6 所有 common widgets 測試

- [ ] 13.4 整合測試
  - [ ] 13.4.1 新增支出完整流程
  - [ ] 13.4.2 編輯支出流程
  - [ ] 13.4.3 刪除與還原流程
  - [ ] 13.4.4 匯出流程
  - [ ] 13.4.5 備份與還原流程

- [ ] 13.5 效能優化
  - [ ] 13.5.1 使用 Selector 替代 Consumer
  - [ ] 13.5.2 ExpenseCard 加入 RepaintBoundary
  - [ ] 13.5.3 圖片記憶體快取限制
  - [ ] 13.5.4 資料庫索引優化
  - [ ] 13.5.5 DevTools profiling 驗證

- [ ] 13.6 離線佇列（可選）
  - [ ] 13.6.1 待同步操作指示器
  - [ ] 13.6.2 離線操作佇列
  - [ ] 13.6.3 網路恢復自動同步

### 驗收標準
- [ ] 測試覆蓋率 >= 80%
- [ ] 列表滾動 60fps
- [ ] 冷啟動 < 2 秒
- [ ] 無記憶體洩漏

---

## 總覽時程

| Phase | 名稱 | 預估時間 | 狀態 |
|-------|------|----------|------|
| 7 | App Icon & Splash | 1 session | ✅ 完成 |
| 8 | Skeleton Loading | 1 session | ✅ 完成 |
| 9 | 空白狀態插圖 | 1 session | ✅ 完成 |
| 10 | 動畫系統 | 1 session | ✅ 完成 |
| 11 | Onboarding & 快捷功能 | 1 session | ⬜ 待開始 |
| 12 | 無障礙 & Dark Mode | 1 session | ⬜ 待開始 |
| 13 | 測試 & 效能 | 1 session | ⬜ 待開始 |

---

## 新增依賴總覽

```yaml
dependencies:
  shimmer: ^3.0.0
  flutter_svg: ^2.0.17
  showcaseview: ^3.0.0
  flutter_local_notifications: ^18.0.1

dev_dependencies:
  flutter_launcher_icons: ^0.14.3
  flutter_native_splash: ^2.4.5
```

---

## 備註

- 每個 Phase 完成後進行 code review
- 每個 Phase 結束時更新此文件狀態
- 重大決策記錄於對應 Phase 區塊
- 遇阻塞問題優先溝通，避免卡關
