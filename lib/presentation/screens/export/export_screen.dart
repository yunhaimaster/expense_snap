import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/expense.dart';
import '../../../domain/repositories/expense_repository.dart';
import '../../../services/export_service.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/skeleton.dart';
import '../../widgets/forms/date_picker_field.dart';

/// 匯出畫面
class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key, this.refreshTrigger = 0});

  /// 刷新觸發器：每次值變化時重新載入資料
  final int refreshTrigger;

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  List<Expense> _expenses = [];
  MonthSummary? _summary;
  bool _isLoadingPreview = false;
  bool _isExporting = false;
  double _exportProgress = 0.0;
  String _exportMessage = '';

  late final ExportService _exportService;
  String _userName = AppConstants.defaultUserName;

  @override
  void initState() {
    super.initState();
    _exportService = ExportService();
    _loadPreview();
    _loadUserName();
  }

  @override
  void didUpdateWidget(ExportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // refreshTrigger 變化時重新載入資料
    if (widget.refreshTrigger != oldWidget.refreshTrigger) {
      _loadPreview();
    }
  }

  /// 載入使用者名稱
  Future<void> _loadUserName() async {
    try {
      final name = await sl.databaseHelper.getSetting('user_name');
      if (mounted && name != null && name.isNotEmpty) {
        setState(() => _userName = name);
      }
    } catch (e) {
      AppLogger.warning('Failed to load user name for export', error: e);
      // 使用預設名稱
    }
  }

  /// 載入預覽資料
  Future<void> _loadPreview() async {
    // 提早取得 repository 參照，避免 async 間隙後存取 context
    final repository = context.read<IExpenseRepository>();
    final year = _selectedYear;
    final month = _selectedMonth;

    setState(() => _isLoadingPreview = true);

    try {
      // 取得該月份所有支出（使用較大 limit 以支援大量資料）
      final expensesResult = await repository.getExpensesByMonth(
        year: year,
        month: month,
        limit: 10000,
      );

      final summaryResult = await repository.getMonthSummary(
        year: year,
        month: month,
      );

      if (mounted) {
        setState(() {
          _expenses = expensesResult.isSuccess ? expensesResult.getOrThrow() : [];
          _summary = summaryResult.isSuccess ? summaryResult.getOrThrow() : null;
          _isLoadingPreview = false;
        });
      }
    } catch (e) {
      AppLogger.warning('Failed to load export preview', error: e, tag: 'Export');
      if (mounted) {
        setState(() {
          _expenses = [];
          _summary = null;
          _isLoadingPreview = false;
        });
      }
    }
  }

  /// 匯出 ZIP（含 Excel + 收據）
  Future<void> _exportZip() async {
    if (_expenses.isEmpty || _isExporting) return;

    // 快照當前資料，避免匯出中途資料變更
    final expenses = List<Expense>.from(_expenses);
    final year = _selectedYear;
    final month = _selectedMonth;
    final userName = _userName;
    final l10n = S.of(context);

    // 建立本地化字串（在 context 有效時建立）
    final exportStrings = ExportStrings.fromL10n(l10n, year: year, month: month);

    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
      _exportMessage = l10n.export_packing;
    });

    try {
      final result = await _exportService.exportToZip(
        expenses: expenses,
        year: year,
        month: month,
        userName: userName,
        strings: exportStrings,
        onProgress: (progress) {
          if (mounted) {
            final l10n = S.of(context);
            setState(() {
              _exportProgress = progress;
              if (progress < 0.3) {
                _exportMessage = l10n.export_generatingExcel;
              } else if (progress < 0.9) {
                _exportMessage = l10n.export_packingReceipts;
              } else {
                _exportMessage = l10n.export_compressing;
              }
            });
          }
        },
      );

      if (!mounted) return;

      if (result.isSuccess) {
        final exportResult = result.getOrThrow();
        setState(() {
          _exportProgress = 1.0;
          _exportMessage = S.of(context).export_preparingShare;
        });

        // 分享檔案
        final shareResult = await _exportService.shareFile(
          exportResult.filePath,
          shareSubject: exportStrings.shareSubject,
        );

        if (mounted) {
          if (shareResult.isSuccess) {
            _showSuccessSnackBar(S.of(context).export_success(exportResult.formattedFileSize));
          }
          // 分享被取消時不顯示訊息
        }
      } else {
        final error = result.errorOrNull;
        _showErrorSnackBar(S.of(context).export_failed(error?.message ?? S.of(context).error_unknown));
      }
    } catch (e) {
      AppLogger.error('Export ZIP failed unexpectedly', error: e, tag: 'Export');
      if (mounted) {
        _showErrorSnackBar(S.of(context).export_failed('$e'));
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isExporting,
      message: _exportMessage,
      child: Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).export_title),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 月份選擇（匯出中禁用）
              IgnorePointer(
                ignoring: _isExporting,
                child: Opacity(
                  opacity: _isExporting ? 0.5 : 1.0,
                  child: MonthPickerField(
                    year: _selectedYear,
                    month: _selectedMonth,
                    onChanged: (year, month) {
                      setState(() {
                        _selectedYear = year;
                        _selectedMonth = month;
                      });
                      _loadPreview();
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 匯出預覽
              Expanded(
                child: _buildPreviewCard(),
              ),

              const SizedBox(height: 16),

              // 進度指示器
              if (_isExporting) ...[
                LinearProgressIndicator(
                  value: _exportProgress,
                  backgroundColor: AppColors.divider,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_exportProgress * 100).toInt()}%',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 16),
              ],

              // 匯出按鈕（Excel + 收據）
              ElevatedButton.icon(
                onPressed: _expenses.isEmpty || _isExporting ? null : _exportZip,
                icon: const Icon(Icons.folder_zip),
                label: Text(S.of(context).export_excelWithReceipts),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 建立預覽卡片
  Widget _buildPreviewCard() {
    // 載入中 - 使用 shimmer 骨架屏
    if (_isLoadingPreview) {
      return const ExportPreviewSkeleton();
    }

    if (_expenses.isEmpty) {
      final l10n = S.of(context);
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: EmptyState(
            illustrationAsset: 'assets/illustrations/empty_expenses.svg',
            title: l10n.export_noData,
            subtitle: l10n.export_noDataMessage(_selectedYear, _selectedMonth),
            animate: false,
          ),
        ),
      );
    }

    final receiptCount = _expenses.where((e) => e.hasReceipt).length;
    final l10n = S.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 圖示
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.description,
                size: 40,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 24),

            // 月份
            Text(
              l10n.export_yearMonth(_selectedYear, _selectedMonth),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 16),

            // 統計資料
            _buildStatRow(
              icon: Icons.receipt_long,
              label: l10n.export_expenseCount,
              value: l10n.export_countUnit(_summary?.totalCount ?? _expenses.length),
            ),

            const SizedBox(height: 8),

            _buildStatRow(
              icon: Icons.attach_money,
              label: l10n.export_totalHkd,
              value: _summary?.formattedTotalAmount ?? 'HKD 0.00',
              valueColor: AppColors.primary,
            ),

            const SizedBox(height: 8),

            _buildStatRow(
              icon: Icons.photo,
              label: l10n.export_receiptCount,
              value: l10n.export_imageUnit(receiptCount),
            ),

            const SizedBox(height: 24),

            // 提示文字
            Text(
              l10n.export_hint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// 建立統計列
  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
        ),
      ],
    );
  }
}
