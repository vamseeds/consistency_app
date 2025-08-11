import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/login_screen.dart';

void handleErrorWithRetry(
  BuildContext context,
  dynamic error,
  VoidCallback onRetry, {
  String errorMessage = 'Operation failed',
  required bool isMounted,
}) {
  print('Error: $error');
  if (!isMounted) return; // Gaurd against unmounted widget
  if (error.toString().contains('Session expired')) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('jwt_token');
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      }
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$errorMessage: $error'),
        action: SnackBarAction(label: 'Retry', onPressed: onRetry),
      ),
    );
  }
}
