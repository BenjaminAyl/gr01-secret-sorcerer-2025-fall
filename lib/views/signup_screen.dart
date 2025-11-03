import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/main.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: AppSpacing.screen,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 10,
          children: [
            const Text('Secret Sorcerer', style: TextStyles.title),
            AppSpacing.gapL,
            const Text('Become a Sorcerer!', style: TextStyles.heading),
            AppSpacing.gapL,
            TextField(
              controller: _emailController,
              style: TextStyles.inputText,
              decoration: InputDecoration(hintText: 'Email'),
            ),
            AppSpacing.gapM,
            TextField(
              controller: _passwordController,
              style: TextStyles.inputText,
              decoration: InputDecoration(hintText: 'Password'),
              obscureText: true,
            ),
            AppSpacing.gapM,
            TextField(
              controller: _usernameController,
              style: TextStyles.inputText,
              decoration: InputDecoration(
                hintText: 'Username',
                counterStyle: TextStyles.label,
              ),
              maxLength: 16,
            ),
            AppSpacing.gapM,
            TextField(
              controller: _nicknameController,
              style: TextStyles.inputText,
              decoration: InputDecoration(
                hintText: 'Nickname',
                counterStyle: TextStyles.label,
              ),
              maxLength: 8,
            ),
            AppSpacing.gapL,
            ElevatedButton(
              onPressed: () async {
                final username = _usernameController.text.trim().toLowerCase();
                final email = _emailController.text.trim();
                final password = _passwordController.text;
                final nickname = _nicknameController.text.trim();

                try {
                  // Check username availability
                  final available = await userAuth.isUsernameAvailable(
                    username,
                  );
                  if (!available) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('That username is already taken.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Try to create the account
                  await userAuth.signUp(
                    email: email,
                    password: password,
                    username: username,
                    nickname: nickname,
                  );

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🎉 Account created successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sign-up failed. Please try again. $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Continue'),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account?", style: TextStyles.body),
                TextButton(
                  onPressed: () => context.go('/'),
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
