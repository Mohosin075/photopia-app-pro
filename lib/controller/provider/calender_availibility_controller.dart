import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:photopya/core/network/Api_service/network_caller.dart';
import 'package:photopya/core/network/urls.dart';
import 'package:photopya/data/models/calender_availibility_model.dart';

class CalenderAvailibilityController extends ChangeNotifier {
  bool _inProgress = false;
  String? _errorMessage;

  bool get inProgress => _inProgress;
  String? get errorMessage => _errorMessage;

  CalenderSettingsModel? _availabilitySettings;
  CalenderSettingsModel? get availabilitySettings => _availabilitySettings;
  Data? get availabilityData => _availabilitySettings?.data;

  // Caching month calendar data to reduce load time
  final Map<String, List<dynamic>> _calendarCache = {};

  Future<List<dynamic>> getMonthCalendar(
    String providerId,
    int month,
    int year,
  ) async {
    final cacheKey = '$providerId-$month-$year';
    if (_calendarCache.containsKey(cacheKey)) {
      debugPrint('⚡ Returning cached calendar for $cacheKey');
      return _calendarCache[cacheKey]!;
    }

    _inProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String url = Urls.getMonthCalendar(providerId, month, year);
      final NetworkResponse response = await NetworkCaller.getRequest(
        url: url,
        requireAuth: true,
      );

      _inProgress = false;
      if (response.isSuccess && response.body != null) {
        final List<dynamic> calendar = response.body!['data']['calendar'] ?? [];
        _calendarCache[cacheKey] = calendar;
        notifyListeners();
        return calendar;
      } else {
        _errorMessage =
            response.errorMessage ?? 'Failed to fetch month calendar';
        notifyListeners();
        return [];
      }
    } catch (e) {
      _inProgress = false;
      _errorMessage = 'An unexpected error occurred: $e';
      notifyListeners();
      return [];
    }
  }

  Future<bool> updateAvailability(Data availabilityData) async {
    _inProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Convert Data object to JSON map
      final Map<String, dynamic> body = availabilityData.toJson();

      // Remove internal metadata that should not be sent
      body.remove('_id');
      body.remove('id');
      body.remove('createdAt');
      body.remove('updatedAt');
      body.remove('__v');

      // As per analysis.txt and Postman screenshot, serviceId is not present
      body.remove('serviceId');

      // Keep only non-null values
      body.removeWhere((key, value) => value == null);

      String bodyStr = jsonEncode(body);
      if (bodyStr.length > 500) {
        bodyStr = "${bodyStr.substring(0, 500)}... [Truncated]";
      }

      debugPrint('🚀 Sending Availability Update to ${Urls.createAvailability}');
      debugPrint('📦 Body: $bodyStr');

      final NetworkResponse response = await NetworkCaller.postRequest(
        url: Urls.createAvailability,
        body: body,
        requireAuth: true,
      );

      _inProgress = false;
      if (response.isSuccess) {
        _calendarCache.clear();
        notifyListeners();
        return true;
      } else {
        _errorMessage =
            response.errorMessage ?? 'Failed to update availability';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _inProgress = false;
      _errorMessage = 'An unexpected error occurred: $e';
      notifyListeners();
      return false;
    }
  }

  Future<CalenderSettingsModel?> getAvailabilitySettings({
    String? providerId,
  }) async {
    _inProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String url = providerId != null
          ? Urls.getProviderAvailability(providerId)
          : Urls.myAvailability;

      final NetworkResponse response = await NetworkCaller.getRequest(
        url: url,
        requireAuth: true,
      );

      _inProgress = false;
      if (response.isSuccess && response.body != null) {
        _availabilitySettings = CalenderSettingsModel.fromJson(response.body!);
        notifyListeners();
        return _availabilitySettings;
      } else {
        _errorMessage = response.errorMessage ?? 'Failed to fetch availability';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _inProgress = false;
      _errorMessage = 'An unexpected error occurred: $e';
      notifyListeners();
      return null;
    }
  }

  Future<List<String>> getTimeSlots(
    String providerId,
    String date,
    int duration,
  ) async {
    _inProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String url = Urls.getTimeSlots(providerId, date, duration);
      final NetworkResponse response = await NetworkCaller.getRequest(
        url: url,
        requireAuth: true,
      );

      _inProgress = false;
      if (response.isSuccess && response.body != null) {
        notifyListeners();
        final List<dynamic> slots = response.body!['data']['slots'] ?? [];
        return slots.map((s) => s.toString()).toList();
      } else {
        _errorMessage = response.errorMessage ?? 'Failed to fetch time slots';
        notifyListeners();
        return [];
      }
    } catch (e) {
      _inProgress = false;
      _errorMessage = 'An unexpected error occurred: $e';
      notifyListeners();
      return [];
    }
  }

  List<dynamic> _bookingsForSelectedDate = [];
  List<dynamic> get bookingsForSelectedDate => _bookingsForSelectedDate;

  Future<bool> getBookingsByDate({required String date}) async {
    _inProgress = true;
    _errorMessage = null;
    _bookingsForSelectedDate = [];
    notifyListeners();

    try {
      final String url = Urls.getBookingsByDate(date);
      debugPrint('📅 Fetching Bookings for Date: $date');
      debugPrint('🌐 URL: $url');

      final NetworkResponse response = await NetworkCaller.getRequest(
        url: url,
        requireAuth: true,
      );

      _inProgress = false;
      if (response.isSuccess && response.body != null) {
        _bookingsForSelectedDate = response.body!['data'] ?? [];
        debugPrint('✅ Fetched ${_bookingsForSelectedDate.length} bookings');
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.errorMessage ?? 'Failed to fetch bookings';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _inProgress = false;
      _errorMessage = 'An unexpected error occurred: $e';
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _inProgress = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> resetDateToDefault(String providerId, DateTime date) async {
    final data = availabilityData ?? Data(providerId: providerId);
    final compareDate = DateTime(date.year, date.month, date.day);
    final dateStr = date.toIso8601String().split('T')[0];

    // 1. Remove from blockedDateRanges
    if (data.blockedDateRanges != null) {
      data.blockedDateRanges!.removeWhere((range) {
        if (range.startDate == null || range.endDate == null) return false;
        try {
          final start = DateTime.parse(range.startDate!);
          final end = DateTime.parse(range.endDate!);
          final startZero = DateTime(start.year, start.month, start.day);
          final endZero = DateTime(end.year, end.month, end.day);
          return (compareDate.isAfter(startZero) || compareDate.isAtSameMomentAs(startZero)) &&
                 (compareDate.isBefore(endZero) || compareDate.isAtSameMomentAs(endZero));
        } catch (e) {
          return false;
        }
      });
    }

    // 2. Remove from customDates
    if (data.customDates != null) {
      data.customDates!.removeWhere((cd) {
        if (cd.date == null) return false;
        return cd.date!.startsWith(dateStr);
      });
    }

    // 3. Remove from availabilityPeriods
    if (data.availabilityPeriods != null) {
      data.availabilityPeriods!.removeWhere((range) {
        if (range.startDate == null || range.endDate == null) return false;
        try {
          final start = DateTime.parse(range.startDate!);
          final end = DateTime.parse(range.endDate!);
          final startZero = DateTime(start.year, start.month, start.day);
          final endZero = DateTime(end.year, end.month, end.day);
          return (compareDate.isAfter(startZero) || compareDate.isAtSameMomentAs(startZero)) &&
                 (compareDate.isBefore(endZero) || compareDate.isAtSameMomentAs(endZero));
        } catch (e) {
          return false;
        }
      });
    }

    return await updateAvailability(data);
  }

  Future<bool> blockDate(String providerId, DateTime date, {String? note}) async {
    final data = availabilityData ?? Data(providerId: providerId);
    data.blockedDateRanges ??= [];
    
    final dateStr = date.toIso8601String().split('T')[0] + 'T00:00:00.000Z';
    bool exists = data.blockedDateRanges!.any((r) => 
      r.startDate != null && r.startDate!.startsWith(dateStr.substring(0, 10))
    );
    if (!exists) {
      data.blockedDateRanges!.add(BlockedDateRanges(
        startDate: dateStr,
        endDate: dateStr,
        note: note ?? 'Blocked Day',
      ));
    }
    
    data.customDates?.removeWhere((cd) {
      if (cd.date == null) return false;
      return cd.date!.startsWith(dateStr.substring(0, 10));
    });

    return await updateAvailability(data);
  }

  Future<bool> blockDateRange(String providerId, DateTime startDate, DateTime endDate, {String? note}) async {
    final data = availabilityData ?? Data(providerId: providerId);
    data.blockedDateRanges ??= [];

    final startStr = startDate.toIso8601String().split('T')[0] + 'T00:00:00.000Z';
    final endStr = endDate.toIso8601String().split('T')[0] + 'T23:59:59.000Z';

    data.blockedDateRanges!.add(BlockedDateRanges(
      startDate: startStr,
      endDate: endStr,
      note: note ?? 'Blocked Range',
    ));

    final startCompare = DateTime(startDate.year, startDate.month, startDate.day);
    final endCompare = DateTime(endDate.year, endDate.month, endDate.day);
    
    data.customDates?.removeWhere((cd) {
      if (cd.date == null) return false;
      try {
        final d = DateTime.parse(cd.date!);
        final dCompare = DateTime(d.year, d.month, d.day);
        return (dCompare.isAfter(startCompare) || dCompare.isAtSameMomentAs(startCompare)) &&
               (dCompare.isBefore(endCompare) || dCompare.isAtSameMomentAs(endCompare));
      } catch (e) {
        return false;
      }
    });

    return await updateAvailability(data);
  }

  Future<bool> markDateAsAvailable(String providerId, DateTime date) async {
    final data = availabilityData ?? Data(providerId: providerId);
    final dateStr = date.toIso8601String().split('T')[0];

    if (data.blockedDateRanges != null) {
      data.blockedDateRanges!.removeWhere((range) {
        if (range.startDate == null || range.endDate == null) return false;
        try {
          final start = DateTime.parse(range.startDate!);
          final end = DateTime.parse(range.endDate!);
          final startZero = DateTime(start.year, start.month, start.day);
          final endZero = DateTime(end.year, end.month, end.day);
          final compareDate = DateTime(date.year, date.month, date.day);
          return (compareDate.isAfter(startZero) || compareDate.isAtSameMomentAs(startZero)) &&
                 (compareDate.isBefore(endZero) || compareDate.isAtSameMomentAs(endZero));
        } catch (e) {
          return false;
        }
      });
    }

    data.customDates ??= [];
    data.customDates!.removeWhere((cd) {
      if (cd.date == null) return false;
      return cd.date!.startsWith(dateStr);
    });
    
    data.customDates!.add(CustomDates(
      date: date.toIso8601String().split('T')[0] + 'T00:00:00.000Z',
      type: 'special_hours',
      start: '09:00',
      end: '18:00',
    ));

    return await updateAvailability(data);
  }

  Future<bool> addAvailabilityPeriod(
    String providerId, 
    DateTime startDate, 
    DateTime endDate, 
    String startTime, 
    String endTime, 
    {double? priceOverride}
  ) async {
    final data = availabilityData ?? Data(providerId: providerId);
    data.availabilityPeriods ??= [];

    final startStr = startDate.toIso8601String().split('T')[0] + 'T00:00:00.000Z';
    final endStr = endDate.toIso8601String().split('T')[0] + 'T23:59:59.000Z';

    data.availabilityPeriods!.add(AvailabilityPeriods(
      startDate: startStr,
      endDate: endStr,
      startTime: startTime,
      endTime: endTime,
      priceOverride: priceOverride,
    ));

    return await updateAvailability(data);
  }

  Future<bool> addManualReservation(
    String providerId, 
    DateTime date, 
    String startTime, 
    String endTime, 
    String note
  ) async {
    final data = availabilityData ?? Data(providerId: providerId);
    data.customDates ??= [];

    final dateStr = date.toIso8601String().split('T')[0] + 'T00:00:00.000Z';
    data.customDates!.add(CustomDates(
      date: dateStr,
      type: 'unavailable',
      start: startTime,
      end: endTime,
      note: note,
    ));

    return await updateAvailability(data);
  }
}
