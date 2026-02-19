import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

/// 收據圖片選擇區塊 — 拍照/相簿選擇 + 圖片預覽
class ImagePickerSection extends StatelessWidget {
  const ImagePickerSection({
    super.key,
    required this.selectedImagePath,
    required this.onPickFromCamera,
    required this.onPickFromGallery,
    required this.onRemoveImage,
  });

  final String? selectedImagePath;
  final VoidCallback onPickFromCamera;
  final VoidCallback onPickFromGallery;
  final VoidCallback onRemoveImage;

  @override
  Widget build(BuildContext context) {
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

        if (selectedImagePath != null)
          // 圖片預覽
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(selectedImagePath!),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  // 限制記憶體，2x 以支援高密度螢幕
                  cacheHeight: 400,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: onRemoveImage,
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
                  onTap: onPickFromCamera,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ImagePickerButton(
                  icon: Icons.photo_library,
                  label: l10n.addExpense_gallery,
                  onTap: onPickFromGallery,
                ),
              ),
            ],
          ),
      ],
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
