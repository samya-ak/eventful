import 'package:flutter/material.dart';
import '../config/supabase_config.dart';

/// Utility class for admin-related functionality
class AdminUtils {
  /// Check if the current user is an admin
  static bool get isAdmin => SupabaseConfig.isAdmin;

  /// Show admin-only widget if user is admin, otherwise return null
  static Widget? adminOnly(Widget widget) {
    return isAdmin ? widget : null;
  }

  /// Show admin-only widget if user is admin, otherwise return alternative widget
  static Widget adminOrElse(Widget adminWidget, Widget userWidget) {
    return isAdmin ? adminWidget : userWidget;
  }

  /// Execute admin-only callback if user is admin
  static VoidCallback? adminOnlyCallback(VoidCallback callback) {
    return isAdmin ? callback : null;
  }
}
