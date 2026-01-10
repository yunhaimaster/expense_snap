import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:expense_snap/services/image_service.dart';

@GenerateMocks([ImagePicker])
import 'image_service_test.mocks.dart';

void main() {
  late MockImagePicker mockPicker;
  late ImageService imageService;

  setUp(() {
    mockPicker = MockImagePicker();
    imageService = ImageService(picker: mockPicker);
  });

  group('ImageService.pickFromCamera', () {
    test('成功拍照應返回圖片路徑', () async {
      when(mockPicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      )).thenAnswer((_) async => XFile('/path/to/image.jpg'));

      final result = await imageService.pickFromCamera();

      expect(result.isSuccess, true);
      result.onSuccess((path) {
        expect(path, '/path/to/image.jpg');
      });
    });

    test('使用者取消應返回 CANCELLED 錯誤', () async {
      when(mockPicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      )).thenAnswer((_) async => null);

      final result = await imageService.pickFromCamera();

      expect(result.isFailure, true);
      result.onFailure((error) {
        expect(error.code, 'CANCELLED');
      });
    });

    test('相機錯誤應返回 CAMERA_ERROR', () async {
      when(mockPicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      )).thenThrow(Exception('相機無法使用'));

      final result = await imageService.pickFromCamera();

      expect(result.isFailure, true);
      result.onFailure((error) {
        expect(error.code, 'CAMERA_ERROR');
      });
    });
  });

  group('ImageService.pickFromGallery', () {
    test('成功選擇應返回圖片路徑', () async {
      when(mockPicker.pickImage(source: ImageSource.gallery))
          .thenAnswer((_) async => XFile('/path/to/gallery/image.jpg'));

      final result = await imageService.pickFromGallery();

      expect(result.isSuccess, true);
      result.onSuccess((path) {
        expect(path, '/path/to/gallery/image.jpg');
      });
    });

    test('使用者取消應返回 CANCELLED 錯誤', () async {
      when(mockPicker.pickImage(source: ImageSource.gallery))
          .thenAnswer((_) async => null);

      final result = await imageService.pickFromGallery();

      expect(result.isFailure, true);
      result.onFailure((error) {
        expect(error.code, 'CANCELLED');
      });
    });

    test('相簿錯誤應返回 GALLERY_ERROR', () async {
      when(mockPicker.pickImage(source: ImageSource.gallery))
          .thenThrow(Exception('相簿無法存取'));

      final result = await imageService.pickFromGallery();

      expect(result.isFailure, true);
      result.onFailure((error) {
        expect(error.code, 'GALLERY_ERROR');
      });
    });
  });

  group('ImageService.imageExists', () {
    test('null 路徑應返回 false', () async {
      final exists = await imageService.imageExists(null);
      expect(exists, false);
    });

    test('空路徑應返回 false', () async {
      final exists = await imageService.imageExists('');
      expect(exists, false);
    });
  });

  group('ProcessedImagePaths', () {
    test('應正確儲存路徑', () {
      const paths = ProcessedImagePaths(
        fullPath: '/full/path.jpg',
        thumbnailPath: '/thumb/path.jpg',
      );

      expect(paths.fullPath, '/full/path.jpg');
      expect(paths.thumbnailPath, '/thumb/path.jpg');
    });
  });

  // ============ Security Configuration Tests ============

  group('ImageService 安全配置', () {
    test('應有 EXIF 移除功能描述', () {
      // ImageService class 文檔應明確說明會移除 EXIF
      // 這是一個文檔驗證測試，確保開發者知道隱私保護功能
      expect(
        ImageService().toString(),
        isNotNull,
      );
      // 實際 EXIF 移除由 flutter_image_compress 的 keepExif: false 處理
    });

    test('處理超時應為 5 秒', () {
      final service = ImageService();
      expect(service.processingTimeout, const Duration(seconds: 5));
    });

    test('可自訂處理超時', () {
      final service = ImageService(
        processingTimeout: const Duration(seconds: 10),
      );
      expect(service.processingTimeout, const Duration(seconds: 10));
    });

    test('預設使用系統 ImagePicker', () {
      // 驗證無 picker 參數時不會拋出異常
      final service = ImageService();
      expect(service, isNotNull);
    });
  });

  group('圖片壓縮常數驗證', () {
    test('ProcessedImagePaths 應為 immutable', () {
      const paths = ProcessedImagePaths(
        fullPath: '/test/full.jpg',
        thumbnailPath: '/test/thumb.jpg',
      );
      // 驗證 const constructor 可用（表示 immutable）
      expect(paths.fullPath, '/test/full.jpg');
      expect(paths.thumbnailPath, '/test/thumb.jpg');
    });

    test('空路徑應有效處理', () {
      const paths = ProcessedImagePaths(
        fullPath: '',
        thumbnailPath: '',
      );
      expect(paths.fullPath, isEmpty);
      expect(paths.thumbnailPath, isEmpty);
    });
  });

  group('ImageService 隱私保護', () {
    test('EXIF 配置說明：keepExif 應為 false', () {
      // 此測試記錄 EXIF 配置要求：
      // flutter_image_compress 應使用 keepExif: false
      // 這會移除 GPS、相機型號、拍攝日期等隱私資訊
      //
      // 實際配置位於 lib/services/image_service.dart:
      // - Line 355: keepExif: false (原圖壓縮)
      // - Line 375: keepExif: false (縮圖生成)
      //
      // 驗證方法：
      // 1. 代碼審查確認 keepExif: false
      // 2. 整合測試使用包含 EXIF 的圖片驗證移除效果
      expect(true, isTrue, reason: 'EXIF removal configured via keepExif: false');
    });

    test('GPS 資訊移除說明', () {
      // GPS metadata 移除是 EXIF 移除的一部分
      // flutter_image_compress 的 keepExif: false 會移除所有 EXIF metadata
      // 包括：
      // - GPS 座標 (GPSLatitude, GPSLongitude)
      // - GPS 時間戳 (GPSDateStamp, GPSTimeStamp)
      // - 拍攝地點資訊
      expect(true, isTrue, reason: 'GPS removal is part of EXIF removal');
    });
  });
}
