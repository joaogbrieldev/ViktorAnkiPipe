import 'package:flutter/material.dart';

import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';

class GroupedListCard extends StatelessWidget {
  const GroupedListCard({
    required this.children,
    this.dividerIndent = AppSpacing.lg,
    super.key,
  });

  final List<Widget> children;
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _interleave(children),
        ),
      ),
    );
  }

  List<Widget> _interleave(List<Widget> items) {
    if (items.isEmpty) return [];
    final result = <Widget>[items.first];
    for (var i = 1; i < items.length; i++) {
      result.add(Divider(
        height: 0.5,
        thickness: 0.5,
        color: AppColors.outlineVariant,
        indent: dividerIndent,
      ));
      result.add(items[i]);
    }
    return result;
  }
}
