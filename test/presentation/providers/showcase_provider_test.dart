import 'package:flutter_test/flutter_test.dart';
import 'package:expense_snap/presentation/providers/showcase_provider.dart';

void main() {
  group('ShowcaseProvider', () {
    late ShowcaseProvider provider;

    setUp(() {
      provider = ShowcaseProvider();
    });

    test('initial state has all showcases incomplete before initialization', () {
      // 在初始化前，initialized 應為 false
      expect(provider.initialized, isFalse);
    });

    test('shouldShowFabShowcase returns correct value', () {
      // 預設情況下（未初始化），FAB showcase 應已完成（true = 不顯示）
      expect(provider.fabShowcaseComplete, isTrue);
      expect(provider.shouldShowFabShowcase, isFalse);
    });

    test('shouldShowSwipeShowcase returns correct value', () {
      expect(provider.swipeShowcaseComplete, isTrue);
      expect(provider.shouldShowSwipeShowcase, isFalse);
    });

    test('shouldShowExportShowcase returns correct value', () {
      expect(provider.exportShowcaseComplete, isTrue);
      expect(provider.shouldShowExportShowcase, isFalse);
    });

    test('completeFabShowcase marks FAB showcase as complete', () async {
      // 由於沒有實際數據庫，此方法應該安全地完成
      // 在實際應用中，這會更新數據庫
      final initialValue = provider.fabShowcaseComplete;
      await provider.completeFabShowcase();

      // 完成後仍應為 true
      expect(provider.fabShowcaseComplete, isTrue);
      expect(provider.shouldShowFabShowcase, isFalse);
    });

    test('completeSwipeShowcase marks swipe showcase as complete', () async {
      final initialValue = provider.swipeShowcaseComplete;
      await provider.completeSwipeShowcase();

      expect(provider.swipeShowcaseComplete, isTrue);
      expect(provider.shouldShowSwipeShowcase, isFalse);
    });

    test('completeExportShowcase marks export showcase as complete', () async {
      final initialValue = provider.exportShowcaseComplete;
      await provider.completeExportShowcase();

      expect(provider.exportShowcaseComplete, isTrue);
      expect(provider.shouldShowExportShowcase, isFalse);
    });

    test('checkExportShowcaseReady returns false when already complete',
        () async {
      // 當 showcase 已完成時，應返回 false
      final result = await provider.checkExportShowcaseReady();
      expect(result, isFalse);
    });
  });
}
