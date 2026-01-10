// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Expense Snap';

  @override
  String get common_save => 'Save';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_edit => 'Edit';

  @override
  String get common_retry => 'Retry';

  @override
  String get common_confirm => 'Confirm';

  @override
  String get common_back => 'Back';

  @override
  String get common_skip => 'Skip';

  @override
  String get common_next => 'Next';

  @override
  String get common_done => 'Done';

  @override
  String get common_close => 'Close';

  @override
  String get common_restore => 'Restore';

  @override
  String get common_clear => 'Clear';

  @override
  String get common_share => 'Share';

  @override
  String get common_loading => 'Loading...';

  @override
  String get common_saving => 'Saving...';

  @override
  String get common_processing => 'Processing...';

  @override
  String get nav_home => 'Home';

  @override
  String get nav_export => 'Export';

  @override
  String get nav_settings => 'Settings';

  @override
  String get home_addExpense => 'Add Expense';

  @override
  String get home_deleteSuccess => 'Expense deleted';

  @override
  String home_deleteFailed(String message) {
    return 'Delete failed: $message';
  }

  @override
  String get home_undo => 'Undo';

  @override
  String get showcase_addExpenseTitle => 'Add Expense';

  @override
  String get showcase_addExpenseDesc =>
      'Tap here to take a photo and record your expense';

  @override
  String get showcase_swipeDeleteTitle => 'Swipe to Delete';

  @override
  String get showcase_swipeDeleteDesc => 'Swipe left to delete an expense';

  @override
  String get addExpense_title => 'Add Expense';

  @override
  String get addExpense_receiptImage => 'Receipt Image';

  @override
  String get addExpense_camera => 'Camera';

  @override
  String get addExpense_gallery => 'Gallery';

  @override
  String get addExpense_amount => 'Amount';

  @override
  String get addExpense_description => 'Description';

  @override
  String get addExpense_descriptionHint => 'Enter description...';

  @override
  String get addExpense_date => 'Date';

  @override
  String get addExpense_currency => 'Currency';

  @override
  String get addExpense_exchangeRate => 'Exchange Rate';

  @override
  String get addExpense_manualInput => 'Manual Input';

  @override
  String get addExpense_ocrProcessing => 'Recognizing receipt...';

  @override
  String get addExpense_ocrSuccess => 'Receipt content recognized';

  @override
  String get addExpense_ocrSuccessVerify =>
      'Receipt content recognized, please verify';

  @override
  String get addExpense_success => 'Expense added';

  @override
  String get addExpense_invalidAmount => 'Please enter a valid amount';

  @override
  String get expenseDetail_title => 'Expense Details';

  @override
  String get expenseDetail_editTitle => 'Edit Expense';

  @override
  String get expenseDetail_amount => 'Amount';

  @override
  String get expenseDetail_hkdAmount => 'HKD Amount';

  @override
  String get expenseDetail_exchangeRate => 'Exchange Rate';

  @override
  String get expenseDetail_description => 'Description';

  @override
  String get expenseDetail_descriptionRequired => 'Please enter a description';

  @override
  String get expenseDetail_date => 'Date';

  @override
  String get expenseDetail_createdAt => 'Created At';

  @override
  String get expenseDetail_replaceImage => 'Replace Image';

  @override
  String get expenseDetail_imageLoadFailed => 'Image failed to load';

  @override
  String get expenseDetail_noReceipt => 'No receipt image';

  @override
  String get expenseDetail_cancelEdit => 'Cancel Edit';

  @override
  String get expenseDetail_saved => 'Saved';

  @override
  String expenseDetail_saveFailed(String message) {
    return 'Save failed: $message';
  }

  @override
  String get expenseDetail_deleted => 'Deleted';

  @override
  String expenseDetail_deleteFailed(String message) {
    return 'Delete failed: $message';
  }

  @override
  String get expenseDetail_confirmDelete => 'Confirm Delete';

  @override
  String get expenseDetail_confirmDeleteMessage =>
      'Are you sure you want to delete this expense?\nYou can restore it from Deleted Items.';

  @override
  String get expenseDetail_expenseNotFound => 'Expense not found';

  @override
  String get expenseDetail_imageReplaceSuccess => 'Image replaced';

  @override
  String expenseDetail_imageReplaceFailed(String message) {
    return 'Replace image failed: $message';
  }

  @override
  String get expenseDetail_selectFromGallery => 'Select from Gallery';

  @override
  String get rateSource_auto => 'Live Rate';

  @override
  String get rateSource_offline => 'Cached Rate';

  @override
  String get rateSource_default => 'Default Rate';

  @override
  String get rateSource_manual => 'Manual Input';

  @override
  String get rateSource_auto_short => 'Live';

  @override
  String get rateSource_offline_short => 'Cached';

  @override
  String get rateSource_default_short => 'Default';

  @override
  String get rateSource_manual_short => 'Manual';

  @override
  String get monthSummary_totalExpense => 'Total Expense';

  @override
  String get monthSummary_count => 'Count';

  @override
  String get monthSummary_countSuffix => '';

  @override
  String get monthSummary_previousMonth => 'Previous Month';

  @override
  String get monthSummary_nextMonth => 'Next Month';

  @override
  String monthSummary_semanticLabel(String month, String amount, int count) {
    return '$month summary. Total expense: HKD $amount. $count expenses.';
  }

  @override
  String get monthSummary_isLatestMonth => 'Already at latest month';

  @override
  String get export_title => 'Export Report';

  @override
  String get export_preview => 'Preview';

  @override
  String get export_expenseCount => 'Expense Count';

  @override
  String get export_totalHkd => 'HKD Total';

  @override
  String get export_receiptCount => 'Receipt Images';

  @override
  String export_countUnit(int count) {
    return '$count';
  }

  @override
  String export_imageUnit(int count) {
    return '$count';
  }

  @override
  String get export_excelWithReceipts => 'Export Excel + Receipts';

  @override
  String get export_noData => 'No Data';

  @override
  String export_noDataMessage(int year, int month) {
    return 'No expenses recorded in $year/$month';
  }

  @override
  String export_yearMonth(int year, int month) {
    return '$year/$month';
  }

  @override
  String get export_hint => 'Exported Excel contains complete expense details';

  @override
  String get export_packing => 'Packing...';

  @override
  String get export_generatingExcel => 'Generating Excel...';

  @override
  String get export_packingReceipts => 'Packing receipt images...';

  @override
  String get export_compressing => 'Compressing...';

  @override
  String get export_preparingShare => 'Preparing to share...';

  @override
  String export_success(String size) {
    return 'Export successful ($size)';
  }

  @override
  String export_failed(String message) {
    return 'Export failed: $message';
  }

  @override
  String export_sheetName(int year, int month) {
    return '$year/$month Expense Report';
  }

  @override
  String get export_shareSubject => 'Expense Snap Report';

  @override
  String get export_headerIndex => 'No.';

  @override
  String get export_headerDate => 'Date';

  @override
  String get export_headerDescription => 'Description';

  @override
  String get export_headerOriginalAmount => 'Original Amount';

  @override
  String get export_headerOriginalCurrency => 'Currency';

  @override
  String get export_headerExchangeRate => 'Exchange Rate';

  @override
  String get export_headerRateSource => 'Rate Source';

  @override
  String get export_headerHkdAmount => 'HKD Amount';

  @override
  String get export_headerReceiptFile => 'Receipt';

  @override
  String get export_headerTotal => 'Total';

  @override
  String get export_rateSourceAuto => 'Auto';

  @override
  String get export_rateSourceOffline => 'Offline Cache';

  @override
  String get export_rateSourceDefault => 'Default';

  @override
  String get export_rateSourceManual => 'Manual';

  @override
  String export_fileName(int year, String month) {
    return 'Expense_Report_${year}_$month';
  }

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_general => 'General';

  @override
  String get settings_userName => 'Username';

  @override
  String get settings_userNameHint => 'Used for report title';

  @override
  String get settings_language => 'Language';

  @override
  String get settings_theme => 'Theme';

  @override
  String get settings_themeLight => 'Light';

  @override
  String get settings_themeDark => 'Dark';

  @override
  String get settings_themeSystem => 'System';

  @override
  String get settings_data => 'Data Management';

  @override
  String get settings_backup => 'Cloud Backup';

  @override
  String get settings_backupDesc => 'Backup to Google Drive';

  @override
  String get settings_restore => 'Restore Backup';

  @override
  String get settings_restoreDesc => 'Restore from Google Drive';

  @override
  String get settings_deletedItems => 'Deleted Items';

  @override
  String get settings_deletedItemsDesc => 'View or restore deleted expenses';

  @override
  String get settings_clearCache => 'Clear Temp Files';

  @override
  String get settings_about => 'About';

  @override
  String get settings_version => 'Version';

  @override
  String get settings_privacyPolicy => 'Privacy Policy';

  @override
  String get settings_feedback => 'Feedback';

  @override
  String get settings_signInGoogle => 'Sign in with Google';

  @override
  String get settings_signOutGoogle => 'Sign out';

  @override
  String settings_signedInAs(String email) {
    return 'Signed in as: $email';
  }

  @override
  String get settings_backupSuccess => 'Backup successful';

  @override
  String settings_backupFailed(String message) {
    return 'Backup failed: $message';
  }

  @override
  String get settings_restoreSuccess => 'Restore successful';

  @override
  String settings_restoreFailed(String message) {
    return 'Restore failed: $message';
  }

  @override
  String get settings_cacheCleared => 'Cache cleared';

  @override
  String get settings_noBackupFound => 'No backup found';

  @override
  String get settings_confirmRestore => 'Confirm Restore';

  @override
  String get settings_confirmRestoreMessage =>
      'Restore will overwrite current data. Continue?';

  @override
  String settings_lastBackup(String date) {
    return 'Last backup: $date';
  }

  @override
  String get deletedItems_title => 'Deleted Items';

  @override
  String get deletedItems_clearAll => 'Clear All';

  @override
  String deletedItems_daysRemaining(int days) {
    return '$days days until auto-delete';
  }

  @override
  String get deletedItems_soonDeleted => 'Will be deleted soon';

  @override
  String get deletedItems_restored => 'Restored';

  @override
  String deletedItems_restoreFailed(String message) {
    return 'Restore failed: $message';
  }

  @override
  String get deletedItems_permanentDelete => 'Delete Permanently';

  @override
  String get deletedItems_permanentDeleteConfirm =>
      'This cannot be undone. Delete permanently?';

  @override
  String get deletedItems_permanentDeleted => 'Permanently deleted';

  @override
  String deletedItems_permanentDeleteFailed(String message) {
    return 'Delete failed: $message';
  }

  @override
  String get deletedItems_clearAllTitle => 'Clear All';

  @override
  String deletedItems_clearAllConfirm(int count) {
    return 'Permanently delete all $count items?\nThis cannot be undone.';
  }

  @override
  String get deletedItems_clearAllButton => 'Delete All';

  @override
  String deletedItems_clearedCount(int count) {
    return 'Deleted $count items';
  }

  @override
  String deletedItems_loadFailed(String message) {
    return 'Load failed: $message';
  }

  @override
  String get onboarding_skip => 'Skip';

  @override
  String get onboarding_next => 'Next';

  @override
  String get onboarding_start => 'Get Started';

  @override
  String get onboarding_page1Title => 'Snap Your Receipts';

  @override
  String get onboarding_page1Desc =>
      'Take photos of receipts instantly\nNever lose a receipt again';

  @override
  String get onboarding_page2Title => 'Multi-Currency Support';

  @override
  String get onboarding_page2Desc =>
      'Supports HKD, CNY, USD\nAuto-fetches live exchange rates';

  @override
  String get onboarding_page3Title => 'One-Click Export';

  @override
  String get onboarding_page3Desc =>
      'Export Excel + receipt images\nEasy expense reporting';

  @override
  String get onboarding_nameLabel => 'Your Name (Optional)';

  @override
  String get onboarding_nameHint => 'Used for report title';

  @override
  String get onboarding_nameTooLong => 'Name cannot exceed 50 characters';

  @override
  String get connectivity_offlineMode =>
      'Offline Mode - Exchange rates may be outdated';

  @override
  String get dialog_duplicateTitle => 'Possible Duplicate';

  @override
  String get dialog_duplicateMessage => 'Similar expense found:';

  @override
  String get dialog_duplicateConfirm => 'Continue adding?';

  @override
  String get dialog_duplicateContinue => 'Add Anyway';

  @override
  String get dialog_largeAmountTitle => 'Large Amount';

  @override
  String get dialog_largeAmountMessage => 'You are recording a large expense:';

  @override
  String get dialog_largeAmountConfirm => 'Is the amount correct?';

  @override
  String get dialog_largeAmountBack => 'Go Back';

  @override
  String get dialog_largeAmountOk => 'Confirm';

  @override
  String get dialog_monthEndTitle => 'Month End Reminder';

  @override
  String get dialog_monthEndMessage => 'Month is ending soon!';

  @override
  String dialog_monthEndExpenseCount(int count) {
    return 'You have $count expenses this month';
  }

  @override
  String get dialog_monthEndSuggestion =>
      'Consider exporting your expense report.';

  @override
  String get dialog_later => 'Later';

  @override
  String get dialog_goExport => 'Export Now';

  @override
  String get emptyState_noExpenses => 'No Expenses';

  @override
  String get emptyState_noExpensesHint =>
      'Tap the button below to add your first expense';

  @override
  String get emptyState_noDeletedItems => 'No Deleted Items';

  @override
  String get emptyState_noDeletedItemsHint =>
      'Deleted expenses are kept for 30 days';

  @override
  String get emptyState_error => 'Load Failed';

  @override
  String get emptyState_offline => 'No Internet Connection';

  @override
  String get emptyState_offlineHint => 'Please check your network settings';

  @override
  String get emptyState_exportSuccess => 'Export Successful';

  @override
  String get emptyState_exportSuccessHint => 'File is ready';

  @override
  String get excel_header_index => 'No.';

  @override
  String get excel_header_date => 'Date';

  @override
  String get excel_header_description => 'Description';

  @override
  String get excel_header_originalAmount => 'Original Amount';

  @override
  String get excel_header_originalCurrency => 'Currency';

  @override
  String get excel_header_exchangeRate => 'Exchange Rate';

  @override
  String get excel_header_rateSource => 'Rate Source';

  @override
  String get excel_header_hkdAmount => 'HKD Amount';

  @override
  String get excel_header_receiptFile => 'Receipt File';

  @override
  String get excel_total => 'Total';

  @override
  String excel_sheetName(int year, int month) {
    return 'Expenses_${year}_$month';
  }

  @override
  String excel_fileName(int year, String month) {
    return 'Expenses_${year}_$month';
  }

  @override
  String get excel_shareSubject => 'Expense Snap Report';

  @override
  String get excel_rateSourceAuto => 'Auto';

  @override
  String get excel_rateSourceOffline => 'Cached';

  @override
  String get excel_rateSourceDefault => 'Default';

  @override
  String get excel_rateSourceManual => 'Manual';

  @override
  String get error_unknown => 'Unknown error occurred';

  @override
  String get error_networkError => 'Network connection error';

  @override
  String get error_serverError => 'Server error';

  @override
  String get error_storageError => 'Storage error';

  @override
  String get error_permissionDenied => 'Permission denied';

  @override
  String get error_fileNotFound => 'File not found';

  @override
  String get error_invalidData => 'Invalid data format';

  @override
  String get error_exportNoData => 'No data to export';

  @override
  String get error_invalidMonth => 'Month must be between 1 and 12';

  @override
  String get error_invalidYear => 'Year must be between 2000 and 2100';

  @override
  String get error_excelGenerationFailed => 'Failed to generate Excel file';

  @override
  String get error_zipFailed => 'Failed to compress file';

  @override
  String get error_shareFailed => 'Share failed';

  @override
  String get error_cleanupFailed => 'Failed to clean up temp files';

  @override
  String get format_date => 'yyyy/MM/dd';

  @override
  String get format_dateTime => 'yyyy/MM/dd HH:mm';

  @override
  String get format_month => 'MMM yyyy';

  @override
  String get format_currency => '#,##0.00';

  @override
  String get currency_HKD => 'HKD';

  @override
  String get currency_CNY => 'CNY';

  @override
  String get currency_USD => 'USD';

  @override
  String get datePicker_selectDate => 'Select Date';

  @override
  String get datePicker_selectMonth => 'Select Month';

  @override
  String get settings_profile => 'Profile';

  @override
  String get settings_appearance => 'Appearance';

  @override
  String get settings_reduceMotion => 'Reduce Motion';

  @override
  String get settings_reduceMotionDesc =>
      'Reduce animations for motion sensitivity';

  @override
  String get settings_storageUsage => 'Storage Usage';

  @override
  String get settings_clearCacheDesc => 'Free up export and backup cache space';

  @override
  String get settings_cloudBackup => 'Cloud Backup';

  @override
  String get settings_googleDrive => 'Google Drive';

  @override
  String get settings_lastBackupTime => 'Last Backup';

  @override
  String get settings_backupNow => 'Backup Now';

  @override
  String get settings_backupNowDesc =>
      'Backup database and receipts to Google Drive';

  @override
  String get settings_restoreBackupTitle => 'Restore Backup';

  @override
  String get settings_restoreBackupDesc => 'Restore from Google Drive';

  @override
  String get settings_selectBackup => 'Select Backup';

  @override
  String get settings_connect => 'Connect';

  @override
  String get settings_disconnect => 'Disconnect';

  @override
  String get settings_connected => 'Connected';

  @override
  String get settings_notConnected => 'Not connected';

  @override
  String get settings_languageSystem => 'Follow System';

  @override
  String get settings_selectTheme => 'Select Theme';

  @override
  String get settings_editName => 'Edit Name';

  @override
  String get settings_nameLabel => 'Name';

  @override
  String get settings_nameHint => 'Used for expense report title';

  @override
  String get settings_saved => 'Saved';

  @override
  String settings_cleanupFailed(String message) {
    return 'Cleanup failed: $message';
  }

  @override
  String settings_cleanedFiles(int count) {
    return 'Cleaned $count temp files';
  }

  @override
  String get settings_backupToCloud => 'Backup to Cloud';

  @override
  String get settings_backupConfirmMessage =>
      'This will backup all expenses and receipts to Google Drive.\n\nContinue?';

  @override
  String get settings_confirmRestoreTitle => 'Confirm Restore';

  @override
  String settings_confirmRestoreDesc(String fileName) {
    return 'This will replace all current data with \"$fileName\".\n\nThis cannot be undone. Continue?';
  }

  @override
  String get settings_disconnectTitle => 'Disconnect Google Account';

  @override
  String get settings_disconnectConfirm =>
      'Cloud backup will be unavailable after disconnecting.\n\nDisconnect?';

  @override
  String settings_connectFailed(String message) {
    return 'Connection failed: $message';
  }

  @override
  String settings_disconnectFailed(String message) {
    return 'Disconnect failed: $message';
  }

  @override
  String get settings_googleConnected => 'Google account connected';

  @override
  String get settings_googleDisconnected => 'Google account disconnected';

  @override
  String get category_label => 'Category (Optional)';

  @override
  String get category_meals => 'Meals';

  @override
  String get category_transport => 'Transport';

  @override
  String get category_accommodation => 'Accommodation';

  @override
  String get category_officeSupplies => 'Office Supplies';

  @override
  String get category_communication => 'Communication';

  @override
  String get category_entertainment => 'Entertainment';

  @override
  String get category_medical => 'Medical';

  @override
  String get category_other => 'Other';

  @override
  String get category_statistics => 'Category Statistics';

  @override
  String get category_uncategorized => 'Uncategorized';

  @override
  String get excel_header_category => 'Category';

  @override
  String get semantic_category_prefix => 'Category';

  @override
  String semantic_expenseItem(String description) {
    return 'Expense item: $description';
  }

  @override
  String semantic_amount(String amount) {
    return 'Amount: $amount';
  }

  @override
  String semantic_originalAmount(String amount) {
    return 'Original amount: $amount';
  }

  @override
  String semantic_date(String date) {
    return 'Date: $date';
  }

  @override
  String semantic_rateSource(String source) {
    return 'Rate source: $source';
  }

  @override
  String get semantic_hasReceipt => 'Has receipt image';

  @override
  String get semantic_tapForDetails => 'Tap to view details';

  @override
  String get semantic_swipeToDelete => 'Swipe left to delete';

  @override
  String get validation_amountRequired => 'Please enter an amount';

  @override
  String validation_amountTooSmall(num min) {
    return 'Amount cannot be less than $min';
  }

  @override
  String validation_amountTooLarge(num max) {
    return 'Amount cannot exceed $max';
  }

  @override
  String get validation_exchangeRateLabel => 'Exchange Rate';

  @override
  String validation_exchangeRateHint(String currency) {
    return '1 $currency = ? HKD';
  }

  @override
  String get validation_exchangeRateRequired => 'Please enter exchange rate';

  @override
  String get validation_exchangeRateInvalid =>
      'Please enter a valid exchange rate';
}
