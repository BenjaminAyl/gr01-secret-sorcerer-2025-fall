import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/main.dart';
import 'package:secret_sorcerer/utils/audio_helper.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  void _showSnackBar(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color ?? Colors.red),
    );
  }

  bool _validateInputs() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final username = _usernameController.text.trim();
    final nickname = _nicknameController.text.trim();

    if (email.isEmpty ||
        password.isEmpty ||
        username.isEmpty ||
        nickname.isEmpty) {
      _showSnackBar('Please fill in all fields before continuing.');
      return false;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _showSnackBar('Please enter a valid email address.');
      return false;
    }

    // Password must be at least 6 characters (per your request)
    if (password.length < 6) {
      _showSnackBar('Password must be at least 6 characters long.');
      return false;
    }

    if (username.length < 3 || username.length > 16) {
      _showSnackBar('Username must be between 3 and 16 characters.');
      return false;
    }

    if (nickname.length < 2 || nickname.length > 8) {
      _showSnackBar('Nickname must be between 2 and 8 characters.');
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: AppSpacing.screen,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 10,
          children: [
            Image.asset(
              'assets/logos/secretSorcerer.png', // <- your image path
              width: 380, // adjust as needed
              height: 200,
              fit: BoxFit.contain,
            ),
            Text(
              'Become a Sorcerer!',
              style: TextStyles.title.copyWith(fontSize: 32),
            ),
            AppSpacing.gapL,

            // Email
            TextField(
              controller: _emailController,
              style: TextStyles.inputText,
              decoration: const InputDecoration(hintText: 'Email'),
            ),
            AppSpacing.gapS,

            // Password
            TextField(
              controller: _passwordController,
              style: TextStyles.inputText,
              decoration: const InputDecoration(hintText: 'Password'),
              obscureText: true,
            ),
            AppSpacing.gapS,

            // Username
            TextField(
              controller: _usernameController,
              style: TextStyles.inputText,
              decoration: const InputDecoration(
                hintText: 'Username',
                counterStyle: TextStyles.label,
              ),
              maxLength: 16,
            ),

            // Nickname
            TextField(
              controller: _nicknameController,
              style: TextStyles.inputText,
              decoration: const InputDecoration(
                hintText: 'Nickname',
                counterStyle: TextStyles.label,
              ),
              maxLength: 8,
            ),

            AppSpacing.gapL,

            ElevatedButton(
              onPressed: () async {
                AudioHelper.playSFX("enterButton.wav");

                if (!_validateInputs()) return;

                final username = _usernameController.text.trim().toLowerCase();
                final email = _emailController.text.trim();
                final password = _passwordController.text;
                final nickname = _nicknameController.text.trim();

                try {
                  final available = await userAuth.isUsernameAvailable(
                    username,
                  );
                  if (!available) {
                    _showSnackBar('That username is already taken.');
                    return;
                  }

                  await userAuth.signUp(
                    email: email,
                    password: password,
                    username: username,
                    nickname: nickname,
                  );

                  if (!mounted) return;
                  _showSnackBar(
                    '🎉 Account created successfully!',
                    color: Colors.green,
                  );
                  context.go('/');
                } on FirebaseAuthException catch (e) {
                  if (!mounted) return;

                  String message = 'Sign-up failed. Please try again.';

                  switch (e.code) {
                    case 'invalid-email':
                      message = 'That email address looks invalid.';
                      break;
                    case 'email-already-in-use':
                      message = 'An account already exists with that email.';
                      break;
                    case 'weak-password':
                      message = 'Your password must be at least 6 characters.';
                      break;
                    default:
                      message = 'Sign-up failed: ${e.message ?? e.code}';
                  }

                  _showSnackBar(message);
                } catch (e) {
                  if (!mounted) return;
                  _showSnackBar('Unexpected error. Please try again later.');
                }
              },
              child: const Text('Continue'),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account?", style: TextStyles.body),
                TextButton(
                  onPressed: () {
                    AudioHelper.playSFX("enter_button.wav");
                    context.go('/');
                  },
                  child: const Text('Login'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
