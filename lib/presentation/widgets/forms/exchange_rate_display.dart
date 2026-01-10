import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/currency_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/exchange_rate_repository.dart';
import '../../providers/exchange_rate_provider.dart';

/// 匯率顯示與控制元件
///
/// 顯示當前匯率、來源指示器、重新整理按鈕
/// 支援長按強制刷新（繞過冷卻時間）
class ExchangeRateDisplay extends StatefulWidget {
  const ExchangeRateDisplay({
    super.key,
    required this.currency,
    required this.onRateChanged,
    this.enabled = true,
  });

  /// 要顯示的幣種
  final String currency;

  /// 匯率變更回調
  final void Function(int rateToHkd, ExchangeRateSource source) onRateChanged;

  /// 是否啟用
  final bool enabled;

  @override
  State<ExchangeRateDisplay> createState() => _ExchangeRateDisplayState();
}

class _ExchangeRateDisplayState extends State<ExchangeRateDisplay> {
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
    // 延遲到 build 完成後再載入匯率，避免在 build 過程中觸發 notifyListeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadRate();
      }
    });
  }

  @override
  void didUpdateWidget(ExchangeRateDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currency != widget.currency) {
      // 使用 postFrameCallback 避免在 build 過程中觸發 notifyListeners
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadRate();
        }
      });
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRate() async {
    final provider = context.read<ExchangeRateProvider>();
    final info = await provider.loadRate(widget.currency);

    if (info != null && mounted) {
      widget.onRateChanged(info.rateToHkd, info.source);
    }
  }

  Future<void> _refreshRate({bool forceRefresh = false}) async {
    final provider = context.read<ExchangeRateProvider>();

    if (!forceRefresh && !provider.canRefresh) {
      _startCooldownTimer(provider.secondsUntilRefresh);
      return;
    }

    final success = await provider.refreshRates(forceRefresh: forceRefresh);

    if (success && mounted) {
      final info = provider.getRate(widget.currency);
      if (info != null) {
        widget.onRateChanged(info.rateToHkd, info.source);
      }
      // 強制刷新成功時顯示提示
      if (forceRefresh) {
        _showForceRefreshSuccess();
      }
    } else if (!forceRefresh && !provider.canRefresh) {
      _startCooldownTimer(provider.secondsUntilRefresh);
    }
  }

  void _showForceRefreshSuccess() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('匯率已強制更新'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _startCooldownTimer(int seconds) {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = seconds);

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // 檢查 widget 是否仍然掛載，避免 setState 在已銷毀的 widget 上調用
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds > 0) {
        setState(() => _cooldownSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExchangeRateProvider>(
      builder: (context, provider, child) {
        final info = provider.getRate(widget.currency);

        if (info == null && provider.isLoading) {
          return _buildLoadingState();
        }

        return _buildRateDisplay(info, provider);
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('正在取得匯率...'),
        ],
      ),
    );
  }

  Widget _buildRateDisplay(
      ExchangeRateInfo? info, ExchangeRateProvider provider) {
    final rate = info?.formattedRate ?? '--';
    final source = info?.source ?? ExchangeRateSource.defaultRate;
    final fetchedAt = info?.formattedFetchedAt;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getSourceColor(source).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 匯率與重新整理按鈕
          Row(
            children: [
              // 匯率來源指示器
              _SourceIndicator(source: source),
              const SizedBox(width: 8),

              // 匯率文字
              Expanded(
                child: Text(
                  '1 ${widget.currency} = $rate HKD',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),

              // 重新整理按鈕
              if (widget.enabled) _buildRefreshButton(provider),
            ],
          ),

          // 更新時間
          if (fetchedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              '更新於 $fetchedAt',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRefreshButton(ExchangeRateProvider provider) {
    final isOnCooldown = _cooldownSeconds > 0;
    final isLoading = provider.isLoading;

    return Tooltip(
      message: isOnCooldown ? '長按可強制刷新' : '點擊刷新匯率',
      child: GestureDetector(
        onTap: isLoading ? null : _refreshRate,
        onLongPress: isLoading ? null : () => _refreshRate(forceRefresh: true),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh,
                      size: 20,
                      color: isOnCooldown
                          ? AppColors.textTertiary
                          : AppColors.primary,
                    ),
                    if (isOnCooldown) ...[
                      const SizedBox(width: 4),
                      Text(
                        '${_cooldownSeconds}s',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Color _getSourceColor(ExchangeRateSource source) {
    switch (source) {
      case ExchangeRateSource.auto:
        return AppColors.success;
      case ExchangeRateSource.offline:
        return AppColors.warning;
      case ExchangeRateSource.defaultRate:
        return AppColors.error;
      case ExchangeRateSource.manual:
        return AppColors.info;
    }
  }
}

/// 匯率來源指示器
class _SourceIndicator extends StatelessWidget {
  const _SourceIndicator({required this.source});

  final ExchangeRateSource source;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: source.label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _getColor().withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIcon(),
              size: 14,
              color: _getColor(),
            ),
            const SizedBox(width: 4),
            Text(
              _getLabel(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _getColor(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (source) {
      case ExchangeRateSource.auto:
        return Icons.check_circle;
      case ExchangeRateSource.offline:
        return Icons.cloud_off;
      case ExchangeRateSource.defaultRate:
        return Icons.warning;
      case ExchangeRateSource.manual:
        return Icons.edit;
    }
  }

  String _getLabel() {
    switch (source) {
      case ExchangeRateSource.auto:
        return '即時';
      case ExchangeRateSource.offline:
        return '離線';
      case ExchangeRateSource.defaultRate:
        return '預設';
      case ExchangeRateSource.manual:
        return '手動';
    }
  }

  Color _getColor() {
    switch (source) {
      case ExchangeRateSource.auto:
        return AppColors.success;
      case ExchangeRateSource.offline:
        return AppColors.warning;
      case ExchangeRateSource.defaultRate:
        return AppColors.error;
      case ExchangeRateSource.manual:
        return AppColors.info;
    }
  }
}
