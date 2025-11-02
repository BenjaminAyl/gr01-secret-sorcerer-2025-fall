import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/widgets/primary_button.dart';
import '../controllers/lobby_controller.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = LobbyController();

    return Scaffold(
      backgroundColor: AppColors.primaryBrand,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBrand,
        centerTitle: true,
        title: const Text('Lobby', style: TextStyles.heading),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.customAccent),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screen,
          child: Column(
            children: [
              Text(
                'Lobby Code: ${controller.lobbyCode}',
                style: TextStyles.title.copyWith(color: AppColors.customAccent),
              ),
              AppSpacing.spaceL,

              Expanded(
                child: GridView.builder(
                  itemCount: controller.fakePlayers.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 40,
                    crossAxisSpacing: 40,
                    childAspectRatio: 0.8,
                  ),
                  itemBuilder: (context, index) {
                    final playerName = controller.fakePlayers[index];
                    return Column(
                      children: [
                        Image.asset('assets/images/wizard_hat.png',
                            width: 100, height: 100),
                        AppSpacing.gapS,
                        Text(playerName, style: TextStyles.body),
                      ],
                    );
                  },
                ),
              ),

              AppSpacing.spaceL,
              PrimaryButton(
                label: 'Start Game',
                onPressed: () => context.go('/game'),
              ),
              AppSpacing.spaceL,
            ],
          ),
        ),
      ),
    );
  }
}
