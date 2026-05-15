import 'package:flutter/material.dart';
import 'package:photopya/core/network/Api_service/network_caller.dart';
import 'package:photopya/core/network/urls.dart';

class DeleteAccountController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> deleteAccount(String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await NetworkCaller.deleteRequest(
        url: Urls.deleteAccount,
        body: {
          'password': password,
        },
      );

      if (response.isSuccess) {
        return true;
      } else {
        _errorMessage = response.errorMessage ?? 'Failed to delete account';
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

  Future<bool> deactivateAccount(String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await NetworkCaller.patchRequest(
        url: Urls.deactivateProfile,
        body: {
          'password': password,
        },
      );

      if (response.isSuccess) {
        return true;
      } else {
        _errorMessage = response.errorMessage ?? 'Failed to deactivate account';
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
}
