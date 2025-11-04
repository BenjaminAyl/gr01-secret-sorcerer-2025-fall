import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/widgets/primary_button.dart';
import '../controllers/lobby_controller.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  late LobbyController controller;
  late List<String> players;

  @override
  void initState() {
    super.initState();
    controller = LobbyController();
    players = controller.fakePlayers.take(10).toList(); //generate fake list for now 
  }

  bool get canStart => players.length >= 5 && players.length <= 10;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.primaryBrand,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBrand,
        elevation: 0,
        centerTitle: true,
        title: const Text('Lobby', style: TextStyles.heading),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.customAccent),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              //Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.secondaryBrand,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                ),
                child: Text(
                  'Lobby: ${controller.lobbyCode}',
                  style: TextStyles.title.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              AppSpacing.gapS,

              //Start Section
              SizedBox(
                width: 160,
                height: AppSpacing.buttonHeightSmall,
                child: Opacity(
                  opacity: canStart ? 1.0 : 0.6, //fade if not enough players
                  child: IgnorePointer(
                    ignoring: !canStart, //block taps when not ready
                    child: PrimaryButton(
                      label: 'Start Game',
                      onPressed: () {
                        // Only the host should start the game manually
                        print('[Lobby] Host clicked start — canStart: $canStart');
                        context.go('/game');
                      },
                    ),
                  ),
                ),
              ),

              AppSpacing.gapXS,

              Text(
                canStart
                    ? 'Ready to start!'
                    : 'Need at least 5 players (currently ${players.length})',
                style: TextStyles.body.copyWith(
                  color:
                      canStart ? AppColors.customAccent : Colors.grey.shade400,
                  fontSize: 13,
                ),
              ),

              AppSpacing.gapS,

              // ─── Player Grid ───────────────────────────────
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: players.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // 3 per row
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 0.9,
                  ),
                  itemBuilder: (context, index) {
                    final playerName = players[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/wizard_hat.png',
                          width: size.width * 0.22,
                          height: size.width * 0.22,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: size.width * 0.25,
                          child: Text(
                            playerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyles.body.copyWith(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
