import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
            const Text('Login', style: TextStyles.heading),
            AppSpacing.gapM,
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(hintText: 'Email'),
            ),
            AppSpacing.gapM,
            TextField(
              controller: _passwordController,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(hintText: 'Password'),
              obscureText: true,
            ),
            AppSpacing.gapL,
            ElevatedButton(
              onPressed: () async {
                try {
                  final email = _emailController.text.trim();
                  final password = _passwordController.text.trim();

                  await userAuth.signIn(email: email, password: password);

                  if (!context.mounted) return;
                  context.go('/home');
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Login failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Login'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account?", style: TextStyles.body),
                TextButton(
                  onPressed: () => context.go('/signup'),
                  child: const Text('Sign up'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
