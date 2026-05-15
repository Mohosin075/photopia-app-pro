import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:photopya/core/network/Api_service/network_caller.dart';
import 'package:photopya/core/network/urls.dart';
import 'package:photopya/data/models/payment_method_model.dart';

class PaymentController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<PaymentMethodModel> _paymentMethods = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<PaymentMethodModel> get paymentMethods => _paymentMethods;

  Map<String, dynamic>? _parsePaymentPayload(dynamic data) {
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    final nested = map['payment'];
    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }
    if (map['clientSecret'] != null || map['client_secret'] != null) {
      return map;
    }
    return null;
  }

  String? _clientSecretFrom(Map<String, dynamic>? pay) {
    if (pay == null) return null;
    return pay['clientSecret'] as String? ?? pay['client_secret'] as String?;
  }

  String? _ephemeralFrom(Map<String, dynamic>? pay) {
    if (pay == null) return null;
    return pay['ephemeralKey'] as String? ?? pay['ephemeral_key'] as String?;
  }

  String? _customerFrom(Map<String, dynamic>? pay) {
    if (pay == null) return null;
    return pay['customerId'] as String? ?? pay['customer_id'] as String?;
  }

  /// Fetch saved payment methods
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
        _errorMessage = response.errorMessage ?? 'Failed to fetch payment methods';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Add a new payment method using SetupIntent
  Future<bool> addNewPaymentMethod() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await NetworkCaller.postRequest(
        url: Urls.createSetupIntent,
        body: {},
      );

      if (response.isSuccess && response.body != null) {
        final data = response.body!['data'];
        final clientSecret = data['clientSecret'] ?? data['client_secret'];
        final customerId = data['customerId'] ?? data['customer_id'];
        final ephemeralKey = data['ephemeralKey'] ?? data['ephemeral_key'];

        if (clientSecret == null) {
          _errorMessage = 'Missing clientSecret for setup';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            setupIntentClientSecret: clientSecret,
            merchantDisplayName: 'Photopia',
            customerId: customerId,
            customerEphemeralKeySecret: ephemeralKey,
            style: ThemeMode.light,
          ),
        );

        final presentSuccess = await presentPaymentSheet();
        if (presentSuccess) {
          await fetchPaymentMethods(); // Refresh list
          return true;
        }
      } else {
        _errorMessage = response.errorMessage ?? 'Failed to create setup intent';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Set a payment method as default
  Future<bool> setDefaultMethod(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await NetworkCaller.postRequest(
        url: Urls.setDefaultPaymentMethod(id),
        body: {},
      );

      if (response.isSuccess) {
        await fetchPaymentMethods();
        return true;
      } else {
        _errorMessage = response.errorMessage ?? 'Failed to set default method';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Delete a payment method
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
        _errorMessage = response.errorMessage ?? 'Failed to delete method';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Initialize sheet from secrets
  Future<bool> initPaymentSheetWithSecrets({
    required String clientSecret,
    String? ephemeralKey,
    String? customerId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final useCustomer = (customerId != null &&
              customerId.isNotEmpty &&
              ephemeralKey != null &&
              ephemeralKey.isNotEmpty);

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Photopia',
          style: ThemeMode.light,
          customerId: useCustomer ? customerId : null,
          customerEphemeralKeySecret: useCustomer ? ephemeralKey : null,
        ),
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Initialize sheet from booking ID
  Future<dynamic> initPaymentSheet({
    String? bookingId,
    String? serviceId,
    required String currency,
    double? amount,
    String? paymentMethodId,
    String? userEmail,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        if (bookingId != null) 'bookingId': bookingId,
        if (serviceId != null) 'serviceId': serviceId,
        'currency': currency.toLowerCase(),
        'email': userEmail,
      };
      if (amount != null && bookingId == null) {
        body['amount'] = amount.round();
      }
      if (paymentMethodId != null && paymentMethodId.isNotEmpty) {
        body['paymentMethodId'] = paymentMethodId;
      }

      final NetworkResponse response = await NetworkCaller.postRequest(
        url: Urls.createPaymentIntent,
        body: body,
      );

      if (response.isSuccess && response.body != null) {
        final pay = _parsePaymentPayload(response.body!['data']);
        final clientSecret = _clientSecretFrom(pay);
        final ephemeralKey = _ephemeralFrom(pay);
        final customerId = _customerFrom(pay);

        if (clientSecret == null || clientSecret.isEmpty) {
          _errorMessage = 'Missing clientSecret from server';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        final useCustomer = (customerId != null &&
                customerId.isNotEmpty &&
                ephemeralKey != null &&
                ephemeralKey.isNotEmpty);

        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'Photopia',
            style: ThemeMode.light,
            customerId: useCustomer ? customerId : null,
            customerEphemeralKeySecret: useCustomer ? ephemeralKey : null,
          ),
        );

        _isLoading = false;
        notifyListeners();
        return response.body?['data'] ?? true;
      } else {
        _errorMessage = response.errorMessage ?? 'Failed to initialize payment';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Charge a saved card directly.
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
      final body = {
        'bookingId': bookingId,
        'amount': amount.round(),
        'paymentMethodId': paymentMethodId,
        'email': userEmail,
      };

      final response = await NetworkCaller.postRequest(
        url: Urls.createPaymentIntent,
        body: body,
      );

      _isLoading = false;
      if (response.isSuccess) {
        notifyListeners();
        return response.body?['data'] ?? true;
      } else {
        _errorMessage = response.errorMessage ?? 'Saved card payment failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Remaining balance after deposit
  Future<bool> initPaymentSheetForBalance({
    required String bookingId,
    String? paymentMethodId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{};
      if (paymentMethodId != null && paymentMethodId.isNotEmpty) {
        body['paymentMethodId'] = paymentMethodId;
      }

      final NetworkResponse response = await NetworkCaller.postRequest(
        url: Urls.payBalance(bookingId),
        body: body.isEmpty ? {} : body,
      );

      if (response.isSuccess && response.body != null) {
        final pay = _parsePaymentPayload(response.body!['data']);
        final clientSecret = _clientSecretFrom(pay);
        final ephemeralKey = _ephemeralFrom(pay);
        final customerId = _customerFrom(pay);

        if (clientSecret == null || clientSecret.isEmpty) {
          _errorMessage = 'Missing clientSecret from pay-balance response';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        final useCustomer = (customerId != null &&
                customerId.isNotEmpty &&
                ephemeralKey != null &&
                ephemeralKey.isNotEmpty);

        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'Photopia',
            style: ThemeMode.light,
            customerId: useCustomer ? customerId : null,
            customerEphemeralKeySecret: useCustomer ? ephemeralKey : null,
          ),
        );

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage =
            response.errorMessage ?? 'Failed to initialize balance payment';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> presentPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      return true;
    } on StripeException catch (e) {
      _errorMessage = e.getAppError().message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}

extension StripeErrorExtension on StripeException {
  LocalizedErrorMessage getAppError() {
    return error;
  }
}
