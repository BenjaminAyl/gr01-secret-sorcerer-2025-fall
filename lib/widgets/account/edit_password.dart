import 'package:flutter/material.dart';
import 'package:secret_sorcerer/widgets/account/edit_dialog_base.dart';

class EditPasswordDialog extends StatelessWidget {
  final Future<bool> Function(String currentPassword) verifyCurrent;
  final Future<String?> Function(String newPassword) changePassword;

  const EditPasswordDialog({
    super.key,
    required this.verifyCurrent,
    required this.changePassword,
  });

  @override
  Widget build(BuildContext context) {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();

    return EditDialogBase(
      title: 'Change Password',
      submitLabel: 'Update',
      fields: [
        EditFieldSpec(
          key: 'current',
          label: 'Current Password',
          controller: current,
          obscureText: true,
          validator: (v) => (v == null || v.isEmpty) ? 'Enter current password' : null,
        ),
        EditFieldSpec(
          key: 'new',
          label: 'New Password',
          controller: next,
          obscureText: true,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter new password';
            if (v.length < 8) return 'Use at least 8 characters';
            return null;
          },
        ),
        EditFieldSpec(
          key: 'confirm',
          label: 'Confirm New Password',
          controller: confirm,
          obscureText: true,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Confirm your new password';
            if (v != next.text) return 'Passwords do not match';
            return null;
          },
        ),
      ],
      onSubmit: (values) async {
        final ok = await verifyCurrent(values['current']!);
        if (!ok) return 'Current password is incorrect';
        return await changePassword(values['new']!);
      },
    );
  }
}
