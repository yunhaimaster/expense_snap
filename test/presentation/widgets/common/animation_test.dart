import 'package:expense_snap/core/utils/animation_utils.dart';
import 'package:expense_snap/presentation/widgets/common/animated_count.dart';
import 'package:expense_snap/presentation/widgets/common/animated_fab.dart';
import 'package:expense_snap/presentation/widgets/common/animated_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnimationUtils', () {
    test('動畫時長常數正確', () {
      expect(AnimationUtils.fast, const Duration(milliseconds: 150));
      expect(AnimationUtils.standard, const Duration(milliseconds: 250));
      expect(AnimationUtils.pageTransition, const Duration(milliseconds: 300));
      expect(AnimationUtils.slow, const Duration(milliseconds: 400));
      expect(AnimationUtils.staggerDelay, const Duration(milliseconds: 50));
    });

    test('staggerOffset 計算正確', () {
      expect(AnimationUtils.staggerOffset(0), Duration.zero);
      expect(
        AnimationUtils.staggerOffset(1),
        const Duration(milliseconds: 50),
      );
      expect(
        AnimationUtils.staggerOffset(5),
        const Duration(milliseconds: 250),
      );
    });

    test('staggerOffset 超過 maxItems 時 clamp', () {
      // 預設 maxItems = 10
      expect(
        AnimationUtils.staggerOffset(15),
        AnimationUtils.staggerOffset(10),
      );
    });
  });

  group('HeroTags', () {
    test('生成正確的收據圖片標籤', () {
      expect(HeroTags.receiptImage(1), 'receipt_1');
      expect(HeroTags.receiptImage(123), 'receipt_123');
    });

    test('生成正確的支出卡片標籤', () {
      expect(HeroTags.expenseCard(1), 'expense_card_1');
      expect(HeroTags.expenseCard(456), 'expense_card_456');
    });
  });

  group('AnimatedListItem', () {
    testWidgets('渲染子組件', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedListItem(
              index: 0,
              child: Text('Test'),
            ),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('不同滑入方向建立成功', (tester) async {
      for (final direction in SlideDirection.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedListItem(
                index: 0,
                slideFrom: direction,
                child: Text('Direction: $direction'),
              ),
            ),
          ),
        );

        expect(find.text('Direction: $direction'), findsOneWidget);
      }
    });

    testWidgets('animateOnMount false 時直接顯示', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedListItem(
              index: 0,
              animateOnMount: false,
              child: Text('No Animation'),
            ),
          ),
        ),
      );

      // 不等待動畫，直接找到
      expect(find.text('No Animation'), findsOneWidget);
    });

    testWidgets('執行進場動畫', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedListItem(
              index: 0,
              child: Text('Animated'),
            ),
          ),
        ),
      );

      // 等待動畫完成
      await tester.pumpAndSettle();
      expect(find.text('Animated'), findsOneWidget);
    });
  });

  group('AnimatedRemoveItem', () {
    testWidgets('正常顯示子組件', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedRemoveItem(
              removed: false,
              child: Text('Not Removed'),
            ),
          ),
        ),
      );

      expect(find.text('Not Removed'), findsOneWidget);
    });

    testWidgets('removed true 時執行退場動畫', (tester) async {
      bool animationCompleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedRemoveItem(
              removed: false,
              onAnimationComplete: () => animationCompleted = true,
              child: const Text('Will Remove'),
            ),
          ),
        ),
      );

      // 更新為 removed
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedRemoveItem(
              removed: true,
              onAnimationComplete: () => animationCompleted = true,
              child: const Text('Will Remove'),
            ),
          ),
        ),
      );

      // 等待動畫完成
      await tester.pumpAndSettle();
      expect(animationCompleted, isTrue);
    });
  });

  group('StaggeredListController', () {
    test('初始狀態未動畫', () {
      final controller = StaggeredListController();
      expect(controller.hasAnimated, isFalse);
    });

    test('markAnimated 標記已動畫', () {
      final controller = StaggeredListController();
      controller.markAnimated();
      expect(controller.hasAnimated, isTrue);
    });

    test('reset 重置動畫狀態', () {
      final controller = StaggeredListController();
      controller.markAnimated();
      controller.reset();
      expect(controller.hasAnimated, isFalse);
    });

    test('監聽狀態變化', () {
      final controller = StaggeredListController();
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.markAnimated();
      expect(notifyCount, 1);

      // 重複 markAnimated 不觸發
      controller.markAnimated();
      expect(notifyCount, 1);

      controller.reset();
      expect(notifyCount, 2);
    });
  });

  group('AnimatedIntCount', () {
    testWidgets('顯示正確數值', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedIntCount(
              count: 42,
            ),
          ),
        ),
      );

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('支援前後綴', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedIntCount(
              count: 10,
              prefix: '共 ',
              suffix: ' 筆',
            ),
          ),
        ),
      );

      expect(find.text('共 10 筆'), findsOneWidget);
    });

    testWidgets('數值變化時執行動畫', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedIntCount(count: 0),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedIntCount(count: 100),
          ),
        ),
      );

      // 動畫過程中
      await tester.pump(const Duration(milliseconds: 125));

      // 等待動畫完成
      await tester.pumpAndSettle();
      expect(find.text('100'), findsOneWidget);
    });
  });

  group('AnimatedAmount', () {
    testWidgets('顯示格式化金額', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedAmount(
              amount: 123456, // 1234.56 元
              currencySymbol: 'HK\$',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('HK\$1,234.56'), findsOneWidget);
    });

    testWidgets('金額變化時執行動畫', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedAmount(
              amount: 10000, // 100.00
              currencySymbol: '\$',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('\$100.00'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedAmount(
              amount: 50000, // 500.00
              currencySymbol: '\$',
            ),
          ),
        ),
      );

      // 等待動畫完成
      await tester.pumpAndSettle();
      expect(find.text('\$500.00'), findsOneWidget);
    });
  });

  group('AnimatedFab', () {
    testWidgets('渲染基本 FAB', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: AnimatedFab(
              onPressed: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('點擊觸發回調', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: AnimatedFab(
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      // 等待 Timer 延遲 (250ms) + 進場動畫 (300ms) 完成
      await tester.pump(const Duration(milliseconds: 300)); // 觸發 Timer
      await tester.pump(const Duration(milliseconds: 350)); // 等待動畫
      await tester.tap(find.byType(FloatingActionButton));
      expect(pressed, isTrue);
    });

    testWidgets('自訂圖示', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: AnimatedFab(
              onPressed: () {},
              icon: Icons.camera_alt,
            ),
          ),
        ),
      );

      // 等待 Timer 延遲 (250ms) + 進場動畫 (300ms) 完成
      await tester.pump(const Duration(milliseconds: 300)); // 觸發 Timer
      await tester.pump(const Duration(milliseconds: 350)); // 等待動畫
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('showPulse 啟用脈動動畫', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: AnimatedFab(
              onPressed: () {},
              showPulse: true,
            ),
          ),
        ),
      );

      // 脈動動畫會無限重複，所以不能使用 pumpAndSettle
      // 等待 Timer 延遲 (250ms) + 進場動畫 (300ms) 完成
      await tester.pump(const Duration(milliseconds: 300)); // 觸發 Timer
      await tester.pump(const Duration(milliseconds: 350)); // 等待動畫
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });

  group('ExpandableFab', () {
    testWidgets('渲染主按鈕', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: ExpandableFab(
              actions: [
                ExpandableFabAction(
                  icon: Icons.camera_alt,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('點擊展開動作按鈕', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: ExpandableFab(
              actions: [
                ExpandableFabAction(
                  icon: Icons.camera_alt,
                  label: '拍照',
                  onPressed: () {},
                ),
                ExpandableFabAction(
                  icon: Icons.photo,
                  label: '相簿',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      // 點擊主按鈕展開
      await tester.tap(find.byType(FloatingActionButton).first);
      await tester.pumpAndSettle();

      // 展開後應該有 3 個 FAB（1 主 + 2 動作）
      expect(find.byType(FloatingActionButton), findsNWidgets(3));
      expect(find.text('拍照'), findsOneWidget);
      expect(find.text('相簿'), findsOneWidget);
    });

    testWidgets('點擊動作按鈕執行回調並收合', (tester) async {
      bool actionPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: ExpandableFab(
              actions: [
                ExpandableFabAction(
                  icon: Icons.camera_alt,
                  onPressed: () => actionPressed = true,
                ),
              ],
            ),
          ),
        ),
      );

      // 展開
      await tester.tap(find.byType(FloatingActionButton).first);
      await tester.pumpAndSettle();

      // 點擊動作按鈕（小的那個）
      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pumpAndSettle();

      expect(actionPressed, isTrue);
    });
  });
}
