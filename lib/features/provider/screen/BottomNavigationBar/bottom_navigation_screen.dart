import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photopya/features/provider/screen/provider_orders_screen.dart';
import 'package:photopya/features/provider/screen/provider_calendar_screen.dart';
import 'package:photopya/features/provider/screen/provider_overview_screen.dart';
import 'package:photopya/features/provider/screen/provider_message_screen.dart';
import 'package:photopya/features/provider/screen/provider_menu_screen.dart';
import 'package:photopya/features/provider/widgets/provider_custom_bottom_nav_bar.dart';

import 'package:photopya/controller/common/bottom_nav_controller.dart';
import 'package:provider/provider.dart';

import 'package:photopya/core/notification/notification_service.dart';

class ProviderBottomNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const ProviderBottomNavigationScreen({super.key, this.initialIndex = 0});
  static const String name = "/provider-bottom-navigation";

  @override
  State<ProviderBottomNavigationScreen> createState() =>
      _ProviderBottomNavigationScreenState();
}

class _ProviderBottomNavigationScreenState
    extends State<ProviderBottomNavigationScreen> {
  DateTime? _lastBackPressTime;
  // Navigation keys for each tab
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
      context.read<BottomNavController>().setIndex(widget.initialIndex);
      // Initialize notification service
      NotificationService.instance.init();
    });
  }

  void _onItemSelected(int index) {
    final controller = context.read<BottomNavController>();
    if (controller.selectedIndex == index) {
      // If tapping the same tab, pop to the first screen of that tab's navigator
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      controller.setIndex(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = context.watch<BottomNavController>().selectedIndex;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final NavigatorState? currentNavigator =
            _navigatorKeys[selectedIndex].currentState;
        if (currentNavigator != null && currentNavigator.canPop()) {
          currentNavigator.pop();
        } else {
          // If we can't pop anymore in the current tab, switch to the default tab (Orders)
          if (selectedIndex != 0) {
            context.read<BottomNavController>().setIndex(0);
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
                  content: const Text(
                    'Press back again to exit',
                    textAlign: TextAlign.center,
                  ),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  backgroundColor: const Color(0xFF1A1A1A),
                ),
              );
            }
          }
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: selectedIndex,
          children: [
            _buildTabNavigator(0, const ProviderOrdersScreen()),
            _buildTabNavigator(1, const ProviderCalendarScreen()),
            _buildTabNavigator(2, const ProviderOverviewScreen()),
            _buildTabNavigator(3, const ProviderMessageScreen()),
            _buildTabNavigator(4, const ProviderMenuScreen()),
          ],
        ),
        bottomNavigationBar: ProviderCustomBottomNavBar(
          selectedIndex: selectedIndex,
          onItemSelected: _onItemSelected,
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
}
