import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/utils/audio_helper.dart';
import 'package:secret_sorcerer/widgets/buttons/chip_button.dart';

class EditDialogBase extends StatefulWidget {
  final String title;
  final List<EditFieldSpec> fields;
  final String submitLabel;

  final Future<String?> Function(Map<String, String> values) onSubmit;

  const EditDialogBase({
    super.key,
    required this.title,
    required this.fields,
    required this.onSubmit,
    this.submitLabel = 'Save',
  });

  @override
  State<EditDialogBase> createState() => _EditDialogBaseState();
}

class _EditDialogBaseState extends State<EditDialogBase> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.secondaryBG, // same app bg as elsewhere
      surfaceTintColor: Colors.transparent, // avoid Material3 tint
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),

      // ✨ Match Signup title styling
      title: Text(widget.title, style: TextStyles.subheading),

      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!),
                ),

              // ✨ Inputs match Signup: filled white, hint-only, inputText style
              ...widget.fields.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: f.controller,
                    obscureText: f.obscureText,
                    maxLength: f.maxLength,
                    keyboardType: f.keyboardType,
                    style: TextStyles.inputText,
                    decoration: InputDecoration(
                      hintText: f.hint ?? f.label, // Signup uses hint-only
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: AppSpacing.item,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(36.0),
                        borderSide: BorderSide.none,
                      ),
                      // Show the same counter style as Signup when maxLength is set
                      counterStyle: f.maxLength != null
                          ? TextStyles.label
                          : null,
                    ),
                    validator: f.validator,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ❌ Cancel chip
            ChipButton(
              icon: Icons.close,
              filled: false,
              onTap: _loading
                  ? () {}
                  : () {
                      AudioHelper.playSFX("backButton.wav");
                      Navigator.of(context).pop();
                    },
            ),
            const SizedBox(width: 16),

            // ✅ Submit chip
            ChipButton(
              icon: _loading ? Icons.hourglass_empty : Icons.check,
              filled: true,
              onTap: _loading
                  ? () {}
                  : () async {
                      setState(() => _error = null);
                      if (!_formKey.currentState!.validate()) return;

                      setState(() => _loading = true);
                      try {
                        final values = {
                          for (final f in widget.fields)
                            f.key: f.controller.text.trim(),
                        };

                        final err = await widget.onSubmit(values);

                        if (err == null && context.mounted) {
                          final resultValue = widget.fields.isNotEmpty
                              ? widget.fields.last.controller.text.trim()
                              : null;

                          context.pop(resultValue);
                        } else {
                          setState(() => _error = err);
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _loading = false);
                        }
                      }
                    },
            ),
          ],
        ),
      ],
    );
  }
}

class EditFieldSpec {
  final String key; // map key returned to onSubmit
  final String label;
  final String? hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final int? maxLength;
  final TextInputType? keyboardType;

  EditFieldSpec({
    required this.key,
    required this.label,
    required this.controller,
    this.validator,
    this.hint,
    this.obscureText = false,
    this.maxLength,
    this.keyboardType,
  });
}
