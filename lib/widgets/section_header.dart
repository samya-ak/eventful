import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../l10n/app_strings.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onCreatePressed;

  const SectionHeader({super.key, required this.title, this.onCreatePressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        ElevatedButton(
          onPressed: onCreatePressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.button,
            foregroundColor: AppColors.white,
            padding: EdgeInsets.symmetric(
              horizontal: AppConstants.x4,
              vertical: AppConstants.x2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.x2),
            ),
          ),
          child: const Text(AppStrings.createButtonText),
        ),
      ],
    );
  }
}
