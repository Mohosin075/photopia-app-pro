// lib/features/client/BottomNavigation.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopya/features/client/home_page.dart';
import 'package:photopya/features/client/user_profile_screen.dart';
import 'package:photopya/features/client/favorites_screen.dart';
import 'package:photopya/features/client/messages_screen.dart';
import 'package:photopya/features/client/search_screen.dart';
import 'package:photopya/controller/auth_controller.dart';
import 'package:photopya/controller/client/service_list_controller.dart';
import 'package:photopya/core/utils/guest_dialog_helper.dart';
import 'package:photopya/core/localization/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:photopya/controller/client/booking_controller.dart';
import 'package:photopya/core/notification/notification_service.dart';

class BottomNavigationScreen extends StatefulWidget {
  const BottomNavigationScreen({super.key});
  static const String name = "/bottom-navigation";

  @override
  State<BottomNavigationScreen> createState() => _BottomNavigationScreenState();
}

class _BottomNavigationScreenState extends State<BottomNavigationScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  DateTime? _lastBackPressTime;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.init();
    });
  }

  void _onItemTapped(int index) {
    if (index == 1 || index == 3 || index == 4) {
      if (!AuthController.isLoggedIn) {
        GuestDialogHelper.showGuestDialog(context);
        return;
      }
    }

    if (_selectedIndex == index) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      if (index == 0) {
        context.read<ServiceListController>().getAllServices(refresh: true);
      }
    } else {
      setState(() {
        _selectedIndex = index;
      });

      if (index == 4) {
        context.read<BookingController>().getMyBookings();
      }
    }
    
    // Haptic feedback for better UX
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final NavigatorState? currentNavigator =
            _navigatorKeys[_selectedIndex].currentState;

        if (currentNavigator != null && currentNavigator.canPop()) {
          currentNavigator.pop();
        } else if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        } else {
          final now = DateTime.now();
          final isDoubleBack = _lastBackPressTime != null &&
              now.difference(_lastBackPressTime!) <
                  const Duration(seconds: 2);

          if (isDoubleBack) {
            SystemNavigator.pop();
          } else {
            _lastBackPressTime = now;
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.l10n.pressBackToExit,
                  textAlign: TextAlign.center,
                ),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: EdgeInsets.symmetric(horizontal: 40.w, vertical: 20.h),
                backgroundColor: const Color(0xFF1A1A1A),
              ),
            );
          }
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildTabNavigator(0, const MyHomePage()),
            _buildTabNavigator(1, const MessagesScreen()),
            _buildTabNavigator(2, const SearchScreen()),
            _buildTabNavigator(3, const FavoritesScreen()),
            _buildTabNavigator(4, const UserProfileScreen()),
          ],
        ),
        bottomNavigationBar: isKeyboardVisible
            ? const SizedBox.shrink()
            : Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Container(
                    height: 60.h,
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(
                          index: 0,
                          iconAsset: 'assets/images/client_home_icon.png',
                          label: context.l10n.navHome,
                        ),
                        _buildNavItem(
                          index: 1,
                          iconAsset: 'assets/images/message_icon.png',
                          label: context.l10n.navMessages,
                        ),
                        Expanded(child: Center(child: _buildSearchButton())),
                        _buildNavItem(
                          index: 3,
                          iconAsset: 'assets/images/client_favorite_icon.png',
                          label: context.l10n.navFavorites,
                        ),
                        _buildNavItem(
                          index: 4,
                          iconAsset: 'assets/images/client_profile_icon.png',
                          label: context.l10n.navProfile,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTabNavigator(int index, Widget rootPage) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(builder: (context) => rootPage);
      },
    );
  }

  Widget _buildSearchButton() {
    bool isSelected = _selectedIndex == 2;
    return GestureDetector(
      onTap: () => _onItemTapped(2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        width: isSelected ? 58.w : 52.w,
        height: isSelected ? 58.w : 52.w,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white 
              : const Color(0xFF1A1A1A),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withOpacity(0.2),
              blurRadius: 12,
              spreadRadius: isSelected ? 4 : 0,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).colorScheme.surface, 
            width: 4,
          ),
        ),
        child: Icon(
          Icons.search,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
          size: isSelected ? 28.sp : 24.sp,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    String? iconAsset,
    required String label,
  }) {
    bool isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Image.asset(
                iconAsset!,
                width: 22.w,
                height: 22.w,
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[400],
              ),
            ),
            SizedBox(height: 6.h),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10.sp,
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[500],
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
              child: Text(label),
            ),
            if (isSelected)
              Container(
                margin: EdgeInsets.only(top: 4.h),
                width: 4.w,
                height: 4.w,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
