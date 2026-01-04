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
}
