import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../widgets/forms/date_picker_field.dart';

/// 匯出畫面（Phase 4 實作，這裡先建立佔位）
class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('匯出報銷單'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 月份選擇
            MonthPickerField(
              year: _selectedYear,
              month: _selectedMonth,
              onChanged: (year, month) {
                setState(() {
                  _selectedYear = year;
                  _selectedMonth = month;
                });
              },
            ),

            const SizedBox(height: 24),

            // 匯出預覽（Phase 4 實作）
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 48,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$_selectedYear 年 $_selectedMonth 月',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '功能將在 Phase 4 實作',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // 匯出按鈕
            ElevatedButton.icon(
              onPressed: null, // Phase 4 啟用
              icon: const Icon(Icons.file_download),
              label: const Text('匯出 Excel'),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: null, // Phase 4 啟用
              icon: const Icon(Icons.folder_zip),
              label: const Text('匯出 Excel + 收據'),
            ),
          ],
        ),
      ),
    );
  }
}
