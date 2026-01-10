import 'dart:collection';

import '../constants/app_constants.dart';

/// 麵包屑類型
enum BreadcrumbType {
  /// 使用者操作
  userAction,

  /// 導航
  navigation,

  /// 網絡請求
  network,

  /// 錯誤
  error,

  /// 系統事件
  system,
}

/// 麵包屑條目
///
/// 記錄使用者操作和系統事件，用於除錯和錯誤追蹤
class Breadcrumb {
  const Breadcrumb({
    required this.type,
    required this.message,
    required this.timestamp,
    this.category,
    this.data,
  });

  /// 類型
  final BreadcrumbType type;

  /// 訊息
  final String message;

  /// 時間戳記
  final DateTime timestamp;

  /// 分類（如：按鈕、表單、頁面等）
  final String? category;

  /// 額外資料
  final Map<String, dynamic>? data;

  /// 建立使用者操作麵包屑
  factory Breadcrumb.userAction(
    String message, {
    String? category,
    Map<String, dynamic>? data,
  }) {
    return Breadcrumb(
      type: BreadcrumbType.userAction,
      message: message,
      timestamp: DateTime.now(),
      category: category,
      data: data,
    );
  }

  /// 建立導航麵包屑
  factory Breadcrumb.navigation(
    String route, {
    Map<String, dynamic>? params,
  }) {
    return Breadcrumb(
      type: BreadcrumbType.navigation,
      message: 'Navigate to $route',
      timestamp: DateTime.now(),
      category: 'navigation',
      data: params,
    );
  }

  /// 建立網絡請求麵包屑
  factory Breadcrumb.network(
    String method,
    String url, {
    int? statusCode,
    bool? success,
  }) {
    return Breadcrumb(
      type: BreadcrumbType.network,
      message: '$method $url',
      timestamp: DateTime.now(),
      category: 'network',
      data: {
        if (statusCode != null) 'statusCode': statusCode,
        if (success != null) 'success': success,
      },
    );
  }

  /// 建立錯誤麵包屑
  factory Breadcrumb.error(
    String message, {
    String? errorType,
  }) {
    return Breadcrumb(
      type: BreadcrumbType.error,
      message: message,
      timestamp: DateTime.now(),
      category: errorType,
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      if (category != null) 'category': category,
      if (data != null && data!.isNotEmpty) 'data': data,
    };
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('[${timestamp.toIso8601String()}] ');
    buffer.write('[${type.name}] ');
    if (category != null) {
      buffer.write('($category) ');
    }
    buffer.write(message);
    return buffer.toString();
  }
}

/// 麵包屑服務
///
/// 追蹤使用者操作和系統事件，用於除錯和錯誤報告
class BreadcrumbService {
  BreadcrumbService._();

  static final BreadcrumbService instance = BreadcrumbService._();

  /// 最大保留的麵包屑數量（使用集中管理的常數）
  static const int maxBreadcrumbs = AppConstants.maxBreadcrumbs;

  /// 麵包屑佇列（固定大小）
  final Queue<Breadcrumb> _breadcrumbs = Queue<Breadcrumb>();

  /// 取得所有麵包屑（唯讀）
  List<Breadcrumb> get breadcrumbs => List.unmodifiable(_breadcrumbs.toList());

  /// 取得麵包屑數量
  int get count => _breadcrumbs.length;

  /// 新增麵包屑
  void add(Breadcrumb breadcrumb) {
    // 如果已達上限，移除最舊的
    while (_breadcrumbs.length >= maxBreadcrumbs) {
      _breadcrumbs.removeFirst();
    }
    _breadcrumbs.addLast(breadcrumb);
  }

  /// 記錄使用者操作
  void addUserAction(
    String message, {
    String? category,
    Map<String, dynamic>? data,
  }) {
    add(Breadcrumb.userAction(message, category: category, data: data));
  }

  /// 記錄導航
  void addNavigation(String route, {Map<String, dynamic>? params}) {
    add(Breadcrumb.navigation(route, params: params));
  }

  /// 記錄網絡請求
  void addNetwork(
    String method,
    String url, {
    int? statusCode,
    bool? success,
  }) {
    add(Breadcrumb.network(
      method,
      url,
      statusCode: statusCode,
      success: success,
    ));
  }

  /// 記錄錯誤
  void addError(String message, {String? errorType}) {
    add(Breadcrumb.error(message, errorType: errorType));
  }

  /// 清除所有麵包屑
  void clear() {
    _breadcrumbs.clear();
  }

  /// 取得格式化的麵包屑報告
  String getReport() {
    if (_breadcrumbs.isEmpty) {
      return 'No breadcrumbs recorded.';
    }

    final buffer = StringBuffer();
    buffer.writeln('=== Breadcrumb Trail (${_breadcrumbs.length} entries) ===');
    for (final crumb in _breadcrumbs) {
      buffer.writeln(crumb.toString());
    }
    buffer.writeln('=== End of Breadcrumbs ===');
    return buffer.toString();
  }

  /// 取得 JSON 格式的麵包屑列表
  List<Map<String, dynamic>> toJsonList() {
    return _breadcrumbs.map((b) => b.toJson()).toList();
  }
}

/// 全域訪問點
BreadcrumbService get breadcrumbs => BreadcrumbService.instance;
