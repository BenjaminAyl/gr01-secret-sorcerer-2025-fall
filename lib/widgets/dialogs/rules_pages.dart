import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';

/// A list of pages used by the Rules / Credits spellbook dialog.
/// Each entry is a full widget so we can style content richly.
final List<Widget> rulesPages = [
  // PAGE 1 — Intro / Basic idea
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Secret Sorcerer', style: TextStyles.bookTitle),
      const SizedBox(height: 12),
      Text(
        'Each player secretly aligns with either the Wizards or the Warlocks. '
        'One player is the Arch Warlock.\n\n'
        'Your goal is to discover them before the Warlocks complete their ritual.',
        style: TextStyles.bookBody,
      ),
      const SizedBox(height: 16),
      Text('Basic Idea', style: TextStyles.bookSectionHeading),
      const SizedBox(height: 8),
      Text(
        '• The Wizards want to stop the ritual.\n'
        '• The Warlocks want to complete their summoning.\n'
        '• Talk, bluff, and accuse, but be careful who you trust.',
        style: TextStyles.bookBody,
      ),
    ],
  ),

  // PAGE 2 — Turn structure / flow
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Turn Structure', style: TextStyles.bookTitle),
      const SizedBox(height: 12),
      Text(
        '1. The Headmaster token moves to the next player in turn order.\n'
        '2. The Headmaster nominates a Spellcaster.\n'
        '3. All players vote to approve or reject the proposed pair.\n',
        style: TextStyles.bookBody,
      ),
      const SizedBox(height: 8),
      Text('If the vote passes', style: TextStyles.bookSectionHeading),
      const SizedBox(height: 4),
      Text(
        'The Headmaster secretly draws three spell cards, discards one, and '
        'passes the remaining two to the Spellcaster. The Spellcaster then '
        'chooses one spell to cast and places it in the summoning circle as '
        'either a Charm or a Curse. Cast spells may protect players, reveal '
        'information, or advance the Warlocks’ ritual.',
        style: TextStyles.bookBody,
      ),
      const SizedBox(height: 12),
      Text('If the vote fails', style: TextStyles.bookSectionHeading),
      const SizedBox(height: 4),
      Text(
        'Leadership passes to the next player, and the ritual becomes increasingly '
        'unstable. Consecutive failed votes can trigger unpredictable and '
        'dangerous shifts within the summoning circle.',
        style: TextStyles.bookBody,
      ),
      const SizedBox(height: 16),
      Text('End of Game', style: TextStyles.bookSectionHeading),
      const SizedBox(height: 4),
      Text(
        'The game ends when one of the following occurs:\n'
        '• The Wizards successfully complete five Charms.\n'
        '• The Warlocks complete six Curses.\n'
        '• After three Curses have been cast, the Arch Warlock is elected '
        'as Spellcaster.\n\n'
        'Stay attentive to voting patterns and spell choices—your allies may '
        'not be who they seem. Only careful deduction will reveal the Secret Sorcerer.',
        style: TextStyles.bookBody,
      ),
    ],
  ),

  // PAGE 3 — Credits
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Team
      Text('Development Team', style: TextStyles.bookSectionHeading),
      const SizedBox(height: 8),
      Text(
        'Marco Del Rizzo - Lead Gameplay Developer',
        style: TextStyles.bookBody,
      ),
      Text(
        'Isabella Day - UI/UX Designer & Developer',
        style: TextStyles.bookBody,
      ),
      Text('Benjamin Aylward - Software Developer', style: TextStyles.bookBody),
      Text('Liam Earle - Software Developer', style: TextStyles.bookBody),

      const SizedBox(height: 20),

      // Art
      Text('Art & Visual Design', style: TextStyles.bookSectionHeading),
      const SizedBox(height: 8),
      Text(
        'All game assets were created specifically for Secret Sorcerer.',
        style: TextStyles.bookBody,
      ),

      const SizedBox(height: 20),

      // Inspiration / attribution
      Text('Inspiration', style: TextStyles.bookSectionHeading),
      const SizedBox(height: 8),
      Text(
        'Inspired by the board game "Secret Hitler" by '
        'Mike Boxleiter, Tommy Maranges, and Mac Schubert. '
        'Used under the Creative Commons BY-NC-SA 4.0 License.',
        style: TextStyles.bookBodySmall,
      ),

      const SizedBox(height: 16),
      Text('© 2025 Secret Sorcerer', style: TextStyles.bookBodySmall),
    ],
  ),
];
