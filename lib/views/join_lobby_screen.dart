import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/widgets/primary_button.dart';
import 'package:secret_sorcerer/controllers/firebase.dart';
import 'package:secret_sorcerer/utils/dev_auth.dart';


class JoinLobbyScreen extends StatefulWidget {
  const JoinLobbyScreen({super.key});

  @override
  State<JoinLobbyScreen> createState() => _JoinLobbyScreenState();
}

class _JoinLobbyScreenState extends State<JoinLobbyScreen> {
  final TextEditingController _controller = TextEditingController();

  bool get _isCodeComplete => _controller.text.length == 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleJoinPressed() async {
    final controller = FirebaseController();
    final playerId = await devSignInAndGetPlayerId();

    final code = int.tryParse(_controller.text.trim());
    if (code == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter valid 4-digit code')));
      return;
    }

  await controller.joinLobby(code, playerId).first;
  if (mounted) context.go('/lobby/$code');
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBrand,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: AppSpacing.screen,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ---- Title ----
                Text(
                  'Enter Game Code',
                  style: TextStyles.title.copyWith(
                    color: AppColors.textAccent,
                    shadows: const [
                      Shadow(blurRadius: 10, color: AppColors.customAccent),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),

                AppSpacing.gapXL,

                // ---- 4-digit input ----
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _controller,
                    maxLength: 4,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      letterSpacing: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    cursorColor: AppColors.customAccent,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '----',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 40,
                        letterSpacing: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      filled: true,
                      fillColor: AppColors.secondaryBrand.withOpacity(0.4),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusL),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusL),
                        borderSide: const BorderSide(
                          color: AppColors.customAccent,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),

                AppSpacing.gapXL,

                // ---- Join Button ----
                Opacity(
                  opacity: _isCodeComplete ? 1.0 : 0.5,
                  child: IgnorePointer(
                    ignoring: !_isCodeComplete,
                    child: PrimaryButton(
                      label: 'Join Game',
                      onPressed: _handleJoinPressed,
                    ),
                  ),
                ),

                AppSpacing.gapL,

                // ---- Helper text ----
                Text(
                  'Ask your host for their 4-digit code',
                  style: TextStyles.body.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
