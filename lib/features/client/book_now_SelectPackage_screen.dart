import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopia/controller/provider/calender_availibility_controller.dart';
import 'package:photopia/features/client/book_now_confirmation_screen.dart';
import 'package:provider/provider.dart';

class SelectPackageScreen extends StatefulWidget {
  final Map<String, dynamic>? service;
  const SelectPackageScreen({super.key, this.service});

  @override
  State<SelectPackageScreen> createState() => _SelectPackageScreenState();
}

class _SelectPackageScreenState extends State<SelectPackageScreen> {
  int _selectedPackageIndex = 0;

  List<Map<String, dynamic>> _packages = [];

  @override
  void initState() {
    super.initState();
    _initializePackages();
    _prefetchAvailability();
  }

  void _prefetchAvailability() {
    // Start pre-fetching calendar data for the next screen
    final providerId = _getProviderId();
    if (providerId != null) {
      debugPrint('⚡ Prefetching availability for provider: $providerId');
      final controller = context.read<CalenderAvailibilityController>();
      // Trigger API calls in background
      controller.getAvailabilitySettings(providerId: providerId);
      controller.getMonthCalendar(
        providerId,
        DateTime.now().month,
        DateTime.now().year,
      );
    }
  }

  String? _getProviderId() {
    if (widget.service?['providerId'] is Map) {
      return widget.service!['providerId']['_id']?.toString() ??
          widget.service!['providerId']['id']?.toString();
    }
    return widget.service?['providerId']?.toString() ??
        widget.service?['provider']?['_id']?.toString() ??
        widget.service?['provider']?['id']?.toString();
  }

  void _initializePackages() {
    final serviceCurrency = widget.service?['currency']?.toString() ?? 'EUR';

    if (widget.service != null && widget.service!['pricingModel'] != null) {
      final pricingModel = widget.service!['pricingModel'];
      if (pricingModel['packages'] != null) {
        final List rawPackages = pricingModel['packages'];
        _packages = rawPackages
            .map(
              (p) => {
                'name': p['name'] ?? 'Package',
                'price': p['price']?.toString() ?? '0',
                'currency': serviceCurrency,
                'duration': '${p['duration']} hours',
                'features': p['includes'] != null
                    ? List<String>.from(p['includes'])
                    : [],
                'description': p['description'] ?? '',
              },
            )
            .toList();
      }
    }

    // Fallback if no packages found
    if (_packages.isEmpty) {
      _packages = [
        {
          'name': 'Standard Package',
          'price': widget.service?['price']?.toString() ?? '0',
          'currency': serviceCurrency,
          'duration': widget.service?['duration'] ?? 'Flexible',
          'features': ['Standard Service'],
        },
      ];
    }
  }

  // Helper to get currency symbol for UI
  String _getCurrencySymbol(String code) {
    if (code.isEmpty) return '€';
    final normalized = code.toUpperCase();
    switch (normalized) {
      case 'EUR':
        return '€';
      case 'USD':
        return '\$';
      case 'GBP':
        return '£';
      case 'BDT':
        return '৳';
      case 'INR':
        return '₹';
      case 'JPY':
        return '¥';
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select a Package',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 18.sp.clamp(18, 20),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 20.h),
        children: [
          ..._packages.asMap().entries.map((entry) {
            final index = entry.key;
            final package = entry.value;
            final isSelected = _selectedPackageIndex == index;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPackageIndex = index;
                });
              },
              child: _buildPackageCard(package, isSelected),
            );
          }).toList(),
          SizedBox(height: 10.h),
          _buildBottomBar(),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> package, bool isSelected) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 15.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(16).r,
        border: Border.all(
          color: isSelected
              ? Colors.transparent
              : colorScheme.onSurface.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                package['name'],
                style: TextStyle(
                  color: isSelected
                      ? (isDark ? Colors.black : Colors.white)
                      : colorScheme.onSurface,
                  fontSize: 16.sp.clamp(16, 18),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_getCurrencySymbol(package['currency'])}${package['price']}',
                style: TextStyle(
                  color: isSelected
                      ? (isDark ? Colors.black : Colors.white)
                      : colorScheme.onSurface,
                  fontSize: 16.sp.clamp(16, 18),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            package['duration'],
            style: TextStyle(
              color: isSelected
                  ? (isDark ? Colors.black54 : Colors.white70)
                  : colorScheme.onSurface.withOpacity(0.6),
              fontSize: 13.sp.clamp(13, 14),
            ),
          ),
          SizedBox(height: 20.h),
          ...List.generate(
            (package['features'] as List).length,
            (i) => Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16.sp,
                    color: isSelected
                        ? (isDark
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF4CAF50))
                        : const Color(0xFF4CAF50).withOpacity(0.6),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      package['features'][i],
                      style: TextStyle(
                        color: isSelected
                            ? (isDark ? Colors.black : Colors.white)
                            : colorScheme.onSurface.withOpacity(0.87),
                        fontSize: 13.sp.clamp(13, 14),
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(12).r,
          ),
          child: Icon(
            Icons.chat_bubble_outline,
            size: 24.sp,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(width: 15.w),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingConfirmationScreen(
                    service: widget.service,
                    package: _packages[_selectedPackageIndex],
                  ),
                ),
              );
            },
            child: Container(
              height: 50.h,
              decoration: BoxDecoration(
                color: colorScheme.onSurface,
                borderRadius: BorderRadius.circular(12).r,
              ),
              child: Center(
                child: Text(
                  'Book Now',
                  style: TextStyle(
                    color: colorScheme.surface,
                    fontSize: 14.sp.clamp(14, 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
