import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/services/notifications/local_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalNotificationService.instance.initialize();
  await LocalNotificationService.instance.requestPermissions();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const FutsmanduApp());
}
