import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/notifications/local_notification_service.dart';
import 'core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.info('App starting...', tag: 'Main');

  await LocalNotificationService.instance.initialize();
  await LocalNotificationService.instance.requestPermissions();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  AppLogger.info('App initialized, running...', tag: 'Main');
  runApp(const ProviderScope(child: FutsmanduApp()));
}
