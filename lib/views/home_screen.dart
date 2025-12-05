import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/widgets/buttons/primary_button.dart';
import 'package:secret_sorcerer/controllers/firebase.dart';
import 'package:secret_sorcerer/utils/audio_helper.dart';
import 'package:secret_sorcerer/widgets/dialogs/rules_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    AudioHelper.crossfade("TavernThemeMusic.wav");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/textures/fog2.png'),
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppSpacing.gapXXL,
              AppSpacing.gapXXL,
              Image.asset(
                'assets/logos/secretSorcerer.png', // <- your image path
                width: 380, // adjust as needed
                height: 200,
                fit: BoxFit.contain,
              ),
              AppSpacing.spaceL,
              AppSpacing.gapXL,

              PrimaryButton(
                label: 'Host Game',
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please sign in first')),
                    );
                    return;
                  }

                  final controller = FirebaseController();
                  final lobbyRef = await controller.createLobby();
                  final lobbyId = lobbyRef.id;

                  if (context.mounted) {
                    context.go('/lobby/$lobbyId');
                    AudioHelper.playSFX("hostJoin.wav");
                  }
                },
              ),

              //AppSpacing.gapXXL,
              AppSpacing.buttonSpacing,

              PrimaryButton(
                label: 'Join Game',
                onPressed: () {
                  AudioHelper.playSFX("enterButton.wav");
                  context.go('/join');
                },
              ),

              const Spacer(),

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
                            showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (_) => const RulesDialog(),
                            );
                            AudioHelper.playSFX("paperRoll.mp3");
                          },
                          child: Image.asset(
                            'assets/images/tome.png',
                            width: 70,
                            height: 70,
                          ),
                        ),
                        AppSpacing.gapXS,
                        const Text('Rules', style: TextStyles.body),
                      ],
                    ),
                    AppSpacing.gapWL,
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            AudioHelper.playSFX("enterButton.wav");
                            context.push('/leaderboard');
                          },
                          child: Image.asset(
                            'assets/images/trophy.png',
                            width: 70,
                            height: 70,
                          ),
                        ),
                        AppSpacing.gapXS,
                        const Text('Leaderboard', style: TextStyles.body),
                      ],
                    ),
                    AppSpacing.gapWL,
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            AudioHelper.playSFX("enterButton.wav");
                            context.push('/profile');
                          },
                          child: Image.asset(
                            'assets/images/wizard_hat.png',
                            width: 70,
                            height: 70,
                          ),
                        ),
                        AppSpacing.gapXS,
                        const Text('Profile', style: TextStyles.body),
                      ],
                    ),
                    AppSpacing.gapWL,
                  ],
                ),
              ),
              AppSpacing.gapXL,
              AppSpacing.gapL,
            ],
          ),
        ),
      ),
    );
  }
}
