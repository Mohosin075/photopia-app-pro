import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:device_preview/device_preview.dart';
import 'package:photopya/app.dart';
import 'package:photopya/features/client/home_page.dart';

import 'package:get_storage/get_storage.dart';

import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:photopya/controller/auth_controller.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:photopya/core/notification/notification_service.dart';
import 'package:photopya/core/services/local_storage_service.dart';
import 'package:photopya/core/services/connectivity_service.dart';
import 'package:photopya/core/services/offline_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(NotificationService.backgroundHandler);
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  
  // TODO: Replace with your actual Stripe Publishable Key
  Stripe.publishableKey = "pk_test_51RcvK8GdOsJASBMC9aDK1onP8kTVwAxve4385Mr09r2Edd1fxcbSWD1y5DCclahZ7MHa0hf1eBnsnq16bWavPRY400W2WfumAa";
  
  await GetStorage.init();
  
  // Read saved locale to synchronize startup state
  final storage = GetStorage();
  final String? savedLanguage = storage.read<String>('app_language');
  final startLocale = savedLanguage != null ? Locale(savedLanguage) : const Locale('en');
  
  // Initialize Offline and Network Services
  await LocalStorageService.init();
  ConnectivityService().init();
  OfflineSyncService().init();

  await AuthController.initialize();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('fr')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: startLocale,
      child: DevicePreview(
        enabled: false,
        builder: (context) => const Photopia(),
      ),
    ),
  );
}
