import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/utils/audio_helper.dart';
import 'rules_pages.dart';

class RulesDialog extends StatefulWidget {
  const RulesDialog({super.key});

  @override
  State<RulesDialog> createState() => _RulesDialogState();
}

class _RulesDialogState extends State<RulesDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  String get _currentTitle {
    if (_currentPage == 2) return 'Credits';
    return 'Rules';
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          width: size.width * 0.9,
          height: size.height * 0.7,
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: AssetImage('assets/textures/parchment.png'),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                blurRadius: 16,
                spreadRadius: 2,
                color: Colors.black.withOpacity(0.4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Title + Close Button
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _currentTitle,
                      style: TextStyles.title.copyWith(
                        color: AppColors.primaryBrand,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: AppColors.primaryBrand,
                    onPressed: () {
                      Navigator.of(context).pop();
                      AudioHelper.playSFX('paperRoll.mp3');
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),
              const Divider(thickness: 1),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: rulesPages.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                    AudioHelper.playSFX('paperRoll.mp3');
                  },
                  itemBuilder: (_, index) {
                    return SingleChildScrollView(
                      child: DefaultTextStyle(
                        // Fallback style if a child Text has no explicit style
                        style: TextStyles.body.copyWith(
                          color: AppColors.primaryBrand,
                        ),
                        child: rulesPages[index],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Bottom controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _currentPage > 0
                        ? () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          )
                        : null,
                    icon: const Icon(Icons.arrow_back),
                    color: AppColors.primaryBrand,
                  ),
                  Text(
                    'Page ${_currentPage + 1} / ${rulesPages.length}',
                    style: TextStyles.body.copyWith(
                      color: AppColors.primaryBrand,
                    ),
                  ),
                  IconButton(
                    onPressed: _currentPage < rulesPages.length - 1
                        ? () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          )
                        : null,
                    icon: const Icon(Icons.arrow_forward),
                    color: AppColors.primaryBrand,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
