import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/primary_button.dart';
import 'package:client/features/sessions/application/sessions_controller.dart';

class NewSessionSheet extends ConsumerStatefulWidget {
  const NewSessionSheet({super.key});

  @override
  ConsumerState<NewSessionSheet> createState() => _NewSessionSheetState();
}

class _NewSessionSheetState extends ConsumerState<NewSessionSheet> {
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'O nome não pode estar vazio.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(sessionsControllerProvider.notifier).create(name);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Erro ao criar sessão. Tente novamente.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nova sessão', style: AppText.navTitle),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            key: const Key('session_name_field'),
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            style: AppText.bodyMd,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Nome',
              hintText: 'ex: Harry Potter cap. 3',
              errorText: _error,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Criar',
            icon: Icons.add,
            isLoading: _isLoading,
            onPressed: _submit,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
