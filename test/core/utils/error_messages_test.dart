import 'package:expense_snap/core/utils/error_messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ErrorMessages', () {
    group('getMessage', () {
      test('應回傳網絡錯誤的用戶友善訊息', () {
        expect(ErrorMessages.getMessage('NO_CONNECTION'), '請檢查網絡連線後再試');
        expect(ErrorMessages.getMessage('TIMEOUT'), '請求逾時，請稍後再試');
        expect(ErrorMessages.getMessage('SERVER_ERROR'), '伺服器暫時無法回應，請稍後再試');
      });

      test('應回傳儲存錯誤的用戶友善訊息', () {
        expect(ErrorMessages.getMessage('INSUFFICIENT_SPACE'), '儲存空間不足，請清理後再試');
        expect(ErrorMessages.getMessage('FILE_NOT_FOUND'), '找不到檔案，請重新操作');
        expect(ErrorMessages.getMessage('WRITE_ERROR'), '無法儲存檔案，請檢查權限');
      });

      test('應回傳資料庫錯誤的用戶友善訊息', () {
        expect(ErrorMessages.getMessage('DB_LOCKED'), '資料正在處理中，請稍後再試');
        expect(ErrorMessages.getMessage('DB_CORRUPTED'), '資料庫損壞，請嘗試從備份還原');
      });

      test('應回傳驗證錯誤的用戶友善訊息', () {
        expect(ErrorMessages.getMessage('REQUIRED'), '請填寫必填欄位');
        expect(ErrorMessages.getMessage('OUT_OF_RANGE'), '輸入的數值超出有效範圍');
      });

      test('應回傳認證錯誤的用戶友善訊息', () {
        expect(ErrorMessages.getMessage('NOT_SIGNED_IN'), '請先登入 Google 帳號');
        expect(ErrorMessages.getMessage('TOKEN_EXPIRED'), '登入已過期，請重新登入');
      });

      test('未知錯誤代碼應回傳預設訊息', () {
        expect(ErrorMessages.getMessage('UNKNOWN_CODE'), '發生未知錯誤');
      });

      test('null 錯誤代碼應回傳預設訊息', () {
        expect(ErrorMessages.getMessage(null), '發生未知錯誤');
      });

      test('應使用提供的 fallback 訊息', () {
        expect(
          ErrorMessages.getMessage('UNKNOWN', fallbackMessage: '自訂訊息'),
          '自訂訊息',
        );
        expect(
          ErrorMessages.getMessage(null, fallbackMessage: '自訂訊息'),
          '自訂訊息',
        );
      });
    });

    group('isRetryable', () {
      test('網絡和伺服器錯誤應可重試', () {
        expect(ErrorMessages.isRetryable('NO_CONNECTION'), isTrue);
        expect(ErrorMessages.isRetryable('TIMEOUT'), isTrue);
        expect(ErrorMessages.isRetryable('SERVER_ERROR'), isTrue);
      });

      test('資料庫鎖定錯誤應可重試', () {
        expect(ErrorMessages.isRetryable('DB_LOCKED'), isTrue);
        expect(ErrorMessages.isRetryable('QUERY_FAILED'), isTrue);
      });

      test('其他錯誤不可重試', () {
        expect(ErrorMessages.isRetryable('DB_CORRUPTED'), isFalse);
        expect(ErrorMessages.isRetryable('INSUFFICIENT_SPACE'), isFalse);
        expect(ErrorMessages.isRetryable('REQUIRED'), isFalse);
      });

      test('null 錯誤代碼不可重試', () {
        expect(ErrorMessages.isRetryable(null), isFalse);
      });
    });

    group('getSuggestedAction', () {
      test('網絡錯誤應有建議動作', () {
        expect(
          ErrorMessages.getSuggestedAction('NO_CONNECTION'),
          '請連接網絡後點擊重試',
        );
      });

      test('空間不足應有建議動作', () {
        expect(
          ErrorMessages.getSuggestedAction('INSUFFICIENT_SPACE'),
          '請刪除一些檔案後重試',
        );
      });

      test('資料庫損壞應有建議動作', () {
        expect(
          ErrorMessages.getSuggestedAction('DB_CORRUPTED'),
          '前往設定頁面從雲端備份還原',
        );
      });

      test('Token 過期應有建議動作', () {
        expect(
          ErrorMessages.getSuggestedAction('TOKEN_EXPIRED'),
          '前往設定頁面重新登入',
        );
      });

      test('一般錯誤沒有特定建議動作', () {
        expect(ErrorMessages.getSuggestedAction('TIMEOUT'), isNull);
        expect(ErrorMessages.getSuggestedAction('REQUIRED'), isNull);
        expect(ErrorMessages.getSuggestedAction(null), isNull);
      });
    });
  });
}
