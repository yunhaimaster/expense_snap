import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/constants/currency_constants.dart';
import '../../../core/constants/validation_rules.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/animation_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/forms/amount_input.dart';
import '../../widgets/forms/currency_dropdown.dart';
import '../../widgets/forms/date_picker_field.dart';

/// 支出詳情畫面
///
/// 可查看、編輯、刪除支出
class ExpenseDetailScreen extends StatefulWidget {
  const ExpenseDetailScreen({
    super.key,
    required this.expenseId,
  });

  final int expenseId;

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _exchangeRateController = TextEditingController();

  Expense? _expense;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  String? _error;

  DateTime _selectedDate = DateTime.now();
  String _selectedCurrency = CurrencyConstants.defaultCurrency;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 只在首次呼叫時載入資料（避免重複載入）
    if (!_initialized) {
      _initialized = true;
      _loadExpense();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _exchangeRateController.dispose();
    super.dispose();
  }

  Future<void> _loadExpense() async {
    final provider = context.read<ExpenseProvider>();
    final result = provider.expenses
        .where((e) => e.id == widget.expenseId)
        .firstOrNull;

    if (result != null) {
      _setExpenseData(result);
    } else {
      setState(() {
        _error = S.of(context).expenseDetail_expenseNotFound;
        _isLoading = false;
      });
    }
  }

