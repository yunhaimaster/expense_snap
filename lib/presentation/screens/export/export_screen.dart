import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/expense.dart';
import '../../../domain/repositories/expense_repository.dart';
import '../../../services/export_service.dart';
import '../../providers/settings_provider.dart';
import '../../providers/showcase_provider.dart';
import '../../widgets/common/loading_overlay.dart';
import 'date_range_selector.dart';
import 'export_preview.dart';

/// 匯出畫面
class ExportScreen extends StatefulWidget {
  const ExportScreen({
    super.key,
    this.refreshTrigger = 0,
    this.isActive = true,
  });

  /// 刷新觸發器：每次值變化時重新載入資料
  final int refreshTrigger;

  /// 是否為當前活躍頁面（用於控制 Showcase 顯示時機）
  final bool isActive;

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

  // Showcase 相關
  final GlobalKey _exportShowcaseKey = GlobalKey();
  BuildContext? _showcaseContext;
  Timer? _showcaseDelayTimer;

  @override
  void initState() {
    super.initState();
    _exportService = ExportService();
    unawaited(_loadPreview());
    unawaited(_loadUserName());
    _checkExportShowcase();
  }

  /// 檢查是否應顯示匯出 Showcase
  void _checkExportShowcase() {
    // 只有在頁面活躍時才顯示 showcase
    if (!widget.isActive) return;

    // 延遲以確保 widget 建構完成（使用 Timer 以便 dispose 時取消）
    _showcaseDelayTimer?.cancel();
    _showcaseDelayTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted || !widget.isActive) return;

      final provider = context.read<ShowcaseProvider>();
      if (!provider.shouldShowExportShowcase) return;

      final ready = await provider.checkExportShowcaseReady();
      if (!ready || !mounted || !widget.isActive) return;

      // 啟動 showcase
      final showcaseContext = _showcaseContext;
      if (showcaseContext != null && showcaseContext.mounted) {
        ShowCaseWidget.of(showcaseContext).startShowCase([_exportShowcaseKey]);
      }
    });
  }

  /// 關閉 Showcase
  void _dismissShowcase() {
    final showcaseContext = _showcaseContext;
    if (showcaseContext != null && showcaseContext.mounted) {
      ShowCaseWidget.of(showcaseContext).dismiss();
    }
  }

  @override
  void didUpdateWidget(ExportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // refreshTrigger 變化時重新載入資料
    if (widget.refreshTrigger != oldWidget.refreshTrigger) {
      unawaited(_loadPreview());
    }

    // 頁面變為活躍時檢查 showcase
    if (widget.isActive && !oldWidget.isActive) {
      _checkExportShowcase();
    }

    // 頁面變為非活躍時關閉 showcase
    if (!widget.isActive && oldWidget.isActive) {
      _dismissShowcase();
    }
  }

  @override
  void dispose() {
    _showcaseDelayTimer?.cancel();
    _showcaseContext = null; // 清除 context 參照避免記憶體洩漏
    super.dispose();
  }

  /// 載入使用者名稱
  Future<void> _loadUserName() async {
    try {
      final name = await sl.databaseHelper.getSetting('user_name');
      if (mounted && name != null && name.isNotEmpty) {
        setState(() => _userName = name);
      }
    } on Object catch (e) {
      // StateError 可能在 sl 未初始化時拋出
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
          _expenses = expensesResult.isSuccess
              ? expensesResult.getOrThrow()
              : [];
          _summary = summaryResult.isSuccess
              ? summaryResult.getOrThrow()
              : null;
          _isLoadingPreview = false;
        });
      }
    } on Exception catch (e) {
      AppLogger.warning(
        'Failed to load export preview',
        error: e,
        tag: 'Export',
      );
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
    final primaryCurrency = context.read<SettingsProvider>().primaryCurrency;

    // 建立本地化字串（在 context 有效時建立）
    final exportStrings = ExportStrings.fromL10n(
      l10n,
      year: year,
      month: month,
      primaryCurrency: primaryCurrency,
    );

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
            _showSuccessSnackBar(
              S.of(context).export_success(exportResult.formattedFileSize),
            );
          }
          // 分享被取消時不顯示訊息
        }
      } else {
        final error = result.errorOrNull;
        _showErrorSnackBar(
          S
              .of(context)
              .export_failed(error?.message ?? S.of(context).error_unknown),
        );
      }
    } on Exception catch (e) {
      AppLogger.error(
        'Export ZIP failed unexpectedly',
        error: e,
        tag: 'Export',
      );
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
    return ShowCaseWidget(
      onComplete: (index, key) {
        if (!mounted) return;
        if (key == _exportShowcaseKey) {
          unawaited(context.read<ShowcaseProvider>().completeExportShowcase());
        }
      },
      builder: (showcaseContext) {
        _showcaseContext = showcaseContext;
        return _buildContent();
      },
    );
  }

  /// 建立畫面內容
  Widget _buildContent() {
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
              DateRangeSelector(
                year: _selectedYear,
                month: _selectedMonth,
                isExporting: _isExporting,
                onChanged: (year, month) {
                  setState(() {
                    _selectedYear = year;
                    _selectedMonth = month;
                  });
                  unawaited(_loadPreview());
                },
              ),

              const SizedBox(height: 24),

              // 匯出預覽
              Expanded(
                child: ExportPreview(
                  isLoading: _isLoadingPreview,
                  expenses: _expenses,
                  summary: _summary,
                  selectedYear: _selectedYear,
                  selectedMonth: _selectedMonth,
                ),
              ),

              const SizedBox(height: 16),

              // 進度指示器
              if (_isExporting) ...[
                LinearProgressIndicator(
                  value: _exportProgress,
                  backgroundColor: AppColors.divider,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
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
              Showcase(
                key: _exportShowcaseKey,
                title: S.of(context).showcase_exportTitle,
                description: S.of(context).showcase_exportDesc,
                child: ElevatedButton.icon(
                  onPressed: _expenses.isEmpty || _isExporting
                      ? null
                      : _exportZip,
                  icon: const Icon(Icons.folder_zip),
                  label: Text(S.of(context).export_excelWithReceipts),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
