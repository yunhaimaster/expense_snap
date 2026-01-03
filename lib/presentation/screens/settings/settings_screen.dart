import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/local/database_helper.dart';

/// 設定畫面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _userName = AppConstants.defaultUserName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final db = DatabaseHelper.instance;
    final name = await db.getSetting('user_name');

    if (mounted) {
      setState(() {
        _userName = name ?? AppConstants.defaultUserName;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // 個人資料區塊
                _SectionHeader(title: '個人資料'),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('姓名'),
                  subtitle: Text(_userName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _editUserName,
                ),

                const Divider(),

                // 資料管理區塊
                _SectionHeader(title: '資料管理'),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('已刪除項目'),
                  subtitle: const Text('查看和還原已刪除的支出'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRouter.deletedItems);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cleaning_services_outlined),
                  title: const Text('清理暫存檔'),
                  subtitle: const Text('釋放匯出暫存空間'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _cleanupTempFiles,
                ),

                const Divider(),

                // 雲端備份區塊（Phase 5 實作）
                _SectionHeader(title: '雲端備份'),
                ListTile(
                  leading: const Icon(Icons.cloud_outlined),
                  title: const Text('Google 雲端硬碟'),
                  subtitle: const Text('尚未連接'),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: false, // Phase 5 啟用
                  onTap: null,
                ),
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('備份'),
                  enabled: false, // Phase 5 啟用
                  onTap: null,
                ),
                ListTile(
                  leading: const Icon(Icons.restore_outlined),
                  title: const Text('還原'),
                  enabled: false, // Phase 5 啟用
                  onTap: null,
                ),

                const Divider(),

                // 關於區塊
                _SectionHeader(title: '關於'),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('版本'),
                  subtitle: Text('${AppConstants.appName} v${AppConstants.appVersion}'),
                ),
              ],
            ),
    );
  }

  Future<void> _editUserName() async {
    final controller = TextEditingController(text: _userName);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('編輯姓名'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '姓名',
            hintText: '用於報銷單標題',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('儲存'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (newName == null || newName.isEmpty || !mounted) return;

    final db = DatabaseHelper.instance;
    await db.setSetting('user_name', newName);

    setState(() => _userName = newName);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已儲存')),
      );
    }
  }

  Future<void> _cleanupTempFiles() async {
    // Phase 4 實作詳細邏輯
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('清理功能將在 Phase 4 實作')),
    );
  }
}

/// 區塊標題
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
