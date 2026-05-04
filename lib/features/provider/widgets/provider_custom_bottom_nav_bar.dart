import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopia/core/localization/app_localizations.dart';

class ProviderCustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const ProviderCustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5), // Match client side offset
          ),
        ],
      ),
      child: SafeArea(
        bottom: true,
        top: false,
        child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 8.w,
              vertical: 8.h.clamp(6, 10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context: context,
                  iconAsset: 'assets/images/provider_order_icon.png',
                  label: context.l10n.providerNavOrders,
                  index: 0,
                ),
                _buildNavItem(
                  context: context,
                  iconAsset: 'assets/images/calendar_icon.png',
                  label: context.l10n.providerNavCalendar,
                  index: 1,
                ),
                _buildNavItem(
                  context: context,
                  iconAsset: 'assets/images/overview_icon.png',
                  label: context.l10n.providerNavListing,
                  index: 2,
                ),
                _buildNavItem(
                  context: context,
                  iconAsset: 'assets/images/message_icon.png',
                  label: context.l10n.navMessages,
                  index: 3,
                ),
                _buildNavItem(
                  context: context,
                  iconAsset: 'assets/images/menu_icon.png',
                  label: context.l10n.providerNavMenu,
                  index: 4,
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    IconData? icon,
    String? iconAsset,
    required String label,
    required int index,
  }) {
    final isSelected = selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onItemSelected(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 4.h.clamp(3, 6)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (iconAsset != null)
                Image.asset(
                  iconAsset,
                  width: 22.sp.clamp(20, 24),
                  height: 22.sp.clamp(20, 24),
                  color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                )
              else if (icon != null)
                Icon(
                  icon,
                  size: 22.sp.clamp(20, 24),
                  color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
              SizedBox(height: 4.h.clamp(3, 5)),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp.clamp(10, 12),
                  color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
