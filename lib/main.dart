// main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:lockguard/app/app_module.dart';
import 'package:lockguard/app/app_widget.dart';
import 'package:permission_handler/permission_handler.dart'; // Import permission_handler
import 'firebase_options.dart'; // Import the generated Firebase options file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with the options for your platform
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions
        .currentPlatform, // Use the generated FirebaseOptions
  );

  // Request notification permission
  // await _requestNotificationPermission();

  runApp(ModularApp(module: AppModule(), child: AppWidget()));
}

// Future<void> _requestNotificationPermission() async {
//   // Check if the permission is already granted
//   if (await Permission.notification.isDenied) {
//     // Request the permission
//     PermissionStatus status = await Permission.notification.request();

//     if (status.isDenied) {
//       // Permission denied, handle accordingly.
//       // You can show a dialog explaining why the permission is needed
//       print('Notification permission denied');
//     } else if (status.isPermanentlyDenied) {
//       // The user opted to never again see the permission request dialog for this app.
//       // The only way to change the permission's status now is to let the user manually enable it in the system settings.
//       await openAppSettings();
//     }
//   }
// }
