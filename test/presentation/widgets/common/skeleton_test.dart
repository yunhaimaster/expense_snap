// Skeleton Loading 元件測試

import 'package:expense_snap/presentation/widgets/common/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';

void main() {
  group('SkeletonBox', () {
    testWidgets('應正確渲染指定尺寸', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonBox(width: 100, height: 50),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final constraints = container.constraints;

      expect(constraints?.maxWidth, 100);
      expect(constraints?.maxHeight, 50);
    });

    testWidgets('寬度為 null 時應填滿可用空間', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: SkeletonBox(height: 50),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(SkeletonBox));
      expect(size.width, 200.0);
      expect(size.height, 50.0);
    });

    testWidgets('應套用指定的圓角', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonBox(width: 100, height: 50, borderRadius: 12.0),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      final borderRadius = decoration.borderRadius as BorderRadius;

      expect(borderRadius.topLeft.x, 12.0);
    });
  });

  group('SkeletonCircle', () {
    testWidgets('應渲染為圓形', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonCircle(size: 40),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.shape, BoxShape.circle);
    });

    testWidgets('應使用指定尺寸', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonCircle(size: 60),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));

      expect(container.constraints?.maxWidth, 60);
      expect(container.constraints?.maxHeight, 60);
    });
  });

  group('SkeletonText', () {
    testWidgets('單行時應渲染單個 SkeletonBox', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonText(width: 100, lines: 1),
          ),
        ),
      );

      expect(find.byType(SkeletonBox), findsOneWidget);
    });

    testWidgets('多行時應渲染多個 SkeletonBox', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonText(width: 100, lines: 3),
          ),
        ),
      );

      expect(find.byType(SkeletonBox), findsNWidgets(3));
    });

    testWidgets('寬度為 null 時最後一行應為 70% 寬度', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: SkeletonText(lines: 2),
            ),
          ),
        ),
      );

      // 應該有 2 個 SkeletonBox
      expect(find.byType(SkeletonBox), findsNWidgets(2));
      // 最後一行應該使用 FractionallySizedBox
      expect(find.byType(FractionallySizedBox), findsOneWidget);
    });

    testWidgets('指定寬度時所有行應使用相同寬度', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonText(width: 150, lines: 3),
          ),
        ),
      );

      // 所有行都應該有指定寬度，不使用 FractionallySizedBox
      expect(find.byType(FractionallySizedBox), findsNothing);
      expect(find.byType(SkeletonBox), findsNWidgets(3));
    });
  });

  group('SkeletonThumbnail', () {
    testWidgets('應渲染為正方形', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonThumbnail(size: 80),
          ),
        ),
      );

      expect(find.byType(SkeletonBox), findsOneWidget);
      final size = tester.getSize(find.byType(SkeletonBox));
      expect(size.width, 80.0);
      expect(size.height, 80.0);
    });

    testWidgets('應使用指定圓角', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonThumbnail(size: 60, borderRadius: 12),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      final borderRadius = decoration.borderRadius as BorderRadius;
      expect(borderRadius.topLeft.x, 12.0);
    });
  });

  group('SkeletonShimmer', () {
    testWidgets('應包裝 Shimmer 效果', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonShimmer(
              child: SkeletonBox(width: 100, height: 50),
            ),
          ),
        ),
      );

      expect(find.byType(Shimmer), findsOneWidget);
    });
  });

  group('ExpenseCardSkeleton', () {
    testWidgets('應正確渲染卡片骨架', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExpenseCardSkeleton(),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(SkeletonShimmer), findsOneWidget);
    });

    testWidgets('應包含縮圖骨架', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExpenseCardSkeleton(),
          ),
        ),
      );

      expect(find.byType(SkeletonThumbnail), findsOneWidget);
    });
  });

  group('ExpenseListSkeleton', () {
    testWidgets('應渲染指定數量的卡片骨架', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExpenseListSkeleton(itemCount: 3),
          ),
        ),
      );

      expect(find.byType(ExpenseCardSkeleton), findsNWidgets(3));
    });

    testWidgets('預設應渲染 5 個卡片', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExpenseListSkeleton(),
          ),
        ),
      );

      expect(find.byType(ExpenseCardSkeleton), findsNWidgets(5));
    });
  });

  group('MonthSummarySkeleton', () {
    testWidgets('應正確渲染摘要骨架', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MonthSummarySkeleton(),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(SkeletonShimmer), findsOneWidget);
    });

    testWidgets('應包含導航按鈕骨架 (2 個圓形)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MonthSummarySkeleton(),
          ),
        ),
      );

      // 月份標題列有 2 個 SkeletonCircle（左右導航）
      expect(find.byType(SkeletonCircle), findsNWidgets(2));
    });
  });

  group('SettingsItemSkeleton', () {
    testWidgets('應正確渲染設定項目骨架', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettingsItemSkeleton(),
          ),
        ),
      );

      expect(find.byType(ListTile), findsOneWidget);
      expect(find.byType(SkeletonShimmer), findsOneWidget);
    });
  });

  group('SettingsListSkeleton', () {
    testWidgets('應渲染指定數量的項目骨架', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettingsListSkeleton(itemCount: 5),
          ),
        ),
      );

      expect(find.byType(SettingsItemSkeleton), findsNWidgets(5));
    });

    testWidgets('預設應渲染 4 個項目', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettingsListSkeleton(),
          ),
        ),
      );

      expect(find.byType(SettingsItemSkeleton), findsNWidgets(4));
    });
  });

  group('ExportPreviewSkeleton', () {
    testWidgets('應正確渲染匯出預覽骨架', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExportPreviewSkeleton(),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(SkeletonShimmer), findsOneWidget);
    });

    testWidgets('應包含圖示骨架 (大圓形)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExportPreviewSkeleton(),
          ),
        ),
      );

      // 有一個 80px 的大圓形圖示 + 3 個 20px 的小圓形
      expect(find.byType(SkeletonCircle), findsNWidgets(4));
    });
  });
}
