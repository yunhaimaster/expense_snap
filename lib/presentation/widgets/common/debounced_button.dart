import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'loading_overlay.dart';

/// 防止連點的按鈕組件
///
/// 在點擊後會自動禁用，直到異步操作完成
class DebouncedButton extends StatefulWidget {
  const DebouncedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.loadingText,
    this.debounceMs = 300,
  });

  /// 點擊回調（支持異步）
  final Future<void> Function()? onPressed;

  /// 按鈕內容
  final Widget child;

  /// 按鈕樣式
  final ButtonStyle? style;

  /// 載入中顯示的文字（如果為 null，顯示原內容 + 載入指示器）
  final String? loadingText;

  /// 防抖延遲（毫秒）
  final int debounceMs;

  @override
  State<DebouncedButton> createState() => _DebouncedButtonState();
}

class _DebouncedButtonState extends State<DebouncedButton> {
  bool _isLoading = false;
  DateTime? _lastClickTime;

  Future<void> _handlePress() async {
    // 防抖檢查
    final now = DateTime.now();
    if (_lastClickTime != null &&
        now.difference(_lastClickTime!).inMilliseconds < widget.debounceMs) {
      return;
    }
    _lastClickTime = now;

    if (_isLoading || widget.onPressed == null) return;

    setState(() => _isLoading = true);

    try {
      await widget.onPressed!();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handlePress,
      style: widget.style,
      child: _isLoading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LoadingIndicator(size: 16, color: Colors.white),
                if (widget.loadingText != null) ...[
                  const SizedBox(width: 8),
                  Text(widget.loadingText!),
                ],
              ],
            )
          : widget.child,
    );
  }
}

/// 防止連點的文字按鈕
class DebouncedTextButton extends StatefulWidget {
  const DebouncedTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.debounceMs = 300,
  });

  final Future<void> Function()? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final int debounceMs;

  @override
  State<DebouncedTextButton> createState() => _DebouncedTextButtonState();
}

class _DebouncedTextButtonState extends State<DebouncedTextButton> {
  bool _isLoading = false;
  DateTime? _lastClickTime;

  Future<void> _handlePress() async {
    final now = DateTime.now();
    if (_lastClickTime != null &&
        now.difference(_lastClickTime!).inMilliseconds < widget.debounceMs) {
      return;
    }
    _lastClickTime = now;

    if (_isLoading || widget.onPressed == null) return;

    setState(() => _isLoading = true);

    try {
      await widget.onPressed!();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: _isLoading ? null : _handlePress,
      style: widget.style,
      child: _isLoading
          ? const LoadingIndicator(size: 16)
          : widget.child,
    );
  }
}

/// 防止連點的圖標按鈕
class DebouncedIconButton extends StatefulWidget {
  const DebouncedIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.color,
    this.debounceMs = 300,
  });

  final Future<void> Function()? onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? color;
  final int debounceMs;

  @override
  State<DebouncedIconButton> createState() => _DebouncedIconButtonState();
}

class _DebouncedIconButtonState extends State<DebouncedIconButton> {
  bool _isLoading = false;
  DateTime? _lastClickTime;

  Future<void> _handlePress() async {
    final now = DateTime.now();
    if (_lastClickTime != null &&
        now.difference(_lastClickTime!).inMilliseconds < widget.debounceMs) {
      return;
    }
    _lastClickTime = now;

    if (_isLoading || widget.onPressed == null) return;

    setState(() => _isLoading = true);

    try {
      await widget.onPressed!();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _isLoading ? null : _handlePress,
      icon: _isLoading
          ? LoadingIndicator(size: 20, color: widget.color ?? AppColors.primary)
          : Icon(widget.icon, color: widget.color),
      tooltip: widget.tooltip,
    );
  }
}

/// 防止連點的 FloatingActionButton
class DebouncedFloatingActionButton extends StatefulWidget {
  const DebouncedFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.tooltip,
    this.heroTag,
    this.debounceMs = 300,
  });

  final Future<void> Function()? onPressed;
  final Widget child;
  final String? tooltip;
  final Object? heroTag;
  final int debounceMs;

  @override
  State<DebouncedFloatingActionButton> createState() =>
      _DebouncedFloatingActionButtonState();
}

class _DebouncedFloatingActionButtonState
    extends State<DebouncedFloatingActionButton> {
  bool _isLoading = false;
  DateTime? _lastClickTime;

  Future<void> _handlePress() async {
    final now = DateTime.now();
    if (_lastClickTime != null &&
        now.difference(_lastClickTime!).inMilliseconds < widget.debounceMs) {
      return;
    }
    _lastClickTime = now;

    if (_isLoading || widget.onPressed == null) return;

    setState(() => _isLoading = true);

    try {
      await widget.onPressed!();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _isLoading ? null : _handlePress,
      tooltip: widget.tooltip,
      heroTag: widget.heroTag,
      child: _isLoading
          ? const LoadingIndicator(size: 24, color: Colors.white)
          : widget.child,
    );
  }
}
