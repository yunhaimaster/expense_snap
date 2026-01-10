// 儲存權限拒絕測試 - 驗證無權限時的應用程式行為
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:image_picker/image_picker.dart';

import 'package:expense_snap/core/errors/app_exception.dart';
import 'package:expense_snap/core/errors/result.dart';
import 'package:expense_snap/services/image_service.dart';

@GenerateMocks([ImagePicker])
import 'storage_permission_test.mocks.dart';

void main() {
  late MockImagePicker mockImagePicker;
  late ImageService imageService;

  setUp(() {
    mockImagePicker = MockImagePicker();
    imageService = ImageService(picker: mockImagePicker);
  });

  group('相機權限拒絕測試', () {
    test('相機權限拒絕應返回 CAMERA_ERROR', () async {
      // 模擬權限被拒絕（PlatformException）
      when(mockImagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: anyNamed('preferredCameraDevice'),
      )).thenThrow(Exception('Permission denied'));

      final result = await imageService.pickFromCamera();

      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('應該失敗'),
        onFailure: (error) {
          expect(error, isA<StorageException>());
          expect(error.code, 'CAMERA_ERROR');
        },
      );
    });

    test('使用者取消拍照應返回 CANCELLED', () async {
      // 使用者取消（返回 null）
      when(mockImagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: anyNamed('preferredCameraDevice'),
      )).thenAnswer((_) async => null);

      final result = await imageService.pickFromCamera();

      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('應該失敗'),
        onFailure: (error) {
          expect(error, isA<StorageException>());
          expect(error.code, 'CANCELLED');
        },
      );
    });

    test('相機不可用應返回錯誤', () async {
      when(mockImagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: anyNamed('preferredCameraDevice'),
      )).thenThrow(Exception('Camera not available'));

      final result = await imageService.pickFromCamera();

      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('應該失敗'),
        onFailure: (error) {
          expect(error, isA<StorageException>());
          expect(error.message.contains('無法開啟相機'), isTrue);
        },
      );
    });
  });

  group('相簿權限拒絕測試', () {
    test('相簿權限拒絕應返回 GALLERY_ERROR', () async {
      when(mockImagePicker.pickImage(
        source: ImageSource.gallery,
      )).thenThrow(Exception('Permission denied'));

      final result = await imageService.pickFromGallery();

      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('應該失敗'),
        onFailure: (error) {
          expect(error, isA<StorageException>());
          expect(error.code, 'GALLERY_ERROR');
        },
      );
    });

    test('使用者取消選擇應返回 CANCELLED', () async {
      when(mockImagePicker.pickImage(
        source: ImageSource.gallery,
      )).thenAnswer((_) async => null);

      final result = await imageService.pickFromGallery();

      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('應該失敗'),
        onFailure: (error) {
          expect(error, isA<StorageException>());
          expect(error.code, 'CANCELLED');
        },
      );
    });

    test('相簿不可用應返回錯誤', () async {
      when(mockImagePicker.pickImage(
        source: ImageSource.gallery,
      )).thenThrow(Exception('Gallery not available'));

      final result = await imageService.pickFromGallery();

      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('應該失敗'),
        onFailure: (error) {
          expect(error, isA<StorageException>());
          expect(error.message.contains('無法開啟相簿'), isTrue);
        },
      );
    });
  });

  group('StorageException 類型測試', () {
    test('insufficientSpace 應有正確代碼', () {
      final exception = StorageException.insufficientSpace();

      expect(exception.code, 'INSUFFICIENT_SPACE');
      expect(exception.message.contains('儲存空間不足'), isTrue);
    });

    test('fileNotFound 應包含路徑', () {
      const testPath = '/test/file.jpg';
      final exception = StorageException.fileNotFound(testPath);

      expect(exception.code, 'FILE_NOT_FOUND');
      expect(exception.message.contains(testPath), isTrue);
    });

    test('writeError 應包含路徑', () {
      const testPath = '/test/file.jpg';
      final exception = StorageException.writeError(testPath);

      expect(exception.code, 'WRITE_ERROR');
      expect(exception.message.contains(testPath), isTrue);
    });

    test('readError 應包含路徑', () {
      const testPath = '/test/file.jpg';
      final exception = StorageException.readError(testPath);

      expect(exception.code, 'READ_ERROR');
      expect(exception.message.contains(testPath), isTrue);
    });

    test('unsafePath 應包含路徑', () {
      const testPath = '../etc/passwd';
      final exception = StorageException.unsafePath(testPath);

      expect(exception.code, 'UNSAFE_PATH');
      expect(exception.message.contains(testPath), isTrue);
    });
  });

  group('權限錯誤恢復測試', () {
    test('權限錯誤後重試應能成功', () async {
      var callCount = 0;

      when(mockImagePicker.pickImage(
        source: ImageSource.gallery,
      )).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          throw Exception('Permission denied');
        }
        return XFile('/test/image.jpg');
      });

      // 第一次失敗
      final result1 = await imageService.pickFromGallery();
      expect(result1.isFailure, isTrue);

      // 第二次成功
      final result2 = await imageService.pickFromGallery();
      expect(result2.isSuccess, isTrue);
      expect(callCount, 2);
    });

    test('多次權限錯誤應各自獨立處理', () async {
      when(mockImagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: anyNamed('preferredCameraDevice'),
      )).thenThrow(Exception('Camera permission denied'));

      when(mockImagePicker.pickImage(
        source: ImageSource.gallery,
      )).thenThrow(Exception('Gallery permission denied'));

      final cameraResult = await imageService.pickFromCamera();
      final galleryResult = await imageService.pickFromGallery();

      expect(cameraResult.isFailure, isTrue);
      expect(galleryResult.isFailure, isTrue);

      cameraResult.fold(
        onSuccess: (_) {},
        onFailure: (e) => expect(e.code, 'CAMERA_ERROR'),
      );

      galleryResult.fold(
        onSuccess: (_) {},
        onFailure: (e) => expect(e.code, 'GALLERY_ERROR'),
      );
    });
  });

  group('Result 模式權限處理測試', () {
    test('Result.failure 應正確封裝 StorageException', () {
      final result = Result<String>.failure(
        StorageException.insufficientSpace(),
      );

      expect(result.isFailure, isTrue);
      expect(result.isSuccess, isFalse);

      result.fold(
        onSuccess: (_) => fail('不應成功'),
        onFailure: (error) {
          expect(error, isA<StorageException>());
          expect(error.code, 'INSUFFICIENT_SPACE');
        },
      );
    });

    test('權限錯誤應可通過 errorOrNull 取得', () {
      final result = Result<String>.failure(
        const StorageException('權限被拒絕', code: 'PERMISSION_DENIED'),
      );

      expect(result.errorOrNull, isNotNull);
      expect(result.errorOrNull?.code, 'PERMISSION_DENIED');
    });

    test('多種 StorageException 類型應可區分', () {
      final errors = [
        StorageException.insufficientSpace(),
        StorageException.fileNotFound('/path'),
        StorageException.writeError('/path'),
        StorageException.readError('/path'),
        StorageException.unsafePath('/path'),
      ];

      final codes = errors.map((e) => e.code).toList();

      expect(codes.contains('INSUFFICIENT_SPACE'), isTrue);
      expect(codes.contains('FILE_NOT_FOUND'), isTrue);
      expect(codes.contains('WRITE_ERROR'), isTrue);
      expect(codes.contains('READ_ERROR'), isTrue);
      expect(codes.contains('UNSAFE_PATH'), isTrue);
    });
  });

  group('並發權限請求測試', () {
    test('同時請求相機和相簿應各自獨立', () async {
      when(mockImagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: anyNamed('preferredCameraDevice'),
      )).thenAnswer((_) async => null);

      when(mockImagePicker.pickImage(
        source: ImageSource.gallery,
      )).thenAnswer((_) async => XFile('/test/image.jpg'));

      final results = await Future.wait([
        imageService.pickFromCamera(),
        imageService.pickFromGallery(),
      ]);

      expect(results[0].isFailure, isTrue); // 相機取消
      expect(results[1].isSuccess, isTrue); // 相簿成功
    });

    test('多個相簿請求應各自獨立處理', () async {
      var callCount = 0;

      when(mockImagePicker.pickImage(
        source: ImageSource.gallery,
      )).thenAnswer((_) async {
        callCount++;
        if (callCount % 2 == 0) {
          return XFile('/test/image_$callCount.jpg');
        }
        return null;
      });

      final results = await Future.wait([
        imageService.pickFromGallery(),
        imageService.pickFromGallery(),
        imageService.pickFromGallery(),
        imageService.pickFromGallery(),
      ]);

      final successCount = results.where((r) => r.isSuccess).length;
      final failureCount = results.where((r) => r.isFailure).length;

      expect(successCount, 2);
      expect(failureCount, 2);
    });
  });

  group('圖片存在性檢查測試', () {
    test('null 路徑應返回 false', () async {
      final exists = await imageService.imageExists(null);
      expect(exists, isFalse);
    });

    test('空路徑應返回 false', () async {
      final exists = await imageService.imageExists('');
      expect(exists, isFalse);
    });

    test('不存在的路徑應返回 false', () async {
      final exists = await imageService.imageExists('/nonexistent/path.jpg');
      expect(exists, isFalse);
    });
  });

  group('檔案大小讀取權限測試', () {
    test('無法讀取的檔案應返回 0', () async {
      final size = await imageService.getImageSizeKb('/nonexistent/file.jpg');
      expect(size, 0);
    });

    test('空路徑的檔案大小應返回 0', () async {
      // 空路徑會在 File() 建構時被允許，但 exists() 會返回 false
      final size = await imageService.getImageSizeKb('');
      expect(size, 0);
    });
  });

  group('刪除圖片權限測試', () {
    test('刪除 null 路徑應成功（無操作）', () async {
      final result = await imageService.deleteImages(
        fullPath: null,
        thumbnailPath: null,
      );

      expect(result.isSuccess, isTrue);
    });

    test('刪除空路徑應成功（無操作）', () async {
      final result = await imageService.deleteImages(
        fullPath: '',
        thumbnailPath: '',
      );

      expect(result.isSuccess, isTrue);
    });
  });

  group('錯誤訊息國際化測試', () {
    test('StorageException 訊息應為中文', () {
      final exceptions = [
        StorageException.insufficientSpace(),
        StorageException.fileNotFound('/path'),
        StorageException.writeError('/path'),
        StorageException.readError('/path'),
        StorageException.unsafePath('/path'),
      ];

      for (final e in exceptions) {
        // 訊息應包含中文字符
        expect(e.message.contains(RegExp(r'[\u4e00-\u9fff]')), isTrue,
            reason: '${e.code} 訊息應為中文');
      }
    });
  });

  group('權限錯誤分類測試', () {
    test('可重試的錯誤應可識別', () {
      bool isRetryable(AppException e) {
        if (e is StorageException) {
          // 這些錯誤可能通過重試解決
          return ['CAMERA_ERROR', 'GALLERY_ERROR'].contains(e.code);
        }
        return false;
      }

      expect(
        isRetryable(const StorageException('', code: 'CAMERA_ERROR')),
        isTrue,
      );
      expect(
        isRetryable(const StorageException('', code: 'GALLERY_ERROR')),
        isTrue,
      );
      expect(
        isRetryable(StorageException.insufficientSpace()),
        isFalse,
      );
    });

    test('使用者操作導致的錯誤應可識別', () {
      bool isUserAction(AppException e) {
        if (e is StorageException) {
          return e.code == 'CANCELLED';
        }
        return false;
      }

      expect(
        isUserAction(const StorageException('', code: 'CANCELLED')),
        isTrue,
      );
      expect(
        isUserAction(const StorageException('', code: 'CAMERA_ERROR')),
        isFalse,
      );
    });

    test('不可恢復的錯誤應可識別', () {
      bool isUnrecoverable(AppException e) {
        if (e is StorageException) {
          return ['INSUFFICIENT_SPACE', 'UNSAFE_PATH'].contains(e.code);
        }
        return false;
      }

      expect(
        isUnrecoverable(StorageException.insufficientSpace()),
        isTrue,
      );
      expect(
        isUnrecoverable(StorageException.unsafePath('/path')),
        isTrue,
      );
      expect(
        isUnrecoverable(StorageException.fileNotFound('/path')),
        isFalse,
      );
    });
  });
}
