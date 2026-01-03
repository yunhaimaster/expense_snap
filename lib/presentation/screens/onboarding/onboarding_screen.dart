import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/local/database_helper.dart';

/// Onboarding 畫面
///
/// 首次啟動時顯示，收集使用者名稱
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // Logo / 歡迎圖示
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 32),

              // 標題
              Text(
                '歡迎使用 ${AppConstants.appName}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // 副標題
              Text(
                '輕鬆記錄支出，一鍵匯出報銷單',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // 名稱輸入
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '您的名字',
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

              const Spacer(),

              // 開始使用按鈕
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _completeOnboarding,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('開始使用'),
                ),
              ),

              const SizedBox(height: 12),

              // 跳過按鈕
              TextButton(
                onPressed: _isLoading ? null : () => _completeOnboarding(skip: true),
                child: const Text('稍後設定'),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completeOnboarding({bool skip = false}) async {
    if (!skip && !_formKey.currentState!.validate()) {
      return;
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

      // 導航到主畫面
      Navigator.of(context).pushReplacementNamed(AppRouter.home);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
