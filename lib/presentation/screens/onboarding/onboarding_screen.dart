import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_constants.dart';
import '../../../l10n/app_localizations.dart';
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

  /// Onboarding 頁面資料（使用 key 引用，實際文字在 build 時透過 l10n 取得）
  static const _pages = [
    _OnboardingPage(
      illustration: 'assets/illustrations/onboarding_camera.svg',
      pageIndex: 1,
    ),
    _OnboardingPage(
      illustration: 'assets/illustrations/onboarding_currency.svg',
      pageIndex: 2,
    ),
    _OnboardingPage(
      illustration: 'assets/illustrations/onboarding_export.svg',
      pageIndex: 3,
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
                  child: Text(
                    S.of(context).onboarding_skip,
                    style: const TextStyle(
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
                          _currentPage < _pages.length - 1
                              ? S.of(context).onboarding_next
                              : S.of(context).onboarding_start,
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
    final l10n = S.of(context);

    // 根據頁面索引取得對應的標題和描述
    final String title;
    final String description;
    switch (page.pageIndex) {
      case 1:
        title = l10n.onboarding_page1Title;
        description = l10n.onboarding_page1Desc;
      case 2:
        title = l10n.onboarding_page2Title;
        description = l10n.onboarding_page2Desc;
      case 3:
        title = l10n.onboarding_page3Title;
        description = l10n.onboarding_page3Desc;
      default:
        title = '';
        description = '';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
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
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // 描述
          Text(
            description,
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
                decoration: InputDecoration(
                  labelText: l10n.onboarding_nameLabel,
                  hintText: l10n.onboarding_nameHint,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value != null && value.trim().length > 50) {
                    return l10n.onboarding_nameTooLong;
                  }
                  return null;
                },
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Onboarding 頁面資料模型
class _OnboardingPage {
  const _OnboardingPage({
    required this.illustration,
    required this.pageIndex,
    this.isLastPage = false,
  });

  final String illustration;

  /// 頁面索引（1-3），用於在 build 時查詢對應的 l10n 字串
  final int pageIndex;
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
