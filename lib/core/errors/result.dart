// ignore_for_file: avoid_returning_this
import 'app_exception.dart';

/// 操作結果封裝 - 強制處理成功/失敗兩種情況
///
/// 使用 sealed class 確保類型安全，避免 nullable data 的問題
sealed class Result<T> {
  const Result._();

  /// 成功結果
  factory Result.success(T data) => Success<T>(data);

  /// 失敗結果
  factory Result.failure(AppException error) => Failure<T>(error);

  /// 是否成功
  bool get isSuccess => this is Success<T>;

  /// 是否失敗
  bool get isFailure => this is Failure<T>;

  /// 折疊處理 - 強制處理成功和失敗兩種情況
  ///
  /// ```dart
  /// final result = await repository.getExpenses();
  /// final message = result.fold(
  ///   onFailure: (error) => '載入失敗: ${error.message}',
  ///   onSuccess: (expenses) => '共 ${expenses.length} 筆',
  /// );
  /// ```
  R fold<R>({
    required R Function(AppException error) onFailure,
    required R Function(T data) onSuccess,
  }) {
    return switch (this) {
      Success<T>(:final data) => onSuccess(data),
      Failure<T>(:final error) => onFailure(error),
    };
  }

  /// 安全取得資料，失敗時回傳 null
  T? getOrNull() => switch (this) {
        Success<T>(:final data) => data,
        Failure<T>() => null,
      };

  /// 安全取得錯誤，成功時回傳 null
  AppException? get errorOrNull => switch (this) {
        Success<T>() => null,
        Failure<T>(:final error) => error,
      };

  /// 取得資料，失敗時回傳預設值
  T getOrElse(T defaultValue) => switch (this) {
        Success<T>(:final data) => data,
        Failure<T>() => defaultValue,
      };

  /// 取得資料，失敗時拋出異常
  ///
  /// 僅在確定結果為成功時使用
  T getOrThrow() => switch (this) {
        Success<T>(:final data) => data,
        Failure<T>(:final error) => throw error,
      };

  /// 轉換成功結果的資料類型
  Result<R> map<R>(R Function(T data) transform) => switch (this) {
        Success<T>(:final data) => Result.success(transform(data)),
        Failure<T>(:final error) => Result.failure(error),
      };

  /// 鏈式操作 - 成功時執行另一個可能失敗的操作
  Future<Result<R>> flatMap<R>(
    Future<Result<R>> Function(T data) transform,
  ) async =>
      switch (this) {
        Success<T>(:final data) => await transform(data),
        Failure<T>(:final error) => Result.failure(error),
      };

  /// 成功時執行副作用操作
  Result<T> onSuccess(void Function(T data) action) {
    if (this case Success<T>(:final data)) {
      action(data);
    }
    return this;
  }

  /// 失敗時執行副作用操作
  Result<T> onFailure(void Function(AppException error) action) {
    if (this case Failure<T>(:final error)) {
      action(error);
    }
    return this;
  }
}

/// 成功結果
final class Success<T> extends Result<T> {
  const Success(this.data) : super._();

  final T data;

  @override
  String toString() => 'Result.success($data)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Success<T> && other.data == data;
  }

  @override
  int get hashCode => data.hashCode;
}

/// 失敗結果
final class Failure<T> extends Result<T> {
  const Failure(this.error) : super._();

  final AppException error;

  @override
  String toString() => 'Result.failure($error)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure<T> && other.error == error;
  }

  @override
  int get hashCode => error.hashCode;
}

/// Result 相關擴展方法
extension ResultExtensions<T> on Future<Result<T>> {
  /// 等待並折疊處理
  Future<R> foldAsync<R>({
    required R Function(AppException error) onFailure,
    required R Function(T data) onSuccess,
  }) async {
    final result = await this;
    return result.fold(onFailure: onFailure, onSuccess: onSuccess);
  }

  /// 等待並安全取得資料
  Future<T?> getOrNullAsync() async {
    final result = await this;
    return result.getOrNull();
  }

  /// 等待並取得資料，失敗時回傳預設值
  Future<T> getOrElseAsync(T defaultValue) async {
    final result = await this;
    return result.getOrElse(defaultValue);
  }
}
