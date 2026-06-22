import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:photopya/core/constants/app_typography.dart';
import 'package:photopya/features/provider/screen/provider_availability_settings_screen.dart';
import 'package:photopya/features/provider/screen/booking_details_screen.dart';
import 'package:photopya/controller/provider/calender_availibility_controller.dart';
import 'package:photopya/controller/provider/provider_orders_controller.dart';
import 'package:photopya/controller/client/user_profile_controller.dart';
import 'package:photopya/data/models/calender_availibility_model.dart';
import 'package:provider/provider.dart';
import 'package:photopya/core/localization/app_localizations.dart';
import 'package:photopya/core/widgets/custom_snacbar.dart';

class ProviderCalendarScreen extends StatefulWidget {
  const ProviderCalendarScreen({super.key});

  @override
  State<ProviderCalendarScreen> createState() => _ProviderCalendarScreenState();
}

class _ProviderCalendarScreenState extends State<ProviderCalendarScreen> {
  int _selectedViewIndex = 1; // 0: Week, 1: Month, 2: Year
  DateTime _currentDate = DateTime.now();
  DateTime? _selectedDate;
  bool _isLoading = false;
  Data? _availabilityData;
  Set<int> _bookedDays = {}; // To store days of the month that have bookings

  List<String> _getWeekdays() {
    final localeCode = Localizations.localeOf(context).languageCode;
    final formatter = DateFormat.E(localeCode);
    return List.generate(7, (index) {
      final date = DateTime(2026, 6, index + 1); // 2026-06-01 is Monday
      final formatted = formatter.format(date);
      final clean = formatted.replaceAll('.', '');
      return clean.isEmpty ? clean : '${clean[0].toUpperCase()}${clean.substring(1)}';
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = _currentDate;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAvailabilityData();
      _fetchBookingsForDate(_selectedDate ?? _currentDate);
      // Fetch upcoming orders for week view
      Provider.of<ProviderOrdersController>(context, listen: false).getMyOrders(filterType: 'upcoming');
    });
  }

  Future<void> _fetchBookingsForDate(DateTime date) async {
    final String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final controller = context.read<CalenderAvailibilityController>();
    await controller.getBookingsByDate(date: formattedDate);
  }

