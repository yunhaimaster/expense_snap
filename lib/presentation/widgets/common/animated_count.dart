import 'package:flutter/material.dart';

import '../../../core/utils/animation_utils.dart';

/// 動畫數字組件
///
/// 當數值變化時以動畫方式過渡
class AnimatedCount extends StatefulWidget {
  const AnimatedCount({
    super.key,
    required this.count,
    this.duration,
    this.curve,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.fractionDigits = 0,
  });

  /// 數值
  final double count;

  /// 動畫時長
  final Duration? duration;

  /// 動畫曲線
  final Curve? curve;

  /// 文字樣式
  final TextStyle? style;

  /// 前綴文字
  final String prefix;

  /// 後綴文字
  final String suffix;

  /// 小數位數
  final int fractionDigits;

  @override
  State<AnimatedCount> createState() => _AnimatedCountState();
}

class _AnimatedCountState extends State<AnimatedCount>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _previousCount = widget.count;
    _controller = AnimationController(
      duration: widget.duration ?? AnimationUtils.standard,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: widget.count,
      end: widget.count,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve ?? AnimationUtils.emphasized,
    ));
  }

  @override
  void didUpdateWidget(AnimatedCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _animation = Tween<double>(
        begin: _previousCount,
        end: widget.count,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: widget.curve ?? AnimationUtils.emphasized,
      ));
      _controller.forward(from: 0);
      _previousCount = widget.count;
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
      return Text(
        _formatNumber(widget.count),
        style: widget.style,
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          _formatNumber(_animation.value),
          style: widget.style,
        );
      },
    );
  }

  String _formatNumber(double value) {
    final formatted = widget.fractionDigits > 0
        ? value.toStringAsFixed(widget.fractionDigits)
        : value.round().toString();
    return '${widget.prefix}$formatted${widget.suffix}';
  }
}

/// 整數動畫組件
class AnimatedIntCount extends StatefulWidget {
  const AnimatedIntCount({
    super.key,
    required this.count,
    this.duration,
    this.curve,
    this.style,
    this.prefix = '',
    this.suffix = '',
  });

  /// 數值
  final int count;

  /// 動畫時長
  final Duration? duration;

  /// 動畫曲線
  final Curve? curve;

  /// 文字樣式
  final TextStyle? style;

  /// 前綴文字
  final String prefix;

  /// 後綴文字
  final String suffix;

  @override
  State<AnimatedIntCount> createState() => _AnimatedIntCountState();
}

class _AnimatedIntCountState extends State<AnimatedIntCount>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;
  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _previousCount = widget.count;
    _controller = AnimationController(
      duration: widget.duration ?? AnimationUtils.standard,
      vsync: this,
    );
    _animation = IntTween(begin: widget.count, end: widget.count).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve ?? AnimationUtils.emphasized,
      ),
    );
  }

  @override
  void didUpdateWidget(AnimatedIntCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _animation = IntTween(
        begin: _previousCount,
        end: widget.count,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: widget.curve ?? AnimationUtils.emphasized,
        ),
      );
      _controller.forward(from: 0);
      _previousCount = widget.count;
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
      return Text(
        '${widget.prefix}${widget.count}${widget.suffix}',
        style: widget.style,
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${widget.prefix}${_animation.value}${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}

/// 金額動畫組件
///
/// 專為金額格式設計，支援千分位和貨幣符號
class AnimatedAmount extends StatefulWidget {
  const AnimatedAmount({
    super.key,
    required this.amount,
    this.duration,
    this.curve,
    this.style,
    this.currencySymbol = '\$',
    this.decimalDigits = 2,
  });

  /// 金額（分）
  final int amount;

  /// 動畫時長
  final Duration? duration;

  /// 動畫曲線
  final Curve? curve;

  /// 文字樣式
  final TextStyle? style;

  /// 貨幣符號
  final String currencySymbol;

  /// 小數位數
  final int decimalDigits;

  @override
  State<AnimatedAmount> createState() => _AnimatedAmountState();
}

class _AnimatedAmountState extends State<AnimatedAmount>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousAmount = 0;

  @override
  void initState() {
    super.initState();
    _previousAmount = widget.amount.toDouble();
    _controller = AnimationController(
      duration: widget.duration ?? AnimationUtils.slow,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: _previousAmount,
      end: _previousAmount,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve ?? AnimationUtils.emphasized,
    ));
  }

  @override
  void didUpdateWidget(AnimatedAmount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount) {
      _animation = Tween<double>(
        begin: _previousAmount,
        end: widget.amount.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: widget.curve ?? AnimationUtils.emphasized,
      ));
      _controller.forward(from: 0);
      _previousAmount = widget.amount.toDouble();
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
      return Text(
        _formatAmount(widget.amount.toDouble()),
        style: widget.style,
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          _formatAmount(_animation.value),
          style: widget.style,
        );
      },
    );
  }

  String _formatAmount(double cents) {
    final amount = cents / 100;
    // 格式化為千分位
    final parts = amount.toStringAsFixed(widget.decimalDigits).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    final formatted =
        widget.decimalDigits > 0 ? '$intPart.${parts[1]}' : intPart;
    return '${widget.currencySymbol}$formatted';
  }
}
