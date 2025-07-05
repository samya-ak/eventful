import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/event.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;

  const EventCard({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.secondary,
      margin: EdgeInsets.only(bottom: AppConstants.x3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.x3),
        side: BorderSide(color: AppColors.whiteWithAlpha(0.1), width: 1),
      ),
      elevation: 2,
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppConstants.x3,
          vertical: AppConstants.x1,
        ),
        title: Text(
          event.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: AppConstants.x1),
          child: Text(
            event.description,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.whiteWithAlpha(0.7),
              height: 1.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
