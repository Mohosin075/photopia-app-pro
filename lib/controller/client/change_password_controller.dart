import 'package:flutter/material.dart';
import 'package:photopia/core/network/Api_service/network_caller.dart';
import 'package:photopia/core/network/urls.dart';

class ChangePasswordController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await NetworkCaller.postRequest(
      url: Urls.changePassword,
      body: {
        'currentPassword': oldPassword,
        'newPassword': newPassword,
        'confirmPassword': newPassword,
      },
    );

    _isLoading = false;
    if (response.isSuccess) {
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.errorMessage ?? 'Failed to change password';
      notifyListeners();
      return false;
    }
  }
}
