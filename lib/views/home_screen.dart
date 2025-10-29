import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';

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

              ElevatedButton(
                onPressed: () {
                  // TODO: route to /host when implemented
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(300, 80),
                ),
                child: const Text('Host Game', style: TextStyles.subheading),
              ),
              AppSpacing.spaceL,
              ElevatedButton(
                onPressed: () {
                  // TODO: route to /join when implemented
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(300, 80),
                ),
                child: const Text('Join Game', style: TextStyles.subheading),
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
                            // TODO: navigate to /profile when implemented
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
