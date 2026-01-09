import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'Expense Snap'**
  String get appTitle;

  /// No description provided for @common_save.
  ///
  /// In zh, this message translates to:
  /// **'儲存'**
  String get common_save;

  /// No description provided for @common_cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get common_cancel;

  /// No description provided for @common_delete.
  ///
  /// In zh, this message translates to:
  /// **'刪除'**
  String get common_delete;

  /// No description provided for @common_edit.
  ///
  /// In zh, this message translates to:
  /// **'編輯'**
  String get common_edit;

  /// No description provided for @common_retry.
  ///
  /// In zh, this message translates to:
  /// **'重試'**
  String get common_retry;

  /// No description provided for @common_confirm.
  ///
  /// In zh, this message translates to:
  /// **'確認'**
  String get common_confirm;

  /// No description provided for @common_back.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get common_back;

  /// No description provided for @common_skip.
  ///
  /// In zh, this message translates to:
  /// **'跳過'**
  String get common_skip;

  /// No description provided for @common_next.
  ///
  /// In zh, this message translates to:
  /// **'下一步'**
  String get common_next;

  /// No description provided for @common_done.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get common_done;

  /// No description provided for @common_close.
  ///
  /// In zh, this message translates to:
  /// **'關閉'**
  String get common_close;

  /// No description provided for @common_restore.
  ///
  /// In zh, this message translates to:
  /// **'還原'**
  String get common_restore;

  /// No description provided for @common_clear.
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get common_clear;

  /// No description provided for @common_share.
  ///
  /// In zh, this message translates to:
  /// **'分享'**
  String get common_share;

  /// No description provided for @common_loading.
  ///
  /// In zh, this message translates to:
  /// **'載入中...'**
  String get common_loading;

  /// No description provided for @common_saving.
  ///
  /// In zh, this message translates to:
  /// **'儲存中...'**
  String get common_saving;

  /// No description provided for @common_processing.
  ///
  /// In zh, this message translates to:
  /// **'處理中...'**
  String get common_processing;

  /// No description provided for @nav_home.
  ///
  /// In zh, this message translates to:
  /// **'首頁'**
  String get nav_home;

  /// No description provided for @nav_export.
  ///
  /// In zh, this message translates to:
  /// **'匯出'**
  String get nav_export;

  /// No description provided for @nav_settings.
  ///
  /// In zh, this message translates to:
  /// **'設定'**
  String get nav_settings;

  /// No description provided for @home_addExpense.
  ///
  /// In zh, this message translates to:
  /// **'新增支出'**
  String get home_addExpense;

  /// No description provided for @home_deleteSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已刪除支出'**
  String get home_deleteSuccess;

  /// No description provided for @home_deleteFailed.
  ///
  /// In zh, this message translates to:
  /// **'刪除失敗: {message}'**
  String home_deleteFailed(String message);

  /// No description provided for @home_undo.
  ///
  /// In zh, this message translates to:
  /// **'復原'**
  String get home_undo;

  /// No description provided for @showcase_addExpenseTitle.
  ///
  /// In zh, this message translates to:
  /// **'新增支出'**
  String get showcase_addExpenseTitle;

  /// No description provided for @showcase_addExpenseDesc.
  ///
  /// In zh, this message translates to:
  /// **'點擊這裡拍照記錄你的支出'**
  String get showcase_addExpenseDesc;

  /// No description provided for @showcase_swipeDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'滑動刪除'**
  String get showcase_swipeDeleteTitle;

  /// No description provided for @showcase_swipeDeleteDesc.
  ///
  /// In zh, this message translates to:
  /// **'向左滑動可以刪除支出記錄'**
  String get showcase_swipeDeleteDesc;

  /// No description provided for @addExpense_title.
  ///
  /// In zh, this message translates to:
  /// **'新增支出'**
  String get addExpense_title;

  /// No description provided for @addExpense_receiptImage.
  ///
  /// In zh, this message translates to:
  /// **'收據圖片'**
  String get addExpense_receiptImage;

  /// No description provided for @addExpense_camera.
  ///
  /// In zh, this message translates to:
  /// **'拍照'**
  String get addExpense_camera;

  /// No description provided for @addExpense_gallery.
  ///
  /// In zh, this message translates to:
  /// **'相簿'**
  String get addExpense_gallery;

  /// No description provided for @addExpense_amount.
  ///
  /// In zh, this message translates to:
  /// **'金額'**
  String get addExpense_amount;

  /// No description provided for @addExpense_description.
  ///
  /// In zh, this message translates to:
  /// **'描述'**
  String get addExpense_description;

  /// No description provided for @addExpense_descriptionHint.
  ///
  /// In zh, this message translates to:
  /// **'輸入描述...'**
  String get addExpense_descriptionHint;

  /// No description provided for @addExpense_date.
  ///
  /// In zh, this message translates to:
  /// **'日期'**
  String get addExpense_date;

  /// No description provided for @addExpense_currency.
  ///
  /// In zh, this message translates to:
  /// **'幣種'**
  String get addExpense_currency;

  /// No description provided for @addExpense_exchangeRate.
  ///
  /// In zh, this message translates to:
  /// **'匯率'**
  String get addExpense_exchangeRate;

  /// No description provided for @addExpense_manualInput.
  ///
  /// In zh, this message translates to:
  /// **'手動輸入'**
  String get addExpense_manualInput;

  /// No description provided for @addExpense_ocrProcessing.
  ///
  /// In zh, this message translates to:
  /// **'正在識別收據...'**
  String get addExpense_ocrProcessing;

  /// No description provided for @addExpense_ocrSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已自動識別收據內容'**
  String get addExpense_ocrSuccess;

  /// No description provided for @addExpense_ocrSuccessVerify.
  ///
  /// In zh, this message translates to:
  /// **'已自動識別收據內容，請確認是否正確'**
  String get addExpense_ocrSuccessVerify;

  /// No description provided for @addExpense_success.
  ///
  /// In zh, this message translates to:
  /// **'支出已新增'**
  String get addExpense_success;

  /// No description provided for @addExpense_invalidAmount.
  ///
  /// In zh, this message translates to:
  /// **'請輸入有效金額'**
  String get addExpense_invalidAmount;

  /// No description provided for @expenseDetail_title.
  ///
  /// In zh, this message translates to:
  /// **'支出詳情'**
  String get expenseDetail_title;

  /// No description provided for @expenseDetail_editTitle.
  ///
  /// In zh, this message translates to:
  /// **'編輯支出'**
  String get expenseDetail_editTitle;

  /// No description provided for @expenseDetail_amount.
  ///
  /// In zh, this message translates to:
  /// **'金額'**
  String get expenseDetail_amount;

  /// No description provided for @expenseDetail_hkdAmount.
  ///
  /// In zh, this message translates to:
  /// **'港幣金額'**
  String get expenseDetail_hkdAmount;

  /// No description provided for @expenseDetail_exchangeRate.
  ///
  /// In zh, this message translates to:
  /// **'匯率'**
  String get expenseDetail_exchangeRate;

  /// No description provided for @expenseDetail_description.
  ///
  /// In zh, this message translates to:
  /// **'描述'**
  String get expenseDetail_description;

  /// No description provided for @expenseDetail_descriptionRequired.
  ///
  /// In zh, this message translates to:
  /// **'請輸入描述'**
  String get expenseDetail_descriptionRequired;

  /// No description provided for @expenseDetail_date.
  ///
  /// In zh, this message translates to:
  /// **'日期'**
  String get expenseDetail_date;

  /// No description provided for @expenseDetail_createdAt.
  ///
  /// In zh, this message translates to:
  /// **'建立時間'**
  String get expenseDetail_createdAt;

  /// No description provided for @expenseDetail_replaceImage.
  ///
  /// In zh, this message translates to:
  /// **'更換圖片'**
  String get expenseDetail_replaceImage;

  /// No description provided for @expenseDetail_imageLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'圖片載入失敗'**
  String get expenseDetail_imageLoadFailed;

  /// No description provided for @expenseDetail_noReceipt.
  ///
  /// In zh, this message translates to:
  /// **'無收據圖片'**
  String get expenseDetail_noReceipt;

  /// No description provided for @expenseDetail_cancelEdit.
  ///
  /// In zh, this message translates to:
  /// **'取消編輯'**
  String get expenseDetail_cancelEdit;

  /// No description provided for @expenseDetail_saved.
  ///
  /// In zh, this message translates to:
  /// **'已儲存'**
  String get expenseDetail_saved;

  /// No description provided for @expenseDetail_saveFailed.
  ///
  /// In zh, this message translates to:
  /// **'儲存失敗: {message}'**
  String expenseDetail_saveFailed(String message);

  /// No description provided for @expenseDetail_deleted.
  ///
  /// In zh, this message translates to:
  /// **'已刪除'**
  String get expenseDetail_deleted;

  /// No description provided for @expenseDetail_deleteFailed.
  ///
  /// In zh, this message translates to:
  /// **'刪除失敗: {message}'**
  String expenseDetail_deleteFailed(String message);

  /// No description provided for @expenseDetail_confirmDelete.
  ///
  /// In zh, this message translates to:
  /// **'確認刪除'**
  String get expenseDetail_confirmDelete;

  /// No description provided for @expenseDetail_confirmDeleteMessage.
  ///
  /// In zh, this message translates to:
  /// **'確定要刪除這筆支出嗎？\n刪除後可在「已刪除項目」中還原。'**
  String get expenseDetail_confirmDeleteMessage;

  /// No description provided for @expenseDetail_expenseNotFound.
  ///
  /// In zh, this message translates to:
  /// **'找不到支出記錄'**
  String get expenseDetail_expenseNotFound;

  /// No description provided for @expenseDetail_imageReplaceSuccess.
  ///
  /// In zh, this message translates to:
  /// **'圖片已更換'**
  String get expenseDetail_imageReplaceSuccess;

  /// No description provided for @expenseDetail_imageReplaceFailed.
  ///
  /// In zh, this message translates to:
  /// **'更換圖片失敗: {message}'**
  String expenseDetail_imageReplaceFailed(String message);

  /// No description provided for @expenseDetail_selectFromGallery.
  ///
  /// In zh, this message translates to:
  /// **'從相簿選擇'**
  String get expenseDetail_selectFromGallery;

  /// No description provided for @rateSource_auto.
  ///
  /// In zh, this message translates to:
  /// **'即時匯率'**
  String get rateSource_auto;

  /// No description provided for @rateSource_offline.
  ///
  /// In zh, this message translates to:
  /// **'離線快取'**
  String get rateSource_offline;

  /// No description provided for @rateSource_default.
  ///
  /// In zh, this message translates to:
  /// **'預設匯率'**
  String get rateSource_default;

  /// No description provided for @rateSource_manual.
  ///
  /// In zh, this message translates to:
  /// **'手動輸入'**
  String get rateSource_manual;

  /// No description provided for @monthSummary_totalExpense.
  ///
  /// In zh, this message translates to:
  /// **'總支出'**
  String get monthSummary_totalExpense;

  /// No description provided for @monthSummary_count.
  ///
  /// In zh, this message translates to:
  /// **'筆數'**
  String get monthSummary_count;

  /// No description provided for @monthSummary_countSuffix.
  ///
  /// In zh, this message translates to:
  /// **' 筆'**
  String get monthSummary_countSuffix;

  /// No description provided for @monthSummary_previousMonth.
  ///
  /// In zh, this message translates to:
  /// **'上個月'**
  String get monthSummary_previousMonth;

  /// No description provided for @monthSummary_nextMonth.
  ///
  /// In zh, this message translates to:
  /// **'下個月'**
  String get monthSummary_nextMonth;

  /// No description provided for @monthSummary_semanticLabel.
  ///
  /// In zh, this message translates to:
  /// **'{month}月份摘要。總支出：港幣 {amount} 元。共 {count} 筆支出。'**
  String monthSummary_semanticLabel(String month, String amount, int count);

  /// No description provided for @monthSummary_isLatestMonth.
  ///
  /// In zh, this message translates to:
  /// **'已是最新月份'**
  String get monthSummary_isLatestMonth;

  /// No description provided for @export_title.
  ///
  /// In zh, this message translates to:
  /// **'匯出報銷單'**
  String get export_title;

  /// No description provided for @export_preview.
  ///
  /// In zh, this message translates to:
  /// **'預覽'**
  String get export_preview;

  /// No description provided for @export_expenseCount.
  ///
  /// In zh, this message translates to:
  /// **'支出筆數'**
  String get export_expenseCount;

  /// No description provided for @export_totalHkd.
  ///
  /// In zh, this message translates to:
  /// **'港幣總額'**
  String get export_totalHkd;

  /// No description provided for @export_receiptCount.
  ///
  /// In zh, this message translates to:
  /// **'收據圖片'**
  String get export_receiptCount;

  /// No description provided for @export_countUnit.
  ///
  /// In zh, this message translates to:
  /// **'{count} 筆'**
  String export_countUnit(int count);

  /// No description provided for @export_imageUnit.
  ///
  /// In zh, this message translates to:
  /// **'{count} 張'**
  String export_imageUnit(int count);

  /// No description provided for @export_excelWithReceipts.
  ///
  /// In zh, this message translates to:
  /// **'匯出 Excel + 收據'**
  String get export_excelWithReceipts;

  /// No description provided for @export_noData.
  ///
  /// In zh, this message translates to:
  /// **'沒有資料'**
  String get export_noData;

  /// No description provided for @export_noDataMessage.
  ///
  /// In zh, this message translates to:
  /// **'{year} 年 {month} 月沒有支出記錄'**
  String export_noDataMessage(int year, int month);

  /// No description provided for @export_yearMonth.
  ///
  /// In zh, this message translates to:
  /// **'{year} 年 {month} 月'**
  String export_yearMonth(int year, int month);

  /// No description provided for @export_hint.
  ///
  /// In zh, this message translates to:
  /// **'匯出的 Excel 包含完整支出明細'**
  String get export_hint;

  /// No description provided for @export_packing.
  ///
  /// In zh, this message translates to:
  /// **'正在打包...'**
  String get export_packing;

  /// No description provided for @export_generatingExcel.
  ///
  /// In zh, this message translates to:
  /// **'正在生成 Excel...'**
  String get export_generatingExcel;

  /// No description provided for @export_packingReceipts.
  ///
  /// In zh, this message translates to:
  /// **'正在打包收據圖片...'**
  String get export_packingReceipts;

  /// No description provided for @export_compressing.
  ///
  /// In zh, this message translates to:
  /// **'正在壓縮...'**
  String get export_compressing;

  /// No description provided for @export_preparingShare.
  ///
  /// In zh, this message translates to:
  /// **'準備分享...'**
  String get export_preparingShare;

  /// No description provided for @export_success.
  ///
  /// In zh, this message translates to:
  /// **'匯出成功 ({size})'**
  String export_success(String size);

  /// No description provided for @export_failed.
  ///
  /// In zh, this message translates to:
  /// **'匯出失敗: {message}'**
  String export_failed(String message);

  /// No description provided for @export_sheetName.
  ///
  /// In zh, this message translates to:
  /// **'{year}年{month}月報銷單'**
  String export_sheetName(int year, int month);

  /// No description provided for @export_shareSubject.
  ///
  /// In zh, this message translates to:
  /// **'Expense Snap 報銷單'**
  String get export_shareSubject;

  /// No description provided for @export_headerIndex.
  ///
  /// In zh, this message translates to:
  /// **'序號'**
  String get export_headerIndex;

  /// No description provided for @export_headerDate.
  ///
  /// In zh, this message translates to:
  /// **'日期'**
  String get export_headerDate;

  /// No description provided for @export_headerDescription.
  ///
  /// In zh, this message translates to:
  /// **'描述'**
  String get export_headerDescription;

  /// No description provided for @export_headerOriginalAmount.
  ///
  /// In zh, this message translates to:
  /// **'原始金額'**
  String get export_headerOriginalAmount;

  /// No description provided for @export_headerOriginalCurrency.
  ///
  /// In zh, this message translates to:
  /// **'原始幣種'**
  String get export_headerOriginalCurrency;

  /// No description provided for @export_headerExchangeRate.
  ///
  /// In zh, this message translates to:
  /// **'匯率'**
  String get export_headerExchangeRate;

  /// No description provided for @export_headerRateSource.
  ///
  /// In zh, this message translates to:
  /// **'匯率來源'**
  String get export_headerRateSource;

  /// No description provided for @export_headerHkdAmount.
  ///
  /// In zh, this message translates to:
  /// **'港幣金額'**
  String get export_headerHkdAmount;

  /// No description provided for @export_headerReceiptFile.
  ///
  /// In zh, this message translates to:
  /// **'收據檔名'**
  String get export_headerReceiptFile;

  /// No description provided for @export_headerTotal.
  ///
  /// In zh, this message translates to:
  /// **'合計'**
  String get export_headerTotal;

  /// No description provided for @export_rateSourceAuto.
  ///
  /// In zh, this message translates to:
  /// **'自動'**
  String get export_rateSourceAuto;

  /// No description provided for @export_rateSourceOffline.
  ///
  /// In zh, this message translates to:
  /// **'離線快取'**
  String get export_rateSourceOffline;

  /// No description provided for @export_rateSourceDefault.
  ///
  /// In zh, this message translates to:
  /// **'預設'**
  String get export_rateSourceDefault;

  /// No description provided for @export_rateSourceManual.
  ///
  /// In zh, this message translates to:
  /// **'手動'**
  String get export_rateSourceManual;

  /// No description provided for @export_fileName.
  ///
  /// In zh, this message translates to:
  /// **'報銷單_{year}年{month}月'**
  String export_fileName(int year, String month);

  /// No description provided for @settings_title.
  ///
  /// In zh, this message translates to:
  /// **'設定'**
  String get settings_title;

  /// No description provided for @settings_general.
  ///
  /// In zh, this message translates to:
  /// **'一般'**
  String get settings_general;

  /// No description provided for @settings_userName.
  ///
  /// In zh, this message translates to:
  /// **'使用者名稱'**
  String get settings_userName;

  /// No description provided for @settings_userNameHint.
  ///
  /// In zh, this message translates to:
  /// **'用於報銷單標題'**
  String get settings_userNameHint;

  /// No description provided for @settings_language.
  ///
  /// In zh, this message translates to:
  /// **'語言'**
  String get settings_language;

  /// No description provided for @settings_theme.
  ///
  /// In zh, this message translates to:
  /// **'主題'**
  String get settings_theme;

  /// No description provided for @settings_themeLight.
  ///
  /// In zh, this message translates to:
  /// **'淺色'**
  String get settings_themeLight;

  /// No description provided for @settings_themeDark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get settings_themeDark;

  /// No description provided for @settings_themeSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟隨系統'**
  String get settings_themeSystem;

  /// No description provided for @settings_data.
  ///
  /// In zh, this message translates to:
  /// **'資料管理'**
  String get settings_data;

  /// No description provided for @settings_backup.
  ///
  /// In zh, this message translates to:
  /// **'雲端備份'**
  String get settings_backup;

  /// No description provided for @settings_backupDesc.
  ///
  /// In zh, this message translates to:
  /// **'備份至 Google Drive'**
  String get settings_backupDesc;

  /// No description provided for @settings_restore.
  ///
  /// In zh, this message translates to:
  /// **'還原備份'**
  String get settings_restore;

  /// No description provided for @settings_restoreDesc.
  ///
  /// In zh, this message translates to:
  /// **'從 Google Drive 還原'**
  String get settings_restoreDesc;

  /// No description provided for @settings_deletedItems.
  ///
  /// In zh, this message translates to:
  /// **'已刪除項目'**
  String get settings_deletedItems;

  /// No description provided for @settings_deletedItemsDesc.
  ///
  /// In zh, this message translates to:
  /// **'查看或還原已刪除的支出'**
  String get settings_deletedItemsDesc;

  /// No description provided for @settings_clearCache.
  ///
  /// In zh, this message translates to:
  /// **'清理暫存檔'**
  String get settings_clearCache;

  /// No description provided for @settings_about.
  ///
  /// In zh, this message translates to:
  /// **'關於'**
  String get settings_about;

  /// No description provided for @settings_version.
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get settings_version;

  /// No description provided for @settings_privacyPolicy.
  ///
  /// In zh, this message translates to:
  /// **'隱私權政策'**
  String get settings_privacyPolicy;

  /// No description provided for @settings_feedback.
  ///
  /// In zh, this message translates to:
  /// **'意見回饋'**
  String get settings_feedback;

  /// No description provided for @settings_signInGoogle.
  ///
  /// In zh, this message translates to:
  /// **'登入 Google'**
  String get settings_signInGoogle;

  /// No description provided for @settings_signOutGoogle.
  ///
  /// In zh, this message translates to:
  /// **'登出 Google'**
  String get settings_signOutGoogle;

  /// No description provided for @settings_signedInAs.
  ///
  /// In zh, this message translates to:
  /// **'已登入：{email}'**
  String settings_signedInAs(String email);

  /// No description provided for @settings_backupSuccess.
  ///
  /// In zh, this message translates to:
  /// **'備份成功'**
  String get settings_backupSuccess;

  /// No description provided for @settings_backupFailed.
  ///
  /// In zh, this message translates to:
  /// **'備份失敗: {message}'**
  String settings_backupFailed(String message);

  /// No description provided for @settings_restoreSuccess.
  ///
  /// In zh, this message translates to:
  /// **'還原成功'**
  String get settings_restoreSuccess;

  /// No description provided for @settings_restoreFailed.
  ///
  /// In zh, this message translates to:
  /// **'還原失敗: {message}'**
  String settings_restoreFailed(String message);

  /// No description provided for @settings_cacheCleared.
  ///
  /// In zh, this message translates to:
  /// **'快取已清除'**
  String get settings_cacheCleared;

  /// No description provided for @settings_noBackupFound.
  ///
  /// In zh, this message translates to:
  /// **'找不到備份檔案'**
  String get settings_noBackupFound;

  /// No description provided for @settings_confirmRestore.
  ///
  /// In zh, this message translates to:
  /// **'確認還原'**
  String get settings_confirmRestore;

  /// No description provided for @settings_confirmRestoreMessage.
  ///
  /// In zh, this message translates to:
  /// **'還原會覆蓋目前的資料，確定要繼續嗎？'**
  String get settings_confirmRestoreMessage;

  /// No description provided for @settings_lastBackup.
  ///
  /// In zh, this message translates to:
  /// **'上次備份：{date}'**
  String settings_lastBackup(String date);

  /// No description provided for @deletedItems_title.
  ///
  /// In zh, this message translates to:
  /// **'已刪除項目'**
  String get deletedItems_title;

  /// No description provided for @deletedItems_clearAll.
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get deletedItems_clearAll;

  /// No description provided for @deletedItems_daysRemaining.
  ///
  /// In zh, this message translates to:
  /// **'還有 {days} 天自動刪除'**
  String deletedItems_daysRemaining(int days);

  /// No description provided for @deletedItems_soonDeleted.
  ///
  /// In zh, this message translates to:
  /// **'即將自動刪除'**
  String get deletedItems_soonDeleted;

  /// No description provided for @deletedItems_restored.
  ///
  /// In zh, this message translates to:
  /// **'已還原'**
  String get deletedItems_restored;

  /// No description provided for @deletedItems_restoreFailed.
  ///
  /// In zh, this message translates to:
  /// **'還原失敗: {message}'**
  String deletedItems_restoreFailed(String message);

  /// No description provided for @deletedItems_permanentDelete.
  ///
  /// In zh, this message translates to:
  /// **'永久刪除'**
  String get deletedItems_permanentDelete;

  /// No description provided for @deletedItems_permanentDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'此操作無法復原，確定要永久刪除嗎？'**
  String get deletedItems_permanentDeleteConfirm;

  /// No description provided for @deletedItems_permanentDeleted.
  ///
  /// In zh, this message translates to:
  /// **'已永久刪除'**
  String get deletedItems_permanentDeleted;

  /// No description provided for @deletedItems_permanentDeleteFailed.
  ///
  /// In zh, this message translates to:
  /// **'刪除失敗: {message}'**
  String deletedItems_permanentDeleteFailed(String message);

  /// No description provided for @deletedItems_clearAllTitle.
  ///
  /// In zh, this message translates to:
  /// **'清空所有'**
  String get deletedItems_clearAllTitle;

  /// No description provided for @deletedItems_clearAllConfirm.
  ///
  /// In zh, this message translates to:
  /// **'確定要永久刪除全部 {count} 筆記錄嗎？\n此操作無法復原。'**
  String deletedItems_clearAllConfirm(int count);

  /// No description provided for @deletedItems_clearAllButton.
  ///
  /// In zh, this message translates to:
  /// **'全部刪除'**
  String get deletedItems_clearAllButton;

  /// No description provided for @deletedItems_clearedCount.
  ///
  /// In zh, this message translates to:
  /// **'已刪除 {count} 筆記錄'**
  String deletedItems_clearedCount(int count);

  /// No description provided for @deletedItems_loadFailed.
  ///
  /// In zh, this message translates to:
  /// **'載入失敗: {message}'**
  String deletedItems_loadFailed(String message);

  /// No description provided for @onboarding_skip.
  ///
  /// In zh, this message translates to:
  /// **'跳過'**
  String get onboarding_skip;

  /// No description provided for @onboarding_next.
  ///
  /// In zh, this message translates to:
  /// **'下一步'**
  String get onboarding_next;

  /// No description provided for @onboarding_start.
  ///
  /// In zh, this message translates to:
  /// **'開始使用'**
  String get onboarding_start;

  /// No description provided for @onboarding_page1Title.
  ///
  /// In zh, this message translates to:
  /// **'拍照記錄支出'**
  String get onboarding_page1Title;

  /// No description provided for @onboarding_page1Desc.
  ///
  /// In zh, this message translates to:
  /// **'隨手拍攝收據，即時記錄每筆支出\n再也不怕遺失收據'**
  String get onboarding_page1Desc;

  /// No description provided for @onboarding_page2Title.
  ///
  /// In zh, this message translates to:
  /// **'多幣種自動轉換'**
  String get onboarding_page2Title;

  /// No description provided for @onboarding_page2Desc.
  ///
  /// In zh, this message translates to:
  /// **'支援 HKD、CNY、USD\n系統自動取得即時匯率'**
  String get onboarding_page2Desc;

  /// No description provided for @onboarding_page3Title.
  ///
  /// In zh, this message translates to:
  /// **'一鍵匯出報銷單'**
  String get onboarding_page3Title;

  /// No description provided for @onboarding_page3Desc.
  ///
  /// In zh, this message translates to:
  /// **'月結時一鍵匯出 Excel + 收據圖片\n輕鬆完成報銷'**
  String get onboarding_page3Desc;

  /// No description provided for @onboarding_nameLabel.
  ///
  /// In zh, this message translates to:
  /// **'您的名字（選填）'**
  String get onboarding_nameLabel;

  /// No description provided for @onboarding_nameHint.
  ///
  /// In zh, this message translates to:
  /// **'用於報銷單標題'**
  String get onboarding_nameHint;

  /// No description provided for @onboarding_nameTooLong.
  ///
  /// In zh, this message translates to:
  /// **'名字不能超過 50 個字'**
  String get onboarding_nameTooLong;

  /// No description provided for @connectivity_offlineMode.
  ///
  /// In zh, this message translates to:
  /// **'離線模式 - 匯率可能不是最新'**
  String get connectivity_offlineMode;

  /// No description provided for @dialog_duplicateTitle.
  ///
  /// In zh, this message translates to:
  /// **'可能重複'**
  String get dialog_duplicateTitle;

  /// No description provided for @dialog_duplicateMessage.
  ///
  /// In zh, this message translates to:
  /// **'發現相似的支出記錄：'**
  String get dialog_duplicateMessage;

  /// No description provided for @dialog_duplicateConfirm.
  ///
  /// In zh, this message translates to:
  /// **'確定要繼續新增嗎？'**
  String get dialog_duplicateConfirm;

  /// No description provided for @dialog_duplicateContinue.
  ///
  /// In zh, this message translates to:
  /// **'繼續新增'**
  String get dialog_duplicateContinue;

  /// No description provided for @dialog_largeAmountTitle.
  ///
  /// In zh, this message translates to:
  /// **'大金額確認'**
  String get dialog_largeAmountTitle;

  /// No description provided for @dialog_largeAmountMessage.
  ///
  /// In zh, this message translates to:
  /// **'您即將記錄一筆大金額支出：'**
  String get dialog_largeAmountMessage;

  /// No description provided for @dialog_largeAmountConfirm.
  ///
  /// In zh, this message translates to:
  /// **'請確認金額是否正確？'**
  String get dialog_largeAmountConfirm;

  /// No description provided for @dialog_largeAmountBack.
  ///
  /// In zh, this message translates to:
  /// **'返回修改'**
  String get dialog_largeAmountBack;

  /// No description provided for @dialog_largeAmountOk.
  ///
  /// In zh, this message translates to:
  /// **'確認正確'**
  String get dialog_largeAmountOk;

  /// No description provided for @dialog_monthEndTitle.
  ///
  /// In zh, this message translates to:
  /// **'月底提醒'**
  String get dialog_monthEndTitle;

  /// No description provided for @dialog_monthEndMessage.
  ///
  /// In zh, this message translates to:
  /// **'本月即將結束！'**
  String get dialog_monthEndMessage;

  /// No description provided for @dialog_monthEndExpenseCount.
  ///
  /// In zh, this message translates to:
  /// **'您本月共有 {count} 筆支出記錄'**
  String dialog_monthEndExpenseCount(int count);

  /// No description provided for @dialog_monthEndSuggestion.
  ///
  /// In zh, this message translates to:
  /// **'建議您匯出報銷單，以便月結報銷。'**
  String get dialog_monthEndSuggestion;

  /// No description provided for @dialog_later.
  ///
  /// In zh, this message translates to:
  /// **'稍後'**
  String get dialog_later;

  /// No description provided for @dialog_goExport.
  ///
  /// In zh, this message translates to:
  /// **'去匯出'**
  String get dialog_goExport;

  /// No description provided for @emptyState_noExpenses.
  ///
  /// In zh, this message translates to:
  /// **'暫無支出記錄'**
  String get emptyState_noExpenses;

  /// No description provided for @emptyState_noExpensesHint.
  ///
  /// In zh, this message translates to:
  /// **'點擊右下角按鈕新增第一筆支出'**
  String get emptyState_noExpensesHint;

  /// No description provided for @emptyState_noDeletedItems.
  ///
  /// In zh, this message translates to:
  /// **'沒有已刪除的項目'**
  String get emptyState_noDeletedItems;

  /// No description provided for @emptyState_noDeletedItemsHint.
  ///
  /// In zh, this message translates to:
  /// **'刪除的支出會在這裡保留 30 天'**
  String get emptyState_noDeletedItemsHint;

  /// No description provided for @emptyState_error.
  ///
  /// In zh, this message translates to:
  /// **'載入失敗'**
  String get emptyState_error;

  /// No description provided for @emptyState_offline.
  ///
  /// In zh, this message translates to:
  /// **'無網路連線'**
  String get emptyState_offline;

  /// No description provided for @emptyState_offlineHint.
  ///
  /// In zh, this message translates to:
  /// **'請檢查您的網路設定'**
  String get emptyState_offlineHint;

  /// No description provided for @emptyState_exportSuccess.
  ///
  /// In zh, this message translates to:
  /// **'匯出成功'**
  String get emptyState_exportSuccess;

  /// No description provided for @emptyState_exportSuccessHint.
  ///
  /// In zh, this message translates to:
  /// **'檔案已準備就緒'**
  String get emptyState_exportSuccessHint;

  /// No description provided for @excel_header_index.
  ///
  /// In zh, this message translates to:
  /// **'序號'**
  String get excel_header_index;

  /// No description provided for @excel_header_date.
  ///
  /// In zh, this message translates to:
  /// **'日期'**
  String get excel_header_date;

  /// No description provided for @excel_header_description.
  ///
  /// In zh, this message translates to:
  /// **'描述'**
  String get excel_header_description;

  /// No description provided for @excel_header_originalAmount.
  ///
  /// In zh, this message translates to:
  /// **'原始金額'**
  String get excel_header_originalAmount;

  /// No description provided for @excel_header_originalCurrency.
  ///
  /// In zh, this message translates to:
  /// **'原始幣種'**
  String get excel_header_originalCurrency;

  /// No description provided for @excel_header_exchangeRate.
  ///
  /// In zh, this message translates to:
  /// **'匯率'**
  String get excel_header_exchangeRate;

  /// No description provided for @excel_header_rateSource.
  ///
  /// In zh, this message translates to:
  /// **'匯率來源'**
  String get excel_header_rateSource;

  /// No description provided for @excel_header_hkdAmount.
  ///
  /// In zh, this message translates to:
  /// **'港幣金額'**
  String get excel_header_hkdAmount;

  /// No description provided for @excel_header_receiptFile.
  ///
  /// In zh, this message translates to:
  /// **'收據檔名'**
  String get excel_header_receiptFile;

  /// No description provided for @excel_total.
  ///
  /// In zh, this message translates to:
  /// **'合計'**
  String get excel_total;

  /// No description provided for @excel_sheetName.
  ///
  /// In zh, this message translates to:
  /// **'{year}年{month}月報銷單'**
  String excel_sheetName(int year, int month);

  /// No description provided for @excel_fileName.
  ///
  /// In zh, this message translates to:
  /// **'報銷單_{year}年{month}月'**
  String excel_fileName(int year, String month);

  /// No description provided for @excel_shareSubject.
  ///
  /// In zh, this message translates to:
  /// **'Expense Snap 報銷單'**
  String get excel_shareSubject;

  /// No description provided for @excel_rateSourceAuto.
  ///
  /// In zh, this message translates to:
  /// **'自動'**
  String get excel_rateSourceAuto;

  /// No description provided for @excel_rateSourceOffline.
  ///
  /// In zh, this message translates to:
  /// **'離線快取'**
  String get excel_rateSourceOffline;

  /// No description provided for @excel_rateSourceDefault.
  ///
  /// In zh, this message translates to:
  /// **'預設'**
  String get excel_rateSourceDefault;

  /// No description provided for @excel_rateSourceManual.
  ///
  /// In zh, this message translates to:
  /// **'手動'**
  String get excel_rateSourceManual;

  /// No description provided for @error_unknown.
  ///
  /// In zh, this message translates to:
  /// **'發生未知錯誤'**
  String get error_unknown;

  /// No description provided for @error_networkError.
  ///
  /// In zh, this message translates to:
  /// **'網路連線錯誤'**
  String get error_networkError;

  /// No description provided for @error_serverError.
  ///
  /// In zh, this message translates to:
  /// **'伺服器錯誤'**
  String get error_serverError;

  /// No description provided for @error_storageError.
  ///
  /// In zh, this message translates to:
  /// **'儲存空間錯誤'**
  String get error_storageError;

  /// No description provided for @error_permissionDenied.
  ///
  /// In zh, this message translates to:
  /// **'權限被拒絕'**
  String get error_permissionDenied;

  /// No description provided for @error_fileNotFound.
  ///
  /// In zh, this message translates to:
  /// **'檔案不存在'**
  String get error_fileNotFound;

  /// No description provided for @error_invalidData.
  ///
  /// In zh, this message translates to:
  /// **'資料格式錯誤'**
  String get error_invalidData;

  /// No description provided for @error_exportNoData.
  ///
  /// In zh, this message translates to:
  /// **'沒有資料可匯出'**
  String get error_exportNoData;

  /// No description provided for @error_invalidMonth.
  ///
  /// In zh, this message translates to:
  /// **'月份必須介於 1 到 12 之間'**
  String get error_invalidMonth;

  /// No description provided for @error_invalidYear.
  ///
  /// In zh, this message translates to:
  /// **'年份必須介於 2000 到 2100 之間'**
  String get error_invalidYear;

  /// No description provided for @error_excelGenerationFailed.
  ///
  /// In zh, this message translates to:
  /// **'無法生成 Excel 檔案'**
  String get error_excelGenerationFailed;

  /// No description provided for @error_zipFailed.
  ///
  /// In zh, this message translates to:
  /// **'無法壓縮檔案'**
  String get error_zipFailed;

  /// No description provided for @error_shareFailed.
  ///
  /// In zh, this message translates to:
  /// **'分享失敗'**
  String get error_shareFailed;

  /// No description provided for @error_cleanupFailed.
  ///
  /// In zh, this message translates to:
  /// **'清理暫存檔案失敗'**
  String get error_cleanupFailed;

  /// No description provided for @format_date.
  ///
  /// In zh, this message translates to:
  /// **'yyyy/MM/dd'**
  String get format_date;

  /// No description provided for @format_dateTime.
  ///
  /// In zh, this message translates to:
  /// **'yyyy/MM/dd HH:mm'**
  String get format_dateTime;

  /// No description provided for @format_month.
  ///
  /// In zh, this message translates to:
  /// **'yyyy年M月'**
  String get format_month;

  /// No description provided for @format_currency.
  ///
  /// In zh, this message translates to:
  /// **'#,##0.00'**
  String get format_currency;

  /// No description provided for @currency_HKD.
  ///
  /// In zh, this message translates to:
  /// **'港幣'**
  String get currency_HKD;

  /// No description provided for @currency_CNY.
  ///
  /// In zh, this message translates to:
  /// **'人民幣'**
  String get currency_CNY;

  /// No description provided for @currency_USD.
  ///
  /// In zh, this message translates to:
  /// **'美元'**
  String get currency_USD;

  /// No description provided for @datePicker_selectDate.
  ///
  /// In zh, this message translates to:
  /// **'選擇日期'**
  String get datePicker_selectDate;

  /// No description provided for @datePicker_selectMonth.
  ///
  /// In zh, this message translates to:
  /// **'選擇月份'**
  String get datePicker_selectMonth;

  /// No description provided for @settings_profile.
  ///
  /// In zh, this message translates to:
  /// **'個人資料'**
  String get settings_profile;

  /// No description provided for @settings_appearance.
  ///
  /// In zh, this message translates to:
  /// **'外觀'**
  String get settings_appearance;

  /// No description provided for @settings_reduceMotion.
  ///
  /// In zh, this message translates to:
  /// **'減少動畫'**
  String get settings_reduceMotion;

  /// No description provided for @settings_reduceMotionDesc.
  ///
  /// In zh, this message translates to:
  /// **'減少動態效果，適合動暈症患者'**
  String get settings_reduceMotionDesc;

  /// No description provided for @settings_storageUsage.
  ///
  /// In zh, this message translates to:
  /// **'本地儲存使用量'**
  String get settings_storageUsage;

  /// No description provided for @settings_clearCacheDesc.
  ///
  /// In zh, this message translates to:
  /// **'釋放匯出和備份暫存空間'**
  String get settings_clearCacheDesc;

  /// No description provided for @settings_cloudBackup.
  ///
  /// In zh, this message translates to:
  /// **'雲端備份'**
  String get settings_cloudBackup;

  /// No description provided for @settings_googleDrive.
  ///
  /// In zh, this message translates to:
  /// **'Google 雲端硬碟'**
  String get settings_googleDrive;

  /// No description provided for @settings_lastBackupTime.
  ///
  /// In zh, this message translates to:
  /// **'上次備份'**
  String get settings_lastBackupTime;

  /// No description provided for @settings_backupNow.
  ///
  /// In zh, this message translates to:
  /// **'立即備份'**
  String get settings_backupNow;

  /// No description provided for @settings_backupNowDesc.
  ///
  /// In zh, this message translates to:
  /// **'備份資料庫和收據到 Google 雲端硬碟'**
  String get settings_backupNowDesc;

  /// No description provided for @settings_restoreBackupTitle.
  ///
  /// In zh, this message translates to:
  /// **'還原備份'**
  String get settings_restoreBackupTitle;

  /// No description provided for @settings_restoreBackupDesc.
  ///
  /// In zh, this message translates to:
  /// **'從 Google 雲端硬碟還原'**
  String get settings_restoreBackupDesc;

  /// No description provided for @settings_selectBackup.
  ///
  /// In zh, this message translates to:
  /// **'選擇備份'**
  String get settings_selectBackup;

  /// No description provided for @settings_connect.
  ///
  /// In zh, this message translates to:
  /// **'連接'**
  String get settings_connect;

  /// No description provided for @settings_disconnect.
  ///
  /// In zh, this message translates to:
  /// **'斷開'**
  String get settings_disconnect;

  /// No description provided for @settings_connected.
  ///
  /// In zh, this message translates to:
  /// **'已連接'**
  String get settings_connected;

  /// No description provided for @settings_notConnected.
  ///
  /// In zh, this message translates to:
  /// **'尚未連接'**
  String get settings_notConnected;

  /// No description provided for @settings_languageSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟隨系統'**
  String get settings_languageSystem;

  /// No description provided for @settings_selectTheme.
  ///
  /// In zh, this message translates to:
  /// **'選擇主題'**
  String get settings_selectTheme;

  /// No description provided for @settings_editName.
  ///
  /// In zh, this message translates to:
  /// **'編輯姓名'**
  String get settings_editName;

  /// No description provided for @settings_nameLabel.
  ///
  /// In zh, this message translates to:
  /// **'姓名'**
  String get settings_nameLabel;

  /// No description provided for @settings_nameHint.
  ///
  /// In zh, this message translates to:
  /// **'用於報銷單標題'**
  String get settings_nameHint;

  /// No description provided for @settings_saved.
  ///
  /// In zh, this message translates to:
  /// **'已儲存'**
  String get settings_saved;

  /// No description provided for @settings_cleanupFailed.
  ///
  /// In zh, this message translates to:
  /// **'清理失敗: {message}'**
  String settings_cleanupFailed(String message);

  /// No description provided for @settings_cleanedFiles.
  ///
  /// In zh, this message translates to:
  /// **'已清理 {count} 個暫存檔案'**
  String settings_cleanedFiles(int count);

  /// No description provided for @settings_backupToCloud.
  ///
  /// In zh, this message translates to:
  /// **'備份到雲端'**
  String get settings_backupToCloud;

  /// No description provided for @settings_backupConfirmMessage.
  ///
  /// In zh, this message translates to:
  /// **'這將備份所有支出記錄和收據圖片到 Google 雲端硬碟。\n\n繼續？'**
  String get settings_backupConfirmMessage;

  /// No description provided for @settings_confirmRestoreTitle.
  ///
  /// In zh, this message translates to:
  /// **'確認還原'**
  String get settings_confirmRestoreTitle;

  /// No description provided for @settings_confirmRestoreDesc.
  ///
  /// In zh, this message translates to:
  /// **'這將使用 \"{fileName}\" 取代目前所有資料。\n\n此操作無法復原，確定要繼續嗎？'**
  String settings_confirmRestoreDesc(String fileName);

  /// No description provided for @settings_disconnectTitle.
  ///
  /// In zh, this message translates to:
  /// **'斷開 Google 帳號'**
  String get settings_disconnectTitle;

  /// No description provided for @settings_disconnectConfirm.
  ///
  /// In zh, this message translates to:
  /// **'斷開後將無法使用雲端備份功能。\n\n確定要斷開嗎？'**
  String get settings_disconnectConfirm;

  /// No description provided for @settings_connectFailed.
  ///
  /// In zh, this message translates to:
  /// **'連接失敗: {message}'**
  String settings_connectFailed(String message);

  /// No description provided for @settings_disconnectFailed.
  ///
  /// In zh, this message translates to:
  /// **'斷開失敗: {message}'**
  String settings_disconnectFailed(String message);

  /// No description provided for @settings_googleConnected.
  ///
  /// In zh, this message translates to:
  /// **'已連接 Google 帳號'**
  String get settings_googleConnected;

  /// No description provided for @settings_googleDisconnected.
  ///
  /// In zh, this message translates to:
  /// **'已斷開 Google 帳號'**
  String get settings_googleDisconnected;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'zh':
      return SZh();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
