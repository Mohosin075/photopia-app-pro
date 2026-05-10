import 'package:flutter/material.dart';
import 'package:photopia/core/network/Api_service/network_caller.dart';
import 'package:photopia/core/network/urls.dart';
import 'package:photopia/data/models/booking_model.dart';

class BookingController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? _lastBookingId;
  String? get lastBookingId => _lastBookingId;

  List<Booking> _bookings = [];
  List<Booking> get bookings => _bookings;

  Future<bool> getMyBookings({String? status, String? filterType}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String url = Urls.getMyOrders(
        status: status,
        filterType: filterType,
      );
      final response = await NetworkCaller.getRequest(
        url: url,
        requireAuth: true,
      );

      if (response.isSuccess && response.body != null) {
        final model = BookingModel.fromJson(response.body!);
        _bookings = model.data ?? [];
        return true;
      } else {
        _errorMessage = response.errorMessage ?? "Failed to fetch bookings";
        return false;
      }
    } catch (e) {
      _errorMessage = "Error fetching bookings: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> createBooking({
    required String providerId,
    required String serviceId,
    required String bookingDate,
    required String startTime,
    String? endTime,
    String? packageName,
    required String address,
    required String city,
    required String country,
    required double lat,
    required double lng,
    String? clientName,
    String? clientEmail,
    String? clientPhone,
    String? eventType,
    String? specialRequests,
    double distanceFromProviderKm = 0,
    String? notes,
    String? paymentMethodId,
    String? paymentIntentId, // Added this
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> body = {
        "serviceId": serviceId,
        "providerId": providerId,
        "bookingDate": bookingDate,
        "startTime": startTime,
        "endTime": endTime,
        "packageName": packageName ?? "",
        "paymentMethodId": paymentMethodId,
        "paymentIntentId": paymentIntentId, // Pass it here
        "isPaid": true,
        "paymentStatus": "Paid",
        "eventLocation": {
          "address": address,
          "city": city,
          "country": country,
          "coordinates": {"lng": lng, "lat": lat},
          "notes": notes,
        },
        "clientName": clientName ?? "",
        "clientEmail": clientEmail ?? "",
        "clientPhone": clientPhone ?? "",
        "client": {
          "name": clientName ?? "",
          "email": clientEmail ?? "",
          "userEmail": clientEmail, // Added here
          "phone": clientPhone ?? "",
        },
        "user": {
          "email": clientEmail, 
          "userEmail": clientEmail
        },
        "payment": {
          "userEmail": clientEmail, 
          "email": clientEmail
        },
        "paymentInfo": {
          "userEmail": clientEmail, 
          "email": clientEmail
        },
        "paymentData": {
          "userEmail": clientEmail
        },
        "eventType": eventType ?? "Photography Session",
        "specialRequests": specialRequests ?? "",
        "distanceFromProviderKm": distanceFromProviderKm,
      };

      debugPrint('📦 [BookingController] Request Body: $body');

      final response = await NetworkCaller.postRequest(
        url: Urls.createBooking,
        body: body,
      );

      if (response.isSuccess) {
        final data = response.body?['data'];
        
        _lastBookingId =
            data?['booking']?['_id']?.toString() ??
            data?['booking']?['id']?.toString() ??
            data?['_id']?.toString() ??
            data?['id']?.toString();

        debugPrint('✅ BookingController: Booking ID parsed: $_lastBookingId');
        return data; // Return full data containing both booking and payment objects

      } else {
        _errorMessage = response.errorMessage ?? "Failed to create booking";
        return null;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateBookingStatus(String bookingId, String status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await NetworkCaller.patchRequest(
        url: Urls.updateBookingStatus(bookingId),
        body: {"status": status},
        requireAuth: true,
      );
      debugPrint(
        '📋 BookingController: Status update to "$status" → success: ${response.isSuccess}',
      );
      if (!response.isSuccess) {
        _errorMessage = response.errorMessage ?? "Failed to update status";
      }
      return response.isSuccess;
    } catch (e) {
      debugPrint('❌ BookingController: Status update failed: $e');
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> acceptModifiedOffer(String bookingId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Typically we update status to 'confirmed' or 'accepted' or a specific modify status
      // For now, let's use the status update endpoint to signify acceptance
      final response = await NetworkCaller.patchRequest(
        url: Urls.updateBookingStatus(bookingId),
        body: {"status": "accepted"},
        requireAuth: true,
      );

      if (response.isSuccess) {
        debugPrint('✅ BookingController: Modified offer accepted successfully');
        return true;
      } else {
        _errorMessage = response.errorMessage ?? "Failed to accept offer";
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> calculateBookingPrice({
    required String serviceId,
    required String bookingDate,
    required String startTime,
    String? endTime,
    String? packageName,
    double distanceFromProviderKm = 0.0,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final Map<String, dynamic> body = {
      "serviceId": serviceId,
      "date": bookingDate,
      "startTime": startTime,
      "distanceFromProviderKm": distanceFromProviderKm,
    };

    if (endTime != null && endTime.isNotEmpty) {
      body["endTime"] = endTime;
    }

    if (packageName != null && packageName.isNotEmpty) {
      body["packageName"] = packageName;
    }

    try {
      final response = await NetworkCaller.postRequest(
        url: Urls.calculateBookingPrice,
        body: body,
      );

      if (response.isSuccess) {
        return response.body?['data'];
      } else {
        _errorMessage = response.errorMessage ?? "Failed to calculate price";
        return null;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