  Future<void> _fetchAvailabilityData() async {
    setState(() => _isLoading = true);
    final availabilityController = context.read<CalenderAvailibilityController>();
    final ordersController = context.read<ProviderOrdersController>();
    final profileController = context.read<UserProfileController>();
    
    if (profileController.userProfile == null) {
      await profileController.getUserProfile();
    }

    final String? providerId = profileController.userProfile?.id;
    debugPrint('🔍 Fetching availability for ProviderID: $providerId');
    
    if (providerId != null) {
      final settingsModel = await availabilityController.getAvailabilitySettings(providerId: providerId);
      await ordersController.getMyOrders(filterType: 'upcoming');
      
      if (mounted && settingsModel != null) {
        debugPrint('✅ Availability Data Received: ${settingsModel.data?.defaultSchedule?.monday?.isActive}');
        
        // Extract booked days from upcoming orders
        Set<int> bookedDays = {};
        for (var booking in ordersController.upcomingOrders) {
          if (booking['bookingDate'] != null) {
            try {
              DateTime bookingDate = DateTime.parse(booking['bookingDate']);
              if (bookingDate.year == _currentDate.year && 
                  bookingDate.month == _currentDate.month) {
                bookedDays.add(bookingDate.day);
              }
            } catch (e) {
              debugPrint('Error parsing booking date: $e');
            }
          }
        }
        
        setState(() {
          _availabilityData = settingsModel.data;
          _bookedDays = bookedDays;
        });
      }
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  bool _isDayWorking(DateTime date) {
    if (_availabilityData == null) return true;

    final compareDate = DateTime(date.year, date.month, date.day);

    // 1. Check Blocked Date Ranges
    if (_availabilityData!.blockedDateRanges != null) {
      for (var range in _availabilityData!.blockedDateRanges!) {
        if (range.startDate != null && range.endDate != null) {
          try {
            final start = DateTime.parse(range.startDate!);
            final end = DateTime.parse(range.endDate!);
            final startZero = DateTime(start.year, start.month, start.day);
            final endZero = DateTime(end.year, end.month, end.day);
            
            if ((compareDate.isAfter(startZero) || compareDate.isAtSameMomentAs(startZero)) &&
                (compareDate.isBefore(endZero) || compareDate.isAtSameMomentAs(endZero))) {
              return false;
            }
          } catch (e) {
            debugPrint('Error parsing blocked range date: $e');
          }
        }
      }
    }

    // 2. Check Custom Dates (Exceptions)
    if (_availabilityData!.customDates != null) {
      for (var cd in _availabilityData!.customDates!) {
        if (cd.date != null) {
          try {
            DateTime? exceptionDate = DateTime.tryParse(cd.date!);
            if (exceptionDate != null) {
              final exceptionZero = DateTime(exceptionDate.year, exceptionDate.month, exceptionDate.day);
              if (exceptionZero.isAtSameMomentAs(compareDate)) {
                return cd.type == 'special_hours';
              }
            }
          } catch (e) {
            debugPrint('Error parsing custom date: $e');
          }
        }
      }
    }

    // 3. Check Availability Periods
    if (_availabilityData!.availabilityPeriods != null && _availabilityData!.availabilityPeriods!.isNotEmpty) {
      bool insidePeriod = false;
      for (var range in _availabilityData!.availabilityPeriods!) {
        if (range.startDate != null && range.endDate != null) {
          try {
            final start = DateTime.parse(range.startDate!);
            final end = DateTime.parse(range.endDate!);
            final startZero = DateTime(start.year, start.month, start.day);
            final endZero = DateTime(end.year, end.month, end.day);
            
            if ((compareDate.isAfter(startZero) || compareDate.isAtSameMomentAs(startZero)) &&
                (compareDate.isBefore(endZero) || compareDate.isAtSameMomentAs(endZero))) {
              insidePeriod = true;
              break;
            }
          } catch (e) {
            debugPrint('Error parsing availability period date: $e');
          }
        }
      }
      if (!insidePeriod) {
        return false;
      }
      return true;
    }

    // 4. Check Default Schedule using weekday integer (1=Mon, 7=Sun)
    Monday? daySchedule;
    switch (date.weekday) {
      case DateTime.monday: daySchedule = _availabilityData!.defaultSchedule?.monday; break;
      case DateTime.tuesday: daySchedule = _availabilityData!.defaultSchedule?.tuesday; break;
      case DateTime.wednesday: daySchedule = _availabilityData!.defaultSchedule?.wednesday; break;
      case DateTime.thursday: daySchedule = _availabilityData!.defaultSchedule?.thursday; break;
      case DateTime.friday: daySchedule = _availabilityData!.defaultSchedule?.friday; break;
      case DateTime.saturday: daySchedule = _availabilityData!.defaultSchedule?.saturday; break;
      case DateTime.sunday: daySchedule = _availabilityData!.defaultSchedule?.sunday; break;
    }

    return daySchedule?.isActive ?? true;
  }

  void _nextMonth() {
    setState(() {
      if (_selectedViewIndex == 2) {
        _currentDate = DateTime(_currentDate.year + 1, _currentDate.month);
      } else {
        _currentDate = DateTime(_currentDate.year, _currentDate.month + 1);
      }
    });
    _fetchAvailabilityData(); // Refresh booked days for new month
  }

  void _previousMonth() {
    setState(() {
      if (_selectedViewIndex == 2) {
        _currentDate = DateTime(_currentDate.year - 1, _currentDate.month);
      } else {
        _currentDate = DateTime(_currentDate.year, _currentDate.month - 1);
      }
    });
    _fetchAvailabilityData(); // Refresh booked days for new month
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        title: Text(
          context.l10n.calendarAvailability,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: AppTypography.h1,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: Theme.of(context).colorScheme.onSurface,
              size: 24.sp,
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProviderAvailabilitySettingsScreen(),
                ),
              );
              // Re-fetch data on return
              _fetchAvailabilityData();
            },
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: _buildCalendarView(),
                ),
          ),
        ],
      ),
      floatingActionButton: _selectedViewIndex == 1 && _selectedDate != null
          ? GestureDetector(
              onTap: () => _showDateActionSheet(context),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface,
                  borderRadius: BorderRadius.circular(50.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_calendar_outlined,
                      color: Theme.of(context).colorScheme.surface,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      DateFormat('MMM d').format(_selectedDate!),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildCalendarView() {
    return Column(
      children: [
        SizedBox(height: 10.h),
        _buildViewToggle(),
        SizedBox(height: 20.h),
        _buildSelectedView(),
      ],
    );
  }

  Widget _buildViewToggle() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          _buildToggleItem(context.l10n.viewWeek, 0),
          _buildToggleItem(context.l10n.viewMonth, 1),
          _buildToggleItem(context.l10n.viewYear, 2),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String label, int index) {
    bool isSelected = _selectedViewIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedViewIndex = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTypography.bodyLarge,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedView() {
    switch (_selectedViewIndex) {
      case 0:
        return _buildWeekView();
      case 1:
        return _buildMonthView();
      case 2:
        return _buildYearView();
      default:
        return const SizedBox();
    }
  }

  Widget _buildMonthView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _previousMonth,
              icon: Icon(Icons.chevron_left, size: 24.sp),
            ),
            Text(
              DateFormat('MMMM yyyy').format(_currentDate),
              style: TextStyle(
                fontSize: AppTypography.h2,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            IconButton(
              onPressed: _nextMonth,
              icon: Icon(Icons.chevron_right, size: 24.sp),
            ),
          ],
        ),
        SizedBox(height: 15.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _getWeekdays()
              .map(
                (day) => Expanded(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTypography.bodySmall,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        SizedBox(height: 10.h),
        _buildCalendarGrid(),
        SizedBox(height: 30.h),
        Text(
          context.l10n.monthlySchedule,
          style: TextStyle(
            fontSize: AppTypography.h1,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 15.h),
        Consumer<CalenderAvailibilityController>(
          builder: (context, controller, child) {
            if (controller.inProgress && controller.bookingsForSelectedDate.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.bookingsForSelectedDate.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Center(
                  child: Text(
                     context.l10n.noBookingsForDate,
                     style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 14.sp),
                   ),
                ),
              );
            }

            return Column(
              children: controller.bookingsForSelectedDate.map((booking) {
                final pricing = booking['pricingDetails'];
                final service = booking['serviceId'];
                
                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: _buildScheduleItem(
                    title: service?['title'] ?? booking['eventType'] ?? context.l10n.defaultBookingTitle,
                    client: booking['clientName'] ?? booking['clientId']?['name'] ?? context.l10n.defaultClientName,
                    time: booking['startTime'] ?? context.l10n.notAvailable,
                    location: booking['eventLocation']?['address'] ?? context.l10n.locationNA,
                    cost: '€${pricing?['subtotal'] ?? '0'}',
                    status: booking['status'] ?? 'pending',
                    bookingData: booking,
                  ),
                );
              }).toList(),
            );
          },
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    final firstWeekday = firstDayOfMonth.weekday - 1;

    final totalItems = daysInMonth + firstWeekday;
    final rowCount = (totalItems / 7).ceil();
    final gridItems = rowCount * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
      ),
      itemCount: gridItems,
      itemBuilder: (context, index) {
        int dayNum = index - firstWeekday + 1;
        if (dayNum < 1 || dayNum > daysInMonth) return const SizedBox();

        bool isSelected = _selectedDate?.day == dayNum &&
            _selectedDate?.month == _currentDate.month &&
            _selectedDate?.year == _currentDate.year;

        DateTime date = DateTime(_currentDate.year, _currentDate.month, dayNum);
        bool isWorking = _isDayWorking(date);
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
            _fetchBookingsForDate(date);
          },
          child: Container(
             decoration: BoxDecoration(
               color: isSelected ? Theme.of(context).colorScheme.onSurface.withOpacity(0.1) : Colors.transparent,
               borderRadius: BorderRadius.circular(8.r),
               border: isSelected ? Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)) : null,
             ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayNum.toString(),
                  style: TextStyle(
                    fontSize: AppTypography.bodyLarge,
                     fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                     color: isWorking ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                   ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 4.h),
                  width: 4.w,
                  height: 4.w,
                  decoration: BoxDecoration(
                    color: _bookedDays.contains(dayNum) 
                        ? Colors.green 
                        : (isWorking ? Colors.yellow : Colors.red),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDateActionSheet(BuildContext context) {
    final date = _selectedDate!;
    final formattedDate = DateFormat('MMMM d, yyyy').format(date);
    final isWorking = _isDayWorking(date);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24.w,
            right: 24.w,
            top: 24.h,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24.h,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20.sp, color: Theme.of(context).colorScheme.primary),
                    SizedBox(width: 10.w),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isWorking ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    isWorking ? context.l10n.currentlyAvailable : context.l10n.currentlyBlocked,
                    style: TextStyle(
                      color: isWorking ? Colors.green : Colors.red,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.block, color: Colors.red, size: 20.sp),
                  ),
                  title: Text(
                    context.l10n.blockDates,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp),
                  ),
                  subtitle: Text(context.l10n.blockDatesSubtitle, style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showBlockDateRangePicker();
                  },
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_circle_outline, color: Colors.green, size: 20.sp),
                  ),
                  title: Text(
                    context.l10n.markAsAvailable,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp),
                  ),
                  subtitle: Text(context.l10n.markAsAvailableSubtitle, style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _resetSelectedDayToDefault();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.event_note, color: Colors.blue, size: 20.sp),
                  ),
                  title: Text(
                    context.l10n.manualReservation,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp),
                  ),
                  subtitle: Text(context.l10n.manualReservationSubtitle, style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showManualReservationDialog(context);
                  },
                ),
                const Divider(),
                SizedBox(height: 10.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resetSelectedDayToDefault() async {
    final profileController = context.read<UserProfileController>();
    final providerId = profileController.userProfile?.id;
    if (providerId == null) return;

    setState(() => _isLoading = true);
    final controller = context.read<CalenderAvailibilityController>();
    final success = await controller.resetDateToDefault(providerId, _selectedDate!);
    
    if (mounted) {
      setState(() => _isLoading = false);
      CustomSnackBar.show(
        context: context,
        message: success ? context.l10n.dayResetSuccess : context.l10n.dayResetFailed,
        isError: !success,
      );
      _fetchAvailabilityData();
    }
  }


  Future<void> _showBlockDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: _selectedDate ?? DateTime.now(),
        end: _selectedDate ?? DateTime.now(),
      ),
      saveText: context.l10n.block,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.onSurface,
                  onPrimary: Theme.of(context).colorScheme.surface,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final noteController = TextEditingController();
      final isSingleDay = picked.start.year == picked.end.year &&
          picked.start.month == picked.end.month &&
          picked.start.day == picked.end.day;

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(isSingleDay ? context.l10n.blockDate : context.l10n.blockDateRange),
          content: TextField(
            controller: noteController,
            decoration: InputDecoration(
              labelText: context.l10n.blockReasonLabel,
              hintText: isSingleDay ? context.l10n.blockReasonHintSingle : context.l10n.blockReasonHintRange,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(context.l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final profileController = context.read<UserProfileController>();
                final providerId = profileController.userProfile?.id;
                if (providerId == null) return;

                setState(() => _isLoading = true);
                final controller = context.read<CalenderAvailibilityController>();
                final success = await controller.blockDateRange(
                  providerId,
                  picked.start,
                  picked.end,
                  note: noteController.text.isNotEmpty 
                      ? noteController.text 
                      : (isSingleDay ? context.l10n.blockedDayDefault : context.l10n.blockedRangeDefault),
                );

                if (mounted) {
                  setState(() => _isLoading = false);
                  CustomSnackBar.show(
                    context: context,
                    message: success 
                        ? (isSingleDay ? context.l10n.dateBlockedSuccess : context.l10n.dateRangeBlockedSuccess) 
                        : (isSingleDay ? context.l10n.dateBlockedFailed : context.l10n.dateRangeBlockedFailed),
                    isError: !success,
                  );
                  _fetchAvailabilityData();
                }
              },
              child: Text(context.l10n.block),
            ),
          ],
        ),
      );
    }
  }



  void _showManualReservationDialog(BuildContext context) {
    final titleController = TextEditingController();
    final startTimeController = TextEditingController(text: '10:00');
    final endTimeController = TextEditingController(text: '12:00');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(context.l10n.manualReservation),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: context.l10n.eventTitleLabel,
                  hintText: context.l10n.eventTitleHint,
                ),
              ),
              SizedBox(height: 10.h),
              GestureDetector(
                onTap: () async {
                  final time = await showTimePicker(
                    context: ctx,
                    initialTime: const TimeOfDay(hour: 10, minute: 0),
                  );
                  if (time != null) {
                    startTimeController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                  }
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: startTimeController,
                    decoration: InputDecoration(
                      labelText: context.l10n.startTime,
                      suffixIcon: const Icon(Icons.access_time),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              GestureDetector(
                onTap: () async {
                  final time = await showTimePicker(
                    context: ctx,
                    initialTime: const TimeOfDay(hour: 12, minute: 0),
                  );
                  if (time != null) {
                    endTimeController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                  }
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: endTimeController,
                    decoration: InputDecoration(
                      labelText: context.l10n.endTime,
                      suffixIcon: const Icon(Icons.access_time),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.cancel)),
          TextButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) {
                CustomSnackBar.show(
                  context: context,
                  message: context.l10n.pleaseEnterEventTitle,
                  isError: true,
                );
                return;
              }
              Navigator.pop(ctx);
              
              final profileController = context.read<UserProfileController>();
              final providerId = profileController.userProfile?.id;
              if (providerId == null) return;

              setState(() => _isLoading = true);
              final controller = context.read<CalenderAvailibilityController>();
              final success = await controller.addManualReservation(
                providerId,
                _selectedDate!,
                startTimeController.text,
                endTimeController.text,
                titleController.text,
              );

              if (mounted) {
                setState(() => _isLoading = false);
                CustomSnackBar.show(
                  context: context,
                  message: success ? context.l10n.manualReservationSuccess : context.l10n.manualReservationFailed,
                  isError: !success,
                );
                _fetchAvailabilityData();
              }
            },
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem({
    required String title,
    required String client,
    required String time,
    required String location,
    required String cost,
    required String status,
    Map<String, dynamic>? bookingData,
  }) {
    return GestureDetector(
      onTap: bookingData != null ? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingDetailsScreen(booking: bookingData),
          ),
        );
      } : null,
      child: Container(
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
         color: Theme.of(context).colorScheme.surface,
         borderRadius: BorderRadius.circular(15.r),
         border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
         boxShadow: [
           BoxShadow(
             color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.02),
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
              Expanded(
                child: Text(
                  title,
                   style: TextStyle(
                    fontSize: AppTypography.bodyLarge,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                 decoration: BoxDecoration(
                  color: status.toLowerCase() == 'confirmed' ? (Theme.of(context).brightness == Brightness.dark ? Colors.green.withOpacity(0.2) : const Color(0xFFE8F5E9)) : (Theme.of(context).brightness == Brightness.dark ? Colors.orange.withOpacity(0.2) : const Color(0xFFFFF3E0)),
                   borderRadius: BorderRadius.circular(6.r),
                 ),
                child: Text(
                  status,
                   style: TextStyle(
                    fontSize: AppTypography.bodySmall,
                    color: status.toLowerCase() == 'confirmed' ? (Theme.of(context).brightness == Brightness.dark ? Colors.green[300] : const Color(0xFF2E7D32)) : (Theme.of(context).brightness == Brightness.dark ? Colors.orange[300] : const Color(0xFFE65100)),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
               Icon(Icons.person_outline, size: 14.sp, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
              SizedBox(width: 5.w),
              Text(
                client,
                 style: TextStyle(
                  fontSize: AppTypography.bodySmall,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                     Icon(Icons.access_time, size: 14.sp, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                    SizedBox(width: 5.w),
                    Text(
                      time,
                       style: TextStyle(
                        fontSize: AppTypography.bodySmall,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    SizedBox(width: 15.w),
                     Icon(Icons.location_on_outlined, size: 14.sp, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                    SizedBox(width: 5.w),
                    Expanded(
                      child: Text(
                        location,
                         style: TextStyle(
                          fontSize: AppTypography.bodySmall,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                cost,
                style: TextStyle(
                  fontSize: AppTypography.bodyLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildWeekView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.weeklyOverview,
          style: TextStyle(
            fontSize: AppTypography.h1,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 15.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _getWeekdays()
              .map(
                (day) => Expanded(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        SizedBox(height: 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) => _buildWeekDayItem(index + 1)),
        ),
        SizedBox(height: 30.h),
        Text(
          context.l10n.upcomingThisWeek,
          style: TextStyle(
             fontSize: AppTypography.h2,
             fontWeight: FontWeight.bold,
             color: Theme.of(context).colorScheme.onSurface,
           ),
        ),
        SizedBox(height: 15.h),
        Consumer<ProviderOrdersController>(
          builder: (context, controller, child) {
            if (controller.upcomingLoading && controller.upcomingOrders.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.upcomingOrders.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Center(
                  child: Text(
                     context.l10n.noBookingsRightNow,
                     style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 14.sp),
                   ),
                ),
              );
            }

            return Column(
              children: controller.upcomingOrders.map((booking) {
                final pricing = booking['pricingDetails'];
                final service = booking['serviceId'];
                
                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: _buildScheduleItem(
                    title: service is Map ? service['title'] : booking['eventType'] ?? context.l10n.defaultBookingTitle,
                    client: booking['clientName'] ?? (booking['clientId'] is Map ? booking['clientId']['name'] : null) ?? context.l10n.defaultClientName,
                    time: booking['startTime'] ?? context.l10n.notAvailable,
                    location: booking['eventLocation'] is Map ? booking['eventLocation']['address'] : null ?? context.l10n.locationNA,
                    cost: '€${pricing?['subtotal'] ?? '0'}',
                    status: booking['status'] ?? 'pending',
                    bookingData: booking,
                  ),
                );
              }).toList(),
            );
          },
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildWeekDayItem(int dayOffset) {
    // Calculate the date for this day of the week
    final now = DateTime.now();
    final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final date = firstDayOfWeek.add(Duration(days: dayOffset - 1));
    bool isWorking = _isDayWorking(date);

    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2.w),
        padding: EdgeInsets.symmetric(vertical: 15.h),
        decoration: BoxDecoration(
           color: isWorking ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
           borderRadius: BorderRadius.circular(10.r),
           border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
         ),
        child: Column(
          children: [
            Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: AppTypography.h2,
                 fontWeight: FontWeight.bold,
                 color: isWorking ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
               ),
            ),
            SizedBox(height: 5.h),
            Text(
              isWorking ? context.l10n.statusOn : context.l10n.statusOff,
              style: TextStyle(
                fontSize: 8.sp,
                fontWeight: FontWeight.w600,
                color: isWorking ? Colors.green : Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _previousMonth,
              icon: Icon(Icons.chevron_left, size: 24.sp),
            ),
            Text(
              _currentDate.year.toString(),
              style: TextStyle(
                 fontSize: AppTypography.h1,
                 fontWeight: FontWeight.bold,
                 color: Theme.of(context).colorScheme.onSurface,
               ),
            ),
            IconButton(
              onPressed: _nextMonth,
              icon: Icon(Icons.chevron_right, size: 24.sp),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 100.h,
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
          ),
          itemCount: 12,
          itemBuilder: (context, index) {
            String monthName = DateFormat('MMMM').format(DateTime(_currentDate.year, index + 1));
            return GestureDetector(
              onTap: () {
                setState(() {
                  _currentDate = DateTime(_currentDate.year, index + 1);
                  _selectedViewIndex = 1;
                });
              },
              child: Container(
                padding: EdgeInsets.all(15.w),
                 decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                   borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                ),
                child: Center(
                  child: Text(
                    monthName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(height: 20.h),
      ],
    );
  }
}
