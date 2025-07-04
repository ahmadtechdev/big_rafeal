import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomSnackBar {
  static void show({
    String? title,
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    Get.snackbar(
      title ?? 'Message',
      message,
      backgroundColor: isError ? const Color(0xFFE53935) : Colors.green,
      colorText: Colors.white,
      duration: duration,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }

  // Quick access methods
  static void success(String message, {String? title, int? duration}) {
    show(
      title: title,
      message: message,
      isError: false,
      duration:  Duration(seconds: duration ?? 4),
    );
  }

  static void error(String message, {String? title, int? duration}) {
    show(
      title: title,
      message: message,
      isError: true,
      duration:  Duration(seconds: duration ?? 4),
    );
  }
}