import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/widgets/primary_button.dart';
import 'package:secret_sorcerer/utils/dev_auth.dart';
import 'package:secret_sorcerer/controllers/firebase.dart';


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
                onPressed: () async {
                  final controller = FirebaseController();
                  final playerId = await devSignInAndGetPlayerId();

                  final lobbyStream = controller.createLobby(playerId);
                  final snap = await lobbyStream.first;
                  final lobbyId = int.parse(snap.id);

                  if (context.mounted) context.go('/lobby/$lobbyId');
                },
              ),
              AppSpacing.buttonSpacing,
              PrimaryButton(
                label: 'Join Game',
                onPressed: () => context.go('/join'),
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
