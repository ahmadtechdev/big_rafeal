// import 'package:flutter/material.dart';
//
// class AppColors {
//   // Main colors
//   static const Color primaryColor = Color(0xFFD71921);
//   static const Color secondaryColor = Color(0xFFFFB319);
//
//   // Button gradient colors
//   static const Color gradientStart = Color(0xFFD71921);
//   static const Color gradientEnd = Color(0xFFE94E1B);
//
//   // Background and card colors
//   static const Color backgroundColor = Color(0xFFF5F5F5);
//   static const Color cardColor = Colors.white;
//
//   // Text colors
//   static const Color textDark = Color(0xFF333333);
//   static const Color textLight = Colors.white;
//   static const Color textGrey = Color(0xFF888888);
//
//   // Other UI elements
//   static const Color dividerColor = Color(0xFFEEEEEE);
//   static const Color iconColor = Colors.white;
//
//   // Predefined gradients
//   static const LinearGradient primaryGradient = LinearGradient(
//     colors: [gradientStart, gradientEnd],
//     begin: Alignment.centerLeft,
//     end: Alignment.centerRight,
//   );
//
//   // Banner background
//   static const Color bannerBackground = Color(0xFFFFB319);
// }

import 'package:flutter/material.dart';


class AppColors {
  // Main colors
  static const Color primaryColor = Color(0xFF6A1B9A); // Deep purple
  static const Color secondaryColor = Color(0xFFAB47BC); // Light purple

  // Button gradient colors
  static const Color gradientStart = Color(0xFF6A1B9A); // Deep purple
  static const Color gradientEnd = Color(0xFFAB47BC); // Light purple

  // Background and card colors
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light grey
  static const Color cardColor = Colors.white; // White

  // Text colors
  static const Color textDark = Color(0xFF333333); // Dark grey
  static const Color textLight = Colors.white; // White
  static const Color textGrey = Color(0xFF888888); // Grey

  // Other UI elements
  static const Color dividerColor = Color(0xFFEEEEEE); // Light grey
  static const Color iconColor = Colors.white; // White

  // Predefined gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Banner background
  static const Color bannerBackground = Color(0xFFAB47BC); // Light purple

  // Additional colors for login and register screens
  static const Color inputFieldBackground = Color(0xFFEDE7F6); // Light purple background
  static const Color inputFieldBorder = Color(0xFFD1C4E9); // Light purple border
}