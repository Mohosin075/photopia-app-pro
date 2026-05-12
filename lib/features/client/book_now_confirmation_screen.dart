import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:photopia/controller/provider/calender_availibility_controller.dart';
import 'package:photopia/controller/location_controller.dart';
import 'package:photopia/controller/client/booking_controller.dart';
import 'package:photopia/controller/client/user_profile_controller.dart';
import 'package:photopia/controller/client/payment_controller.dart';
import 'package:photopia/data/models/calender_availibility_model.dart';
import 'package:provider/provider.dart';

import 'package:photopia/data/models/payment_method_model.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic>? service;
  final Map<String, dynamic>? package;
  const BookingConfirmationScreen({super.key, this.service, this.package});

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;
  bool _isSuccess = false;
  bool _isLoadingAvailability = true;
  PaymentMethodModel? _selectedPaymentMethod;

  // Booking Data
  DateTime? _selectedDateTime;
  String _selectedTime = '';
  bool _isLoadingSlots = false;
  List<dynamic> _apiAvailableDates = [];
  String _location = '';
  double? _lat;
  double? _lng;
  String? _city;
  String? _country;
  String _specialRequests = '';
  double _distanceFromProvider = 0.0;
  String _paymentMethod = 'Credit/Debit Card';
  String? _createdBookingId; // Track if booking was already created

  // Track critical booking details to detect changes
  String? _lastBookingKey;

  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _specialRequestsController =
      TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _locationController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  // Availability
  Data? _availabilityData;
  List<DateTime> _availableDates = [];
  List<String> _timeSlots = [];

  @override
  void initState() {
    super.initState();

    // Start fetching availability immediately for speed
    _buildAvailableDatesFallback();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAvailability(); // Re-sync if needed but should be fast now
      context.read<PaymentController>().fetchPaymentMethods().then((_) {
        final methods = context.read<PaymentController>().paymentMethods;
        if (methods.isNotEmpty) {
          setState(() {
            _selectedPaymentMethod = methods.firstWhere(
              (m) => m.isDefault,
              orElse: () => methods.first,
            );
          });
        }
      });
    });
  }

  Future<void> _fetchAvailability() async {
    setState(() => _isLoadingAvailability = true);

    String? providerId = _getProviderId();
    debugPrint('📅 BookingScreen: Fetching availability for: $providerId');

    if (providerId != null) {
      final controller = context.read<CalenderAvailibilityController>();

      try {
        // Run both calls in parallel for speed
        final results = await Future.wait([
          controller.getAvailabilitySettings(providerId: providerId),
          controller.getMonthCalendar(
            providerId,
            DateTime.now().month,
            DateTime.now().year,
          ),
        ]);

        final settingsModel = results[0] as CalenderSettingsModel?;
        final calendarData = results[1] as List<dynamic>;

        if (mounted) {
          setState(() {
            _availabilityData = settingsModel?.data;
            _apiAvailableDates = calendarData;
            _buildAvailableDatesFromApi();
          });
        }
      } catch (e) {
        debugPrint('❌ Error fetching availability: $e');
        _buildAvailableDatesFallback();
      }
    } else {
      _buildAvailableDatesFallback();
    }
    if (mounted) setState(() => _isLoadingAvailability = false);
  }

  String? _getProviderId() {
    final providerData =
        widget.service?['providerId'] ?? widget.service?['provider'];
    if (providerData is Map) {
      return providerData['_id']?.toString() ?? providerData['id']?.toString();
    }
    if (providerData != null) {
      return providerData.toString();
    }
    // Fallback to top level if somehow nested differently
    return widget.service?['providerId']?.toString() ??
        widget.service?['provider']?.toString();
  }

  void _buildAvailableDatesFromApi() {
    final List<DateTime> dates = [];
    for (var item in _apiAvailableDates) {
      final dateStr = item['date']?.toString();
      final isAvailable = item['isAvailable'] == true;
      if (dateStr != null && isAvailable) {
        final parsedDate = DateTime.tryParse(dateStr);
        if (parsedDate != null) {
          // Only show future/today dates
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          if (parsedDate.isAfter(today.subtract(const Duration(seconds: 1)))) {
            dates.add(parsedDate);
          }
        }
      }
    }
    setState(() => _availableDates = dates);
  }

  void _buildAvailableDatesFallback() {
    final List<DateTime> dates = [];
    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final date = DateTime(now.year, now.month, now.day + i);
      dates.add(date);
    }
    setState(() => _availableDates = dates);
  }

  void _onDateSelected(DateTime date) {
    if (_selectedDateTime != date) {
      setState(() {
        _selectedDateTime = date;
        _selectedTime = '';
        _createdBookingId = null; // Reset booking ID if date changes
      });
      _fetchTimeSlotsFromApi(date);
    }
  }

  Future<void> _fetchTimeSlotsFromApi(DateTime date) async {
    setState(() => _isLoadingSlots = true);

    final providerId = _getProviderId();
    if (providerId != null) {
      final controller = context.read<CalenderAvailibilityController>();
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      final slots = await controller.getTimeSlots(
        providerId,
        dateStr,
        _packageDurationInMinutes,
      );

      if (mounted) {
        setState(() {
          _timeSlots = slots;
          _isLoadingSlots = false;
        });
      }
    } else {
      _buildTimeSlotsForDate(date); // Fallback to local logic
      if (mounted) setState(() => _isLoadingSlots = false);
    }
  }

  int get _packageDurationInMinutes {
    final durationStr =
        (widget.package?['duration'] ?? widget.service?['duration'] ?? '')
            .toString()
            .toLowerCase();
    if (durationStr.contains('4 hour')) return 240;
    if (durationStr.contains('8 hour')) return 480;
    if (durationStr.contains('full day')) return 600;

    // Check if it's just a number of hours
    final int? hours = int.tryParse(durationStr.split(' ')[0]);
    if (hours != null) return hours * 60;

    return 60; // Default to 1 hour
  }

  void _buildTimeSlotsForDate(DateTime date) {
    String startStr = '09:00';
    String endStr = '18:00';

    // Check custom date override first
    if (_availabilityData?.customDates != null) {
      for (var cd in _availabilityData!.customDates!) {
        if (cd.date != null && cd.type == 'available') {
          final exDate = DateTime.tryParse(cd.date!);
          if (exDate != null &&
              exDate.year == date.year &&
              exDate.month == date.month &&
              exDate.day == date.day) {
            startStr = cd.start ?? startStr;
            endStr = cd.end ?? endStr;
          }
        }
      }
    }

    // Otherwise use the weekly schedule
    Monday? daySchedule;
    switch (date.weekday) {
      case DateTime.monday:
        daySchedule = _availabilityData?.defaultSchedule?.monday;
        break;
      case DateTime.tuesday:
        daySchedule = _availabilityData?.defaultSchedule?.tuesday;
        break;
      case DateTime.wednesday:
        daySchedule = _availabilityData?.defaultSchedule?.wednesday;
        break;
      case DateTime.thursday:
        daySchedule = _availabilityData?.defaultSchedule?.thursday;
        break;
      case DateTime.friday:
        daySchedule = _availabilityData?.defaultSchedule?.friday;
        break;
      case DateTime.saturday:
        daySchedule = _availabilityData?.defaultSchedule?.saturday;
        break;
      case DateTime.sunday:
        daySchedule = _availabilityData?.defaultSchedule?.sunday;
        break;
    }
    if (daySchedule != null) {
      startStr = daySchedule.start ?? startStr;
      endStr = daySchedule.end ?? endStr;
    }

    final slots = <String>[];
    int startHour = int.tryParse(startStr.split(':')[0]) ?? 9;
    final endHour = int.tryParse(endStr.split(':')[0]) ?? 18;
    while (startHour < endHour) {
      slots.add('${startHour.toString().padLeft(2, '0')}:00');
      startHour++;
    }
    setState(() => _timeSlots = slots);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            if (!_isSuccess) _buildHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _pageIndex = index;
                    if (index == 4) _isSuccess = true;
                  });
                },
                children: [
                  _buildStep1(), // Combines Time Slots & Full Day logic
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                  _buildSuccessStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int get _currentStep {
    if (_pageIndex >= 0 && _pageIndex <= 3) return _pageIndex;
    return 3; // Clamp for success screen or others
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.arrow_back,
                  size: 24.sp,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () {
                  if (_pageIndex > 0) {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
              Text(
                'Step ${_currentStep + 1} of 4',
                style: TextStyle(
                  fontSize: 14.sp.clamp(14, 16),
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: List.generate(4, (index) {
              return Expanded(
                child: Container(
                  height: 4.h,
                  margin: EdgeInsets.symmetric(horizontal: 2.w),
                  decoration: BoxDecoration(
                    color: index <= _currentStep
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).dividerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2).r,
                  ),
                ),
              );
            }),
          ),
          Divider(color: Theme.of(context).dividerColor.withOpacity(0.1)),
          if (_isLoadingAvailability)
            LinearProgressIndicator(
              backgroundColor: Theme.of(context).dividerColor.withOpacity(0.05),
              color: Theme.of(context).colorScheme.primary,
              minHeight: 2,
            ),
        ],
      ),
    );
  }

  // ─── Step 1 Variants ──────────────────────────────────────────────────────

  int _selectedStep1Tab = 0; // 0 for Time Slots, 1 for Full Day

  Widget _buildStep1() {
    return _buildStepScaffold(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStep1Tabs(),
          SizedBox(height: 25.h),
          Text(
            'Available Dates',
            style: TextStyle(
              fontSize: 14.sp.clamp(14, 16),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 15.h),

          // Dates Grid - Animates on height change but stays in place
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Container(
              constraints: BoxConstraints(minHeight: 180.h),
              child: (_isLoadingAvailability && _availableDates.isEmpty)
                  ? SizedBox(
                      height: 180.h,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _buildDateGrid(),
            ),
          ),

          // Conditional Time Slots
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1.0,
                  child: child,
                ),
              );
            },
            child: (_selectedStep1Tab == 0 && _selectedDateTime != null)
                ? Column(
                    key: const ValueKey('time_slots_section'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 15.h), // Reduced from 30.h
                      Text(
                        'Time Slot',
                        style: TextStyle(
                          fontSize: 14.sp.clamp(14, 16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12.h), // Adjusted spacing
                      Container(
                        constraints: BoxConstraints(minHeight: 100.h),
                        child: _isLoadingSlots
                            ? SizedBox(
                                height: 100.h,
                                child: const Center(
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : _buildTimeSlotGrid(),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepScaffold(Widget content) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Date & Time',
            style: TextStyle(
              fontSize: 16.sp.clamp(16, 18),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Choose your preferred date and time slot',
            style: TextStyle(fontSize: 13.sp.clamp(13, 14), color: Colors.grey),
          ),
          SizedBox(height: 25.h),
          content,
          SizedBox(height: 30.h),
          _buildBottomButton(),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildStep1Tabs() {
    final tabs = ['Time Slots', 'Full Day'];
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12).r,
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = _selectedStep1Tab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedStep1Tab = index;
                  // If we switch to Full Day, we might need different logic
                  // but we keep the selected date if possible.
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10).r,
                ),
                child: Center(
                  child: Text(
                    tab,
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.surface
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.4),
                      fontSize: 13.sp.clamp(13, 14),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Date Grid (Dynamic) ──────────────────────────────────────────────────

  Widget _buildDateGrid() {
    if (_availableDates.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Text(
            'No available dates found.',
            style: TextStyle(color: Colors.grey, fontSize: 13.sp),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10.h,
        crossAxisSpacing: 10.w,
        childAspectRatio: 2.1, // Increased to make containers shorter
      ),
      itemCount: _availableDates.length,
      itemBuilder: (context, index) {
        final date = _availableDates[index];
        final isSelected =
            _selectedDateTime != null &&
            _selectedDateTime!.year == date.year &&
            _selectedDateTime!.month == date.month &&
            _selectedDateTime!.day == date.day;

        return GestureDetector(
          onTap: () => _onDateSelected(date),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10).r,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).dividerColor.withOpacity(0.1),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('EEE').format(date), // Mon, Tue...
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
                Text(
                  DateFormat('MMM dd').format(date), // Jun 17
                  style: TextStyle(
                    fontSize: 12.sp.clamp(12, 13),
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Time Slot Grid (Dynamic) ─────────────────────────────────────────────

  Widget _buildTimeSlotGrid() {
    if (_timeSlots.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Text(
            'No time slots available.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              fontSize: 13.sp,
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: _timeSlots.map((time) {
        final isSelected = _selectedTime == time;
        return GestureDetector(
          onTap: () => setState(() => _selectedTime = time),
          child: Container(
            width: 80.w,
            padding: EdgeInsets.symmetric(vertical: 10.h),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8).r,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).dividerColor.withOpacity(0.1),
              ),
            ),
            child: Center(
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 12.sp.clamp(12, 13),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Steps 2-4 ────────────────────────────────────────────────────────────

  Widget _buildStep2() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location Details',
                    style: TextStyle(
                      fontSize: 16.sp.clamp(16, 18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Where should the session take place?',
                    style: TextStyle(
                      fontSize: 13.sp.clamp(13, 14),
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Consumer<LocationController>(
                builder: (context, locationCtrl, child) {
                  return IconButton(
                    onPressed: () async {
                      await locationCtrl.determinePosition();
                      if (locationCtrl.currentAddress !=
                              "Error getting location" &&
                          !locationCtrl.currentAddress.contains("denied")) {
                        setState(() {
                          _location = locationCtrl.currentAddress;
                          _locationController.text = _location;
                          _lat = locationCtrl.latitude;
                          _lng = locationCtrl.longitude;
                          _city = locationCtrl.city;
                          _country = locationCtrl.country;
                        });
                      }
                    },
                    icon: locationCtrl.isLoading
                        ? SizedBox(
                            width: 20.sp,
                            height: 20.sp,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            Icons.my_location_outlined,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 28.sp,
                          ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 25.h),
          _buildInputLabel('Location Address'),
          _buildTextField(
            controller: _locationController,
            hint: 'Enter or detect your location',
            icon: Icons.location_on_outlined,
            onChanged: (val) {
              setState(() {
                _location = val;
                // Clear auto-detected coords if user types manually to prevent mismatch
                _lat = null;
                _lng = null;
                _city = null;
                _country = null;
              });
            },
          ),
          SizedBox(height: 10.h),
          Consumer<LocationController>(
            builder: (context, locationCtrl, _) {
              if (locationCtrl.currentAddress.contains("Off") ||
                  locationCtrl.currentAddress.contains("denied")) {
                return Row(
                  children: [
                    Icon(Icons.info_outline, size: 14.sp, color: Colors.orange),
                    SizedBox(width: 5.w),
                    Expanded(
                      child: Text(
                        "Tip: ${locationCtrl.currentAddress}. You can also type manually.",
                        style: TextStyle(color: Colors.grey, fontSize: 11.sp),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          SizedBox(height: 25.h),
          _buildInputLabel('Special Requests (Optional)'),
          _buildTextField(
            controller: _specialRequestsController,
            hint: 'Any specific requirements or notes for the photographer',
            maxLines: 5,
            onChanged: (val) => setState(() => _specialRequests = val),
          ),
          SizedBox(height: 40.h),
          _buildBottomButton(),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  // Helper to get currency symbol for UI
  String _getCurrencySymbol(String? code) {
    if (code == null || code.isEmpty) return '€';
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
        return normalized;
    }
  }

  Widget _buildStep3() {
    final dateStr = _selectedDateTime != null
        ? DateFormat('EEEE, MMMM d, y').format(_selectedDateTime!)
        : 'No date selected';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencySymbol = _getCurrencySymbol(
      widget.package?['currency'] ?? widget.service?['currency'],
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Booking',
            style: TextStyle(
              fontSize: 16.sp.clamp(16, 18),
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Please confirm your booking details',
            style: TextStyle(
              fontSize: 13.sp.clamp(13, 14),
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          SizedBox(height: 25.h),
          if (_hasDeposit) ...[
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14).r,
                border: Border.all(color: Colors.amber.withOpacity(0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock_clock_outlined, color: Colors.amber.shade700, size: 18.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'Deposit Required to Confirm',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.amber[200] : Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'This provider requires a ${(_depositPercentage * 100).toInt()}% upfront deposit to secure your booking. Pay $currencySymbol${_depositAmount.toStringAsFixed(2)} now — the remaining $currencySymbol${_balanceAmount.toStringAsFixed(2)} is settled after the session.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isDark ? Colors.amber[100] : Colors.amber.shade900,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
          ],
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16).r,
              border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReviewItem(
                  'Service',
                  widget.service?['title'] ?? 'Photography Session',
                ),
                if (widget.package != null)
                  _buildReviewItem(
                    'Package',
                    widget.package!['name'] ?? 'Custom',
                  ),
                _buildReviewItem(
                  'Provider',
                  widget.service?['providerId']?['name']?.toString() ??
                      widget.service?['provider']?['name']?.toString() ??
                      widget.service?['subtitle'] ??
                      'Professional',
                ),
                Divider(color: theme.dividerColor.withOpacity(0.1)),
                _buildReviewIconItem(Icons.calendar_today_outlined, dateStr),
                if (_selectedTime.isNotEmpty)
                  _buildReviewIconItem(
                    Icons.access_time,
                    '$_selectedTime - ${_calculateEndTime()}',
                  ),
                _buildReviewIconItem(
                  Icons.location_on_outlined,
                  _location.isEmpty ? 'Not specified' : _location,
                ),
                if (_specialRequests.isNotEmpty) ...[
                  Divider(color: theme.dividerColor.withOpacity(0.1)),
                  _buildReviewItem('Special Requests', _specialRequests),
                ],
                Divider(color: theme.dividerColor.withOpacity(0.1)),
                _buildReviewItem(
                  'Final Service Total',
                  '$currencySymbol${_packagePrice.toStringAsFixed(2)}',
                ),
                if (_hasDeposit) ...[
                  _buildReviewItem(
                    'Pay Now (${(_depositPercentage * 100).toInt()}% Deposit)',
                    '$currencySymbol${_depositAmount.toStringAsFixed(2)}',
                    color: Colors.green,
                    isBold: true,
                  ),
                  _buildReviewItem(
                    'Due After Session (Balance)',
                    '$currencySymbol${_balanceAmount.toStringAsFixed(2)}',
                    color: Colors.orange,
                  ),
                ],
              ],
            ),
          ),
          if (_hasDeposit) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10).r,
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green, size: 18.sp),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Only $currencySymbol${_depositAmount.toStringAsFixed(2)} is charged today. Balance of $currencySymbol${_balanceAmount.toStringAsFixed(2)} is due after your session.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark ? Colors.green[200] : Colors.green.shade800,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 40.h),
          _buildBottomButton(),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  String _calculateEndTime() {
    if (_selectedTime.isEmpty) return "";
    try {
      int durationHours = 1;
      if (widget.service?['pricingType'] == 'DAILY' ||
          widget.service?['pricingModel']?['type'] == 'DAILY') {
        durationHours = widget.service?['pricingModel']?['dailyHours'] ?? 8;
      } else {
        final durationStr =
            (widget.package?['duration'] ?? widget.service?['duration'] ?? "1")
                .toString()
                .toLowerCase();
        durationHours = int.tryParse(durationStr.split(' ')[0]) ?? 1;
      }

      final parts = _selectedTime.split(':');
      if (parts.length < 2) return "";

      final int startHour = int.tryParse(parts[0]) ?? 9;
      final int startMinute = int.tryParse(parts[1]) ?? 0;

      int endHour = startHour + durationHours;
      if (endHour >= 24) endHour = endHour % 24;

      return "${endHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}";
    } catch (e) {
      debugPrint("Error calculating end time: $e");
      return "";
    }
  }

  double get _packagePrice {
    final priceStr =
        (widget.package?['price'] ?? widget.service?['price'] ?? '0')
            .toString()
            .replaceAll(',', '');
    return double.tryParse(priceStr) ?? 0;
  }

  bool get _hasDeposit => false; // Deposit disabled

  double get _depositPercentage {
    // Default to 50% as requested for automatic deposit
    final val = widget.service?['depositPercentage']?.toString();
    if (val != null) {
      final parsed = double.tryParse(val);
      if (parsed != null && parsed > 0) return parsed;
    }
    return 0.5;
  }

  double get _depositAmount {
    return _packagePrice * _depositPercentage;
  }

  double get _balanceAmount {
    return _packagePrice - _depositAmount;
  }

  double get _totalBookingAmount {
    // Only charge the deposit amount at the time of booking
    return _depositAmount;
  }

  Widget _buildStep4() {
    final currencySymbol = _getCurrencySymbol(
      widget.package?['currency'] ?? widget.service?['currency'],
    );
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment',
            style: TextStyle(
              fontSize: 16.sp.clamp(16, 18),
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _hasDeposit
                ? 'Secure your booking with a partial payment'
                : 'Complete your booking with payment',
            style: TextStyle(
              fontSize: 13.sp.clamp(13, 14),
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          SizedBox(height: 25.h),

          if (_hasDeposit) ...[
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14).r,
                border: Border.all(color: Colors.blue.withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(isDark ? 0.08 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.payment_outlined, color: Colors.blue, size: 16.sp),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'How Deposit Billing Works',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  _buildDepositStep('1', 'Pay $currencySymbol${_depositAmount.toStringAsFixed(2)} now (${(_depositPercentage * 100).toInt()}% deposit) to confirm.', Colors.blue),
                  SizedBox(height: 6.h),
                  _buildDepositStep('2', 'Your session is locked in. Provider is notified immediately.', Colors.green),
                  SizedBox(height: 6.h),
                  _buildDepositStep('3', 'Pay remaining $currencySymbol${_balanceAmount.toStringAsFixed(2)} after your session is complete.', Colors.orange),
                ],
              ),
            ),
            SizedBox(height: 20.h),
          ],

          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16).r,
              border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildPriceRow(
                  'Service Total',
                  '$currencySymbol${_packagePrice.toStringAsFixed(2)}',
                ),
                if (_hasDeposit) ...[
                  _buildPriceRow(
                    'Deposit Rate',
                    '${(_depositPercentage * 100).toInt()}% of total',
                  ),
                  Divider(color: theme.dividerColor.withOpacity(0.1)),
                  _buildPriceRow(
                    'Charge Today',
                    '$currencySymbol${_depositAmount.toStringAsFixed(2)}',
                    isBold: true,
                  ),
                  _buildPriceRow(
                    'Due After Session',
                    '$currencySymbol${_balanceAmount.toStringAsFixed(2)}',
                  ),
                ] else ...[
                  Divider(color: theme.dividerColor.withOpacity(0.1)),
                  _buildPriceRow(
                    'Total',
                    '$currencySymbol${_totalBookingAmount.toStringAsFixed(2)}',
                    isBold: true,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 25.h),
          Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 14.sp.clamp(14, 16),
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 15.h),

          Consumer<PaymentController>(
            builder: (context, controller, child) {
              final methods = controller.paymentMethods;

              return Column(
                children: [
                  ...methods.map(
                    (method) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: _buildSavedCardOption(method),
                    ),
                  ),
                  _buildPaymentOption(
                    'Use a different card',
                    'Pay with a new credit/debit card',
                    Icons.add_card_outlined,
                    isSelected: _selectedPaymentMethod == null,
                    onTap: () => setState(() => _selectedPaymentMethod = null),
                  ),
                ],
              );
            },
          ),

          SizedBox(height: 40.h),
          _buildBottomButton(),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildSavedCardOption(PaymentMethodModel method) {
    final isSelected = _selectedPaymentMethod?.id == method.id;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = method),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.05)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color:
                    (method.brand.toLowerCase() == 'visa'
                            ? Colors.blue
                            : Colors.orange)
                        .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.credit_card,
                color: method.brand.toLowerCase() == 'visa'
                    ? Colors.blue
                    : Colors.orange,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 15.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${method.brand.toUpperCase()} •••• ${method.last4}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Expires ${method.expMonth}/${method.expYear}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 20.sp,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessStep() {
    final dateStr = _selectedDateTime != null
        ? DateFormat('EEEE, MMMM d, y').format(_selectedDateTime!)
        : 'N/A';
    final currencySymbol = _getCurrencySymbol(
      widget.package?['currency'] ?? widget.service?['currency'],
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(25.w),
      child: Column(
        children: [
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.all(15.w),
            decoration: BoxDecoration(
              color: isDark ? Colors.green.withOpacity(0.15) : const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              color: isDark ? Colors.greenAccent : const Color(0xFF4CAF50),
              size: 35.sp,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'Booking Confirmed!',
            style: TextStyle(
              fontSize: 20.sp.clamp(18, 24),
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            "Your session has been successfully booked.\nYou'll receive a confirmation email shortly.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp.clamp(12, 14),
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              height: 1.4,
            ),
          ),
          SizedBox(height: 30.h),

          // --- Booking Summary Card ---
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16).r,
              border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RECEIPT',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      '#${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                    ),
                  ],
                ),
                const Divider(height: 30),
                _buildSummaryRow(
                  Icons.camera_alt_outlined,
                  'Service',
                  widget.service?['title'] ?? 'Photography',
                ),
                _buildSummaryRow(
                  Icons.calendar_today_outlined,
                  'Date',
                  dateStr,
                ),
                _buildSummaryRow(
                  Icons.access_time,
                  'Time',
                  '$_selectedTime - ${_calculateEndTime()}',
                ),
                _buildSummaryRow(
                  Icons.location_on_outlined,
                  'Location',
                  _location.isEmpty ? 'Not specified' : _location,
                ),
                const Divider(height: 30),

                // --- Payment Details in Card ---
                _buildSummaryPriceRow(
                  'Total Price',
                  '$currencySymbol${_packagePrice.toStringAsFixed(2)}',
                ),
                if (_hasDeposit) ...[
                  _buildSummaryPriceRow(
                    'Paid (Deposit)',
                    '$currencySymbol${_depositAmount.toStringAsFixed(2)}',
                    color: Colors.green,
                    isBold: true,
                  ),
                  _buildSummaryPriceRow(
                    'Balance Due',
                    '$currencySymbol${_balanceAmount.toStringAsFixed(2)}',
                    color: Colors.orange,
                  ),
                ] else ...[
                  _buildSummaryPriceRow(
                    'Amount Paid',
                    '$currencySymbol${_packagePrice.toStringAsFixed(2)}',
                    color: Colors.green,
                    isBold: true,
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 40.h),
          GestureDetector(
            onTap: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: Container(
              width: double.infinity,
              height: 46.h,
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(12).r,
              ),
              child: Center(
                child: Text(
                  'Go to Home',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp.clamp(16, 18),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 15.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16.sp, color: theme.colorScheme.onSurface.withOpacity(0.4)),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11.sp, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPriceRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: isBold ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBooking() async {
    // Sync location with controller in case onChanged didn't fire for some edge case
    _location = _locationController.text;
    _specialRequests = _specialRequestsController.text;

    final userProfile = context.read<UserProfileController>().userProfile;
    if (userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to continue')),
      );
      return;
    }

    final providerId = _getProviderId();
    final serviceId = widget.service?['id'] ?? widget.service?['_id'];

    // Dynamic event type from service category
    final eventType =
        widget.service?['category']?['name']?.toString() ??
        "Photography Session";

    // Final booking time determination
    String bookingStartTime = _selectedTime;
    if (_selectedStep1Tab == 1) {
      bookingStartTime = "09:00"; // Default for full day
    }

    if (providerId == null ||
        serviceId == null ||
        _selectedDateTime == null ||
        bookingStartTime.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Missing booking details')));
      return;
    }

    if (_location.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a location address')),
      );
      _pageController.animateToPage(
        1, // Move back to Step 2 (Location Details)
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      return;
    }

    // Format date for API (YYYY-MM-DDT00:00:00.000Z)
    final String formattedDate =
        "${DateFormat('yyyy-MM-dd').format(_selectedDateTime!)}T00:00:00.000Z";

    // Calculate endTime based on package or service duration
    String endTime = _calculateEndTime();
    if (_selectedStep1Tab == 1 || widget.service?['pricingType'] == 'DAILY') {
      endTime = "18:00"; // Standard for daily
    }

    // 1. Initial Step: Prepare Payment Sheet / Checkout
    final paymentCtrl = context.read<PaymentController>();
    final bookingCtrl = context.read<BookingController>();
    bool paymentSuccess = false;

    // Check if user has email (required for Stripe)
    if (userProfile.email == null || userProfile.email!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'User email is required for payment. Please update your profile.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Generate a key to check if booking details changed
    final String currentBookingKey =
        "$serviceId-$formattedDate-$bookingStartTime-$_location";
    if (_lastBookingKey != currentBookingKey) {
      _createdBookingId = null; // Data changed
      _lastBookingKey = currentBookingKey;
    }

    // --- FINAL CUSTOM FLOW ---
    // --- UNIFIED FLOW (New or Saved Card) ---
    debugPrint('🚀 Flow: Starting Booking & Payment');
    
    String? bookingId = _createdBookingId;
    dynamic bookingData;
    
    if (bookingId == null) {
      debugPrint('Step 1: Create Booking FIRST');
      bookingData = await bookingCtrl.createBooking(
        providerId: providerId,
        serviceId: serviceId.toString(),
        bookingDate: formattedDate,
        startTime: bookingStartTime,
        endTime: endTime,
        packageName: widget.package?['name'],
        address: _location,
        city: _city ?? "Dhaka",
        country: _country ?? "Bangladesh",
        lat: _lat ?? 23.8103,
        lng: _lng ?? 90.4125,
        clientName: userProfile.fullName,
        clientEmail: userProfile.email,
        clientPhone: userProfile.phone,
        eventType: eventType,
        specialRequests: _specialRequests,
        notes: _specialRequests,
        distanceFromProviderKm: _distanceFromProvider,
        paymentMethodId: _selectedPaymentMethod?.id, 
        paymentIntentId: "pending_mobile_flow", 
      );
      
      if (bookingData != null) {
        bookingId = bookingData['booking']?['_id'] ?? bookingData['_id'];
        _createdBookingId = bookingId;
      } else {
        paymentSuccess = false;
        debugPrint('❌ ERROR: Booking creation failed!');
        return;
      }
    }

    // --- CHECK FOR OFF-SESSION PAYMENT SUCCESS ---
    final bool isPaidAutomatically = 
        bookingData?['isPaid'] == true || 
        bookingData?['booking']?['isPaid'] == true ||
        bookingData?['paymentStatus']?.toString().toLowerCase() == 'paid' ||
        bookingData?['booking']?['paymentStatus']?.toString().toLowerCase() == 'paid';

    debugPrint('🔍 Booking Response: isPaid=$isPaidAutomatically, paymentStatus=${bookingData?['paymentStatus'] ?? bookingData?['booking']?['paymentStatus']}');

    if (isPaidAutomatically) {
      debugPrint('✅ Payment successful automatically (Off-session)');
      paymentSuccess = true;
    } else {
      debugPrint('Step 2: Check for Payment Secrets');
      final paymentInfo = bookingData?['payment'] ?? bookingData?['booking']?['payment'];
      final String? paymentStatus = paymentInfo?['status']?.toString().toLowerCase();
      
      debugPrint('🔍 Payment Info Found: ${paymentInfo != null}, ClientSecret Found: ${paymentInfo?['clientSecret'] != null}, Status: $paymentStatus');
      
      if (paymentStatus == 'succeeded') {
        debugPrint('✅ Payment already succeeded in booking response!');
        paymentSuccess = true;
      } else if (paymentInfo != null && paymentInfo['clientSecret'] != null) {
        final String clientSecret = paymentInfo['clientSecret'];
        final String? ephemeralKey = paymentInfo['ephemeralKey'];
        final String? customerId = paymentInfo['customerId'];

        final initSuccess = await paymentCtrl.initPaymentSheetWithSecrets(
          clientSecret: clientSecret,
          ephemeralKey: ephemeralKey,
          customerId: customerId,
        );

        if (initSuccess) {
          debugPrint('Step 3: Present Payment Sheet (Confirmation required)');
          paymentSuccess = await paymentCtrl.presentPaymentSheet();
        } else {
          paymentSuccess = false;
        }
      } else {
        // Fallback: manually init if backend didn't return secret in booking call
        final double payableAmount = paymentInfo?['amount']?.toDouble() ?? _totalBookingAmount;
        
        final dynamic initResult = await paymentCtrl.initPaymentSheet(
          bookingId: bookingId,
          amount: payableAmount,
          currency: widget.package?['currency'] ?? widget.service?['currency'] ?? 'EUR',
          userEmail: userProfile.email,
          paymentMethodId: _selectedPaymentMethod?.id,
        );
        
        if (initResult != false) {
          final String? manualStatus = initResult is Map ? initResult['status']?.toString().toLowerCase() : null;
          
          if (manualStatus == 'succeeded') {
            debugPrint('✅ Payment already succeeded in manual init!');
            paymentSuccess = true;
          } else {
            debugPrint('Step 3: Present Payment Sheet (Manual Init)');
            paymentSuccess = await paymentCtrl.presentPaymentSheet();
          }
        } else {
          paymentSuccess = false;
        }
      }
    }

    if (paymentSuccess && mounted) {
      // ✅ Success — move to success screen
      debugPrint('🎉 Process complete, moving to success screen!');
      if (mounted) {
        _pageController.animateToPage(
          4,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    } else if (mounted) {
      final error =
          paymentCtrl.errorMessage ??
          bookingCtrl.errorMessage ??
          'Process failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
    }
  }

  Widget _buildBottomButton() {
    return Consumer<BookingController>(
      builder: (context, bookingCtrl, child) {
        return GestureDetector(
          onTap: () {
            if (bookingCtrl.isLoading) return;

            if (_pageIndex < 4) {
              if (_pageIndex == 0) {
                if (_selectedDateTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a date first')),
                  );
                  return;
                }
                if (_selectedStep1Tab == 0 && _selectedTime.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a time slot')),
                  );
                  return;
                }
              }

              if (_pageIndex == 1 && _location.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a location address'),
                  ),
                );
                return;
              }

              // 3. Step 3 (Review) - No specific validation needed before moving to Payment

              if (_pageIndex == 3) {
                // Final payment step -> call API and start payment
                _handleBooking();
              } else {
                int nextPageIndex = _pageIndex + 1;
                _pageController.animateToPage(
                  nextPageIndex,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              }
            }
          },
          child: Container(
            width: double.infinity,
            height: 46.h,
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(12).r,
            ),
            child: Center(
              child: bookingCtrl.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _pageIndex == 3
                          ? (_hasDeposit
                                ? 'Pay ${_getCurrencySymbol(widget.package?['currency'] ?? widget.service?['currency'])}${_depositAmount.toStringAsFixed(2)} Deposit & Confirm'
                                : 'Pay & Confirm')
                          : 'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp.clamp(16, 18),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13.sp.clamp(13, 14),
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    IconData? icon,
    int maxLines = 1,
    TextEditingController? controller,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13.sp.clamp(13, 14),
          color: Colors.grey.shade400,
        ),
        prefixIcon: icon != null
            ? Icon(icon, size: 20.sp, color: Colors.grey)
            : null,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: EdgeInsets.all(16.w),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10).r,
          borderSide: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10).r,
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewItem(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 15.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11.sp.clamp(11, 12), color: Colors.grey),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp.clamp(14, 16),
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewIconItem(IconData icon, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18.sp.clamp(18, 20),
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.sp.clamp(13, 14),
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepositStep(String step, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20.w,
          height: 20.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            step,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp.clamp(13, 14),
              color: isBold
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withOpacity(0.5),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.sp.clamp(13, 15),
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    String title,
    String subtitle,
    IconData icon, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.05)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12).r,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor.withOpacity(0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8).r,
              ),
              child: Icon(
                icon,
                size: 20.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            SizedBox(width: 15.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp.clamp(14, 16),
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.sp.clamp(11, 12),
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: 20.sp,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
