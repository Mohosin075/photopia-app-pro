import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopya/features/client/home_page.dart';
import 'package:photopya/features/client/BottomNavigation.dart';
import 'package:provider/provider.dart';
import 'package:photopya/controller/client/favorites_controller.dart';
import 'package:photopya/controller/provider/provider_profile_controller.dart';
import 'package:photopya/controller/auth_controller.dart';
import 'package:photopya/controller/client/sign_up_controller.dart';
import 'package:photopya/controller/client/sign_in_controller.dart';
import 'package:photopya/controller/client/log_out_controller.dart';
import 'package:photopya/controller/client/verify_otp_controller.dart';
import 'package:photopya/controller/client/forgot_pass_controller.dart';
import 'package:photopya/controller/client/reset_password_controller.dart';
import 'package:photopya/controller/client/change_password_controller.dart';
import 'package:photopya/controller/client/user_profile_controller.dart';
import 'package:photopya/controller/client/role_switch_controller.dart';
import 'package:photopya/controller/provider/service_controller.dart';
import 'package:photopya/controller/provider/calender_availibility_controller.dart';
import 'package:photopya/controller/provider/my_listing_controller.dart';
import 'package:photopya/controller/client/service_list_controller.dart';
import 'package:photopya/controller/provider/provider_orders_controller.dart';
import 'package:photopya/controller/client/provider_details_controller.dart';
import 'package:photopya/controller/client/home_controller.dart';
import 'package:photopya/controller/common/bottom_nav_controller.dart';
import 'package:photopya/controller/client/review_controller.dart';
import 'package:photopya/controller/provider/wallet_controller.dart';
import 'package:photopya/controller/client/chat_controller.dart';
import 'package:photopya/controller/client/booking_controller.dart';
import 'package:photopya/controller/provider/statistics_controller.dart';
import 'package:photopya/controller/location_controller.dart';
import 'package:photopya/controller/client/notification_controller.dart';
import 'package:photopya/controller/client/payment_controller.dart';
import 'package:photopya/controller/client/delete_account_controller.dart';
import 'package:photopya/controller/client/search_history_controller.dart';
import 'package:photopya/controller/provider/subscription_controller.dart';
import 'package:photopya/controller/language_controller.dart';
import 'package:photopya/controller/theme_controller.dart';
import 'package:photopya/controller/provider/provider_onboarding_controller.dart';
import 'package:photopya/core/localization/app_localizations.dart';
import 'package:photopya/core/routes/app_routes.dart';
import 'package:photopya/features/onboarding/get_started.dart';
import 'package:photopya/features/provider/screen/BottomNavigationBar/bottom_navigation_screen.dart';
import 'package:photopya/core/notification/notification_service.dart';
import 'package:photopya/controller/category_controller.dart';
import 'package:photopya/core/theme/app_theme.dart';

class Photopia extends StatefulWidget {
  const Photopia({super.key});

  @override
  State<Photopia> createState() => _PhotopiaState();
}

class _PhotopiaState extends State<Photopia> {
  @override
  void initState() {
    super.initState();
    // Initialize notification service after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => LanguageController()),
            ChangeNotifierProvider(create: (_) => FavoritesController()),
            ChangeNotifierProvider(create: (_) => ProviderProfileController()),
            ChangeNotifierProvider(
              create: (_) => ProviderOnboardingController(),
            ),
            ChangeNotifierProvider(create: (_) => AuthController()),
            ChangeNotifierProvider(create: (_) => SignUpController()),
            ChangeNotifierProvider(create: (_) => SignInController()),
            ChangeNotifierProvider(create: (_) => LogOutController()),
            ChangeNotifierProvider(create: (_) => VerifyOtpController()),
            ChangeNotifierProvider(create: (_) => ForgotPassController()),
            ChangeNotifierProvider(create: (_) => ResetPasswordController()),
            ChangeNotifierProvider(create: (_) => ChangePasswordController()),
            ChangeNotifierProvider(create: (_) => UserProfileController()),
            ChangeNotifierProvider(create: (_) => RoleSwitchController()),
            ChangeNotifierProvider(create: (_) => MyListingController()),
            ChangeNotifierProvider(create: (_) => ServiceController()),
            ChangeNotifierProvider(create: (_) => ServiceListController()),
            ChangeNotifierProvider(create: (_) => HomeController()),
            ChangeNotifierProvider(create: (_) => BottomNavController()),
            ChangeNotifierProvider(create: (_) => CategoryController()),
            ChangeNotifierProvider(
              create: (_) => CalenderAvailibilityController(),
            ),
            ChangeNotifierProvider(create: (_) => ProviderDetailsController()),
            ChangeNotifierProvider(create: (_) => ProviderOrdersController()),
            ChangeNotifierProvider(create: (_) => LocationController()),
            ChangeNotifierProvider(create: (_) => ReviewController()),
            ChangeNotifierProvider(create: (_) => WalletController()),
            ChangeNotifierProvider(create: (_) => DeleteAccountController()),
            ChangeNotifierProvider(create: (_) => ChatController()),
            ChangeNotifierProvider(create: (_) => BookingController()),
            ChangeNotifierProvider(create: (_) => StatisticsController()),
            ChangeNotifierProvider(create: (_) => NotificationController()),
            ChangeNotifierProvider(create: (_) => PaymentController()),
            ChangeNotifierProvider(create: (_) => SubscriptionController()),
            ChangeNotifierProvider(create: (_) => ThemeController()),
            ChangeNotifierProvider(create: (_) => SearchHistoryController()),
          ],
          child: Consumer2<LanguageController, ThemeController>(
            builder: (context, langController, themeController, child) {
              debugPrint('MaterialApp build: context.locale=${context.locale}, langController.locale=${langController.locale}');
              return MaterialApp(
                navigatorKey: navigatorKey,
                debugShowCheckedModeBanner: false,
                useInheritedMediaQuery: true,
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: [
                  AppLocalizations.delegate,
                  ...context.localizationDelegates,
                ],
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeController.themeMode,

                routes: AppRoutes.routes,
                home: _getInitialScreen(),
              );
            },
          ),
        );
      },
    );
  }

  Widget _getInitialScreen() {
    if (!AuthController.isLoggedIn) {
      return const GetStartedScreen();
    }

    if (AuthController.activeRole == 'professional') {
      return const ProviderBottomNavigationScreen();
    } else {
      return const BottomNavigationScreen();
    }
  }
}
