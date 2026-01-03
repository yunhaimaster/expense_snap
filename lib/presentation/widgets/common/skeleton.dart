// Skeleton Loading 元件庫
// 使用 shimmer 效果取代傳統 spinner，提升感知效能

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';

/// Shimmer 包裝器，統一動畫效果
class SkeletonShimmer extends StatelessWidget {
  final Widget child;

  const SkeletonShimmer({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.skeletonBase,
      highlightColor: AppColors.skeletonHighlight,
      child: child,
    );
  }
}

/// 基礎矩形骨架
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 4.0,
  })  : assert(height > 0, 'height 必須為正數'),
        assert(width == null || width > 0, 'width 必須為正數或 null'),
        assert(borderRadius >= 0, 'borderRadius 不能為負數');

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// 圓形骨架（頭像、圖示等）
class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({
    super.key,
    required this.size,
  }) : assert(size > 0, 'size 必須為正數');

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// 文字行骨架
class SkeletonText extends StatelessWidget {
  final double? width;
  final double height;
  final int lines;
  final double spacing;

  const SkeletonText({
    super.key,
    this.width,
    this.height = 14.0,
    this.lines = 1,
    this.spacing = 8.0,
  })  : assert(height > 0, 'height 必須為正數'),
        assert(lines > 0, 'lines 必須為正數'),
        assert(spacing >= 0, 'spacing 不能為負數'),
        assert(width == null || width > 0, 'width 必須為正數或 null');

  @override
  Widget build(BuildContext context) {
    if (lines == 1) {
      return SkeletonBox(
        width: width,
        height: height,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (index) {
        final isLastLine = index == lines - 1;
        final bottomPadding = isLastLine ? 0.0 : spacing;

        // 最後一行較短，模擬自然文字結尾
        Widget lineWidget;
        if (isLastLine && width == null) {
          // 最後一行使用 70% 寬度
          lineWidget = FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 0.7,
            child: SkeletonBox(height: height),
          );
        } else {
          // 其他行使用完整寬度或指定寬度
          lineWidget = SkeletonBox(width: width, height: height);
        }

        return Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: lineWidget,
        );
      }),
    );
  }
}

/// 圖片縮圖骨架
class SkeletonThumbnail extends StatelessWidget {
  final double size;
  final double borderRadius;

  const SkeletonThumbnail({
    super.key,
    this.size = 60.0,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: size,
      height: size,
      borderRadius: borderRadius,
    );
  }
}

/// 支出卡片骨架
class ExpenseCardSkeleton extends StatelessWidget {
  const ExpenseCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonShimmer(
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              // 縮圖
              SkeletonThumbnail(size: 56),
              SizedBox(width: 12),
              // 內容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 描述
                    SkeletonBox(width: 140, height: 16),
                    SizedBox(height: 8),
                    // 日期
                    SkeletonBox(width: 80, height: 12),
                  ],
                ),
              ),
              // 金額
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SkeletonBox(width: 70, height: 18),
                  SizedBox(height: 4),
                  SkeletonBox(width: 50, height: 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 支出列表骨架（多個卡片）
class ExpenseListSkeleton extends StatelessWidget {
  final int itemCount;

  const ExpenseListSkeleton({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ExpenseCardSkeleton(),
    );
  }
}

/// 月份摘要骨架
class MonthSummarySkeleton extends StatelessWidget {
  const MonthSummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonShimmer(
      child: Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // 月份標題
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonCircle(size: 32),
                  SkeletonBox(width: 100, height: 20),
                  SkeletonCircle(size: 32),
                ],
              ),
              SizedBox(height: 16),
              // 總金額
              SkeletonBox(width: 150, height: 32),
              SizedBox(height: 8),
              // 筆數
              SkeletonBox(width: 80, height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

/// 設定項目骨架
class SettingsItemSkeleton extends StatelessWidget {
  const SettingsItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonShimmer(
      child: ListTile(
        leading: SkeletonCircle(size: 40),
        title: SkeletonBox(width: 120, height: 16),
        subtitle: SkeletonBox(width: 180, height: 12),
        trailing: SkeletonBox(width: 24, height: 24, borderRadius: 4),
      ),
    );
  }
}

/// 設定列表骨架
class SettingsListSkeleton extends StatelessWidget {
  final int itemCount;

  const SettingsListSkeleton({
    super.key,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => const SettingsItemSkeleton(),
      ),
    );
  }
}

/// 匯出預覽骨架
class ExportPreviewSkeleton extends StatelessWidget {
  const ExportPreviewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonShimmer(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 圖示
              SkeletonCircle(size: 80),
              SizedBox(height: 24),
              // 月份
              SkeletonBox(width: 120, height: 24),
              SizedBox(height: 16),
              // 統計行 1
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SkeletonCircle(size: 20),
                  SizedBox(width: 8),
                  SkeletonBox(width: 60, height: 14),
                  Spacer(),
                  SkeletonBox(width: 50, height: 14),
                ],
              ),
              SizedBox(height: 8),
              // 統計行 2
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SkeletonCircle(size: 20),
                  SizedBox(width: 8),
                  SkeletonBox(width: 60, height: 14),
                  Spacer(),
                  SkeletonBox(width: 80, height: 14),
                ],
              ),
              SizedBox(height: 8),
              // 統計行 3
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SkeletonCircle(size: 20),
                  SizedBox(width: 8),
                  SkeletonBox(width: 60, height: 14),
                  Spacer(),
                  SkeletonBox(width: 50, height: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
