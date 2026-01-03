import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 動畫工具類
///
/// 提供統一的動畫時長、曲線和觸覺回饋
class AnimationUtils {
  AnimationUtils._();

  // ===== 動畫時長 =====

  /// 快速動畫 (150ms) - 用於小型元素
  static const Duration fast = Duration(milliseconds: 150);

  /// 標準動畫 (250ms) - 預設動畫
  static const Duration standard = Duration(milliseconds: 250);

  /// 頁面轉場 (300ms)
  static const Duration pageTransition = Duration(milliseconds: 300);

  /// 緩慢動畫 (400ms) - 用於複雜動畫
  static const Duration slow = Duration(milliseconds: 400);

  /// 列表 stagger 延遲
  static const Duration staggerDelay = Duration(milliseconds: 50);

  // ===== 動畫曲線 =====

  /// 標準進入曲線
  static const Curve standardIn = Curves.easeOut;

  /// 標準退出曲線
  static const Curve standardOut = Curves.easeIn;

  /// 標準進出曲線
  static const Curve standardInOut = Curves.easeInOut;

  /// 彈性曲線 - 用於按鈕等
  static const Curve bouncy = Curves.elasticOut;

  /// 強調曲線 - 用於重要動畫
  static const Curve emphasized = Curves.easeOutCubic;

  // ===== 觸覺回饋 =====

  /// 儲存成功 - 輕觸感
  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  /// 刪除確認 - 中等觸感
  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  /// 錯誤發生 - 重觸感
  static Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }

  /// 選擇項目 - 點擊感
  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }

  /// 震動
  static Future<void> vibrate() async {
    await HapticFeedback.vibrate();
  }

  // ===== 工具方法 =====

  /// 計算 stagger 動畫延遲
  static Duration staggerOffset(int index, {int maxItems = 10}) {
    final clampedIndex = index.clamp(0, maxItems);
    return staggerDelay * clampedIndex;
  }

  /// 檢查是否應減少動畫（無障礙設定）
  static bool shouldReduceMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }
}

/// Hero 標籤生成器
class HeroTags {
  HeroTags._();

  /// 收據圖片 Hero 標籤
  static String receiptImage(int expenseId) => 'receipt_$expenseId';

  /// 支出卡片 Hero 標籤
  static String expenseCard(int expenseId) => 'expense_card_$expenseId';
}
