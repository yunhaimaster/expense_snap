// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class SJa extends S {
  SJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Expense Snap';

  @override
  String get common_save => '保存';

  @override
  String get common_cancel => 'キャンセル';

  @override
  String get common_delete => '削除';

  @override
  String get common_edit => '編集';

  @override
  String get common_retry => '再試行';

  @override
  String get common_confirm => '確認';

  @override
  String get common_back => '戻る';

  @override
  String get common_skip => 'スキップ';

  @override
  String get common_next => '次へ';

  @override
  String get common_done => '完了';

  @override
  String get common_close => '閉じる';

  @override
  String get common_restore => '復元';

  @override
  String get common_clear => 'クリア';

  @override
  String get common_share => '共有';

  @override
  String get common_loading => '読み込み中...';

  @override
  String get common_saving => '保存中...';

  @override
  String get common_processing => '処理中...';

  @override
  String get nav_home => 'ホーム';

  @override
  String get nav_export => 'エクスポート';

  @override
  String get nav_settings => '設定';

  @override
  String get home_addExpense => '支出を追加';

  @override
  String get home_deleteSuccess => '支出を削除しました';

  @override
  String home_deleteFailed(String message) {
    return '削除に失敗しました: $message';
  }

  @override
  String get home_undo => '元に戻す';

  @override
  String get showcase_addExpenseTitle => '支出を追加';

  @override
  String get showcase_addExpenseDesc => 'ここをタップして写真を撮り、支出を記録します';

  @override
  String get showcase_swipeDeleteTitle => 'スワイプで削除';

  @override
  String get showcase_swipeDeleteDesc => '左にスワイプすると支出を削除できます';

  @override
  String get showcase_exportTitle => 'レポートをエクスポート';

  @override
  String get showcase_exportDesc => 'ここをタップしてExcelとレシートをエクスポート';

  @override
  String get addExpense_title => '支出を追加';

  @override
  String get addExpense_receiptImage => 'レシート画像';

  @override
  String get addExpense_camera => 'カメラ';

  @override
  String get addExpense_gallery => 'ギャラリー';

  @override
  String get addExpense_amount => '金額';

  @override
  String get addExpense_description => '説明';

  @override
  String get addExpense_descriptionHint => '説明を入力...';

  @override
  String get addExpense_date => '日付';

  @override
  String get addExpense_currency => '通貨';

  @override
  String get addExpense_exchangeRate => '為替レート';

  @override
  String get addExpense_manualInput => '手動入力';

  @override
  String get addExpense_ocrProcessing => 'レシートを認識中...';

  @override
  String get addExpense_ocrSuccess => 'レシート内容を認識しました';

  @override
  String get addExpense_ocrSuccessVerify => 'レシート内容を認識しました。確認してください';

  @override
  String get addExpense_success => '支出を追加しました';

  @override
  String get addExpense_invalidAmount => '有効な金額を入力してください';

  @override
  String get expenseDetail_title => '支出詳細';

  @override
  String get expenseDetail_editTitle => '支出を編集';

  @override
  String get expenseDetail_amount => '金額';

  @override
  String get expenseDetail_hkdAmount => 'HKD金額';

  @override
  String get expenseDetail_exchangeRate => '為替レート';

  @override
  String get expenseDetail_description => '説明';

  @override
  String get expenseDetail_descriptionRequired => '説明を入力してください';

  @override
  String get expenseDetail_date => '日付';

  @override
  String get expenseDetail_createdAt => '作成日時';

  @override
  String get expenseDetail_replaceImage => '画像を変更';

  @override
  String get expenseDetail_imageLoadFailed => '画像の読み込みに失敗しました';

  @override
  String get expenseDetail_noReceipt => 'レシート画像なし';

  @override
  String get expenseDetail_cancelEdit => '編集をキャンセル';

  @override
  String get expenseDetail_saved => '保存しました';

  @override
  String expenseDetail_saveFailed(String message) {
    return '保存に失敗しました: $message';
  }

  @override
  String get expenseDetail_deleted => '削除しました';

  @override
  String expenseDetail_deleteFailed(String message) {
    return '削除に失敗しました: $message';
  }

  @override
  String get expenseDetail_confirmDelete => '削除の確認';

  @override
  String get expenseDetail_confirmDeleteMessage =>
      'この支出を削除しますか？\n削除済みアイテムから復元できます。';

  @override
  String get expenseDetail_expenseNotFound => '支出が見つかりません';

  @override
  String get expenseDetail_imageReplaceSuccess => '画像を変更しました';

  @override
  String expenseDetail_imageReplaceFailed(String message) {
    return '画像の変更に失敗しました: $message';
  }

  @override
  String get expenseDetail_selectFromGallery => 'ギャラリーから選択';

  @override
  String get rateSource_auto => 'リアルタイムレート';

  @override
  String get rateSource_offline => 'キャッシュされたレート';

  @override
  String get rateSource_default => 'デフォルトレート';

  @override
  String get rateSource_manual => '手動入力';

  @override
  String get rateSource_auto_short => 'リアルタイム';

  @override
  String get rateSource_offline_short => 'キャッシュ';

  @override
  String get rateSource_default_short => 'デフォルト';

  @override
  String get rateSource_manual_short => '手動';

  @override
  String get monthSummary_totalExpense => '合計支出';

  @override
  String get monthSummary_count => '件数';

  @override
  String get monthSummary_countSuffix => '件';

  @override
  String get monthSummary_previousMonth => '前月';

  @override
  String get monthSummary_nextMonth => '翌月';

  @override
  String monthSummary_semanticLabel(String month, String amount, int count) {
    return '$monthの概要。合計支出：HKD $amount。$count件の支出。';
  }

  @override
  String get monthSummary_isLatestMonth => '最新の月です';

  @override
  String get export_title => 'レポートをエクスポート';

  @override
  String get export_preview => 'プレビュー';

  @override
  String get export_expenseCount => '支出件数';

  @override
  String get export_totalHkd => 'HKD合計';

  @override
  String get export_receiptCount => 'レシート画像';

  @override
  String export_countUnit(int count) {
    return '$count件';
  }

  @override
  String export_imageUnit(int count) {
    return '$count枚';
  }

  @override
  String get export_excelWithReceipts => 'Excel + レシートをエクスポート';

  @override
  String get export_noData => 'データなし';

  @override
  String export_noDataMessage(int year, int month) {
    return '$year年$month月の支出記録はありません';
  }

  @override
  String export_yearMonth(int year, int month) {
    return '$year年$month月';
  }

  @override
  String get export_hint => 'エクスポートされたExcelには完全な支出明細が含まれます';

  @override
  String get export_packing => 'パッキング中...';

  @override
  String get export_generatingExcel => 'Excel生成中...';

  @override
  String get export_packingReceipts => 'レシート画像をパッキング中...';

  @override
  String get export_compressing => '圧縮中...';

  @override
  String get export_preparingShare => '共有の準備中...';

  @override
  String export_success(String size) {
    return 'エクスポート成功 ($size)';
  }

  @override
  String export_failed(String message) {
    return 'エクスポートに失敗しました: $message';
  }

  @override
  String export_sheetName(int year, int month) {
    return '$year年$month月経費精算書';
  }

  @override
  String get export_shareSubject => 'Expense Snap レポート';

  @override
  String get export_headerIndex => 'No.';

  @override
  String get export_headerDate => '日付';

  @override
  String get export_headerDescription => '説明';

  @override
  String get export_headerOriginalAmount => '元の金額';

  @override
  String get export_headerOriginalCurrency => '通貨';

  @override
  String get export_headerExchangeRate => '為替レート';

  @override
  String get export_headerRateSource => 'レート出典';

  @override
  String get export_headerHkdAmount => 'HKD金額';

  @override
  String get export_headerReceiptFile => 'レシート';

  @override
  String get export_headerTotal => '合計';

  @override
  String get export_rateSourceAuto => '自動';

  @override
  String get export_rateSourceOffline => 'オフラインキャッシュ';

  @override
  String get export_rateSourceDefault => 'デフォルト';

  @override
  String get export_rateSourceManual => '手動';

  @override
  String export_fileName(int year, String month) {
    return '経費精算書_$year年$month月';
  }

  @override
  String get settings_title => '設定';

  @override
  String get settings_general => '一般';

  @override
  String get settings_userName => 'ユーザー名';

  @override
  String get settings_userNameHint => 'レポートのタイトルに使用';

  @override
  String get settings_language => '言語';

  @override
  String get settings_theme => 'テーマ';

  @override
  String get settings_themeLight => 'ライト';

  @override
  String get settings_themeDark => 'ダーク';

  @override
  String get settings_themeSystem => 'システム設定に従う';

  @override
  String get settings_data => 'データ管理';

  @override
  String get settings_backup => 'クラウドバックアップ';

  @override
  String get settings_backupDesc => 'Google ドライブにバックアップ';

  @override
  String get settings_restore => 'バックアップを復元';

  @override
  String get settings_restoreDesc => 'Google ドライブから復元';

  @override
  String get settings_deletedItems => '削除済みアイテム';

  @override
  String get settings_deletedItemsDesc => '削除した支出を表示または復元';

  @override
  String get settings_clearCache => '一時ファイルを削除';

  @override
  String get settings_about => 'アプリについて';

  @override
  String get settings_version => 'バージョン';

  @override
  String get settings_privacyPolicy => 'プライバシーポリシー';

  @override
  String get settings_termsOfService => '利用規約';

  @override
  String get settings_feedback => 'フィードバック';

  @override
  String get legal_privacyContent =>
      'プライバシーポリシー\n\n最終更新日：2026年1月\n\n1. データ収集\n当アプリは、お客様が入力した支出記録、レシート画像、個人設定のみを収集します。\n\n2. データ保存\nすべてのデータはお客様のデバイスにローカルで保存されます。クラウドバックアップ機能を使用する場合、データはお客様のGoogleドライブアカウントに同期されます。\n\n3. データ使用\n当アプリはお客様のデータを広告に使用したり、第三者と共有したりしません。\n\n4. データ削除\nアプリ内のすべてのデータはいつでも削除できます。削除されたアイテムは30日間保持された後、完全に削除されます。\n\n5. お問い合わせ\nプライバシーに関するご質問は、アプリ内のフィードバック機能からお問い合わせください。';

  @override
  String get legal_termsContent =>
      '利用規約\n\n最終更新日：2026年1月\n\n1. サービス内容\nExpense Snapは、日々の支出を記録・管理するための個人向け経費追跡アプリです。\n\n2. 利用条件\n本アプリを使用することで、これらの規約に同意したものとみなされます。\n\n3. 責任の制限\n本アプリは「現状のまま」提供されます。データの損失やその他の間接的な損害について、当社は責任を負いません。\n\n4. 知的財産権\n本アプリのすべてのコンテンツと機能は著作権で保護されています。\n\n5. 規約の変更\n当社はいつでもこれらの規約を変更する権利を留保します。継続して使用することで、変更後の規約に同意したものとみなされます。';

  @override
  String get settings_signInGoogle => 'Googleでサインイン';

  @override
  String get settings_signOutGoogle => 'サインアウト';

  @override
  String settings_signedInAs(String email) {
    return 'ログイン中：$email';
  }

  @override
  String get settings_backupSuccess => 'バックアップ成功';

  @override
  String settings_backupFailed(String message) {
    return 'バックアップに失敗しました: $message';
  }

  @override
  String get settings_restoreSuccess => '復元成功';

  @override
  String settings_restoreFailed(String message) {
    return '復元に失敗しました: $message';
  }

  @override
  String get settings_cacheCleared => 'キャッシュを削除しました';

  @override
  String get settings_noBackupFound => 'バックアップが見つかりません';

  @override
  String get settings_confirmRestore => '復元の確認';

  @override
  String get settings_confirmRestoreMessage => '復元すると現在のデータが上書きされます。続行しますか？';

  @override
  String settings_lastBackup(String date) {
    return '最終バックアップ：$date';
  }

  @override
  String get deletedItems_title => '削除済みアイテム';

  @override
  String get deletedItems_clearAll => 'すべてクリア';

  @override
  String deletedItems_daysRemaining(int days) {
    return 'あと$days日で自動削除';
  }

  @override
  String get deletedItems_soonDeleted => 'まもなく削除されます';

  @override
  String get deletedItems_restored => '復元しました';

  @override
  String deletedItems_restoreFailed(String message) {
    return '復元に失敗しました: $message';
  }

  @override
  String get deletedItems_permanentDelete => '完全に削除';

  @override
  String get deletedItems_permanentDeleteConfirm => 'この操作は元に戻せません。完全に削除しますか？';

  @override
  String get deletedItems_permanentDeleted => '完全に削除しました';

  @override
  String deletedItems_permanentDeleteFailed(String message) {
    return '削除に失敗しました: $message';
  }

  @override
  String get deletedItems_clearAllTitle => 'すべてクリア';

  @override
  String deletedItems_clearAllConfirm(int count) {
    return '$count件すべてを完全に削除しますか？\nこの操作は元に戻せません。';
  }

  @override
  String get deletedItems_clearAllButton => 'すべて削除';

  @override
  String deletedItems_clearedCount(int count) {
    return '$count件削除しました';
  }

  @override
  String deletedItems_loadFailed(String message) {
    return '読み込みに失敗しました: $message';
  }

  @override
  String get onboarding_skip => 'スキップ';

  @override
  String get onboarding_next => '次へ';

  @override
  String get onboarding_start => '始める';

  @override
  String get onboarding_page1Title => 'レシートを撮影';

  @override
  String get onboarding_page1Desc => 'レシートをすぐに撮影して支出を記録\nもうレシートを失くしません';

  @override
  String get onboarding_page2Title => '複数通貨対応';

  @override
  String get onboarding_page2Desc => 'HKD、CNY、USDに対応\n為替レートを自動取得';

  @override
  String get onboarding_page3Title => 'ワンクリックでエクスポート';

  @override
  String get onboarding_page3Desc => 'Excel + レシート画像をエクスポート\n簡単に経費精算';

  @override
  String get onboarding_nameLabel => 'お名前（任意）';

  @override
  String get onboarding_nameHint => 'レポートのタイトルに使用';

  @override
  String get onboarding_nameTooLong => '名前は50文字以内にしてください';

  @override
  String get connectivity_offlineMode => 'オフラインモード - 為替レートが最新でない可能性があります';

  @override
  String get dialog_duplicateTitle => '重複の可能性';

  @override
  String get dialog_duplicateMessage => '類似の支出が見つかりました：';

  @override
  String get dialog_duplicateConfirm => '追加を続けますか？';

  @override
  String get dialog_duplicateContinue => '追加する';

  @override
  String get dialog_largeAmountTitle => '高額支出';

  @override
  String get dialog_largeAmountMessage => '高額な支出を記録しようとしています：';

  @override
  String get dialog_largeAmountConfirm => '金額は正しいですか？';

  @override
  String get dialog_largeAmountBack => '戻る';

  @override
  String get dialog_largeAmountOk => '確認';

  @override
  String get dialog_monthEndTitle => '月末リマインダー';

  @override
  String get dialog_monthEndMessage => '今月もうすぐ終わります！';

  @override
  String dialog_monthEndExpenseCount(int count) {
    return '今月は$count件の支出があります';
  }

  @override
  String get dialog_monthEndSuggestion => '経費レポートのエクスポートをお勧めします。';

  @override
  String get dialog_later => '後で';

  @override
  String get dialog_goExport => 'エクスポートへ';

  @override
  String get emptyState_noExpenses => '支出なし';

  @override
  String get emptyState_noExpensesHint => '下のボタンをタップして最初の支出を追加';

  @override
  String get emptyState_noDeletedItems => '削除済みアイテムなし';

  @override
  String get emptyState_noDeletedItemsHint => '削除された支出は30日間保持されます';

  @override
  String get emptyState_error => '読み込みに失敗';

  @override
  String get emptyState_offline => 'インターネット接続なし';

  @override
  String get emptyState_offlineHint => 'ネットワーク設定を確認してください';

  @override
  String get emptyState_exportSuccess => 'エクスポート成功';

  @override
  String get emptyState_exportSuccessHint => 'ファイルの準備ができました';

  @override
  String get excel_header_index => 'No.';

  @override
  String get excel_header_date => '日付';

  @override
  String get excel_header_description => '説明';

  @override
  String get excel_header_originalAmount => '元の金額';

  @override
  String get excel_header_originalCurrency => '通貨';

  @override
  String get excel_header_exchangeRate => '為替レート';

  @override
  String get excel_header_rateSource => 'レート出典';

  @override
  String get excel_header_hkdAmount => 'HKD金額';

  @override
  String get excel_header_receiptFile => 'レシートファイル';

  @override
  String get excel_total => '合計';

  @override
  String excel_sheetName(int year, int month) {
    return '経費_$year年$month月';
  }

  @override
  String excel_fileName(int year, String month) {
    return '経費_$year年$month月';
  }

  @override
  String get excel_shareSubject => 'Expense Snap レポート';

  @override
  String get excel_rateSourceAuto => '自動';

  @override
  String get excel_rateSourceOffline => 'キャッシュ';

  @override
  String get excel_rateSourceDefault => 'デフォルト';

  @override
  String get excel_rateSourceManual => '手動';

  @override
  String get error_unknown => '不明なエラーが発生しました';

  @override
  String get error_networkError => 'ネットワーク接続エラー';

  @override
  String get error_serverError => 'サーバーエラー';

  @override
  String get error_storageError => 'ストレージエラー';

  @override
  String get error_permissionDenied => '権限が拒否されました';

  @override
  String get error_fileNotFound => 'ファイルが見つかりません';

  @override
  String get error_invalidData => '無効なデータ形式';

  @override
  String get error_exportNoData => 'エクスポートするデータがありません';

  @override
  String get error_invalidMonth => '月は1から12の間で指定してください';

  @override
  String get error_invalidYear => '年は2000から2100の間で指定してください';

  @override
  String get error_excelGenerationFailed => 'Excelファイルの生成に失敗しました';

  @override
  String get error_zipFailed => 'ファイルの圧縮に失敗しました';

  @override
  String get error_shareFailed => '共有に失敗しました';

  @override
  String get error_cleanupFailed => '一時ファイルの削除に失敗しました';

  @override
  String get format_date => 'yyyy/MM/dd';

  @override
  String get format_dateTime => 'yyyy/MM/dd HH:mm';

  @override
  String get format_month => 'yyyy年M月';

  @override
  String get format_currency => '#,##0.00';

  @override
  String get currency_HKD => '香港ドル';

  @override
  String get currency_CNY => '人民元';

  @override
  String get currency_USD => '米ドル';

  @override
  String get datePicker_selectDate => '日付を選択';

  @override
  String get datePicker_selectMonth => '月を選択';

  @override
  String get settings_profile => 'プロフィール';

  @override
  String get settings_appearance => '外観';

  @override
  String get settings_reduceMotion => 'モーションを減らす';

  @override
  String get settings_reduceMotionDesc => 'アニメーションを減らします（動きに敏感な方向け）';

  @override
  String get settings_storageUsage => 'ストレージ使用量';

  @override
  String get settings_clearCacheDesc => 'エクスポートとバックアップのキャッシュを削除';

  @override
  String get settings_cloudBackup => 'クラウドバックアップ';

  @override
  String get settings_googleDrive => 'Google ドライブ';

  @override
  String get settings_lastBackupTime => '最終バックアップ';

  @override
  String get settings_backupNow => '今すぐバックアップ';

  @override
  String get settings_backupNowDesc => 'データベースとレシートをGoogle ドライブにバックアップ';

  @override
  String get settings_restoreBackupTitle => 'バックアップを復元';

  @override
  String get settings_restoreBackupDesc => 'Google ドライブから復元';

  @override
  String get settings_selectBackup => 'バックアップを選択';

  @override
  String get settings_connect => '接続';

  @override
  String get settings_disconnect => '切断';

  @override
  String get settings_connected => '接続済み';

  @override
  String get settings_notConnected => '未接続';

  @override
  String get settings_languageSystem => 'システム設定に従う';

  @override
  String get settings_selectTheme => 'テーマを選択';

  @override
  String get settings_editName => '名前を編集';

  @override
  String get settings_nameLabel => '名前';

  @override
  String get settings_nameHint => '経費レポートのタイトルに使用';

  @override
  String get settings_saved => '保存しました';

  @override
  String settings_cleanupFailed(String message) {
    return 'クリーンアップに失敗しました: $message';
  }

  @override
  String settings_cleanedFiles(int count) {
    return '$count個の一時ファイルを削除しました';
  }

  @override
  String get settings_backupToCloud => 'クラウドにバックアップ';

  @override
  String get settings_backupConfirmMessage =>
      'すべての支出とレシートをGoogle ドライブにバックアップします。\n\n続行しますか？';

  @override
  String get settings_confirmRestoreTitle => '復元の確認';

  @override
  String settings_confirmRestoreDesc(String fileName) {
    return '現在のすべてのデータが「$fileName」で置き換えられます。\n\nこの操作は元に戻せません。続行しますか？';
  }

  @override
  String get settings_disconnectTitle => 'Googleアカウントを切断';

  @override
  String get settings_disconnectConfirm =>
      '切断するとクラウドバックアップが使用できなくなります。\n\n切断しますか？';

  @override
  String settings_connectFailed(String message) {
    return '接続に失敗しました: $message';
  }

  @override
  String settings_disconnectFailed(String message) {
    return '切断に失敗しました: $message';
  }

  @override
  String get settings_googleConnected => 'Googleアカウントに接続しました';

  @override
  String get settings_googleDisconnected => 'Googleアカウントを切断しました';

  @override
  String get category_label => 'カテゴリ（任意）';

  @override
  String get category_meals => '食事';

  @override
  String get category_transport => '交通';

  @override
  String get category_accommodation => '宿泊';

  @override
  String get category_officeSupplies => '事務用品';

  @override
  String get category_communication => '通信';

  @override
  String get category_entertainment => '娯楽';

  @override
  String get category_medical => '医療';

  @override
  String get category_other => 'その他';

  @override
  String get category_statistics => 'カテゴリ統計';

  @override
  String get category_uncategorized => '未分類';

  @override
  String get excel_header_category => 'カテゴリ';

  @override
  String get semantic_category_prefix => 'カテゴリ';

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
    return '元の金額：$amount';
  }

  @override
  String semantic_date(String date) {
    return '日付：$date';
  }

  @override
  String semantic_rateSource(String source) {
    return 'レート出典：$source';
  }

  @override
  String get semantic_hasReceipt => 'レシート画像あり';

  @override
  String get semantic_tapForDetails => 'タップして詳細を表示';

  @override
  String get semantic_swipeToDelete => '左にスワイプして削除';

  @override
  String get validation_amountRequired => '金額を入力してください';

  @override
  String validation_amountTooSmall(num min) {
    return '金額は$min以上にしてください';
  }

  @override
  String validation_amountTooLarge(num max) {
    return '金額は$max以下にしてください';
  }

  @override
  String get validation_exchangeRateLabel => '為替レート';

  @override
  String validation_exchangeRateHint(String currency) {
    return '1 $currency = ? HKD';
  }

  @override
  String get validation_exchangeRateRequired => '為替レートを入力してください';

  @override
  String get validation_exchangeRateInvalid => '有効な為替レートを入力してください';
}
