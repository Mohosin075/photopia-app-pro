import 'package:flutter/material.dart';
import 'package:photopya/controller/auth_controller.dart';
import 'package:photopya/core/network/Api_service/network_caller.dart';
import 'package:photopya/core/network/urls.dart';

class RoleSwitchController extends ChangeNotifier {
  bool _inProgress = false;
  bool get inProgress => _inProgress;
  String? errorMessage;

  Future<bool> switchRole(
    String targetRole, {
    List<String>? specialties,
  }) async {
    _inProgress = true;
    errorMessage = null;
    notifyListeners();
    try {
      // 1. Switch Role via API
      final Map<String, dynamic> body = {"role": targetRole};
      final response = await NetworkCaller.patchRequest(
        url: Urls.role,
        body: body,
      );

      // 2. If the API succeeds, save the role normally
      if (response.isSuccess) {
        await AuthController.saveUserRole(targetRole);

        // If the response contains a new token, update it
        if (response.body != null && response.body!['data'] != null) {
          final newToken = response.body!['data']['accessToken'];
          if (newToken != null) {
            debugPrint('🔑 RoleSwitchController: Updating access token');
            await AuthController.updateToken(newToken);
          } else {
            // If no token in response, force a refresh to get a token with the new role
            debugPrint(
              '🔄 RoleSwitchController: No token in response, forcing refresh',
            );
            await NetworkCaller.refreshAccessToken();
          }
        } else {
          // Force refresh if data is missing
          debugPrint('🔄 RoleSwitchController: Missing data, forcing refresh');
          await NetworkCaller.refreshAccessToken();
        }

        // If professional and have specialties, update professional profile
        if (targetRole == 'professional' &&
            specialties != null &&
            specialties.isNotEmpty) {
          debugPrint(
            '👔 Updating specialties in professional profile: $specialties',
          );
          await NetworkCaller.patchRequest(
            url: Urls.professionalProfile,
            body: {"specialties": specialties},
          );
        }

        _inProgress = false;
        notifyListeners();
        return true;
      }

      // 3. If 403 (super_admin or elevated role), bypass the API and allow
      //    local role switch — super_admin can access all modes.
      if (response.statusCode == 403) {
        debugPrint(
          '⚠️ RoleSwitchController: 403 received — treating as privileged user, switching role locally.',
        );
        await AuthController.saveUserRole(targetRole);
        _inProgress = false;
        notifyListeners();
        return true;
      }

      // 4. Any other error
      debugPrint('RoleSwitchController Error: ${response.errorMessage}');
      errorMessage = response.errorMessage;
      _inProgress = false;
      notifyListeners();
      return false;
    } catch (e) {
      _inProgress = false;
      errorMessage = e.toString();
      notifyListeners();
      debugPrint('RoleSwitchController Exception: $e');
      return false;
    }
  }
}
