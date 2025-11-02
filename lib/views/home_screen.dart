import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/widgets/primary_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppSpacing.gapL,
              const Text('Secret Sorcerer', style: TextStyles.title),
              AppSpacing.spaceXXL,

              PrimaryButton(
                label: 'Host Game',
                onPressed: () => context.go('/lobby'),
              ),
              AppSpacing.buttonSpacing,
              PrimaryButton(
                label: 'Join Game',
                onPressed: () {
                  // TODO: route to /join when implemented
                },
              ),

              const Spacer(),

              // Bottom buttons for profile and rules
              Padding(
                padding: AppSpacing.item,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppSpacing.gapWL,

                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            // TODO: navigate to /rules when implemented
                          },
                          child: Image.asset(
                            'assets/images/tome.png', // TODO: CREATE ASSET
                            width: 70,
                            height: 70,
                          ),
                        ),
                        AppSpacing.gapXS,
                        const Text('RULES', style: TextStyles.body),
                      ],
                    ),

                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            context.go('/profile');
                          },
                          child: Image.asset(
                            'assets/images/wizard_hat.png', // TODO: CREATE ASSET
                            width: 70,
                            height: 70,
                          ),
                        ),
                        AppSpacing.gapXS,
                        const Text('PROFILE', style: TextStyles.body),
                      ],
                    ),

                    AppSpacing.gapWL,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
