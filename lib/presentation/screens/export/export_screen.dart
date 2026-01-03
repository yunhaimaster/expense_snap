import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/expense.dart';
import '../../../domain/repositories/expense_repository.dart';
import '../../../services/export_service.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/forms/date_picker_field.dart';

/// 匯出畫面
class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

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

  /// 載入使用者名稱
  Future<void> _loadUserName() async {
    try {
      final name = await sl.databaseHelper.getSetting('user_name');
      if (mounted && name != null && name.isNotEmpty) {
        setState(() => _userName = name);
      }
    } catch (e) {
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
      if (mounted) {
        setState(() {
          _expenses = [];
          _summary = null;
          _isLoadingPreview = false;
        });
      }
    }
  }

  /// 匯出 Excel
  Future<void> _exportExcel() async {
    if (_expenses.isEmpty || _isExporting) return;

    // 快照當前資料，避免匯出中途資料變更
    final expenses = List<Expense>.from(_expenses);
    final year = _selectedYear;
    final month = _selectedMonth;
    final userName = _userName;

    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
      _exportMessage = '正在生成 Excel...';
    });

    try {
      final result = await _exportService.exportToExcel(
        expenses: expenses,
        year: year,
        month: month,
        userName: userName,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        final exportResult = result.getOrThrow();
        setState(() {
          _exportProgress = 1.0;
          _exportMessage = '準備分享...';
        });

        // 分享檔案
        final shareResult = await _exportService.shareFile(exportResult.filePath);

        if (mounted) {
          if (shareResult.isSuccess) {
            _showSuccessSnackBar('Excel 匯出成功');
          }
          // 分享被取消時不顯示訊息
        }
      } else {
        final error = result.errorOrNull;
        _showErrorSnackBar('匯出失敗: ${error?.message ?? '未知錯誤'}');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('匯出失敗: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  /// 匯出 ZIP（含收據）
  Future<void> _exportZip() async {
    if (_expenses.isEmpty || _isExporting) return;

    // 快照當前資料，避免匯出中途資料變更
    final expenses = List<Expense>.from(_expenses);
    final year = _selectedYear;
    final month = _selectedMonth;
    final userName = _userName;

    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
      _exportMessage = '正在打包...';
    });

    try {
      final result = await _exportService.exportToZip(
        expenses: expenses,
        year: year,
        month: month,
        userName: userName,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _exportProgress = progress;
              if (progress < 0.3) {
                _exportMessage = '正在生成 Excel...';
              } else if (progress < 0.9) {
                _exportMessage = '正在打包收據圖片...';
              } else {
                _exportMessage = '正在壓縮...';
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
          _exportMessage = '準備分享...';
        });

        // 分享檔案
        final shareResult = await _exportService.shareFile(exportResult.filePath);

        if (mounted) {
          if (shareResult.isSuccess) {
            _showSuccessSnackBar('匯出成功 (${exportResult.formattedFileSize})');
          }
          // 分享被取消時不顯示訊息
        }
      } else {
        final error = result.errorOrNull;
        _showErrorSnackBar('匯出失敗: ${error?.message ?? '未知錯誤'}');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('匯出失敗: $e');
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
          title: const Text('匯出報銷單'),
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

              // 匯出按鈕
              ElevatedButton.icon(
                onPressed: _expenses.isEmpty || _isExporting ? null : _exportExcel,
                icon: const Icon(Icons.table_chart),
                label: const Text('匯出 Excel'),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: _expenses.isEmpty || _isExporting ? null : _exportZip,
                icon: const Icon(Icons.folder_zip),
                label: const Text('匯出 Excel + 收據'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 建立預覽卡片
  Widget _buildPreviewCard() {
    if (_isLoadingPreview) {
      return const Card(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_expenses.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: EmptyState(
            icon: Icons.description_outlined,
            title: '沒有資料',
            subtitle: '$_selectedYear 年 $_selectedMonth 月沒有支出記錄',
          ),
        ),
      );
    }

    final receiptCount = _expenses.where((e) => e.hasReceipt).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
              '$_selectedYear 年 $_selectedMonth 月',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 16),

            // 統計資料
            _buildStatRow(
              icon: Icons.receipt_long,
              label: '支出筆數',
              value: '${_summary?.totalCount ?? _expenses.length} 筆',
            ),

            const SizedBox(height: 8),

            _buildStatRow(
              icon: Icons.attach_money,
              label: '港幣總額',
              value: _summary?.formattedTotalAmount ?? 'HKD 0.00',
              valueColor: AppColors.primary,
            ),

            const SizedBox(height: 8),

            _buildStatRow(
              icon: Icons.photo,
              label: '收據圖片',
              value: '$receiptCount 張',
            ),

            const Spacer(),

            // 提示文字
            Text(
              '匯出的 Excel 包含完整支出明細',
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
