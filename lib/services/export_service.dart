import 'dart:io';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants/currency_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/errors/result.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/formatters.dart';
import '../data/models/expense.dart';

/// 匯出服務
///
/// 負責：
/// - 生成 Excel 報銷單
/// - 打包收據圖片為 ZIP
/// - 分享匯出檔案
/// - 清理暫存檔案
class ExportService {
  ExportService();

  /// 暫存目錄路徑
  Future<Directory> get _tempDir async {
    final dir = await getTemporaryDirectory();
    final exportDir = Directory('${dir.path}/export');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }

  /// 匯出 Excel 報銷單
  ///
  /// [expenses] 要匯出的支出清單
  /// [year] 年份
  /// [month] 月份
  /// [userName] 使用者名稱（用於檔名）
  ///
  /// 回傳匯出的檔案路徑
  Future<Result<ExportResult>> exportToExcel({
    required List<Expense> expenses,
    required int year,
    required int month,
    required String userName,
  }) async {
    try {
      // 參數驗證
      if (month < 1 || month > 12) {
        return Result.failure(
          const ValidationException('月份必須介於 1 到 12 之間', code: 'INVALID_MONTH'),
        );
      }
      if (year < 2000 || year > 2100) {
        return Result.failure(
          const ValidationException('年份必須介於 2000 到 2100 之間', code: 'INVALID_YEAR'),
        );
      }
      if (expenses.isEmpty) {
        return Result.failure(ExportException.noData());
      }

      final excel = Excel.createExcel();
      final sheetName = '$year年$month月報銷單';

      // 建立新 sheet
      final sheet = excel[sheetName];
      // 設為預設 sheet 並刪除預設的 Sheet1
      excel.setDefaultSheet(sheetName);
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // 設定標題列
      _setHeaderRow(sheet);

      // 填入資料
      int totalHkdCents = 0;
      for (int i = 0; i < expenses.length; i++) {
        final expense = expenses[i];
        final rowIndex = i + 1;

        // 生成收據檔名（如果有收據）
        String? receiptFileName;
        if (expense.hasReceipt && expense.receiptImagePath != null) {
          receiptFileName = _generateReceiptFileName(expense, rowIndex, expense.receiptImagePath!);
        }

        _setDataRow(sheet, rowIndex, expense, receiptFileName: receiptFileName);
        totalHkdCents += expense.hkdAmountCents;
      }

      // 設定合計列
      _setTotalRow(sheet, expenses.length + 1, totalHkdCents);

      // 儲存檔案
      final tempDir = await _tempDir;
      final fileName = _generateFileName(
        userName: userName,
        year: year,
        month: month,
        extension: 'xlsx',
      );
      final filePath = '${tempDir.path}/$fileName';

      final fileBytes = excel.encode();
      if (fileBytes == null) {
        return Result.failure(
          ExportException.excelGenerationFailed('無法編碼 Excel 檔案'),
        );
      }

      await File(filePath).writeAsBytes(fileBytes);

      final fileSize = await File(filePath).length();
      AppLogger.info('Excel exported: $filePath (${Formatters.formatFileSize(fileSize)})');

      return Result.success(ExportResult(
        filePath: filePath,
        fileName: fileName,
        fileSize: fileSize,
        expenseCount: expenses.length,
        totalHkdCents: totalHkdCents,
      ));
    } catch (e) {
      AppLogger.error('exportToExcel failed', error: e);
      return Result.failure(
        ExportException.excelGenerationFailed(e.toString()),
      );
    }
  }

