import 'package:flutter/material.dart';
import 'package:photopia/core/network/Api_service/network_caller.dart';
import 'package:photopia/core/network/urls.dart';

class VerifyOtpController extends ChangeNotifier {
  bool _inProgress = false;
  String? _errorMessage;
  String? _resetToken;

  bool get inProgress => _inProgress;
  String? get errorMessage => _errorMessage;
  String? get resetToken => _resetToken;

  Future<bool> verifyOtp(String email, String otp) async {
    bool isSuccess = false;
    _inProgress = true;
    _resetToken = null;
    notifyListeners();

    Map<String, dynamic> requestBody = {"email": email, "oneTimeCode": otp};

    NetworkResponse response = await NetworkCaller.postRequest(
      url: Urls.verifyOtp,
      body: requestBody,
      requireAuth: false,
    );

    _inProgress = false;
    if (response.isSuccess) {
      _resetToken = response.body?['data']?['token'] ?? response.body?['data']?['accessToken'];
      isSuccess = true;
    } else {
      _errorMessage = response.errorMessage;
    }
    notifyListeners();
    return isSuccess;
  }
}
