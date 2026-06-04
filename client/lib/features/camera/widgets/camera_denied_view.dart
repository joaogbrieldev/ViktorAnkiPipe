import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/primary_button.dart';

class CameraDeniedView extends StatelessWidget {
  const CameraDeniedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.camera_alt_outlined,
            size: 64,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Precisamos da câmera',
            style: AppText.navTitle.copyWith(color: AppColors.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Permita o acesso à câmera nas configurações do sistema.',
            style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          const PrimaryButton(
            label: 'Abrir Configurações',
            onPressed: openAppSettings,
          ),
        ],
      ),
    );
  }
}
