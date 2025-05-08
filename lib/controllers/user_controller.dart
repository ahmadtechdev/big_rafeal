// controllers/user_controller.dart
import 'package:get/get.dart';
import '../models/user_model.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:convert';

class UserController extends GetxController {
  Rx<User?> currentUser = Rx<User?>(null);
  final storage = GetStorage();

  // Default login duration - 30 days in milliseconds
  static const int defaultLoginDuration = 30 * 24 * 60 * 60 * 1000;

  @override
  void onInit() {
    super.onInit();
    // Load user data from storage if available and check expiration
    loadUserFromStorage();
  }

  void setUser(User user, {int? durationInMilliseconds}) {
    currentUser.value = user;

    // Calculate expiration time
    final expirationTime = DateTime.now().millisecondsSinceEpoch +
        (durationInMilliseconds ?? defaultLoginDuration);

    // Save user to storage with expiration
    final userData = {
      'user': user.toJson(),
      'expiration': expirationTime,
    };

    storage.write('user_data', jsonEncode(userData));
  }

  void clearUser() {
    currentUser.value = null;
    // Remove user from storage
    storage.remove('user_data');
  }

  bool get isLoggedIn => currentUser.value != null;

  void loadUserFromStorage() {
    try {
      final userData = storage.read('user_data');
      if (userData != null) {
        final Map<String, dynamic> userDataMap = jsonDecode(userData);

        // Check if login is expired
        final int? expirationTime = userDataMap['expiration'];
        final currentTime = DateTime.now().millisecondsSinceEpoch;

        if (expirationTime != null && currentTime < expirationTime) {
          // Login still valid
          final userMap = userDataMap['user'] as Map<String, dynamic>;
          currentUser.value = User.fromJson(userMap);
        } else {
          // Login expired, clear data
          clearUser();
        }
      }
    } catch (e) {
      // Clear any corrupted data
      clearUser();
    }
  }

  // Refresh user login period
  void refreshLoginPeriod({int? durationInMilliseconds}) {
    if (currentUser.value != null) {
      setUser(currentUser.value!, durationInMilliseconds: durationInMilliseconds);
    }
  }

  // Check if login is about to expire
  bool isLoginAboutToExpire({int warningThresholdDays = 3}) {
    try {
      final userData = storage.read('user_data');
      if (userData != null) {
        final Map<String, dynamic> userDataMap = jsonDecode(userData);
        final int? expirationTime = userDataMap['expiration'];
        final currentTime = DateTime.now().millisecondsSinceEpoch;

        // Calculate days remaining
        final int warningThresholdMillis = warningThresholdDays * 24 * 60 * 60 * 1000;

        return expirationTime != null &&
            (expirationTime - currentTime) < warningThresholdMillis &&
            currentTime < expirationTime;
      }
    } catch (e) {
    }
    return false;
  }

  // Get remaining login days
  int getRemainingLoginDays() {
    try {
      final userData = storage.read('user_data');
      if (userData != null) {
        final Map<String, dynamic> userDataMap = jsonDecode(userData);
        final int? expirationTime = userDataMap['expiration'];
        final currentTime = DateTime.now().millisecondsSinceEpoch;

        if (expirationTime != null && currentTime < expirationTime) {
          // Calculate days remaining
          return ((expirationTime - currentTime) / (24 * 60 * 60 * 1000)).floor();
        }
      }
    } catch (e) {
    }
    return 0;
  }
}