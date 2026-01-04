import 'package:flutter/material.dart';

import '../utils/animation_utils.dart';

/// 左右滑動頁面轉場
///
/// 從右側滑入，向左側滑出
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  SlidePageRoute({
    required this.page,
    super.settings,
    this.duration,
    this.reverseDuration,
    super.fullscreenDialog = false,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // 減少動畫模式
            if (AnimationUtils.shouldReduceMotion(context)) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            }

            // 主頁面從右滑入
            final slideIn = Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: AnimationUtils.emphasized,
            ));

            // 背景頁面向左移動
            final slideOut = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.3, 0.0),
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: AnimationUtils.standardInOut,
            ));

            // 背景頁面淡出
            final fadeOut = Tween<double>(
              begin: 1.0,
              end: 0.9,
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: AnimationUtils.standardInOut,
            ));

            return SlideTransition(
              position: slideOut,
              child: FadeTransition(
                opacity: fadeOut,
                child: SlideTransition(
                  position: slideIn,
                  child: child,
                ),
              ),
            );
          },
          transitionDuration: duration ?? AnimationUtils.pageTransition,
          reverseTransitionDuration:
              reverseDuration ?? AnimationUtils.pageTransition,
        );

  final Widget page;
  final Duration? duration;
  final Duration? reverseDuration;
}

/// 淡入淡出頁面轉場
///
/// 適用於全螢幕對話框
class FadePageRoute<T> extends PageRouteBuilder<T> {
  FadePageRoute({
    required this.page,
    super.settings,
    this.duration,
    this.reverseDuration,
    super.fullscreenDialog = false,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: AnimationUtils.standardIn,
                reverseCurve: AnimationUtils.standardOut,
              ),
              child: child,
            );
          },
          transitionDuration: duration ?? AnimationUtils.standard,
          reverseTransitionDuration: reverseDuration ?? AnimationUtils.standard,
        );

  final Widget page;
  final Duration? duration;
  final Duration? reverseDuration;
}

/// 從底部滑入頁面轉場
///
/// 適用於模態頁面（如新增支出）
class BottomSlidePageRoute<T> extends PageRouteBuilder<T> {
  BottomSlidePageRoute({
    required this.page,
    super.settings,
    this.duration,
    this.reverseDuration,
    super.fullscreenDialog = true,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // 減少動畫模式
            if (AnimationUtils.shouldReduceMotion(context)) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            }

            final slide = Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: AnimationUtils.emphasized,
            ));

            final fade = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.5),
            ));

            return SlideTransition(
              position: slide,
              child: FadeTransition(
                opacity: fade,
                child: child,
              ),
            );
          },
          transitionDuration: duration ?? AnimationUtils.pageTransition,
          reverseTransitionDuration:
              reverseDuration ?? AnimationUtils.pageTransition,
        );

  final Widget page;
  final Duration? duration;
  final Duration? reverseDuration;
}

/// 縮放頁面轉場
///
/// 適用於從小元素展開的頁面
class ScalePageRoute<T> extends PageRouteBuilder<T> {
  ScalePageRoute({
    required this.page,
    super.settings,
    this.duration,
    this.reverseDuration,
    this.alignment = Alignment.center,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // 減少動畫模式
            if (AnimationUtils.shouldReduceMotion(context)) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            }

            final scale = Tween<double>(
              begin: 0.9,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: AnimationUtils.emphasized,
            ));

            final fade = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: AnimationUtils.standardIn,
            ));

            return FadeTransition(
              opacity: fade,
              child: ScaleTransition(
                alignment: alignment,
                scale: scale,
                child: child,
              ),
            );
          },
          transitionDuration: duration ?? AnimationUtils.pageTransition,
          reverseTransitionDuration:
              reverseDuration ?? AnimationUtils.pageTransition,
        );

  final Widget page;
  final Duration? duration;
  final Duration? reverseDuration;
  final Alignment alignment;
}
