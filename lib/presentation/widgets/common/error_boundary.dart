import 'package:flutter/material.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/error_messages.dart';

/// 全局錯誤邊界組件
///
/// 捕獲子組件的錯誤，顯示友善的錯誤畫面
class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({
    super.key,
    required this.child,
    this.onError,
  });

  /// 子組件
  final Widget child;

  /// 錯誤回調（可選）
  final void Function(Object error, StackTrace stackTrace)? onError;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    // 設置 Flutter 錯誤處理
    FlutterError.onError = _handleFlutterError;
  }

  void _handleFlutterError(FlutterErrorDetails details) {
    AppLogger.error(
      'Flutter error caught by ErrorBoundary',
      error: details.exception,
      stackTrace: details.stack,
    );

    widget.onError?.call(details.exception, details.stack ?? StackTrace.current);

    if (mounted) {
      setState(() {
        _hasError = true;
        _error = details.exception;
      });
    }
  }

  void _resetError() {
    setState(() {
      _hasError = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return ErrorFallbackScreen(
        error: _error,
        onRetry: _resetError,
      );
    }

    return widget.child;
  }
}

/// 錯誤回退畫面
///
/// 當發生嚴重錯誤時顯示的畫面
class ErrorFallbackScreen extends StatelessWidget {
  const ErrorFallbackScreen({
    super.key,
    this.error,
    required this.onRetry,
  });

  /// 錯誤對象
  final Object? error;

  /// 重試回調
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final errorCode = error is AppException ? (error as AppException).code : null;
    final message = ErrorMessages.getMessage(
      errorCode,
      fallbackMessage: '應用程式發生錯誤',
    );
    final suggestedAction = ErrorMessages.getSuggestedAction(errorCode);
    final isRetryable = ErrorMessages.isRetryable(errorCode);

    return Material(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 錯誤圖示
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.errorLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
              ),

              const SizedBox(height: 24),

              // 錯誤標題
              Text(
                '發生問題了',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 12),

              // 錯誤訊息
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),

              // 建議動作
              if (suggestedAction != null) ...[
                const SizedBox(height: 8),
                Text(
                  suggestedAction,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
              ],

              const SizedBox(height: 32),

              // 重試按鈕
              if (isRetryable)
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重試'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                )
              else
                OutlinedButton(
                  onPressed: onRetry,
                  child: const Text('返回'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 錯誤橫幅組件
///
/// 用於在畫面頂部顯示可忽略的錯誤訊息
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    super.key,
    required this.error,
    this.onDismiss,
    this.onRetry,
  });

  /// 錯誤對象
  final AppException error;

  /// 關閉回調
  final VoidCallback? onDismiss;

  /// 重試回調
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isRetryable = ErrorMessages.isRetryable(error.code);
    final message = ErrorMessages.getMessage(
      error.code,
      fallbackMessage: error.message,
    );

    return Material(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppColors.errorLight,
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
              ),
            ),
            if (isRetryable && onRetry != null)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('重試'),
              ),
            if (onDismiss != null)
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 顯示錯誤 SnackBar 的工具方法
void showErrorSnackBar(
  BuildContext context, {
  required AppException error,
  VoidCallback? onRetry,
}) {
  final message = ErrorMessages.getMessage(
    error.code,
    fallbackMessage: error.message,
  );
  final isRetryable = ErrorMessages.isRetryable(error.code);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.error,
      action: isRetryable && onRetry != null
          ? SnackBarAction(
              label: '重試',
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
    ),
  );
}

/// 顯示成功 SnackBar 的工具方法
void showSuccessSnackBar(
  BuildContext context, {
  required String message,
  SnackBarAction? action,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.success,
      action: action,
    ),
  );
}
