// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class SZh extends S {
  SZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Expense Snap';

  @override
  String get common_save => '儲存';

  @override
  String get common_cancel => '取消';

  @override
  String get common_delete => '刪除';

  @override
  String get common_edit => '編輯';

  @override
  String get common_retry => '重試';

  @override
  String get common_confirm => '確認';

  @override
  String get common_back => '返回';

  @override
  String get common_skip => '跳過';

  @override
  String get common_next => '下一步';

  @override
  String get common_done => '完成';

  @override
  String get common_close => '關閉';

  @override
  String get common_restore => '還原';

  @override
  String get common_clear => '清空';

  @override
  String get common_share => '分享';

  @override
  String get common_loading => '載入中...';

  @override
  String get common_saving => '儲存中...';

  @override
  String get common_processing => '處理中...';

  @override
  String get nav_home => '首頁';

  @override
  String get nav_export => '匯出';

  @override
  String get nav_settings => '設定';

  @override
  String get home_addExpense => '新增支出';

  @override
  String get home_deleteSuccess => '已刪除支出';

  @override
  String home_deleteFailed(String message) {
    return '刪除失敗: $message';
  }

  @override
  String get home_undo => '復原';

  @override
  String get showcase_addExpenseTitle => '新增支出';

  @override
  String get showcase_addExpenseDesc => '點擊這裡拍照記錄你的支出';

  @override
  String get showcase_swipeDeleteTitle => '滑動刪除';

  @override
  String get showcase_swipeDeleteDesc => '向左滑動可以刪除支出記錄';

  @override
  String get addExpense_title => '新增支出';

  @override
  String get addExpense_receiptImage => '收據圖片';

  @override
  String get addExpense_camera => '拍照';

  @override
  String get addExpense_gallery => '相簿';

  @override
  String get addExpense_amount => '金額';

  @override
  String get addExpense_description => '描述';

  @override
  String get addExpense_descriptionHint => '輸入描述...';

  @override
  String get addExpense_date => '日期';

  @override
  String get addExpense_currency => '幣種';

  @override
  String get addExpense_exchangeRate => '匯率';

  @override
  String get addExpense_manualInput => '手動輸入';

  @override
  String get addExpense_ocrProcessing => '正在識別收據...';

  @override
  String get addExpense_ocrSuccess => '已自動識別收據內容';

  @override
  String get addExpense_ocrSuccessVerify => '已自動識別收據內容，請確認是否正確';

  @override
  String get addExpense_success => '支出已新增';

  @override
  String get addExpense_invalidAmount => '請輸入有效金額';

  @override
  String get expenseDetail_title => '支出詳情';

  @override
  String get expenseDetail_editTitle => '編輯支出';

  @override
  String get expenseDetail_amount => '金額';

  @override
  String get expenseDetail_hkdAmount => '港幣金額';

  @override
  String get expenseDetail_exchangeRate => '匯率';

  @override
  String get expenseDetail_description => '描述';

  @override
  String get expenseDetail_descriptionRequired => '請輸入描述';

  @override
  String get expenseDetail_date => '日期';

  @override
  String get expenseDetail_createdAt => '建立時間';

  @override
  String get expenseDetail_replaceImage => '更換圖片';

  @override
  String get expenseDetail_imageLoadFailed => '圖片載入失敗';

  @override
  String get expenseDetail_noReceipt => '無收據圖片';

  @override
  String get expenseDetail_cancelEdit => '取消編輯';

  @override
  String get expenseDetail_saved => '已儲存';

  @override
  String expenseDetail_saveFailed(String message) {
    return '儲存失敗: $message';
  }

  @override
  String get expenseDetail_deleted => '已刪除';

  @override
  String expenseDetail_deleteFailed(String message) {
    return '刪除失敗: $message';
  }

  @override
  String get expenseDetail_confirmDelete => '確認刪除';

  @override
  String get expenseDetail_confirmDeleteMessage =>
      '確定要刪除這筆支出嗎？\n刪除後可在「已刪除項目」中還原。';

  @override
  String get expenseDetail_expenseNotFound => '找不到支出記錄';

  @override
  String get expenseDetail_imageReplaceSuccess => '圖片已更換';

  @override
  String expenseDetail_imageReplaceFailed(String message) {
    return '更換圖片失敗: $message';
  }

  @override
  String get expenseDetail_selectFromGallery => '從相簿選擇';

  @override
  String get rateSource_auto => '即時匯率';

  @override
  String get rateSource_offline => '離線快取';

  @override
  String get rateSource_default => '預設匯率';

  @override
  String get rateSource_manual => '手動輸入';

  @override
  String get rateSource_auto_short => '即時';

  @override
  String get rateSource_offline_short => '離線';

  @override
  String get rateSource_default_short => '預設';

  @override
  String get rateSource_manual_short => '手動';

  @override
  String get monthSummary_totalExpense => '總支出';

  @override
  String get monthSummary_count => '筆數';

  @override
  String get monthSummary_countSuffix => ' 筆';

  @override
  String get monthSummary_previousMonth => '上個月';

  @override
  String get monthSummary_nextMonth => '下個月';

  @override
  String monthSummary_semanticLabel(String month, String amount, int count) {
    return '$month月份摘要。總支出：港幣 $amount 元。共 $count 筆支出。';
  }

  @override
  String get monthSummary_isLatestMonth => '已是最新月份';

  @override
  String get export_title => '匯出報銷單';

  @override
  String get export_preview => '預覽';

  @override
  String get export_expenseCount => '支出筆數';

  @override
  String get export_totalHkd => '港幣總額';

  @override
  String get export_receiptCount => '收據圖片';

  @override
  String export_countUnit(int count) {
    return '$count 筆';
  }

  @override
  String export_imageUnit(int count) {
    return '$count 張';
  }

  @override
  String get export_excelWithReceipts => '匯出 Excel + 收據';

  @override
  String get export_noData => '沒有資料';

  @override
  String export_noDataMessage(int year, int month) {
    return '$year 年 $month 月沒有支出記錄';
  }

  @override
  String export_yearMonth(int year, int month) {
    return '$year 年 $month 月';
  }

  @override
  String get export_hint => '匯出的 Excel 包含完整支出明細';

  @override
  String get export_packing => '正在打包...';

  @override
  String get export_generatingExcel => '正在生成 Excel...';

  @override
  String get export_packingReceipts => '正在打包收據圖片...';

  @override
  String get export_compressing => '正在壓縮...';

  @override
  String get export_preparingShare => '準備分享...';

  @override
  String export_success(String size) {
    return '匯出成功 ($size)';
  }

  @override
  String export_failed(String message) {
    return '匯出失敗: $message';
  }

  @override
  String export_sheetName(int year, int month) {
    return '$year年$month月報銷單';
  }

  @override
  String get export_shareSubject => 'Expense Snap 報銷單';

  @override
  String get export_headerIndex => '序號';

  @override
  String get export_headerDate => '日期';

  @override
  String get export_headerDescription => '描述';

  @override
  String get export_headerOriginalAmount => '原始金額';

  @override
  String get export_headerOriginalCurrency => '原始幣種';

  @override
  String get export_headerExchangeRate => '匯率';

  @override
  String get export_headerRateSource => '匯率來源';

  @override
  String get export_headerHkdAmount => '港幣金額';

  @override
  String get export_headerReceiptFile => '收據檔名';

  @override
  String get export_headerTotal => '合計';

  @override
  String get export_rateSourceAuto => '自動';

  @override
  String get export_rateSourceOffline => '離線快取';

  @override
  String get export_rateSourceDefault => '預設';

  @override
  String get export_rateSourceManual => '手動';

  @override
  String export_fileName(int year, String month) {
    return '報銷單_$year年$month月';
  }

  @override
  String get settings_title => '設定';

  @override
  String get settings_general => '一般';

  @override
  String get settings_userName => '使用者名稱';

  @override
  String get settings_userNameHint => '用於報銷單標題';

  @override
  String get settings_language => '語言';

  @override
  String get settings_theme => '主題';

  @override
  String get settings_themeLight => '淺色';

  @override
  String get settings_themeDark => '深色';

  @override
  String get settings_themeSystem => '跟隨系統';

  @override
  String get settings_data => '資料管理';

  @override
  String get settings_backup => '雲端備份';

  @override
  String get settings_backupDesc => '備份至 Google Drive';

  @override
  String get settings_restore => '還原備份';

  @override
  String get settings_restoreDesc => '從 Google Drive 還原';

  @override
  String get settings_deletedItems => '已刪除項目';

  @override
  String get settings_deletedItemsDesc => '查看或還原已刪除的支出';

  @override
  String get settings_clearCache => '清理暫存檔';

  @override
  String get settings_about => '關於';

  @override
  String get settings_version => '版本';

  @override
  String get settings_privacyPolicy => '隱私權政策';

  @override
  String get settings_feedback => '意見回饋';

  @override
  String get settings_signInGoogle => '登入 Google';

  @override
  String get settings_signOutGoogle => '登出 Google';

  @override
  String settings_signedInAs(String email) {
    return '已登入：$email';
  }

  @override
  String get settings_backupSuccess => '備份成功';

  @override
  String settings_backupFailed(String message) {
    return '備份失敗: $message';
  }

  @override
  String get settings_restoreSuccess => '還原成功';

  @override
  String settings_restoreFailed(String message) {
    return '還原失敗: $message';
  }

  @override
  String get settings_cacheCleared => '快取已清除';

  @override
  String get settings_noBackupFound => '找不到備份檔案';

  @override
  String get settings_confirmRestore => '確認還原';

  @override
  String get settings_confirmRestoreMessage => '還原會覆蓋目前的資料，確定要繼續嗎？';

  @override
  String settings_lastBackup(String date) {
    return '上次備份：$date';
  }

  @override
  String get deletedItems_title => '已刪除項目';

  @override
  String get deletedItems_clearAll => '清空';

  @override
  String deletedItems_daysRemaining(int days) {
    return '還有 $days 天自動刪除';
  }

  @override
  String get deletedItems_soonDeleted => '即將自動刪除';

  @override
  String get deletedItems_restored => '已還原';

  @override
  String deletedItems_restoreFailed(String message) {
    return '還原失敗: $message';
  }

  @override
  String get deletedItems_permanentDelete => '永久刪除';

  @override
  String get deletedItems_permanentDeleteConfirm => '此操作無法復原，確定要永久刪除嗎？';

  @override
  String get deletedItems_permanentDeleted => '已永久刪除';

  @override
  String deletedItems_permanentDeleteFailed(String message) {
    return '刪除失敗: $message';
  }

  @override
  String get deletedItems_clearAllTitle => '清空所有';

  @override
  String deletedItems_clearAllConfirm(int count) {
    return '確定要永久刪除全部 $count 筆記錄嗎？\n此操作無法復原。';
  }

  @override
  String get deletedItems_clearAllButton => '全部刪除';

  @override
  String deletedItems_clearedCount(int count) {
    return '已刪除 $count 筆記錄';
  }

  @override
  String deletedItems_loadFailed(String message) {
    return '載入失敗: $message';
  }

  @override
  String get onboarding_skip => '跳過';

  @override
  String get onboarding_next => '下一步';

  @override
  String get onboarding_start => '開始使用';

  @override
  String get onboarding_page1Title => '拍照記錄支出';

  @override
  String get onboarding_page1Desc => '隨手拍攝收據，即時記錄每筆支出\n再也不怕遺失收據';

  @override
  String get onboarding_page2Title => '多幣種自動轉換';

  @override
  String get onboarding_page2Desc => '支援 HKD、CNY、USD\n系統自動取得即時匯率';

  @override
  String get onboarding_page3Title => '一鍵匯出報銷單';

  @override
  String get onboarding_page3Desc => '月結時一鍵匯出 Excel + 收據圖片\n輕鬆完成報銷';

  @override
  String get onboarding_nameLabel => '您的名字（選填）';

  @override
  String get onboarding_nameHint => '用於報銷單標題';

  @override
  String get onboarding_nameTooLong => '名字不能超過 50 個字';

  @override
  String get connectivity_offlineMode => '離線模式 - 匯率可能不是最新';

  @override
  String get dialog_duplicateTitle => '可能重複';

  @override
  String get dialog_duplicateMessage => '發現相似的支出記錄：';

  @override
  String get dialog_duplicateConfirm => '確定要繼續新增嗎？';

  @override
  String get dialog_duplicateContinue => '繼續新增';

  @override
  String get dialog_largeAmountTitle => '大金額確認';

  @override
  String get dialog_largeAmountMessage => '您即將記錄一筆大金額支出：';

  @override
  String get dialog_largeAmountConfirm => '請確認金額是否正確？';

  @override
  String get dialog_largeAmountBack => '返回修改';

  @override
  String get dialog_largeAmountOk => '確認正確';

  @override
  String get dialog_monthEndTitle => '月底提醒';

  @override
  String get dialog_monthEndMessage => '本月即將結束！';

  @override
  String dialog_monthEndExpenseCount(int count) {
    return '您本月共有 $count 筆支出記錄';
  }

  @override
  String get dialog_monthEndSuggestion => '建議您匯出報銷單，以便月結報銷。';

  @override
  String get dialog_later => '稍後';

  @override
  String get dialog_goExport => '去匯出';

  @override
  String get emptyState_noExpenses => '暫無支出記錄';

  @override
  String get emptyState_noExpensesHint => '點擊右下角按鈕新增第一筆支出';

  @override
  String get emptyState_noDeletedItems => '沒有已刪除的項目';

  @override
  String get emptyState_noDeletedItemsHint => '刪除的支出會在這裡保留 30 天';

  @override
  String get emptyState_error => '載入失敗';

  @override
  String get emptyState_offline => '無網路連線';

  @override
  String get emptyState_offlineHint => '請檢查您的網路設定';

  @override
  String get emptyState_exportSuccess => '匯出成功';

  @override
  String get emptyState_exportSuccessHint => '檔案已準備就緒';

  @override
  String get excel_header_index => '序號';

  @override
  String get excel_header_date => '日期';

  @override
  String get excel_header_description => '描述';

  @override
  String get excel_header_originalAmount => '原始金額';

  @override
  String get excel_header_originalCurrency => '原始幣種';

  @override
  String get excel_header_exchangeRate => '匯率';

  @override
  String get excel_header_rateSource => '匯率來源';

  @override
  String get excel_header_hkdAmount => '港幣金額';

  @override
  String get excel_header_receiptFile => '收據檔名';

  @override
  String get excel_total => '合計';

  @override
  String excel_sheetName(int year, int month) {
    return '$year年$month月報銷單';
  }

  @override
  String excel_fileName(int year, String month) {
    return '報銷單_$year年$month月';
  }

  @override
  String get excel_shareSubject => 'Expense Snap 報銷單';

  @override
  String get excel_rateSourceAuto => '自動';

  @override
  String get excel_rateSourceOffline => '離線快取';

  @override
  String get excel_rateSourceDefault => '預設';

  @override
  String get excel_rateSourceManual => '手動';

  @override
  String get error_unknown => '發生未知錯誤';

  @override
  String get error_networkError => '網路連線錯誤';

  @override
  String get error_serverError => '伺服器錯誤';

  @override
  String get error_storageError => '儲存空間錯誤';

  @override
  String get error_permissionDenied => '權限被拒絕';

  @override
  String get error_fileNotFound => '檔案不存在';

  @override
  String get error_invalidData => '資料格式錯誤';

  @override
  String get error_exportNoData => '沒有資料可匯出';

  @override
  String get error_invalidMonth => '月份必須介於 1 到 12 之間';

  @override
  String get error_invalidYear => '年份必須介於 2000 到 2100 之間';

  @override
  String get error_excelGenerationFailed => '無法生成 Excel 檔案';

  @override
  String get error_zipFailed => '無法壓縮檔案';

  @override
  String get error_shareFailed => '分享失敗';

  @override
  String get error_cleanupFailed => '清理暫存檔案失敗';

  @override
  String get format_date => 'yyyy/MM/dd';

  @override
  String get format_dateTime => 'yyyy/MM/dd HH:mm';

  @override
  String get format_month => 'yyyy年M月';

  @override
  String get format_currency => '#,##0.00';

  @override
  String get currency_HKD => '港幣';

  @override
  String get currency_CNY => '人民幣';

  @override
  String get currency_USD => '美元';

  @override
  String get datePicker_selectDate => '選擇日期';

  @override
  String get datePicker_selectMonth => '選擇月份';

  @override
  String get settings_profile => '個人資料';

  @override
  String get settings_appearance => '外觀';

  @override
  String get settings_reduceMotion => '減少動畫';

  @override
  String get settings_reduceMotionDesc => '減少動態效果，適合動暈症患者';

  @override
  String get settings_storageUsage => '本地儲存使用量';

  @override
  String get settings_clearCacheDesc => '釋放匯出和備份暫存空間';

  @override
  String get settings_cloudBackup => '雲端備份';

  @override
  String get settings_googleDrive => 'Google 雲端硬碟';

  @override
  String get settings_lastBackupTime => '上次備份';

  @override
  String get settings_backupNow => '立即備份';

  @override
  String get settings_backupNowDesc => '備份資料庫和收據到 Google 雲端硬碟';

  @override
  String get settings_restoreBackupTitle => '還原備份';

  @override
  String get settings_restoreBackupDesc => '從 Google 雲端硬碟還原';

  @override
  String get settings_selectBackup => '選擇備份';

  @override
  String get settings_connect => '連接';

  @override
  String get settings_disconnect => '斷開';

  @override
  String get settings_connected => '已連接';

  @override
  String get settings_notConnected => '尚未連接';

  @override
  String get settings_languageSystem => '跟隨系統';

  @override
  String get settings_selectTheme => '選擇主題';

  @override
  String get settings_editName => '編輯姓名';

  @override
  String get settings_nameLabel => '姓名';

  @override
  String get settings_nameHint => '用於報銷單標題';

  @override
  String get settings_saved => '已儲存';

  @override
  String settings_cleanupFailed(String message) {
    return '清理失敗: $message';
  }

  @override
  String settings_cleanedFiles(int count) {
    return '已清理 $count 個暫存檔案';
  }

  @override
  String get settings_backupToCloud => '備份到雲端';

  @override
  String get settings_backupConfirmMessage =>
      '這將備份所有支出記錄和收據圖片到 Google 雲端硬碟。\n\n繼續？';

  @override
  String get settings_confirmRestoreTitle => '確認還原';

  @override
  String settings_confirmRestoreDesc(String fileName) {
    return '這將使用 \"$fileName\" 取代目前所有資料。\n\n此操作無法復原，確定要繼續嗎？';
  }

  @override
  String get settings_disconnectTitle => '斷開 Google 帳號';

  @override
  String get settings_disconnectConfirm => '斷開後將無法使用雲端備份功能。\n\n確定要斷開嗎？';

  @override
  String settings_connectFailed(String message) {
    return '連接失敗: $message';
  }

  @override
  String settings_disconnectFailed(String message) {
    return '斷開失敗: $message';
  }

  @override
  String get settings_googleConnected => '已連接 Google 帳號';

  @override
  String get settings_googleDisconnected => '已斷開 Google 帳號';

  @override
  String get category_label => '分類（選填）';

  @override
  String get category_meals => '餐飲';

  @override
  String get category_transport => '交通';

  @override
  String get category_accommodation => '住宿';

  @override
  String get category_officeSupplies => '辦公用品';

  @override
  String get category_communication => '通訊';

  @override
  String get category_entertainment => '娛樂';

  @override
  String get category_medical => '醫療';

  @override
  String get category_other => '其他';

  @override
  String get category_statistics => '分類統計';

  @override
  String get category_uncategorized => '未分類';

  @override
  String get excel_header_category => '分類';

  @override
  String get semantic_category_prefix => '分類';

  @override
  String semantic_expenseItem(String description) {
    return '支出項目：$description';
  }

  @override
  String semantic_amount(String amount) {
    return '金額：$amount';
  }

  @override
  String semantic_originalAmount(String amount) {
    return '原始金額：$amount';
  }

  @override
  String semantic_date(String date) {
    return '日期：$date';
  }

  @override
  String semantic_rateSource(String source) {
    return '匯率來源：$source';
  }

  @override
  String get semantic_hasReceipt => '有收據圖片';

  @override
  String get semantic_tapForDetails => '點擊查看詳情';

  @override
  String get semantic_swipeToDelete => '向左滑動刪除';

  @override
  String get validation_amountRequired => '請輸入金額';

  @override
  String validation_amountTooSmall(num min) {
    return '金額不能小於 $min';
  }

  @override
  String validation_amountTooLarge(num max) {
    return '金額不能大於 $max';
  }

  @override
  String get validation_exchangeRateLabel => '匯率';

  @override
  String validation_exchangeRateHint(String currency) {
    return '1 $currency = ? HKD';
  }

  @override
  String get validation_exchangeRateRequired => '請輸入匯率';

  @override
  String get validation_exchangeRateInvalid => '請輸入有效匯率';
}
