import 'package:flutter/material.dart';
import 'package:photopya/core/network/Api_service/network_caller.dart';
import 'package:photopya/core/network/urls.dart';
import 'package:photopya/data/models/wallet_model.dart';
import 'package:photopya/data/models/stripe_connect_model.dart';

class WalletController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  WalletData? _walletData;
  WalletData? get walletData => _walletData;

  num get balance => _walletData?.balance ?? 0;
  num get pendingBalance => _walletData?.pendingBalance ?? 0;
  num get totalEarnings => _walletData?.totalEarnings ?? 0;
  num get totalBalance => (balance + pendingBalance);
  
  StripeConnectStatus? _stripeStatus;
  StripeConnectStatus? get stripeStatus => _stripeStatus;

  bool get isStripeReady => 
      _stripeStatus?.isComplete == true && 
      _stripeStatus?.detailsSubmitted == true &&
      _stripeStatus?.payoutsEnabled == true;

  List<dynamic> _transactions = [];
  List<dynamic> get transactions => _transactions;

  Future<void> getTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch withdrawals
      final withdrawalsResponse = await NetworkCaller.getRequest(
        url: Urls.myWithdrawals,
      );
      List<dynamic> withdrawalsList = [];
      if (withdrawalsResponse.isSuccess && withdrawalsResponse.body != null) {
        if (withdrawalsResponse.body!['data'] != null && withdrawalsResponse.body!['data'] is List) {
          withdrawalsList = withdrawalsResponse.body!['data'];
        }
      }

      // 2. Fetch bookings/orders
      final bookingsResponse = await NetworkCaller.getRequest(
        url: Urls.getMyOrders(),
      );
      List<dynamic> bookingsList = [];
      if (bookingsResponse.isSuccess && bookingsResponse.body != null) {
        if (bookingsResponse.body!['data'] != null && bookingsResponse.body!['data'] is List) {
          bookingsList = bookingsResponse.body!['data'];
        }
      }

      // 3. Format & Combine
      final List<Map<String, dynamic>> combined = [];

      for (var w in withdrawalsList) {
        combined.add({
          'type': 'withdrawal',
          'id': w['_id'],
          'title': 'Withdrawal',
          'name': 'Stripe Transfer',
          'amount': (w['amount'] as num?)?.toDouble() ?? 0.0,
          'date': w['createdAt'] ?? '',
          'status': w['status'] ?? 'pending',
          'raw': w,
        });
      }

      for (var b in bookingsList) {
        final service = b['serviceId'] is Map ? b['serviceId'] : {};
        final client = b['clientId'] is Map ? b['clientId'] : {};
        final pricingDetails = b['pricingDetails'] is Map ? b['pricingDetails'] : {};
        
        double earnings = 0.0;
        if (pricingDetails['providerEarnings'] != null) {
          earnings = (pricingDetails['providerEarnings'] as num).toDouble();
        } else if (pricingDetails['subtotal'] != null) {
          earnings = (pricingDetails['subtotal'] as num).toDouble();
        } else {
          earnings = (b['totalPrice'] as num?)?.toDouble() ?? 0.0;
        }

        combined.add({
          'type': 'booking',
          'id': b['_id'],
          'title': service['title'] ?? 'Service Booking',
          'name': client['name'] ?? 'Client',
          'amount': earnings,
          'date': b['bookingDate'] ?? b['createdAt'] ?? '',
          'status': b['status'] ?? 'pending',
          'raw': b,
        });
      }

      // Sort by date descending
      combined.sort((a, b) {
        final dateA = DateTime.tryParse(a['date']) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = DateTime.tryParse(b['date']) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

      _transactions = combined;
    } catch (e) {
      debugPrint("Error fetching transactions: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getMyWallet() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await NetworkCaller.getRequest(
        url: Urls.myWallet,
      );

      if (response.isSuccess && response.body != null) {
        final walletRes = WalletResponse.fromJson(response.body!);
        _walletData = walletRes.data;
      } else {
        debugPrint("Failed to fetch wallet: ${response.errorMessage}");
      }
    } catch (e) {
      debugPrint("Error fetching wallet: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> getStripeStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await NetworkCaller.getRequest(
        url: Urls.stripeConnectStatus,
      );

      if (response.isSuccess && response.body != null) {
        final statusRes = StripeConnectStatusResponse.fromJson(response.body!);
        _stripeStatus = statusRes.data;
        return true;
      } else {
        debugPrint("Failed to fetch stripe status: ${response.errorMessage}");
      }
    } catch (e) {
      debugPrint("Error fetching stripe status: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<String?> getStripeOnboardingUrl() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await NetworkCaller.postRequest(
        url: Urls.stripeOnboarding,
        body: {},
      );

      if (response.isSuccess && response.body != null) {
        final onboardingRes = StripeOnboardingResponse.fromJson(response.body!);
        return onboardingRes.data.url;
      } else {
        debugPrint("Failed to fetch onboarding url: ${response.errorMessage}");
      }
    } catch (e) {
      debugPrint("Error fetching onboarding url: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  Future<bool> createWithdrawal(double amount) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await NetworkCaller.postRequest(
        url: Urls.createWithdrawal,
        body: {"amount": amount},
      );

      if (response.isSuccess) {
        // Refresh wallet data after successful withdrawal
        await getMyWallet();
        return true;
      } else {
        debugPrint("Withdrawal failed: ${response.errorMessage}");
        // We could store the error message if needed
        return false;
      }
    } catch (e) {
      debugPrint("Error creating withdrawal: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _walletData = null;
    _stripeStatus = null;
    _transactions = [];
    _isLoading = false;
    notifyListeners();
  }
}
