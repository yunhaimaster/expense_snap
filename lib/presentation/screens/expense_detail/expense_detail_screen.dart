import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/currency_constants.dart';
import '../../../core/constants/validation_rules.dart';
import '../../../core/theme/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _loadExpense();
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
        _error = '找不到支出記錄';
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
      return Scaffold(
        appBar: AppBar(title: const Text('支出詳情')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(_error ?? '載入失敗'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('返回'),
              ),
            ],
          ),
        ),
      );
    }

    return LoadingOverlay(
      isLoading: _isSaving,
      message: '儲存中...',
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? '編輯支出' : '支出詳情'),
          actions: [
            if (_isEditing)
              TextButton(
                onPressed: _saveChanges,
                child: const Text('儲存', style: TextStyle(color: Colors.white)),
              )
            else ...[
              IconButton(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit),
                tooltip: '編輯',
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
                  const PopupMenuItem(
                    value: 'replace_image',
                    child: Row(
                      children: [
                        Icon(Icons.image, color: AppColors.textSecondary),
                        SizedBox(width: 8),
                        Text('更換圖片'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('刪除', style: TextStyle(color: AppColors.error)),
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
                padding: const EdgeInsets.all(16),
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
        tag: 'receipt_${_expense!.id}',
        child: Container(
          height: 250,
          width: double.infinity,
          color: Colors.black,
          child: Image.file(
            File(_expense!.receiptImagePath!),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image, size: 48, color: Colors.white54),
                  SizedBox(height: 8),
                  Text('圖片載入失敗', style: TextStyle(color: Colors.white54)),
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
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_outlined, size: 48, color: AppColors.textHint),
            SizedBox(height: 8),
            Text('無收據圖片', style: TextStyle(color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 金額
        _DetailRow(
          label: '金額',
          value: _expense!.formattedOriginalAmount,
          valueStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
        ),

        if (_expense!.originalCurrency != 'HKD') ...[
          const SizedBox(height: 8),
          _DetailRow(
            label: '港幣金額',
            value: _expense!.formattedHkdAmount,
          ),
          const SizedBox(height: 8),
          _DetailRow(
            label: '匯率',
            value: '1 ${_expense!.originalCurrency} = ${_expense!.formattedExchangeRate} HKD',
            trailing: _buildRateSourceChip(),
          ),
        ],

        const Divider(height: 32),

        _DetailRow(
          label: '描述',
          value: _expense!.description,
        ),

        const SizedBox(height: 16),

        _DetailRow(
          label: '日期',
          value: Formatters.formatDate(_expense!.date),
        ),

        const SizedBox(height: 16),

        _DetailRow(
          label: '建立時間',
          value: Formatters.formatDateTime(_expense!.createdAt),
          valueStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildRateSourceChip() {
    final (icon, color, label) = switch (_expense!.exchangeRateSource) {
      ExchangeRateSource.auto => (Icons.check_circle, AppColors.rateAuto, '即時匯率'),
      ExchangeRateSource.offline => (Icons.offline_bolt, AppColors.rateOffline, '離線快取'),
      ExchangeRateSource.defaultRate => (Icons.warning, AppColors.rateDefault, '預設匯率'),
      ExchangeRateSource.manual => (Icons.edit, AppColors.rateManual, '手動輸入'),
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
            label: '金額',
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
            decoration: const InputDecoration(
              labelText: '描述',
              prefixIcon: Icon(Icons.description_outlined),
            ),
            maxLength: ValidationRules.maxDescriptionLength,
            maxLines: 2,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '請輸入描述';
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
            child: const Text('取消編輯'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final provider = context.read<ExpenseProvider>();

      // 安全解析金額
      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('請輸入有效金額'),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('儲存失敗: ${error.message}'),
              backgroundColor: AppColors.error,
            ),
          );
        },
        onSuccess: (expense) {
          setState(() {
            _expense = expense;
            _isEditing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已儲存')),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: const Text('確定要刪除這筆支出嗎？\n刪除後可在「已刪除項目」中還原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('刪除'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('刪除失敗: ${error.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      },
      onSuccess: (_) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已刪除')),
        );
      },
    );
  }

  Future<void> _replaceImage() async {
    final source = await showModalBottomSheet<_ImagePickSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () => Navigator.pop(context, _ImagePickSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('從相簿選擇'),
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
            content: Text('更換圖片失敗: ${error.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      },
      onSuccess: (updated) {
        setState(() {
          _expense = updated;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('圖片已更換')),
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
          heroTag: 'receipt_${_expense!.id}',
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
