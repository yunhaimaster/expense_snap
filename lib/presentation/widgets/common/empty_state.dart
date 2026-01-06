import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';

/// 空狀態組件
///
/// 用於顯示列表為空時的友善提示
/// 支援 SVG 插圖和進場動畫
class EmptyState extends StatefulWidget {
  const EmptyState({
    super.key,
    this.icon,
    this.illustrationAsset,
    required this.title,
    this.subtitle,
    this.action,
    this.actionLabel,
    this.onAction,
    this.animate = true,
  }) : assert(
          icon != null || illustrationAsset != null,
          '必須提供 icon 或 illustrationAsset',
        );

  /// 圖標（與 illustrationAsset 二選一）
  final IconData? icon;

  /// SVG 插圖資源路徑（與 icon 二選一，優先使用）
  final String? illustrationAsset;

  /// 標題
  final String title;

  /// 副標題（可選）
  final String? subtitle;

  /// 操作按鈕文字（可選）
  final String? actionLabel;

  /// 操作按鈕（可選，優先於 actionLabel）
  final Widget? action;

  /// 操作回調（可選）
  final VoidCallback? onAction;

  /// 是否播放進場動畫
  final bool animate;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  bool _animationStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 首次執行時啟動動畫（若適用）
    if (!_animationStarted) {
      _animationStarted = true;
      _startAnimationIfNeeded();
    }
  }

  /// 根據設定決定是否啟動動畫
  void _startAnimationIfNeeded() {
    // 尊重系統「減少動態效果」設定
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    if (widget.animate && !disableAnimations) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(EmptyState oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 處理 animate 屬性變更
    if (widget.animate != oldWidget.animate) {
      final disableAnimations = MediaQuery.of(context).disableAnimations;
      if (widget.animate && !disableAnimations) {
        _controller.forward(from: 0);
      } else {
        _controller.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 插圖或圖標
                _buildVisual(),
                const SizedBox(height: 24),

                // 標題
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),

                // 副標題
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],

                // 操作按鈕
                if (widget.action != null || widget.actionLabel != null) ...[
                  const SizedBox(height: 24),
                  widget.action ??
                      ElevatedButton(
                        onPressed: widget.onAction,
                        child: Text(widget.actionLabel!),
                      ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 建立視覺元素（插圖優先，否則使用圖標）
  Widget _buildVisual() {
    if (widget.illustrationAsset != null) {
      // 使用 Semantics 標記為裝飾性插圖，避免螢幕閱讀器讀取
      return Semantics(
        excludeSemantics: true,
        child: SvgPicture.asset(
          widget.illustrationAsset!,
          width: 160,
          height: 160,
          // SVG 載入失敗時顯示備用圖標
          placeholderBuilder: (context) => _buildIconFallback(),
        ),
      );
    }

    return _buildIconFallback();
  }

  /// 建立圖標備用顯示（用於 icon 模式或 SVG 載入失敗時）
  Widget _buildIconFallback() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        widget.icon ?? Icons.image_not_supported_outlined,
        size: 40,
        color: AppColors.primary,
      ),
    );
  }
}

/// 預設空狀態工廠
class EmptyStates {
  EmptyStates._();

  /// 無支出記錄
  static EmptyState noExpenses({VoidCallback? onAddExpense}) {
    return EmptyState(
      illustrationAsset: 'assets/illustrations/empty_expenses.svg',
      title: '暫無支出記錄',
      subtitle: '點擊右下角按鈕新增第一筆支出',
      actionLabel: onAddExpense != null ? '新增支出' : null,
      onAction: onAddExpense,
    );
  }

  /// 無已刪除項目
  static EmptyState noDeletedItems() {
    return const EmptyState(
      illustrationAsset: 'assets/illustrations/empty_trash.svg',
      title: '沒有已刪除的項目',
      subtitle: '刪除的支出會在這裡保留 30 天',
      animate: false,
    );
  }

  /// 載入失敗
  static EmptyState error({required String message, VoidCallback? onRetry}) {
    return EmptyState(
      illustrationAsset: 'assets/illustrations/error_state.svg',
      title: '載入失敗',
      subtitle: message,
      actionLabel: onRetry != null ? '重試' : null,
      onAction: onRetry,
    );
  }

  /// 離線模式
  static EmptyState offline({String? message}) {
    return EmptyState(
      illustrationAsset: 'assets/illustrations/offline_mode.svg',
      title: '無網路連線',
      subtitle: message ?? '請檢查您的網路設定',
    );
  }

  /// 匯出成功
  static EmptyState exportSuccess({VoidCallback? onShare}) {
    return EmptyState(
      illustrationAsset: 'assets/illustrations/success_export.svg',
      title: '匯出成功',
      subtitle: '檔案已準備就緒',
      actionLabel: onShare != null ? '分享' : null,
      onAction: onShare,
    );
  }
}
