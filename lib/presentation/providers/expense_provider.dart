import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/currency_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/result.dart';
import '../../core/utils/app_logger.dart';
import '../../data/models/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../services/image_service.dart';

/// 支出管理 Provider
///
/// 負責：
/// - 月份導航
/// - 支出列表載入與分頁
/// - 支出 CRUD 操作狀態管理
/// - 摘要計算
class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider({
    required IExpenseRepository repository,
    required ImageService imageService,
  })  : _repository = repository,
        _imageService = imageService {
    _initCurrentMonth();
  }

  final IExpenseRepository _repository;
  final ImageService _imageService;

  // 狀態
  List<Expense> _expenses = [];
  MonthSummary _summary = MonthSummary.empty(DateTime.now().year, DateTime.now().month);
  bool _isLoading = false;
  bool _hasMore = true;
  AppException? _error;
  int _currentYear = DateTime.now().year;
  int _currentMonth = DateTime.now().month;
  int _currentOffset = 0;

  // Getters
  List<Expense> get expenses => List.unmodifiable(_expenses);
  MonthSummary get summary => _summary;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  AppException? get error => _error;
  int get currentYear => _currentYear;
  int get currentMonth => _currentMonth;

  /// 當前月份顯示文字
  String get currentMonthDisplay {
    return '$_currentYear 年 $_currentMonth 月';
  }

  /// 是否為當前月份
  bool get isCurrentMonth {
    final now = DateTime.now();
    return _currentYear == now.year && _currentMonth == now.month;
  }

  /// 初始化當前月份
  void _initCurrentMonth() {
    final now = DateTime.now();
    _currentYear = now.year;
    _currentMonth = now.month;
  }

  /// 載入月份資料
  Future<void> loadMonth({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _currentOffset = 0;
      _hasMore = true;
      _expenses = [];
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 並行載入列表和摘要
      final results = await Future.wait([
        _repository.getExpensesByMonth(
          year: _currentYear,
          month: _currentMonth,
          limit: AppConstants.defaultPageSize,
          offset: _currentOffset,
        ),
        _repository.getMonthSummary(
          year: _currentYear,
          month: _currentMonth,
        ),
      ]);

      final expensesResult = results[0] as Result<List<Expense>>;
      final summaryResult = results[1] as Result<MonthSummary>;

      // 處理支出列表
      expensesResult.fold(
        onFailure: (e) => _error = e,
        onSuccess: (list) {
          if (refresh) {
            _expenses = list;
          } else {
            _expenses = [..._expenses, ...list];
          }
          _currentOffset = _expenses.length;
          _hasMore = list.length >= AppConstants.defaultPageSize;
        },
      );

      // 處理摘要
      summaryResult.fold(
        onFailure: (e) => _error ??= e,
        onSuccess: (s) => _summary = s,
      );
    } catch (e) {
      AppLogger.error('loadMonth failed', error: e);
      _error = DatabaseException.queryFailed(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 載入更多
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;
    await loadMonth();
  }

  /// 刷新資料
  Future<void> refresh() async {
    await loadMonth(refresh: true);
  }

  /// 前往上個月
  void previousMonth() {
    if (_currentMonth == 1) {
      _currentYear--;
      _currentMonth = 12;
    } else {
      _currentMonth--;
    }
    loadMonth(refresh: true);
  }

  /// 前往下個月
  void nextMonth() {
    // 不能超過當前月份
    final now = DateTime.now();
    if (_currentYear == now.year && _currentMonth >= now.month) {
      return;
    }

    if (_currentMonth == 12) {
      _currentYear++;
      _currentMonth = 1;
    } else {
      _currentMonth++;
    }
    loadMonth(refresh: true);
  }

  /// 跳轉至指定月份
  void goToMonth(int year, int month) {
    _currentYear = year;
    _currentMonth = month;
    loadMonth(refresh: true);
  }

  /// 新增支出
  Future<Result<Expense>> addExpense({
    required DateTime date,
    required int originalAmountCents,
    required String originalCurrency,
    required int exchangeRate,
    required ExchangeRateSource exchangeRateSource,
    required int hkdAmountCents,
    required String description,
    String? imagePath,
  }) async {
    final now = DateTime.now();
    final expense = Expense(
      date: date,
      originalAmountCents: originalAmountCents,
      originalCurrency: originalCurrency,
      exchangeRate: exchangeRate,
      exchangeRateSource: exchangeRateSource,
      hkdAmountCents: hkdAmountCents,
      description: description,
      createdAt: now,
      updatedAt: now,
    );

    final result = await _repository.addExpense(
      expense: expense,
      imagePath: imagePath,
    );

    result.onSuccess((_) {
      // 如果是當前月份，刷新列表
      if (date.year == _currentYear && date.month == _currentMonth) {
        refresh();
      }
    });

    return result;
  }

  /// 更新支出
  Future<Result<Expense>> updateExpense(Expense expense) async {
    final result = await _repository.updateExpense(expense);

    result.onSuccess((_) {
      // 更新本地列表
      final index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index >= 0) {
        _expenses[index] = expense;
        notifyListeners();
      }
      // 刷新摘要
      _refreshSummary();
    });

    return result;
  }

  /// 軟刪除支出
  Future<Result<void>> softDeleteExpense(int id) async {
    final result = await _repository.softDeleteExpense(id);

    result.onSuccess((_) {
      // 從列表移除
      _expenses.removeWhere((e) => e.id == id);
      notifyListeners();
      // 刷新摘要
      _refreshSummary();
    });

    return result;
  }

  /// 還原支出
  Future<Result<void>> restoreExpense(int id) async {
    final result = await _repository.restoreExpense(id);
    // 刷新會在 DeletedItemsScreen 處理
    return result;
  }

  /// 永久刪除支出
  Future<Result<void>> permanentlyDeleteExpense(int id) async {
    return _repository.permanentlyDeleteExpense(id);
  }

  /// 替換收據圖片
  Future<Result<Expense>> replaceReceiptImage({
    required int expenseId,
    required String newImagePath,
  }) async {
    final result = await _repository.replaceReceiptImage(
      expenseId: expenseId,
      newImagePath: newImagePath,
    );

    result.onSuccess((updated) {
      // 更新本地列表
      final index = _expenses.indexWhere((e) => e.id == expenseId);
      if (index >= 0) {
        _expenses[index] = updated;
        notifyListeners();
      }
    });

    return result;
  }

  /// 從相機拍照
  Future<Result<String>> pickImageFromCamera() async {
    return _imageService.pickFromCamera();
  }

  /// 從相簿選擇
  Future<Result<String>> pickImageFromGallery() async {
    return _imageService.pickFromGallery();
  }

  /// 刷新摘要
  Future<void> _refreshSummary() async {
    final result = await _repository.getMonthSummary(
      year: _currentYear,
      month: _currentMonth,
    );
    result.onSuccess((s) {
      _summary = s;
      notifyListeners();
    });
  }

  /// 清除錯誤
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
