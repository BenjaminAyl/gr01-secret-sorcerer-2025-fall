import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/widgets/info_row.dart';

class ManageFriendsScreen extends StatefulWidget {
  const ManageFriendsScreen({super.key});

  @override
  State<ManageFriendsScreen> createState() => _ManageFriendsScreenState();
}

class _ManageFriendsScreenState extends State<ManageFriendsScreen> {
  final _usernameCtrl = TextEditingController();

  // Mock list just to render the UI; not wired to any backend.
  final List<String> _mockFriends = const [
    'Marco',
    'Ben',
    'Bella',
    'Liam',
    'Pranjal',
  ];

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBrand,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBrand,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.customAccent,
            size: AppSpacing.iconSizeLarge, 
          ),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        title: const Text('Manage Friends', style: TextStyles.subheading),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Add Friend ---
              Text(
                'Add Friend',
                style: TextStyles.bodyLarge.copyWith(color: Colors.white),
              ),
              AppSpacing.gapS,
              TextField(
                controller: _usernameCtrl,
                style: const TextStyle(color: AppColors.secondaryBrand),
                decoration: InputDecoration(
                  hintText: 'Username',
                  hintStyle: const TextStyle(
                    color: AppColors.customAccent,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: AppSpacing.item,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              AppSpacing.gapM,
              Center(
                child: SizedBox(
                  width: AppSpacing.cardWidthNarrow,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: call backend to send friend request using _usernameCtrl.text
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryBrand,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(
                        double.infinity,
                        AppSpacing.buttonHeightSmall,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusButton,
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Add', style: TextStyles.body),
                  ),
                ),
              ),

              AppSpacing.gapXXL,

              // --- Friends List ---
              Center(
                child: Text(
                  'Friends List',
                  style: TextStyles.bodyLarge.copyWith(color: Colors.white),
                ),
              ),
              AppSpacing.gapL,

              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _mockFriends.length,
                separatorBuilder: (_, __) => AppSpacing.gapM,
                itemBuilder: (context, i) {
                  final name = _mockFriends[i];
                  return InfoRow(
                    title: name,
                    value: '@username',
                    actionLabel: 'Remove',
                    onPress: () {
                      // TODO: call backend to remove friend `name`
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
