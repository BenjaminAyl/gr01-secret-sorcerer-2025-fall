import 'package:flutter/material.dart';
import 'edit_dialog_base.dart';

class EditNicknameDialog extends StatelessWidget {
  final String initial;
  final Future<String?> Function(String nickname) save;

  const EditNicknameDialog({
    super.key,
    required this.initial,
    required this.save,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController(text: initial);

    return EditDialogBase(
      title: 'Edit Nickname',
      fields: [
        EditFieldSpec(
          key: 'nickname',
          label: 'Nickname',
          controller: ctrl,
          maxLength: 8,
          validator: (v) {
            final s = (v ?? '').trim();
            if (s.isEmpty) return 'Nickname can’t be empty';
            if (s.length > 8) return 'Max 8 characters';
            return null;
          },
        ),
      ],
      onSubmit: (values) => save(values['nickname']!),
    );
  }
}
