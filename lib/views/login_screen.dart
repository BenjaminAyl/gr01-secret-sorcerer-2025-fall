import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  void _showSnackBar(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color ?? Colors.red),
    );
  }

  bool _validateInputs() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter both email and password.');
      return false;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _showSnackBar('Please enter a valid email address.');
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
            // Match Signup title styling
            Text('Secret Sorcerer', style: TextStyles.title),
            Text('Login', style: TextStyles.title.copyWith(fontSize: 32)),
            AppSpacing.gapM,

            // Email field – match Signup (TextStyles.inputText, simple hint)
            TextField(
              controller: _emailController,
              style: TextStyles.inputText,
              decoration: const InputDecoration(hintText: 'Email'),
            ),
            AppSpacing.gapM,

            // Password field – match Signup styling
            TextField(
              controller: _passwordController,
              style: TextStyles.inputText,
              decoration: const InputDecoration(hintText: 'Password'),
              obscureText: true,
            ),
            AppSpacing.gapL,

            ElevatedButton(
              onPressed: () async {
                if (!_validateInputs()) return;

                final email = _emailController.text.trim();
                final password = _passwordController.text.trim();

                try {
                  await userAuth.signIn(email: email, password: password);

                  if (!context.mounted) return;
                  context.go('/home');
                } on FirebaseAuthException catch (e) {
                  if (!context.mounted) return;

                  String message = 'Login failed. Please try again.';

                  switch (e.code) {
                    case 'invalid-email':
                      message = 'That email address looks invalid.';
                      break;
                    case 'user-not-found':
                      message =
                          'No account found with that email. Try signing up first.';
                      break;
                    case 'wrong-password':
                      message =
                          'Incorrect password. Double-check your credentials.';
                      break;
                    case 'user-disabled':
                      message =
                          'This account has been disabled. Contact support if this is a mistake.';
                      break;
                    case 'too-many-requests':
                      message =
                          'Too many failed attempts. Please wait a moment and try again.';
                      break;
                    default:
                      message = 'Login failed: ${e.message ?? e.code}';
                  }

                  _showSnackBar(message);
                } catch (e) {
                  if (!context.mounted) return;
                  _showSnackBar(
                    'Unexpected error during login. Please try again later.',
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
