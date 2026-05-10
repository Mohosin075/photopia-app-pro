import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:photopia/core/network/Api_service/network_caller.dart';
import 'package:photopia/core/network/urls.dart';
import 'package:photopia/data/models/payment_method_model.dart';

class PaymentController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<PaymentMethodModel> _paymentMethods = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<PaymentMethodModel> get paymentMethods => _paymentMethods;

  /// Initializes the Stripe Payment Sheet by calling the backend
  Future<dynamic> initPaymentSheet({
    String? bookingId,
    String? serviceId, // Added serviceId for pre-booking intent
    required double amount,
    required String currency,
    String? userEmail,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Call backend to create PaymentIntent
      final Map<String, dynamic> body = {
        'bookingId': bookingId,
        'amount': amount,
      };

      final NetworkResponse response = await NetworkCaller.postRequest(
        url: Urls.createPaymentIntent,
        body: body,
      );

      if (response.isSuccess && response.body != null) {
        final data = response.body!['data'];

        // Handle both camelCase and snake_case from server
        final clientSecret = data['clientSecret'] ?? data['client_secret'];
        final ephemeralKey = data['ephemeralKey'] ?? data['ephemeral_key'];
        final customerId = data['customerId'] ?? data['customer_id'];

        if (clientSecret == null) {
          _errorMessage = "Missing clientSecret from server";
          return false;
        }

        // 2. Initialize Payment Sheet
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            customerEphemeralKeySecret: ephemeralKey,
            customerId: customerId,
            merchantDisplayName: 'Photopia',
            style: ThemeMode.light,
          ),
        );

        return response.body?['data']?['paymentIntentId'] ?? true;
      } else {
        _errorMessage = response.errorMessage ?? "Failed to initialize payment";
        return false;
      }
    } catch (e) {
      _errorMessage = _getStripeErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Displays the initialized Payment Sheet
  Future<bool> presentPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      // If no error is thrown, payment was successful or handled by webhook
      return true;
    } catch (e) {
      _errorMessage = _getStripeErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// Fetches saved payment methods
  Future<void> fetchPaymentMethods() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await NetworkCaller.getRequest(url: Urls.paymentMethods);
      if (response.isSuccess && response.body != null) {
        final List<dynamic> data = response.body!['data'] ?? [];
        _paymentMethods = data
            .map((json) => PaymentMethodModel.fromJson(json))
            .toList();
      } else {
        _errorMessage =
            response.errorMessage ?? "Failed to load payment methods";
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new payment method via Setup Intent using Stripe Payment Sheet
  Future<bool> addNewPaymentMethod() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Create Setup Intent on backend
      final response = await NetworkCaller.postRequest(
        url: Urls.createSetupIntent,
      );

      if (response.isSuccess && response.body != null) {
        final data = response.body!['data'];
        final clientSecret = data?['clientSecret'] ?? data?['client_secret'];
        final customerId = data?['customerId'] ?? data?['customer_id'];
        final ephemeralKey = data?['ephemeralKey'] ?? data?['ephemeral_key'];

        if (clientSecret == null) {
          _errorMessage = "Failed to get setup secret";
          return false;
        }

        // 2. Initialize Payment Sheet for Setup Intent
        // This provides the UI for entering card details
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            setupIntentClientSecret: clientSecret,
            customerId: customerId,
            customerEphemeralKeySecret: ephemeralKey,
            merchantDisplayName: 'Photopia',
            style: ThemeMode.light,
          ),
        );

        // 3. Present the Payment Sheet to the user
        await Stripe.instance.presentPaymentSheet();

        // 4. Refresh list after successful addition
        await fetchPaymentMethods();
        return true;
      } else {
        if (response.statusCode == 403) {
          _errorMessage =
              "Please switch to Client mode to manage payment methods.";
        } else {
          _errorMessage = response.errorMessage ?? "Failed to start setup";
        }
        return false;
      }
    } catch (e) {
      _errorMessage = _getStripeErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets a payment method as default
  Future<bool> setDefaultMethod(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await NetworkCaller.patchRequest(
        url: Urls.setDefaultPaymentMethod(id),
      );
      if (response.isSuccess) {
        await fetchPaymentMethods();
        return true;
      } else {
        _errorMessage = response.errorMessage ?? "Failed to set default";
        return false;
      }
    } catch (e) {
      _errorMessage = _getStripeErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deletes a payment method
  Future<bool> deleteMethod(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await NetworkCaller.deleteRequest(
        url: Urls.deletePaymentMethod(id),
      );
      if (response.isSuccess) {
        await fetchPaymentMethods();
        return true;
      } else {
        _errorMessage = response.errorMessage ?? "Failed to delete method";
        return false;
      }
    } catch (e) {
      _errorMessage = _getStripeErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charges a saved payment method directly
  Future<dynamic> chargeSavedCard({
    required String bookingId,
    required double amount,
    required String paymentMethodId,
    String? userEmail,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await NetworkCaller.postRequest(
        url: Urls.createPaymentIntent,
        body: {
          'bookingId': bookingId,
          'amount': amount,
          'paymentMethodId': paymentMethodId,
        },
      );

      if (response.isSuccess) {
        debugPrint('📦 [chargeSavedCard] Full Body: ${response.body}');
        final status = response.body?['data']?['status']?.toString();
        debugPrint('🔍 [chargeSavedCard] Extracted Status: $status');
        
        if (status == 'succeeded') {
          final pId = response.body?['data']?['paymentIntentId'];
          debugPrint('✅ [chargeSavedCard] Payment ID: $pId');
          return pId ?? true;
        } else if (status == 'requires_action') {
          // Handle 3D Secure / SCA if required
          final clientSecret = response.body?['data']?['clientSecret'];
          if (clientSecret != null) {
            await Stripe.instance.confirmPayment(
              paymentIntentClientSecret: clientSecret,
            );
            return true;
          }
          return false;
        } else {
          _errorMessage = "Payment status: $status";
          return false;
        }
      } else {
        _errorMessage = response.errorMessage ?? "Failed to charge saved card";
        return false;
      }
    } catch (e) {
      _errorMessage = _getStripeErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Helper to convert Stripe error to human readable message
  String _getStripeErrorMessage(dynamic e) {
    if (e is StripeException) {
      return e.error.localizedMessage ??
          e.error.message ??
          "Stripe error occurred";
    }
    return e.toString();
  }
}
