import 'package:flutter/material.dart';

// Generates a themed AppBar. Pass a BuildContext so callers can provide
// an optional back button behavior. By default the leading button will
// call Navigator.pop(context) if `showBack` is true and no `onBack` is
// provided.
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
