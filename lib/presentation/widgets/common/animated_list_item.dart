import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/utils/animation_utils.dart';

/// 動畫列表項目包裝器
///
/// 提供進場、退場動畫效果
class AnimatedListItem extends StatefulWidget {
  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.animateOnMount = true,
    this.slideFrom = SlideDirection.right,
  });

  /// 子組件
  final Widget child;

  /// 項目索引（用於計算 stagger 延遲）
  final int index;

  /// 是否在掛載時執行動畫
  final bool animateOnMount;

  /// 滑入方向
  final SlideDirection slideFrom;

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  // Stagger 延遲計時器（可取消）
  Timer? _staggerDelayTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: AnimationUtils.standard,
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: AnimationUtils.standardIn,
    );

    final beginOffset = switch (widget.slideFrom) {
      SlideDirection.left => const Offset(-0.3, 0),
      SlideDirection.right => const Offset(0.3, 0),
      SlideDirection.top => const Offset(0, -0.3),
      SlideDirection.bottom => const Offset(0, 0.3),
    };

    _slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AnimationUtils.emphasized,
    ));

    if (widget.animateOnMount) {
      // Stagger 延遲（使用可取消的 Timer）
      final delay = AnimationUtils.staggerOffset(widget.index);
      _staggerDelayTimer = Timer(delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _staggerDelayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 減少動畫模式時直接顯示
    if (AnimationUtils.shouldReduceMotion(context)) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// 滑入方向
enum SlideDirection {
  left,
  right,
  top,
  bottom,
}

/// 可動畫的刪除項目包裝器
///
/// 當 [removed] 為 true 時執行退出動畫
class AnimatedRemoveItem extends StatefulWidget {
  const AnimatedRemoveItem({
    super.key,
    required this.child,
    required this.removed,
    this.onAnimationComplete,
  });

  /// 子組件
  final Widget child;

  /// 是否已被刪除
  final bool removed;

  /// 動畫完成回調
  final VoidCallback? onAnimationComplete;

  @override
  State<AnimatedRemoveItem> createState() => _AnimatedRemoveItemState();
}

class _AnimatedRemoveItemState extends State<AnimatedRemoveItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: AnimationUtils.fast,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AnimationUtils.standardOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AnimationUtils.standardOut,
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedRemoveItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.removed && !oldWidget.removed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 減少動畫模式
    if (AnimationUtils.shouldReduceMotion(context)) {
      if (widget.removed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onAnimationComplete?.call();
        });
        return const SizedBox.shrink();
      }
      return widget.child;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizeTransition(
          sizeFactor: ReverseAnimation(_controller),
          axisAlignment: -1,
          child: widget.child,
        ),
      ),
    );
  }
}

/// 列表進場動畫控制器
///
/// 用於控制整個列表的 stagger 動畫
class StaggeredListController extends ChangeNotifier {
  bool _hasAnimated = false;

  /// 是否已執行過進場動畫
  bool get hasAnimated => _hasAnimated;

  /// 標記已執行進場動畫
  void markAnimated() {
    if (!_hasAnimated) {
      _hasAnimated = true;
      notifyListeners();
    }
  }

  /// 重置動畫狀態
  void reset() {
    _hasAnimated = false;
    notifyListeners();
  }
}
