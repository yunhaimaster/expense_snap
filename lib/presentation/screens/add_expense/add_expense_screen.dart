import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/currency_constants.dart';
import '../../../core/constants/expense_category.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/animation_utils.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/receipt_parser.dart';
import '../../providers/exchange_rate_provider.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/forms/amount_input.dart';
import '../../widgets/forms/category_picker.dart';
import '../../widgets/forms/currency_dropdown.dart';
import '../../widgets/forms/date_picker_field.dart';
import '../../widgets/dialogs/smart_prompt_dialogs.dart';
import '../../widgets/forms/description_autocomplete.dart';
import '../../widgets/forms/exchange_rate_display.dart';
import '../../../core/services/smart_prompt_service.dart';

/// 新增支出畫面
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _exchangeRateController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedCurrency = CurrencyConstants.defaultCurrency;
  String? _selectedImagePath;
  ExpenseCategory? _selectedCategory;
  bool _isLoading = false;
  bool _useManualRate = false;
  bool _isProcessingOcr = false;

  // 當前匯率資訊
  int _currentRateMicros = CurrencyConstants.ratePrecision;
  ExchangeRateSource _currentRateSource = ExchangeRateSource.defaultRate;

  @override
  void initState() {
    super.initState();
    _updateDefaultExchangeRate();
    // 初始化時載入匯率
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExchangeRate();
    });
  }

  Future<void> _loadExchangeRate() async {
    if (_selectedCurrency == 'HKD') return;

    final provider = context.read<ExchangeRateProvider>();
    final info = await provider.loadRate(_selectedCurrency);

    if (info != null && mounted) {
      setState(() {
        _currentRateMicros = info.rateToHkd;
        _currentRateSource = info.source;
        if (!_useManualRate) {
          _exchangeRateController.text =
              Formatters.formatExchangeRate(info.rateToHkd);
        }
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _exchangeRateController.dispose();
    super.dispose();
  }

  void _updateDefaultExchangeRate() {
    // 暫時使用預設匯率，Phase 3 會實作即時匯率
    final rate = CurrencyConstants.defaultRates[_selectedCurrency] ?? 1.0;
    _exchangeRateController.text = rate.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return LoadingOverlay(
      isLoading: _isLoading,
      message: l10n.common_saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.addExpense_title),
          actions: [
            TextButton(
              onPressed: _saveExpense,
              child: Text(
                l10n.common_save,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(context).viewPadding.bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 收據圖片
                _buildImagePicker(),

                const SizedBox(height: 24),

                // 日期
                DatePickerField(
                  value: _selectedDate,
                  onChanged: (date) {
                    setState(() => _selectedDate = date);
                  },
                  lastDate: DateTime.now(),
                ),

                const SizedBox(height: 16),

                // 幣種
                CurrencyButtonGroup(
                  value: _selectedCurrency,
                  onChanged: (currency) {
                    setState(() {
                      _selectedCurrency = currency;
                      // 重置匯率來源為預設值，避免幣種切換時來源不同步
                      _currentRateSource = ExchangeRateSource.defaultRate;
                      if (!_useManualRate) {
                        _updateDefaultExchangeRate();
                      }
                    });
                    // 載入新幣種的匯率
                    _loadExchangeRate();
                  },
                ),

                const SizedBox(height: 16),

                // 金額（含 OCR 識別中的 shimmer 效果）
                _isProcessingOcr
                    ? _buildOcrShimmer(context, label: l10n.addExpense_amount)
                    : AmountInput(
                        controller: _amountController,
                        label: l10n.addExpense_amount,
                        suffix: _selectedCurrency,
                        autofocus: true,
                      ),

                const SizedBox(height: 16),

                // 匯率（非港幣時顯示）
                if (_selectedCurrency != 'HKD') ...[
                  // 匯率顯示區
                  ExchangeRateDisplay(
                    currency: _selectedCurrency,
                    enabled: !_useManualRate,
                    onRateChanged: (rate, source) {
                      setState(() {
                        _currentRateMicros = rate;
                        _currentRateSource = source;
                        if (!_useManualRate) {
                          _exchangeRateController.text =
                              Formatters.formatExchangeRate(rate);
                        }
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  // 手動輸入切換
                  Row(
                    children: [
                      Expanded(
                        child: _useManualRate
                            ? ExchangeRateInput(
                                controller: _exchangeRateController,
                                fromCurrency: _selectedCurrency,
                                enabled: true,
                                onChanged: (_) {
                                  // 更新手動匯率來源
                                  setState(() {
                                    _currentRateSource = ExchangeRateSource.manual;
                                  });
                                },
                              )
                            : const SizedBox.shrink(),
                      ),
                      Row(
                        children: [
                          Text(
                            l10n.addExpense_manualInput,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Switch(
                            value: _useManualRate,
                            onChanged: (value) {
                              setState(() {
                                _useManualRate = value;
                                if (!value) {
                                  // 恢復自動匯率
                                  _exchangeRateController.text =
                                      Formatters.formatExchangeRate(_currentRateMicros);
                                  _loadExchangeRate();
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  // 換算金額預覽
                  if (_amountController.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildConversionPreview(),
                  ],

                  const SizedBox(height: 16),
                ],

                // 描述（含自動完成、OCR 識別中的 shimmer 效果）
                _isProcessingOcr
                    ? _buildOcrShimmer(context, label: l10n.addExpense_description)
                    : DescriptionAutocomplete(
                        controller: _descriptionController,
                      ),

                const SizedBox(height: 16),

                // 分類選擇器
                CategoryPicker(
                  value: _selectedCategory,
                  onChanged: (category) {
                    setState(() => _selectedCategory = category);
                  },
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    final l10n = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.addExpense_receiptImage,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 8),

        if (_selectedImagePath != null)
          // 圖片預覽
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_selectedImagePath!),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () {
                    setState(() => _selectedImagePath = null);
                  },
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          )
        else
          // 選擇按鈕
          Row(
            children: [
              Expanded(
                child: _ImagePickerButton(
                  icon: Icons.camera_alt,
                  label: l10n.addExpense_camera,
                  onTap: _pickFromCamera,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ImagePickerButton(
                  icon: Icons.photo_library,
                  label: l10n.addExpense_gallery,
                  onTap: _pickFromGallery,
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// 建立 OCR 處理中的 shimmer 效果
  Widget _buildOcrShimmer(BuildContext context, {required String label}) {
    final l10n = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 8),
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.document_scanner, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    l10n.addExpense_ocrProcessing,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConversionPreview() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final rate = double.tryParse(_exchangeRateController.text) ?? 1;
    final hkdAmount = amount * rate;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$_selectedCurrency ${Formatters.formatCurrency(amount)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.arrow_forward, size: 16),
          ),
          Text(
            'HKD ${Formatters.formatCurrency(hkdAmount)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    // 觸覺回饋 - 拍照
    unawaited(AnimationUtils.selectionClick());

    final provider = context.read<ExpenseProvider>();
    final result = await provider.pickImageFromCamera();

    result.fold(
      onFailure: (error) {
        if (error.code != 'CANCELLED') {
          _showError(error.message);
        }
      },
      onSuccess: (path) {
        // 觸覺回饋 - 成功拍照
        AnimationUtils.lightImpact();
        setState(() => _selectedImagePath = path);
        // 執行 OCR 識別
        _processOcr(path);
      },
    );
  }

  Future<void> _pickFromGallery() async {
    final provider = context.read<ExpenseProvider>();
    final result = await provider.pickImageFromGallery();

    result.fold(
      onFailure: (error) {
        if (error.code != 'CANCELLED') {
          _showError(error.message);
        }
      },
      onSuccess: (path) {
        setState(() => _selectedImagePath = path);
        // 執行 OCR 識別
        _processOcr(path);
      },
    );
  }

  /// 執行 OCR 識別並填入表單
  Future<void> _processOcr(String imagePath) async {
    if (!mounted) return;

    setState(() => _isProcessingOcr = true);

    try {
      // 執行 OCR
      final ocrService = sl.ocrService;
      final result = await ocrService.recognizeText(imagePath);

      if (!mounted) return;

      result.fold(
        onFailure: (error) {
          // 靜默失敗，用戶可手動輸入
          AppLogger.warning('OCR failed: ${error.message}');
        },
        onSuccess: (recognizedText) {
          // 解析收據內容
          final parser = ReceiptParser(
            defaultCurrency: _selectedCurrency,
          );
          final parsed = parser.parse(recognizedText);

          AppLogger.info('OCR parsed: $parsed');

          if (!mounted) return;

          // 自動填入表單
          setState(() {
            // 幣別
            if (parsed.currency != null &&
                CurrencyConstants.supportedCurrencies.contains(parsed.currency)) {
              _selectedCurrency = parsed.currency!;
              _updateDefaultExchangeRate();
              _loadExchangeRate();
            }

            // 金額（轉換為元顯示）
            if (parsed.amountCents != null) {
              final amountDollars = parsed.amountCents! / 100;
              _amountController.text = Formatters.formatCurrency(amountDollars);
            }

            // 日期
            if (parsed.date != null) {
              _selectedDate = parsed.date!;
            }

            // 描述
            if (parsed.description != null && parsed.description!.isNotEmpty) {
              _descriptionController.text = parsed.description!;
            }

            // 分類（OCR 建議）
            if (parsed.suggestedCategory != null) {
              _selectedCategory = parsed.suggestedCategory;
            }
          });

          // 顯示 OCR 識別結果提示
          if (parsed.hasData && mounted) {
            AnimationUtils.lightImpact();
            final l10n = S.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  parsed.confidence >= 0.7
                      ? l10n.addExpense_ocrSuccess
                      : l10n.addExpense_ocrSuccessVerify,
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessingOcr = false);
      }
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      // 觸覺回饋 - 驗證失敗
      unawaited(AnimationUtils.heavyImpact());
      return;
    }

    // 安全解析金額（表單驗證應已確保有效，但加上防護）
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError(S.of(context).addExpense_invalidAmount);
      return;
    }
    final amountCents = Formatters.amountToCents(amount);

    // 安全解析匯率
    final rate = _selectedCurrency == 'HKD'
        ? 1.0
        : (double.tryParse(_exchangeRateController.text) ?? 1.0);
    final rateMicros = Formatters.rateToMicros(rate);

    final hkdAmountCents = _selectedCurrency == 'HKD'
        ? amountCents
        : (amountCents * rate).round();

    // 智慧提示檢查
    final smartPrompt = SmartPromptService.instance;

    // 檢查大金額
    if (smartPrompt.isLargeAmount(hkdAmountCents)) {
      final confirmed = await SmartPromptDialogs.showLargeAmountConfirmation(
        context,
        amount: amount,
        currency: _selectedCurrency,
        hkdAmount: hkdAmountCents / 100,
      );
      if (!mounted) return;
      if (!confirmed) return;
    }

    // 檢查重複支出
    final duplicate = await smartPrompt.findDuplicateExpense(
      hkdAmountCents: hkdAmountCents,
      description: _descriptionController.text.trim(),
      date: _selectedDate,
    );
    if (!mounted) return;

    if (duplicate != null) {
      final proceed = await SmartPromptDialogs.showDuplicateWarning(
        context,
        existingExpense: duplicate,
      );
      if (!mounted) return;
      if (!proceed) return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<ExpenseProvider>();

      // 使用追蹤的匯率來源
      final rateSource = _selectedCurrency == 'HKD'
          ? ExchangeRateSource.auto
          : _currentRateSource;

      final result = await provider.addExpense(
        date: _selectedDate,
        originalAmountCents: amountCents,
        originalCurrency: _selectedCurrency,
        exchangeRate: rateMicros,
        exchangeRateSource: rateSource,
        hkdAmountCents: hkdAmountCents,
        description: _descriptionController.text.trim(),
        imagePath: _selectedImagePath,
        category: _selectedCategory,
      );

      if (!mounted) return;

      result.fold(
        onFailure: (error) {
          // 觸覺回饋 - 錯誤
          AnimationUtils.heavyImpact();
          _showError(error.message);
        },
        onSuccess: (_) {
          // 觸覺回饋 - 儲存成功
          AnimationUtils.lightImpact();
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).addExpense_success)),
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

/// 圖片選擇按鈕
class _ImagePickerButton extends StatelessWidget {
  const _ImagePickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
