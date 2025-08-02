import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ThreeDotMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showEdit;
  final bool showDelete;

  const ThreeDotMenu({
    super.key,
    this.onEdit,
    this.onDelete,
    this.showEdit = true,
    this.showDelete = true,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.white, size: 20),
      color: AppColors.secondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColors.whiteWithAlpha(0.2), width: 1),
      ),
      itemBuilder: (BuildContext context) {
        List<PopupMenuEntry<String>> items = [];

        if (showEdit) {
          items.add(
            PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit, color: AppColors.white, size: 18),
                  const SizedBox(width: 12),
                  const Text(
                    'Edit',
                    style: TextStyle(color: AppColors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        if (showDelete) {
          items.add(
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, color: Colors.red, size: 18),
                  const SizedBox(width: 12),
                  const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        return items;
      },
      onSelected: (String value) {
        switch (value) {
          case 'edit':
            onEdit?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
    );
  }
}
