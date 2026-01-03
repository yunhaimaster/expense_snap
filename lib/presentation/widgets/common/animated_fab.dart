import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/utils/animation_utils.dart';

/// 動畫浮動按鈕
///
/// 支援進場動畫、脈動提示和按壓效果
class AnimatedFab extends StatefulWidget {
  const AnimatedFab({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.tooltip,
    this.showPulse = false,
    this.heroTag,
  });

  /// 點擊回調
  final VoidCallback onPressed;

  /// 圖示
  final IconData icon;

  /// 提示文字
  final String? tooltip;

  /// 是否顯示脈動動畫（用於引導用戶）
  final bool showPulse;

  /// Hero 標籤
  final Object? heroTag;

  @override
  State<AnimatedFab> createState() => _AnimatedFabState();
}

class _AnimatedFabState extends State<AnimatedFab>
    with TickerProviderStateMixin {
  // 進場動畫
  late final AnimationController _entryController;
  late final Animation<double> _scaleAnimation;

  // 脈動動畫
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // 進場延遲計時器（可取消）
  Timer? _entryDelayTimer;

  @override
  void initState() {
    super.initState();

    // 進場動畫
    _entryController = AnimationController(
      duration: AnimationUtils.pageTransition,
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _entryController,
      curve: AnimationUtils.bouncy,
    );

    // 延遲進場（使用可取消的 Timer）
    _entryDelayTimer = Timer(AnimationUtils.standard, () {
      if (mounted) {
        _entryController.forward();
      }
    });

    // 脈動動畫
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.showPulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedFab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.showPulse != oldWidget.showPulse) {
      if (widget.showPulse) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _entryDelayTimer?.cancel();
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 減少動畫模式
    final reduceMotion = AnimationUtils.shouldReduceMotion(context);

    Widget fab = FloatingActionButton(
      heroTag: widget.heroTag,
      onPressed: () {
        // 觸覺回饋
        AnimationUtils.selectionClick();
        widget.onPressed();
      },
      tooltip: widget.tooltip,
      child: Icon(widget.icon),
    );

    // 減少動畫模式時不加動畫
    if (reduceMotion) {
      return fab;
    }

    // 脈動效果
    if (widget.showPulse) {
      fab = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          );
        },
        child: fab,
      );
    }

    // 進場動畫
    return ScaleTransition(
      scale: _scaleAnimation,
      child: fab,
    );
  }
}

/// 可展開的 FAB
///
/// 點擊後展開選項
class ExpandableFab extends StatefulWidget {
  const ExpandableFab({
    super.key,
    required this.actions,
    this.icon = Icons.add,
    this.closeIcon = Icons.close,
  });

  /// 展開後的動作按鈕
  final List<ExpandableFabAction> actions;

  /// 關閉時的圖示
  final IconData icon;

  /// 開啟時的圖示
  final IconData closeIcon;

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationUtils.standard,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
    AnimationUtils.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AnimationUtils.shouldReduceMotion(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 展開的動作按鈕
        ...widget.actions.asMap().entries.map((entry) {
          final index = entry.key;
          final action = entry.value;
          final reverseIndex = widget.actions.length - index - 1;

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final progress = Interval(
                reverseIndex * 0.1,
                0.5 + reverseIndex * 0.1,
                curve: AnimationUtils.emphasized,
              ).transform(_controller.value);

              if (!_isOpen && _controller.value == 0) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Transform.scale(
                  scale: reduceMotion ? (_isOpen ? 1 : 0) : progress,
                  child: Opacity(
                    opacity: reduceMotion ? (_isOpen ? 1 : 0) : progress,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (action.label != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              action.label!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        const SizedBox(width: 12),
                        FloatingActionButton.small(
                          heroTag: null,
                          onPressed: () {
                            _toggle();
                            action.onPressed();
                          },
                          backgroundColor: action.backgroundColor,
                          child: Icon(action.icon),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),

        // 主按鈕
        FloatingActionButton(
          heroTag: null,
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0,
            duration:
                reduceMotion ? Duration.zero : AnimationUtils.standard,
            child: Icon(_isOpen ? widget.closeIcon : widget.icon),
          ),
        ),
      ],
    );
  }
}

/// 可展開 FAB 的動作項目
class ExpandableFabAction {
  const ExpandableFabAction({
    required this.icon,
    required this.onPressed,
    this.label,
    this.backgroundColor,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? label;
  final Color? backgroundColor;
}
