import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/animation_utils.dart';
import '../../../data/datasources/local/database_helper.dart';

/// Onboarding 畫面
///
/// 首次啟動時顯示 3 步驟 carousel：
/// 1. 歡迎 + 拍照記錄介紹
/// 2. 多幣種轉換介紹
/// 3. 一鍵匯出介紹 + 名稱輸入
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  int _currentPage = 0;
  bool _isLoading = false;

  /// Onboarding 頁面資料
  static const _pages = [
    _OnboardingPage(
      illustration: 'assets/illustrations/onboarding_camera.svg',
      title: '拍照記錄支出',
      description: '隨手拍攝收據，即時記錄每筆支出\n再也不怕遺失收據',
    ),
    _OnboardingPage(
      illustration: 'assets/illustrations/onboarding_currency.svg',
      title: '多幣種自動轉換',
      description: '支援 HKD、CNY、USD\n系統自動取得即時匯率',
    ),
    _OnboardingPage(
      illustration: 'assets/illustrations/onboarding_export.svg',
      title: '一鍵匯出報銷單',
      description: '月結時一鍵匯出 Excel + 收據圖片\n輕鬆完成報銷',
      isLastPage: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    AnimationUtils.selectionClick();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: AnimationUtils.standard,
        curve: AnimationUtils.standardInOut,
      );
    }
  }

  Future<void> _completeOnboarding({bool skip = false}) async {
    // 最後一頁才需要驗證表單
    if (!skip && _currentPage == _pages.length - 1) {
      final formState = _formKey.currentState;
      if (formState == null || !formState.validate()) {
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final db = DatabaseHelper.instance;

      // 儲存使用者名稱
      final name = skip || _nameController.text.trim().isEmpty
          ? AppConstants.defaultUserName
          : _nameController.text.trim();
      await db.setSetting('user_name', name);

      // 標記 onboarding 完成
      await db.setSetting('onboarding_completed', 'true');

      if (!mounted) return;

      unawaited(AnimationUtils.lightImpact());

      // 導航到主畫面
      unawaited(Navigator.of(context).pushReplacementNamed(AppRouter.home));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip 按鈕
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _isLoading ? null : () => _completeOnboarding(skip: true),
                  child: const Text(
                    '跳過',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _buildPage(page, index);
                },
              ),
            ),

            // 頁面指示器
            _PageIndicator(
              pageCount: _pages.length,
              currentPage: _currentPage,
            ),

            const SizedBox(height: 24),

            // 底部按鈕
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_currentPage < _pages.length - 1
                          ? _nextPage
                          : _completeOnboarding),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _currentPage < _pages.length - 1 ? '下一步' : '開始使用',
                        ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 插圖（加入進場動畫）
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: AnimationUtils.slow,
            curve: AnimationUtils.standardInOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: SvgPicture.asset(
              page.illustration,
              width: 200,
              height: 200,
            ),
          ),

          const SizedBox(height: 48),

          // 標題
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // 描述
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),

          // 最後一頁顯示名稱輸入
          if (page.isLastPage) ...[
            const SizedBox(height: 32),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '您的名字（選填）',
                  hintText: '用於報銷單標題',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value != null && value.trim().length > 50) {
                    return '名字不能超過 50 個字';
                  }
                  return null;
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Onboarding 頁面資料模型
class _OnboardingPage {
  const _OnboardingPage({
    required this.illustration,
    required this.title,
    required this.description,
    this.isLastPage = false,
  });

  final String illustration;
  final String title;
  final String description;
  final bool isLastPage;
}

/// 頁面指示器
class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.pageCount,
    required this.currentPage,
  });

  final int pageCount;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: AnimationUtils.fast,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.divider,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
