import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../l10n/app_strings.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      leading: Padding(
        padding: EdgeInsets.all(AppConstants.x3),
        child: Center(
          child: Text(
            AppStrings.appName,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 21, // Custom size
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      leadingWidth: 120, // Custom size
      title: const SizedBox.shrink(),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
