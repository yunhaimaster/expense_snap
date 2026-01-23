// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class SKo extends S {
  SKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Expense Snap';

  @override
  String get common_save => '저장';

  @override
  String get common_cancel => '취소';

  @override
  String get common_delete => '삭제';

  @override
  String get common_edit => '편집';

  @override
  String get common_retry => '재시도';

  @override
  String get common_confirm => '확인';

  @override
  String get common_back => '뒤로';

  @override
  String get common_skip => '건너뛰기';

  @override
  String get common_next => '다음';

  @override
  String get common_done => '완료';

  @override
  String get common_close => '닫기';

  @override
  String get common_restore => '복원';

  @override
  String get common_clear => '지우기';

  @override
  String get common_share => '공유';

  @override
  String get common_loading => '로딩 중...';

  @override
  String get common_saving => '저장 중...';

  @override
  String get common_processing => '처리 중...';

  @override
  String get nav_home => '홈';

  @override
  String get nav_export => '내보내기';

  @override
  String get nav_settings => '설정';

  @override
  String get home_addExpense => '지출 추가';

  @override
  String get home_deleteSuccess => '지출이 삭제되었습니다';

  @override
  String home_deleteFailed(String message) {
    return '삭제 실패: $message';
  }

  @override
  String get home_undo => '실행 취소';

  @override
  String get showcase_addExpenseTitle => '지출 추가';

  @override
  String get showcase_addExpenseDesc => '여기를 탭하여 사진을 찍고 지출을 기록하세요';

  @override
  String get showcase_swipeDeleteTitle => '스와이프하여 삭제';

  @override
  String get showcase_swipeDeleteDesc => '왼쪽으로 스와이프하면 지출을 삭제할 수 있습니다';

  @override
  String get showcase_exportTitle => '보고서 내보내기';

  @override
  String get showcase_exportDesc => '여기를 탭하여 Excel과 영수증을 내보내세요';

  @override
  String get addExpense_title => '지출 추가';

  @override
  String get addExpense_receiptImage => '영수증 이미지';

  @override
  String get addExpense_camera => '카메라';

  @override
  String get addExpense_gallery => '갤러리';

  @override
  String get addExpense_amount => '금액';

  @override
  String get addExpense_description => '설명';

  @override
  String get addExpense_descriptionHint => '설명을 입력하세요...';

  @override
  String get addExpense_date => '날짜';

  @override
  String get addExpense_currency => '통화';

  @override
  String get addExpense_exchangeRate => '환율';

  @override
  String get addExpense_manualInput => '수동 입력';

  @override
  String get addExpense_ocrProcessing => '영수증 인식 중...';

  @override
  String get addExpense_ocrSuccess => '영수증 내용을 인식했습니다';

  @override
  String get addExpense_ocrSuccessVerify => '영수증 내용을 인식했습니다. 확인해 주세요';

  @override
  String get addExpense_success => '지출이 추가되었습니다';

  @override
  String get addExpense_invalidAmount => '유효한 금액을 입력하세요';

  @override
  String get addExpense_invalidExchangeRate => '환율은 0보다 커야 합니다';

  @override
  String get expenseDetail_title => '지출 상세';

  @override
  String get expenseDetail_editTitle => '지출 편집';

  @override
  String get expenseDetail_amount => '금액';

  @override
  String get expenseDetail_hkdAmount => 'HKD 금액';

  @override
  String get expenseDetail_exchangeRate => '환율';

  @override
  String get expenseDetail_description => '설명';

  @override
  String get expenseDetail_descriptionRequired => '설명을 입력하세요';

  @override
  String get expenseDetail_date => '날짜';

  @override
  String get expenseDetail_createdAt => '생성일';

  @override
  String get expenseDetail_replaceImage => '이미지 변경';

  @override
  String get expenseDetail_imageLoadFailed => '이미지 로드 실패';

  @override
  String get expenseDetail_noReceipt => '영수증 이미지 없음';

  @override
  String get expenseDetail_cancelEdit => '편집 취소';

  @override
  String get expenseDetail_saved => '저장되었습니다';

  @override
  String expenseDetail_saveFailed(String message) {
    return '저장 실패: $message';
  }

  @override
  String get expenseDetail_deleted => '삭제되었습니다';

  @override
  String expenseDetail_deleteFailed(String message) {
    return '삭제 실패: $message';
  }

  @override
  String get expenseDetail_confirmDelete => '삭제 확인';

  @override
  String get expenseDetail_confirmDeleteMessage =>
      '이 지출을 삭제하시겠습니까?\n삭제된 항목에서 복원할 수 있습니다.';

  @override
  String get expenseDetail_expenseNotFound => '지출을 찾을 수 없습니다';

  @override
  String get expenseDetail_imageReplaceSuccess => '이미지가 변경되었습니다';

  @override
  String expenseDetail_imageReplaceFailed(String message) {
    return '이미지 변경 실패: $message';
  }

  @override
  String get expenseDetail_selectFromGallery => '갤러리에서 선택';

  @override
  String get rateSource_auto => '실시간 환율';

  @override
  String get rateSource_offline => '캐시된 환율';

  @override
  String get rateSource_default => '기본 환율';

  @override
  String get rateSource_manual => '수동 입력';

  @override
  String get rateSource_auto_short => '실시간';

  @override
  String get rateSource_offline_short => '캐시';

  @override
  String get rateSource_default_short => '기본';

  @override
  String get rateSource_manual_short => '수동';

  @override
  String get monthSummary_totalExpense => '총 지출';

  @override
  String get monthSummary_count => '건수';

  @override
  String get monthSummary_countSuffix => '건';

  @override
  String get monthSummary_previousMonth => '이전 달';

  @override
  String get monthSummary_nextMonth => '다음 달';

  @override
  String monthSummary_semanticLabel(String month, String amount, int count) {
    return '$month 요약. 총 지출: HKD $amount. $count건의 지출.';
  }

  @override
  String get monthSummary_isLatestMonth => '최신 월입니다';

  @override
  String get monthSummary_mixedCurrencies => '다중 통화';

  @override
  String get export_title => '보고서 내보내기';

  @override
  String get export_preview => '미리보기';

  @override
  String get export_expenseCount => '지출 건수';

  @override
  String get export_totalHkd => 'HKD 합계';

  @override
  String get export_receiptCount => '영수증 이미지';

  @override
  String export_countUnit(int count) {
    return '$count건';
  }

  @override
  String export_imageUnit(int count) {
    return '$count장';
  }

  @override
  String get export_excelWithReceipts => 'Excel + 영수증 내보내기';

  @override
  String get export_noData => '데이터 없음';

  @override
  String export_noDataMessage(int year, int month) {
    return '$year년 $month월 지출 기록이 없습니다';
  }

  @override
  String export_yearMonth(int year, int month) {
    return '$year년 $month월';
  }

  @override
  String get export_hint => '내보낸 Excel에는 전체 지출 내역이 포함됩니다';

  @override
  String get export_packing => '패키징 중...';

  @override
  String get export_generatingExcel => 'Excel 생성 중...';

  @override
  String get export_packingReceipts => '영수증 이미지 패키징 중...';

  @override
  String get export_compressing => '압축 중...';

  @override
  String get export_preparingShare => '공유 준비 중...';

  @override
  String export_success(String size) {
    return '내보내기 성공 ($size)';
  }

  @override
  String export_failed(String message) {
    return '내보내기 실패: $message';
  }

  @override
  String export_sheetName(int year, int month) {
    return '$year년 $month월 경비 보고서';
  }

  @override
  String get export_shareSubject => 'Expense Snap 보고서';

  @override
  String get export_headerIndex => '번호';

  @override
  String get export_headerDate => '날짜';

  @override
  String get export_headerDescription => '설명';

  @override
  String get export_headerOriginalAmount => '원래 금액';

  @override
  String get export_headerOriginalCurrency => '통화';

  @override
  String get export_headerExchangeRate => '환율';

  @override
  String get export_headerRateSource => '환율 출처';

  @override
  String get export_headerHkdAmount => 'HKD 금액';

  @override
  String get export_headerReceiptFile => '영수증';

  @override
  String get export_headerTotal => '합계';

  @override
  String get export_rateSourceAuto => '자동';

  @override
  String get export_rateSourceOffline => '오프라인 캐시';

  @override
  String get export_rateSourceDefault => '기본';

  @override
  String get export_rateSourceManual => '수동';

  @override
  String export_fileName(int year, String month) {
    return '경비보고서_$year년$month월';
  }

  @override
  String get settings_title => '설정';

  @override
  String get settings_general => '일반';

  @override
  String get settings_userName => '사용자 이름';

  @override
  String get settings_userNameHint => '보고서 제목에 사용됩니다';

  @override
  String get settings_language => '언어';

  @override
  String get settings_theme => '테마';

  @override
  String get settings_themeLight => '라이트';

  @override
  String get settings_themeDark => '다크';

  @override
  String get settings_themeSystem => '시스템 설정';

  @override
  String get settings_data => '데이터 관리';

  @override
  String get settings_backup => '클라우드 백업';

  @override
  String get settings_backupDesc => 'Google 드라이브에 백업';

  @override
  String get settings_restore => '백업 복원';

  @override
  String get settings_restoreDesc => 'Google 드라이브에서 복원';

  @override
  String get settings_deletedItems => '삭제된 항목';

  @override
  String get settings_deletedItemsDesc => '삭제된 지출 보기 또는 복원';

  @override
  String get settings_clearCache => '임시 파일 삭제';

  @override
  String get settings_about => '정보';

  @override
  String get settings_version => '버전';

  @override
  String get settings_privacyPolicy => '개인정보 보호정책';

  @override
  String get settings_termsOfService => '서비스 약관';

  @override
  String get settings_feedback => '피드백';

  @override
  String get legal_privacyContent =>
      '개인정보 보호정책\n\n최종 업데이트: 2026년 1월\n\n1. 데이터 수집\n본 앱은 사용자가 입력한 지출 기록, 영수증 이미지, 개인 설정만 수집합니다.\n\n2. 데이터 저장\n모든 데이터는 사용자의 기기에 로컬로 저장됩니다. 클라우드 백업 기능을 사용하는 경우 데이터는 사용자의 Google 드라이브 계정에 동기화됩니다.\n\n3. 데이터 사용\n본 앱은 사용자의 데이터를 광고에 사용하거나 제3자와 공유하지 않습니다.\n\n4. 데이터 삭제\n앱 내의 모든 데이터는 언제든지 삭제할 수 있습니다. 삭제된 항목은 30일 후 영구 삭제됩니다.\n\n5. 문의\n개인정보 관련 질문은 앱 내 피드백 기능을 통해 문의해 주세요.';

  @override
  String get legal_termsContent =>
      '서비스 약관\n\n최종 업데이트: 2026년 1월\n\n1. 서비스 설명\nExpense Snap은 일상 지출을 기록하고 관리할 수 있는 개인 경비 추적 앱입니다.\n\n2. 이용 약관\n본 앱을 사용함으로써 이 약관에 동의하는 것으로 간주됩니다.\n\n3. 책임 제한\n본 앱은 \"있는 그대로\" 제공됩니다. 데이터 손실이나 기타 간접적 손해에 대해 당사는 책임지지 않습니다.\n\n4. 지적 재산권\n본 앱의 모든 콘텐츠와 기능은 저작권으로 보호됩니다.\n\n5. 약관 변경\n당사는 언제든지 이 약관을 변경할 권리가 있습니다. 계속 사용하면 변경된 약관에 동의하는 것으로 간주됩니다.';

  @override
  String get settings_signInGoogle => 'Google로 로그인';

  @override
  String get settings_signOutGoogle => '로그아웃';

  @override
  String settings_signedInAs(String email) {
    return '로그인됨: $email';
  }

  @override
  String get settings_backupSuccess => '백업 성공';

  @override
  String settings_backupFailed(String message) {
    return '백업 실패: $message';
  }

  @override
  String get settings_restoreSuccess => '복원 성공';

  @override
  String settings_restoreFailed(String message) {
    return '복원 실패: $message';
  }

  @override
  String get settings_cacheCleared => '캐시가 삭제되었습니다';

  @override
  String get settings_noBackupFound => '백업을 찾을 수 없습니다';

  @override
  String get settings_confirmRestore => '복원 확인';

  @override
  String get settings_confirmRestoreMessage =>
      '복원하면 현재 데이터가 덮어씌워집니다. 계속하시겠습니까?';

  @override
  String settings_lastBackup(String date) {
    return '마지막 백업: $date';
  }

  @override
  String get deletedItems_title => '삭제된 항목';

  @override
  String get deletedItems_clearAll => '모두 지우기';

  @override
  String deletedItems_daysRemaining(int days) {
    return '$days일 후 자동 삭제';
  }

  @override
  String get deletedItems_soonDeleted => '곧 삭제됩니다';

  @override
  String get deletedItems_restored => '복원되었습니다';

  @override
  String deletedItems_restoreFailed(String message) {
    return '복원 실패: $message';
  }

  @override
  String get deletedItems_permanentDelete => '영구 삭제';

  @override
  String get deletedItems_permanentDeleteConfirm =>
      '이 작업은 취소할 수 없습니다. 영구 삭제하시겠습니까?';

  @override
  String get deletedItems_permanentDeleted => '영구 삭제되었습니다';

  @override
  String deletedItems_permanentDeleteFailed(String message) {
    return '삭제 실패: $message';
  }

  @override
  String get deletedItems_clearAllTitle => '모두 지우기';

  @override
  String deletedItems_clearAllConfirm(int count) {
    return '$count개 항목을 모두 영구 삭제하시겠습니까?\n이 작업은 취소할 수 없습니다.';
  }

  @override
  String get deletedItems_clearAllButton => '모두 삭제';

  @override
  String deletedItems_clearedCount(int count) {
    return '$count개 항목이 삭제되었습니다';
  }

  @override
  String deletedItems_loadFailed(String message) {
    return '로드 실패: $message';
  }

  @override
  String get onboarding_skip => '건너뛰기';

  @override
  String get onboarding_next => '다음';

  @override
  String get onboarding_start => '시작하기';

  @override
  String get onboarding_page1Title => '영수증 촬영';

  @override
  String get onboarding_page1Desc =>
      '영수증을 바로 촬영하여 지출을 기록하세요\n영수증을 다시는 잃어버리지 마세요';

  @override
  String get onboarding_page2Title => '다중 통화 지원';

  @override
  String get onboarding_page2Desc => 'HKD, CNY, USD 지원\n실시간 환율 자동 적용';

  @override
  String get onboarding_page3Title => '원클릭 내보내기';

  @override
  String get onboarding_page3Desc => 'Excel + 영수증 이미지 내보내기\n간편한 경비 정산';

  @override
  String get onboarding_selectCurrencyTitle => '결제 통화 선택';

  @override
  String get onboarding_selectCurrencyDesc => '지출이 자동으로 이 통화로 변환됩니다';

  @override
  String get onboarding_nameLabel => '이름 (선택사항)';

  @override
  String get onboarding_nameHint => '보고서 제목에 사용됩니다';

  @override
  String get onboarding_nameTooLong => '이름은 50자를 초과할 수 없습니다';

  @override
  String get connectivity_offlineMode => '오프라인 모드 - 환율이 최신이 아닐 수 있습니다';

  @override
  String get dialog_duplicateTitle => '중복 가능성';

  @override
  String get dialog_duplicateMessage => '유사한 지출이 발견되었습니다:';

  @override
  String get dialog_duplicateConfirm => '계속 추가하시겠습니까?';

  @override
  String get dialog_duplicateContinue => '계속 추가';

  @override
  String get dialog_largeAmountTitle => '대금액 확인';

  @override
  String get dialog_largeAmountMessage => '대금액 지출을 기록하려고 합니다:';

  @override
  String get dialog_largeAmountConfirm => '금액이 맞습니까?';

  @override
  String get dialog_largeAmountBack => '뒤로';

  @override
  String get dialog_largeAmountOk => '확인';

  @override
  String get dialog_monthEndTitle => '월말 알림';

  @override
  String get dialog_monthEndMessage => '이번 달이 곧 끝납니다!';

  @override
  String dialog_monthEndExpenseCount(int count) {
    return '이번 달 $count건의 지출이 있습니다';
  }

  @override
  String get dialog_monthEndSuggestion => '경비 보고서를 내보내는 것을 권장합니다.';

  @override
  String get dialog_later => '나중에';

  @override
  String get dialog_goExport => '내보내기로 이동';

  @override
  String get emptyState_noExpenses => '지출 없음';

  @override
  String get emptyState_noExpensesHint => '아래 버튼을 탭하여 첫 번째 지출을 추가하세요';

  @override
  String get emptyState_noDeletedItems => '삭제된 항목 없음';

  @override
  String get emptyState_noDeletedItemsHint => '삭제된 지출은 30일간 보관됩니다';

  @override
  String get emptyState_error => '로드 실패';

  @override
  String get emptyState_offline => '인터넷 연결 없음';

  @override
  String get emptyState_offlineHint => '네트워크 설정을 확인하세요';

  @override
  String get emptyState_exportSuccess => '내보내기 성공';

  @override
  String get emptyState_exportSuccessHint => '파일이 준비되었습니다';

  @override
  String get excel_header_index => '번호';

  @override
  String get excel_header_date => '날짜';

  @override
  String get excel_header_description => '설명';

  @override
  String get excel_header_originalAmount => '원래 금액';

  @override
  String get excel_header_originalCurrency => '통화';

  @override
  String get excel_header_exchangeRate => '환율';

  @override
  String get excel_header_rateSource => '환율 출처';

  @override
  String get excel_header_hkdAmount => 'HKD 금액';

  @override
  String get excel_header_receiptFile => '영수증 파일';

  @override
  String get excel_total => '합계';

  @override
  String excel_sheetName(int year, int month) {
    return '지출_$year년$month월';
  }

  @override
  String excel_fileName(int year, String month) {
    return '지출_$year년$month월';
  }

  @override
  String get excel_shareSubject => 'Expense Snap 보고서';

  @override
  String get excel_rateSourceAuto => '자동';

  @override
  String get excel_rateSourceOffline => '캐시';

  @override
  String get excel_rateSourceDefault => '기본';

  @override
  String get excel_rateSourceManual => '수동';

  @override
  String get error_unknown => '알 수 없는 오류가 발생했습니다';

  @override
  String get error_networkError => '네트워크 연결 오류';

  @override
  String get error_serverError => '서버 오류';

  @override
  String get error_storageError => '저장 공간 오류';

  @override
  String get error_permissionDenied => '권한이 거부되었습니다';

  @override
  String get error_fileNotFound => '파일을 찾을 수 없습니다';

  @override
  String get error_invalidData => '잘못된 데이터 형식';

  @override
  String get error_exportNoData => '내보낼 데이터가 없습니다';

  @override
  String get error_invalidMonth => '월은 1에서 12 사이여야 합니다';

  @override
  String get error_invalidYear => '연도는 2000에서 2100 사이여야 합니다';

  @override
  String get error_excelGenerationFailed => 'Excel 파일 생성 실패';

  @override
  String get error_zipFailed => '파일 압축 실패';

  @override
  String get error_shareFailed => '공유 실패';

  @override
  String get error_cleanupFailed => '임시 파일 삭제 실패';

  @override
  String get format_date => 'yyyy/MM/dd';

  @override
  String get format_dateTime => 'yyyy/MM/dd HH:mm';

  @override
  String get format_month => 'yyyy년 M월';

  @override
  String get format_currency => '#,##0.00';

  @override
  String get currency_HKD => '홍콩 달러';

  @override
  String get currency_CNY => '위안';

  @override
  String get currency_USD => '미국 달러';

  @override
  String get currency_EUR => '유로';

  @override
  String get currency_GBP => '영국 파운드';

  @override
  String get currency_JPY => '일본 엔';

  @override
  String get currency_TWD => '대만 달러';

  @override
  String get currency_KRW => '한국 원';

  @override
  String get currency_SGD => '싱가포르 달러';

  @override
  String get currency_AUD => '호주 달러';

  @override
  String get datePicker_selectDate => '날짜 선택';

  @override
  String get datePicker_selectMonth => '월 선택';

  @override
  String get settings_profile => '프로필';

  @override
  String get settings_appearance => '외관';

  @override
  String get settings_reduceMotion => '모션 줄이기';

  @override
  String get settings_reduceMotionDesc => '움직임에 민감한 분들을 위해 애니메이션을 줄입니다';

  @override
  String get settings_storageUsage => '저장 공간 사용량';

  @override
  String get settings_clearCacheDesc => '내보내기 및 백업 캐시 공간 확보';

  @override
  String get settings_cloudBackup => '클라우드 백업';

  @override
  String get settings_googleDrive => 'Google 드라이브';

  @override
  String get settings_lastBackupTime => '마지막 백업';

  @override
  String get settings_backupNow => '지금 백업';

  @override
  String get settings_backupNowDesc => '데이터베이스와 영수증을 Google 드라이브에 백업';

  @override
  String get settings_restoreBackupTitle => '백업 복원';

  @override
  String get settings_restoreBackupDesc => 'Google 드라이브에서 복원';

  @override
  String get settings_selectBackup => '백업 선택';

  @override
  String get settings_connect => '연결';

  @override
  String get settings_disconnect => '연결 해제';

  @override
  String get settings_connected => '연결됨';

  @override
  String get settings_notConnected => '연결되지 않음';

  @override
  String get settings_languageSystem => '시스템 설정';

  @override
  String get settings_primaryCurrency => '기본 통화';

  @override
  String get settings_selectCurrency => '통화 선택';

  @override
  String get settings_changeCurrencyWarning => '변경 사항은 향후 지출에만 적용됩니다';

  @override
  String get settings_selectTheme => '테마 선택';

  @override
  String get settings_editName => '이름 편집';

  @override
  String get settings_nameLabel => '이름';

  @override
  String get settings_nameHint => '경비 보고서 제목에 사용됩니다';

  @override
  String get settings_saved => '저장되었습니다';

  @override
  String settings_cleanupFailed(String message) {
    return '정리 실패: $message';
  }

  @override
  String settings_cleanedFiles(int count) {
    return '$count개의 임시 파일이 삭제되었습니다';
  }

  @override
  String get settings_backupToCloud => '클라우드에 백업';

  @override
  String get settings_backupConfirmMessage =>
      '모든 지출과 영수증을 Google 드라이브에 백업합니다.\n\n계속하시겠습니까?';

  @override
  String get settings_confirmRestoreTitle => '복원 확인';

  @override
  String settings_confirmRestoreDesc(String fileName) {
    return '현재 모든 데이터가 \"$fileName\"(으)로 교체됩니다.\n\n이 작업은 취소할 수 없습니다. 계속하시겠습니까?';
  }

  @override
  String get settings_disconnectTitle => 'Google 계정 연결 해제';

  @override
  String get settings_disconnectConfirm =>
      '연결 해제 후 클라우드 백업을 사용할 수 없습니다.\n\n연결을 해제하시겠습니까?';

  @override
  String settings_connectFailed(String message) {
    return '연결 실패: $message';
  }

  @override
  String settings_disconnectFailed(String message) {
    return '연결 해제 실패: $message';
  }

  @override
  String get settings_googleConnected => 'Google 계정에 연결되었습니다';

  @override
  String get settings_googleDisconnected => 'Google 계정 연결이 해제되었습니다';

  @override
  String get category_label => '카테고리 (선택사항)';

  @override
  String get category_meals => '식사';

  @override
  String get category_transport => '교통';

  @override
  String get category_accommodation => '숙박';

  @override
  String get category_officeSupplies => '사무용품';

  @override
  String get category_communication => '통신';

  @override
  String get category_entertainment => '오락';

  @override
  String get category_medical => '의료';

  @override
  String get category_other => '기타';

  @override
  String get category_statistics => '카테고리 통계';

  @override
  String get category_uncategorized => '미분류';

  @override
  String get excel_header_category => '카테고리';

  @override
  String get semantic_category_prefix => '카테고리';

  @override
  String semantic_expenseItem(String description) {
    return '지출 항목: $description';
  }

  @override
  String semantic_amount(String amount) {
    return '금액: $amount';
  }

  @override
  String semantic_originalAmount(String amount) {
    return '원래 금액: $amount';
  }

  @override
  String semantic_date(String date) {
    return '날짜: $date';
  }

  @override
  String semantic_rateSource(String source) {
    return '환율 출처: $source';
  }

  @override
  String get semantic_hasReceipt => '영수증 이미지 있음';

  @override
  String get semantic_tapForDetails => '탭하여 상세 보기';

  @override
  String get semantic_swipeToDelete => '왼쪽으로 스와이프하여 삭제';

  @override
  String get validation_amountRequired => '금액을 입력하세요';

  @override
  String validation_amountTooSmall(num min) {
    return '금액은 $min 이상이어야 합니다';
  }

  @override
  String validation_amountTooLarge(num max) {
    return '금액은 $max를 초과할 수 없습니다';
  }

  @override
  String get validation_exchangeRateLabel => '환율';

  @override
  String validation_exchangeRateHint(String currency) {
    return '1 $currency = ? HKD';
  }

  @override
  String get validation_exchangeRateRequired => '환율을 입력하세요';

  @override
  String get validation_exchangeRateInvalid => '유효한 환율을 입력하세요';

  @override
  String get rate_forceUpdated => '환율이 강제 업데이트되었습니다';

  @override
  String get rate_loading => '환율을 가져오는 중...';

  @override
  String get error_title => '오류';

  @override
  String get error_invalidExpenseId => '잘못된 지출 ID';

  @override
  String get error_pageNotFound => '페이지를 찾을 수 없습니다';
}
