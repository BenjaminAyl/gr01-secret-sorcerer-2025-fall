import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:secret_sorcerer/controllers/lobby_controller.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/widgets/primary_button.dart';

class LobbyScreen extends StatefulWidget {
  final String code;
  const LobbyScreen({super.key, required this.code});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final LobbyController controller = LobbyController();

  @override
  void initState() {
    super.initState();
    controller.init(widget.code);
  }

  Future<void> _leave(Map<String, dynamic> data) async {
    await controller.leaveLobby(data);
    if (mounted) context.go('/home');
  }

  Future<void> _start(List<int> ids) async {
    await controller.startGame(ids);
    if (mounted) context.go('/game/${widget.code}');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: controller.lobbyStream,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snap.data!.exists) {
          return Scaffold(
            backgroundColor: AppColors.primaryBrand,
            body: Center(
              child: Text(
                'Lobby not found',
                style: TextStyles.body.copyWith(color: Colors.white),
              ),
            ),
          );
        }

        final data = snap.data!.data()!;
        final status = data['status'] ?? 'waiting';
        final creatorId = (data['creatorId'] as num).toInt();
        final ids = List<int>.from((data['players'] ?? []).cast<int>());
        final isHost = creatorId == controller.playerId;
        final canStart = ids.length >= 2;
        final hostName = 'Wizard_$creatorId';
        final otherPlayers = ids.where((id) => id != creatorId).toList();

        // auto-jump to game when host starts
        if (status == 'playing') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/game/${widget.code}');
          });
        }

        return Scaffold(
          backgroundColor: AppColors.primaryBrand,
          appBar: AppBar(
            backgroundColor: AppColors.primaryBrand,
            elevation: 0,
            centerTitle: true,
            title: const Text('Lobby', style: TextStyles.subheading),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.customAccent),
              onPressed: () => _leave(data),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: AppSpacing.screen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🔹 Lobby Code Banner (Top)
                  Text(
                    'Lobby Code:',
                    style: TextStyles.subheading.copyWith(
                      color: AppColors.textAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 26,
                    ),
                  ),
                  AppSpacing.gapS,
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBrand,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusL),
                    ),
                    child: Text(
                      widget.code,
                      style: TextStyles.title.copyWith(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textAccent,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  AppSpacing.gapL,

                  // 🔹 Host section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'HOST:',
                      style: TextStyles.bodyLarge.copyWith(
                        color: AppColors.textAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  AppSpacing.gapS,
                  Column(
                    children: [
                      Image.asset('assets/images/wizard_hat.png',
                          width: 80, height: 80, fit: BoxFit.contain),
                      AppSpacing.gapXS,
                      Text(
                        hostName,
                        style: TextStyles.body.copyWith(
                          color: AppColors.textAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapL,

                  // 🔹 Player List below host
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          if (otherPlayers.isNotEmpty)
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              alignment: WrapAlignment.center,
                              children: otherPlayers.map((pid) {
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      'assets/images/wizard_hat.png',
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.contain,
                                    ),
                                    AppSpacing.gapXS,
                                    Text(
                                      'Wizard_$pid',
                                      style: TextStyles.bodySmall.copyWith(
                                        color: AppColors.textAccent,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            )
                          else
                            Text(
                              'Waiting for players...',
                              style: TextStyles.body.copyWith(
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          AppSpacing.spaceL,

                          // 🔹 Start button or waiting text
                          if (isHost)
                            SizedBox(
                              width: 220,
                              height: AppSpacing.buttonHeightMedium,
                              child: Opacity(
                                opacity: canStart ? 1 : 0.6,
                                child: IgnorePointer(
                                  ignoring: !canStart,
                                  child: PrimaryButton(
                                    label: 'Start Game',
                                    onPressed: () => _start(ids),
                                  ),
                                ),
                              ),
                            )
                          else
                            Text(
                              'Waiting for host to start...',
                              style: TextStyles.body
                                  .copyWith(color: Colors.white70),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