  /// 匯出 Excel + 收據 ZIP
  ///
  /// [expenses] 要匯出的支出清單
  /// [year] 年份
  /// [month] 月份
  /// [userName] 使用者名稱（用於檔名）
  /// [onProgress] 進度回調（0.0 ~ 1.0）
  ///
  /// 回傳匯出的檔案路徑
  Future<Result<ExportResult>> exportToZip({
    required List<Expense> expenses,
    required int year,
    required int month,
    required String userName,
    void Function(double progress)? onProgress,
  }) async {
    try {
      // 參數驗證（與 exportToExcel 相同）
      if (month < 1 || month > 12) {
        return Result.failure(
          const ValidationException('月份必須介於 1 到 12 之間', code: 'INVALID_MONTH'),
        );
      }
      if (year < 2000 || year > 2100) {
        return Result.failure(
          const ValidationException('年份必須介於 2000 到 2100 之間', code: 'INVALID_YEAR'),
        );
      }
      if (expenses.isEmpty) {
        return Result.failure(ExportException.noData());
      }

      final archive = Archive();
      onProgress?.call(0.1);

      // 1. 生成 Excel 並加入 ZIP
      final excelResult = await exportToExcel(
        expenses: expenses,
        year: year,
        month: month,
        userName: userName,
      );

      if (excelResult.isFailure) {
        return excelResult;
      }

      final excelInfo = excelResult.getOrThrow();
      final excelBytes = await File(excelInfo.filePath).readAsBytes();
      archive.addFile(ArchiveFile(
        excelInfo.fileName,
        excelBytes.length,
        excelBytes,
      ));
      onProgress?.call(0.3);

      // 2. 加入收據圖片（使用 Excel 行號作為檔名序號，方便配對）
      final receiptCount = expenses.where((e) => e.hasReceipt).length;
      int processedReceipts = 0;
      for (int i = 0; i < expenses.length; i++) {
        final expense = expenses[i];
        if (!expense.hasReceipt) continue;

        final imagePath = expense.receiptImagePath;
        final excelRowIndex = i + 1; // Excel 行號（1-based，與表格序號一致）

        if (imagePath != null && imagePath.isNotEmpty) {
          final imageFile = File(imagePath);
          if (await imageFile.exists()) {
            final imageBytes = await imageFile.readAsBytes();
            final imageName = _generateReceiptFileName(expense, excelRowIndex, imagePath);

            archive.addFile(ArchiveFile(
              'receipts/$imageName',
              imageBytes.length,
              imageBytes,
            ));
          }
        }

        processedReceipts++;
        // 更新進度（0.3 ~ 0.9）
        final progress = 0.3 + (0.6 * processedReceipts / receiptCount);
        onProgress?.call(progress);
      }

      // 3. 壓縮並儲存 ZIP
      final zipEncoder = ZipEncoder();
      final zipBytes = zipEncoder.encode(archive);
      if (zipBytes == null) {
        return Result.failure(ExportException.zipFailed('無法編碼 ZIP 檔案'));
      }

      final tempDir = await _tempDir;
      final fileName = _generateFileName(
        userName: userName,
        year: year,
        month: month,
        extension: 'zip',
      );
      final filePath = '${tempDir.path}/$fileName';

      await File(filePath).writeAsBytes(zipBytes);
      onProgress?.call(1.0);

      final fileSize = await File(filePath).length();
      AppLogger.info('ZIP exported: $filePath (${Formatters.formatFileSize(fileSize)})');

      // 清理暫時的 Excel 檔案（失敗時僅記錄，不影響 ZIP 匯出結果）
      try {
        await File(excelInfo.filePath).delete();
      } catch (e) {
        AppLogger.warning('Failed to cleanup temp Excel file: $e');
      }

      return Result.success(ExportResult(
        filePath: filePath,
        fileName: fileName,
        fileSize: fileSize,
        expenseCount: expenses.length,
        totalHkdCents: excelInfo.totalHkdCents,
        receiptCount: receiptCount,
      ));
    } catch (e) {
      AppLogger.error('exportToZip failed', error: e);
      return Result.failure(ExportException.zipFailed(e.toString()));
    }
  }

