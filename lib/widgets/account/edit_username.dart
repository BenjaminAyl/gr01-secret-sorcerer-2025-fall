import 'package:flutter/material.dart';
import 'edit_dialog_base.dart';

class EditUsernameDialog extends StatelessWidget {
  final String initial;
  final Future<String?> Function(String username) save; // null on success

  const EditUsernameDialog({
    super.key,
    required this.initial,
    required this.save,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController(text: initial);

    return EditDialogBase(
      title: 'Edit Username',
      fields: [
        EditFieldSpec(
          key: 'username',
          label: 'Username',
          controller: ctrl,
          maxLength: 16,
          validator: (v) {
            final s = (v ?? '').trim();
            if (s.isEmpty) return 'Username can’t be empty';
            final valid = RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(s);
            if (!valid) return 'Letters, numbers, underscore only';
            if (s.length > 16) return 'Max 16 characters';
            return null;
          },
        ),
      ],
      onSubmit: (values) => save(values['username']!),
    );
  }
}
