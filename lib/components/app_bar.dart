import 'package:flutter/material.dart';

/// Generates the AppBar. Receives context and Text for screen name.
/// showBack: Bool to indicate if back buttons needs to be shown.
/// In case it's true, returns to the windows assigned to onBack.
/// In case onBack is null, returns to the last windows.
AppBar generateAppBar(
  BuildContext context,
  String screenName, {
  bool showBack = false,
  VoidCallback? onBack,
}) {
  return AppBar(
    leading:
        showBack
            ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack ?? () => Navigator.of(context).pop(),
            )
            : null,
    title: Text(screenName, style: const TextStyle(fontSize: 24)),
  );
}