  /// 分享檔案
  Future<Result<void>> shareFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return Result.failure(StorageException.fileNotFound(filePath));
      }

      final result = await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Expense Snap 報銷單',
      );

      if (result.status == ShareResultStatus.dismissed) {
        AppLogger.info('Share dismissed by user');
      } else {
        AppLogger.info('File shared successfully');
      }

      return Result.success(null);
    } catch (e) {
      AppLogger.error('shareFile failed', error: e);
      return Result.failure(ExportException.shareFailed());
    }
  }

  /// 清理暫存檔案
  Future<Result<int>> cleanupTempFiles() async {
    try {
      final tempDir = await _tempDir;
      if (!await tempDir.exists()) {
        return Result.success(0);
      }

      int deletedCount = 0;
      final files = await tempDir.list().toList();
      for (final entity in files) {
        if (entity is File) {
          await entity.delete();
          deletedCount++;
        }
      }

      AppLogger.info('Cleaned up $deletedCount temp files');
      return Result.success(deletedCount);
    } catch (e) {
      AppLogger.error('cleanupTempFiles failed', error: e);
      return Result.failure(StorageException('清理暫存檔案失敗: $e'));
    }
  }

  // ============ 私有方法 ============

  /// 設定標題列
  void _setHeaderRow(Sheet sheet) {
    final headers = [
      '序號',
      '日期',
      '描述',
      '原始金額',
      '原始幣種',
      '匯率',
      '匯率來源',
      '港幣金額',
      '收據檔名',
    ];

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        backgroundColorHex: ExcelColor.fromHexString('#E0E0E0'),
      );
    }
  }

  /// 設定資料列
  void _setDataRow(Sheet sheet, int rowIndex, Expense expense, {String? receiptFileName}) {
    // 序號
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
      .value = IntCellValue(rowIndex);

    // 日期
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
      .value = TextCellValue(Formatters.formatDate(expense.date));

    // 描述
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
      .value = TextCellValue(expense.description);

    // 原始金額
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
      .value = DoubleCellValue(expense.originalAmount);

    // 原始幣種
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
      .value = TextCellValue(expense.originalCurrency);

    // 匯率
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
      .value = TextCellValue(expense.formattedExchangeRate);

    // 匯率來源
    final rateSourceText = _getRateSourceText(expense.exchangeRateSource);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
      .value = TextCellValue(rateSourceText);

    // 港幣金額
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
      .value = DoubleCellValue(expense.hkdAmount);

    // 收據檔名（有收據則顯示檔名，無則顯示「-」）
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
      .value = TextCellValue(receiptFileName ?? '-');
  }

  /// 設定合計列
  void _setTotalRow(Sheet sheet, int rowIndex, int totalHkdCents) {
    // 合計標籤
    final labelCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex),
    );
    labelCell.value = TextCellValue('合計');
    labelCell.cellStyle = CellStyle(bold: true);

    // 合計金額
    final totalCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex),
    );
    totalCell.value = DoubleCellValue(Formatters.centsToAmount(totalHkdCents));
    totalCell.cellStyle = CellStyle(bold: true);
  }

  /// 取得匯率來源文字
  String _getRateSourceText(ExchangeRateSource source) {
    switch (source) {
      case ExchangeRateSource.auto:
        return '自動';
      case ExchangeRateSource.offline:
        return '離線快取';
      case ExchangeRateSource.defaultRate:
        return '預設';
      case ExchangeRateSource.manual:
        return '手動';
    }
  }

  /// 生成檔案名稱
  String _generateFileName({
    required String userName,
    required int year,
    required int month,
    required String extension,
  }) {
    final monthStr = month.toString().padLeft(2, '0');
    // 加入時間戳避免檔名碰撞（同月多次匯出時會覆蓋）
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '報銷單_$year年$monthStr月_$timestamp.$extension';
  }

  /// 生成收據圖片檔名
  ///
  /// [expense] 支出記錄
  /// [index] 序號
  /// [originalPath] 原始圖片路徑（用於取得副檔名）
  String _generateReceiptFileName(Expense expense, int index, String originalPath) {
    final dateStr = Formatters.formatDate(expense.date);
    final indexStr = index.toString().padLeft(3, '0');

    // 截取描述前 20 字元作為檔名一部分
    final desc = expense.description.length > 20
        ? expense.description.substring(0, 20)
        : expense.description;

    // 移除不適合檔名的字元（包含 Unicode 控制字元）
    // 只保留字母、數字、中文、底線、連字號
    final safeDesc = desc
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s_-]', unicode: true), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();

    // 若描述全為特殊字元，使用預設值
    final finalDesc = safeDesc.isEmpty ? 'receipt' : safeDesc;

    // 保留原始副檔名，預設為 jpg
    final extension = originalPath.contains('.')
        ? originalPath.split('.').last.toLowerCase()
        : 'jpg';

    // 限制副檔名長度，避免惡意檔名
    final safeExtension = extension.length <= 4 ? extension : 'jpg';

    return '${indexStr}_${dateStr}_$finalDesc.$safeExtension';
  }
}

/// 匯出結果
class ExportResult {
  const ExportResult({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.expenseCount,
    required this.totalHkdCents,
    this.receiptCount,
  });

  /// 檔案路徑
  final String filePath;

  /// 檔案名稱
  final String fileName;

  /// 檔案大小（bytes）
  final int fileSize;

  /// 支出筆數
  final int expenseCount;

  /// 港幣總金額（分）
  final int totalHkdCents;

  /// 收據數量（僅 ZIP 匯出時有值）
  final int? receiptCount;

  /// 格式化的檔案大小
  String get formattedFileSize => Formatters.formatFileSize(fileSize);

  /// 格式化的港幣總金額
  String get formattedTotalAmount => Formatters.formatAmount(totalHkdCents, 'HKD');
}