  void _setExpenseData(Expense expense) {
    setState(() {
      _expense = expense;
      _selectedDate = expense.date;
      _selectedCurrency = expense.originalCurrency;
      _amountController.text = expense.originalAmount.toString();
      _descriptionController.text = expense.description;
      _exchangeRateController.text = expense.formattedExchangeRate;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _expense == null) {
      final l10n = S.of(context);
      return Scaffold(
        appBar: AppBar(title: Text(l10n.expenseDetail_title)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(_error ?? l10n.common_loading),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.common_back),
              ),
            ],
          ),
        ),
      );
    }

    final l10n = S.of(context);
    return LoadingOverlay(
      isLoading: _isSaving,
      message: l10n.common_saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? l10n.expenseDetail_editTitle : l10n.expenseDetail_title),
          actions: [
            if (_isEditing)
              TextButton(
                onPressed: _saveChanges,
                child: Text(l10n.common_save, style: const TextStyle(color: Colors.white)),
              )
            else ...[
              IconButton(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit),
                tooltip: l10n.common_edit,
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _confirmDelete();
                  } else if (value == 'replace_image') {
                    _replaceImage();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'replace_image',
                    child: Row(
                      children: [
                        const Icon(Icons.image, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(l10n.expenseDetail_replaceImage),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, color: AppColors.error),
                        const SizedBox(width: 8),
                        Text(l10n.common_delete, style: const TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 收據圖片
              if (_expense!.hasReceipt)
                _buildReceiptImage()
              else
                _buildNoReceiptPlaceholder(),

              // 表單
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.of(context).viewPadding.bottom,
                ),
                child: _isEditing ? _buildEditForm() : _buildDetailView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptImage() {
    return GestureDetector(
      onTap: () => _showFullImage(context),
      child: Hero(
        tag: HeroTags.receiptImage(_expense!.id!),
        child: Container(
          height: 250,
          width: double.infinity,
          color: Colors.black,
          child: Image.file(
            File(_expense!.receiptImagePath!),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.broken_image, size: 48, color: Colors.white54),
                  const SizedBox(height: 8),
                  Text(S.of(context).expenseDetail_imageLoadFailed, style: const TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoReceiptPlaceholder() {
    return Container(
      height: 150,
      color: AppColors.divider,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_outlined, size: 48, color: AppColors.textHint),
            const SizedBox(height: 8),
            Text(S.of(context).expenseDetail_noReceipt, style: const TextStyle(color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailView() {
    final l10n = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 金額
        _DetailRow(
          label: l10n.expenseDetail_amount,
          value: _expense!.formattedOriginalAmount,
          valueStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
        ),

        if (_expense!.originalCurrency != 'HKD') ...[
          const SizedBox(height: 8),
          _DetailRow(
            label: l10n.expenseDetail_hkdAmount,
            value: _expense!.formattedHkdAmount,
          ),
          const SizedBox(height: 8),
          _DetailRow(
            label: l10n.expenseDetail_exchangeRate,
            value: '1 ${_expense!.originalCurrency} = ${_expense!.formattedExchangeRate} HKD',
            trailing: _buildRateSourceChip(),
          ),
        ],

        const Divider(height: 32),

        _DetailRow(
          label: l10n.expenseDetail_description,
          value: _expense!.description,
        ),

        const SizedBox(height: 16),

        _DetailRow(
          label: l10n.expenseDetail_date,
          value: Formatters.formatDate(_expense!.date),
        ),

        const SizedBox(height: 16),

        _DetailRow(
          label: l10n.expenseDetail_createdAt,
          value: Formatters.formatDateTime(_expense!.createdAt),
          valueStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildRateSourceChip() {
    final l10n = S.of(context);
    final (icon, color, label) = switch (_expense!.exchangeRateSource) {
      ExchangeRateSource.auto => (Icons.check_circle, AppColors.rateAuto, l10n.rateSource_auto),
      ExchangeRateSource.offline => (Icons.offline_bolt, AppColors.rateOffline, l10n.rateSource_offline),
      ExchangeRateSource.defaultRate => (Icons.warning, AppColors.rateDefault, l10n.rateSource_default),
      ExchangeRateSource.manual => (Icons.edit, AppColors.rateManual, l10n.rateSource_manual),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    final l10n = S.of(context);
    return Form(
      key: _formKey,
      child: Column(
        children: [
          DatePickerField(
            value: _selectedDate,
            onChanged: (date) => setState(() => _selectedDate = date),
            lastDate: DateTime.now(),
          ),

          const SizedBox(height: 16),

          CurrencyDropdown(
            value: _selectedCurrency,
            onChanged: (currency) => setState(() => _selectedCurrency = currency),
          ),

          const SizedBox(height: 16),

          AmountInput(
            controller: _amountController,
            label: l10n.expenseDetail_amount,
            suffix: _selectedCurrency,
          ),

          if (_selectedCurrency != 'HKD') ...[
            const SizedBox(height: 16),
            ExchangeRateInput(
              controller: _exchangeRateController,
              fromCurrency: _selectedCurrency,
            ),
          ],

          const SizedBox(height: 16),

          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: l10n.expenseDetail_description,
              prefixIcon: const Icon(Icons.description_outlined),
            ),
            maxLength: ValidationRules.maxDescriptionLength,
            maxLines: 2,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.expenseDetail_descriptionRequired;
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          OutlinedButton(
            onPressed: () {
              _setExpenseData(_expense!);
              setState(() => _isEditing = false);
            },
            child: Text(l10n.expenseDetail_cancelEdit),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = S.of(context);
    setState(() => _isSaving = true);

    try {
      final provider = context.read<ExpenseProvider>();

      // 安全解析金額
      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.addExpense_invalidAmount),
            backgroundColor: AppColors.error,
          ),
        );
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

      final updated = _expense!.copyWith(
        date: _selectedDate,
        originalAmountCents: amountCents,
        originalCurrency: _selectedCurrency,
        exchangeRate: rateMicros,
        hkdAmountCents: hkdAmountCents,
        description: _descriptionController.text.trim(),
        updatedAt: DateTime.now(),
      );

      final result = await provider.updateExpense(updated);

      if (!mounted) return;

      result.fold(
        onFailure: (error) {
          // 觸覺回饋 - 錯誤
          AnimationUtils.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.expenseDetail_saveFailed(error.message)),
              backgroundColor: AppColors.error,
            ),
          );
        },
        onSuccess: (expense) {
          // 觸覺回饋 - 儲存成功
          AnimationUtils.lightImpact();
          setState(() {
            _expense = expense;
            _isEditing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.expenseDetail_saved)),
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.expenseDetail_confirmDelete),
        content: Text(l10n.expenseDetail_confirmDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () {
              // 觸覺回饋 - 確認刪除
              AnimationUtils.mediumImpact();
              Navigator.of(context).pop(true);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.common_delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<ExpenseProvider>();
    final result = await provider.softDeleteExpense(_expense!.id!);

    if (!mounted) return;

    result.fold(
      onFailure: (error) {
        // 觸覺回饋 - 錯誤
        AnimationUtils.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.expenseDetail_deleteFailed(error.message)),
            backgroundColor: AppColors.error,
          ),
        );
      },
      onSuccess: (_) {
        // 觸覺回饋 - 刪除成功
        AnimationUtils.lightImpact();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.expenseDetail_deleted)),
        );
      },
    );
  }

  Future<void> _replaceImage() async {
    final l10n = S.of(context);
    final source = await showModalBottomSheet<_ImagePickSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.addExpense_camera),
              onTap: () => Navigator.pop(context, _ImagePickSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.expenseDetail_selectFromGallery),
              onTap: () => Navigator.pop(context, _ImagePickSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    final provider = context.read<ExpenseProvider>();
    final pickResult = source == _ImagePickSource.camera
        ? await provider.pickImageFromCamera()
        : await provider.pickImageFromGallery();

    if (!mounted) return;

    final imagePath = pickResult.getOrNull();
    if (imagePath == null) return;

    setState(() => _isSaving = true);

    final result = await provider.replaceReceiptImage(
      expenseId: _expense!.id!,
      newImagePath: imagePath,
    );

    if (!mounted) return;

    result.fold(
      onFailure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.expenseDetail_imageReplaceFailed(error.message)),
            backgroundColor: AppColors.error,
          ),
        );
      },
      onSuccess: (updated) {
        setState(() {
          _expense = updated;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.expenseDetail_imageReplaceSuccess)),
        );
      },
    );

    setState(() => _isSaving = false);
  }

  void _showFullImage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullImageViewer(
          imagePath: _expense!.receiptImagePath!,
          heroTag: HeroTags.receiptImage(_expense!.id!),
        ),
      ),
    );
  }
}

/// 圖片選擇來源（內部使用，避免與 image_picker 衝突）
enum _ImagePickSource { camera, gallery }

/// 詳情行組件
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueStyle,
    this.trailing,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: valueStyle ?? Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ],
    );
  }
}

/// 全螢幕圖片查看器
class _FullImageViewer extends StatelessWidget {
  const _FullImageViewer({
    required this.imagePath,
    required this.heroTag,
  });

  final String imagePath;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Hero(
            tag: heroTag,
            child: Image.file(
              File(imagePath),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
