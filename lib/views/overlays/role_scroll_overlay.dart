import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:secret_sorcerer/views/game_view.dart';
import 'package:secret_sorcerer/models/game_player.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/utils/audio_helper.dart';

class RoleScrollOverlay extends StatefulWidget {
  final WizardGameView game;
  final String myUid;
  final double height;
  final double width;

  const RoleScrollOverlay({
    super.key,
    required this.game,
    required this.myUid,
    required this.height,
    required this.width,
  });

  @override
  State<RoleScrollOverlay> createState() => _RoleScrollOverlayState();
}

class _RoleScrollOverlayState extends State<RoleScrollOverlay>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _heightAnim;

  bool _holding = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 260),
      vsync: this,
    );

    _heightAnim = Tween<double>(
      begin: 0,
      end: widget.height * 0.32,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final h = widget.height;
    final w = widget.width;
    final game = widget.game;

    GamePlayer? me = game.players.firstWhere(
      (p) => p.username == widget.myUid,
      orElse: () => GamePlayer(username: widget.myUid, role: 'wizard'),
    );

    final bool isDead = game.dead[widget.myUid] == true;

    final roleName = _roleLabel(me.role);
    final roleColour = _roleColour(me.role);
    final roleBlurb = _roleDescription(me.role, isDead: isDead);

    final knownIds = _knownPartnerIds(me);
    final allies = game.players.where((p) => knownIds.contains(p.username)).toList();

    return Stack(
      children: [
        // Animated unrolling scroll
        Positioned(
          left: w * 0.05,
          right: w * 0.05,
          bottom: h * 0.11,
          child: AnimatedBuilder(
            animation: _heightAnim,
            builder: (context, _) {
              if (_heightAnim.value <= 2) return const SizedBox.shrink();
              return _buildScroll(
                h: _heightAnim.value,
                w: w,
                roleName: roleName,
                roleColour: roleColour,
                roleBlurb: roleBlurb,
                allies: allies,
                isDead: isDead,
                game: game,
              );
            },
          ),
        ),

        // Press & hold handle
        Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onLongPressStart: (_) {
              setState(() => _holding = true);
              _controller.forward();
              AudioHelper.playSFX("paperRoll.mp3");
            },
            onLongPressEnd: (_) {
              setState(() => _holding = false);
              _controller.reverse();
            },
            child: _buildScrollHandle(h: h, w: w),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // SCROLL HANDLE
  // -------------------------------------------------------------
  Widget _buildScrollHandle({required double h, required double w}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: EdgeInsets.only(bottom: h * 0.02),
      height: h * 0.06,
      width: w * 0.55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(h * 0.04),
        gradient: const LinearGradient(
          colors: [Color(0xFFCCB48A), Color(0xFFEAD2A0), Color(0xFFCCB48A)],
        ),
        border: Border.all(color: Color(0xFF8B6A3B), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _holding
                ? Colors.amberAccent.withOpacity(0.6)
                : Colors.black.withOpacity(0.25),
            blurRadius: _holding ? 16 : 6,
            spreadRadius: _holding ? 1 : 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          "Hold to reveal your role",
          style: TextStyles.bodySmall.copyWith(
            color: const Color(0xFF4E3716),
            fontSize: h * 0.018,
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // MAIN SCROLL (UNROLLED)
  // -------------------------------------------------------------
  Widget _buildScroll({
    required double h,
    required double w,
    required String roleName,
    required Color roleColour,
    required String roleBlurb,
    required List<GamePlayer> allies,
    required bool isDead,
    required WizardGameView game,
  }) {
    return Container(
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFFF5E2B8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8B6A3B), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(w * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              isDead ? "Your Fate" : "Your Secret Role",
              style: TextStyles.subheading.copyWith(
                color: const Color(0xFF3A2610),
              ),
            ),

            SizedBox(height: w * 0.02),

            // Role Name
            Text(
              roleName,
              style: TextStyles.heading.copyWith(
                color: roleColour,
              ),
            ),

            SizedBox(height: w * 0.02),

            // Description
            Text(
              roleBlurb,
              style: TextStyles.body.copyWith(
                color: const Color(0xFF4B3823),
                height: 1.25,
              ),
            ),

            SizedBox(height: w * 0.04),

            // Allies or message
            if (!isDead && allies.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: allies.length,
                  itemBuilder: (_, i) {
                    final ally = allies[i];
                    final name = game.nicknameCache[ally.username] ?? "Unknown";

                    return Padding(
                      padding: EdgeInsets.only(bottom: w * 0.01),
                      child: Text(
                        "• $name",
                        style: TextStyles.bodySmall.copyWith(
                          color: const Color(0xFF3D2711),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Expanded(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    isDead
                        ? "You drift as a silent specter."
                        : "Keep your loyalty hidden.",
                    style: TextStyles.label.copyWith(
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF5A4024),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'archwarlock':
        return "Archwarlock";
      case 'warlock':
        return "Warlock";
      default:
        return "Wizard";
    }
  }

  Color _roleColour(String role) {
    switch (role) {
      case 'archwarlock':
        return Colors.deepOrangeAccent;
      case 'warlock':
        return Colors.redAccent;
      default:
        return AppColors.textAccent;
    }
  }

  String _roleDescription(String role, {required bool isDead}) {
    if (isDead) {
      return "You have been eliminated.\nYou may watch, but cannot act.";
    }
    switch (role) {
      case 'archwarlock':
        return "You are the hidden leader of the warlocks.";
      case 'warlock':
        return "Work with the archwarlock to corrupt the realm.";
      default:
        return "You are a loyal wizard defending the realm.";
    }
  }

  List<String> _knownPartnerIds(GamePlayer me) {
    if (me.vote == null || me.vote!.trim().isEmpty) {
      return const [];
    }
    return me.vote!.split(',').map((s) => s.trim()).toList();
  }

}
