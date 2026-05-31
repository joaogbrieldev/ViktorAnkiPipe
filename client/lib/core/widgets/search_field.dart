import 'package:flutter/material.dart';

import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';

class SearchField extends StatelessWidget {
  const SearchField({
    required this.controller,
    this.hintText = 'Buscar',
    super.key,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          style: AppText.bodyMd,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppText.bodyMd.copyWith(
              color: AppColors.outline,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: AppColors.outline,
              size: 20,
            ),
            suffixIcon: value.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    color: AppColors.outline,
                    onPressed: controller.clear,
                  )
                : null,
            filled: true,
            fillColor: AppColors.searchFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }
}
