import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:lottery_app/lottery_screen_3.dart';
import 'package:lottery_app/sale_report.dart';
import 'package:lottery_app/utils/app_colors.dart';
import 'package:lottery_app/widget/qr_scanner_service.dart';

import 'api_service/api_service.dart';
import 'controllers/lottery_controller.dart';
import 'controllers/user_controller.dart';
import 'login_screen_2.dart';
import 'lottery_cards_screen_4.dart';
import 'lottery_sale.dart';

class AnimatedHomeScreen extends StatefulWidget {
  const AnimatedHomeScreen({super.key});

  @override
  _AnimatedHomeScreenState createState() => _AnimatedHomeScreenState();
}

class _AnimatedHomeScreenState extends State<AnimatedHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Define menu items
  final List<MenuItem> _menuItems = [
    MenuItem(title: 'Lottery', icon: Icons.confirmation_number_outlined),
    MenuItem(title: 'Play', icon: Icons.style_outlined),
    MenuItem(title: 'Lottery Sale History', icon: Icons.history_outlined),
    MenuItem(title: 'Sale Report', icon: Icons.bar_chart_outlined),
    MenuItem(title: 'Result Scanner', icon: Icons.qr_code_scanner_outlined),
    MenuItem(title: 'Logout', icon: Icons.logout),

  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryColor, AppColors.secondaryColor],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Animated Grid Menu
              Expanded(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return GridView.builder(
                      padding: const EdgeInsets.all(16.0),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.1,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: _menuItems.length,
                      itemBuilder: (context, index) {
                        // Create a staggered animation effect
                        final delay = index * 0.2;
                        final animation = Tween<double>(
                          begin: 0.0,
                          end: 1.0,
                        ).animate(
                          CurvedAnimation(
                            parent: _controller,
                            curve: Interval(
                              delay.clamp(0.0, 0.8),
                              (delay + 0.2).clamp(0.0, 1.0),
                              curve: Curves.easeOutBack,
                            ),
                          ),
                        );

                        return _buildAnimatedMenuItem(
                          animation,
                          _menuItems[index],
                          index,
                        );
                      },
                    );
                  },
                ),
              ),


            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final headerAnimation = CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
        );

        return Transform.translate(
          offset: Offset(0, -50 * (1 - headerAnimation.value)),
          child: Opacity(
            opacity: headerAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Hero(tag: 'logo', child: _buildLogo())],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final logoAnimation = CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.2, 0.6, curve: Curves.elasticOut),
        );

        return Transform.scale(
          scale: 0.8 + (0.2 * logoAnimation.value),
          child: Transform.rotate(
            angle: math.pi * 2 * logoAnimation.value,
            child: Image.asset('assets/logo.png', width: 70, height: 70),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedMenuItem(
    Animation<double> animation,
    MenuItem item,
    int index,
  ) {
    return ScaleTransition(
      scale: animation,
      child: FadeTransition(
        opacity: animation,
        child: InkWell(
          onTap: () {
            // Use GetX navigation instead of routes
            _handleMenuItemTap(index);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated icon
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final iconAnimation = CurvedAnimation(
                      parent: _controller,
                      curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
                    );

                    return Transform.scale(
                      scale:
                          1.0 + (0.2 * math.sin(iconAnimation.value * math.pi)),
                      child: Icon(item.icon, size: 36, color: Colors.white),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleMenuItemTap(int index) async {
    // Handle tap based on index using GetX navigation
    switch (index) {
      case 0: // Lottery
        Get.to(() => LotteryScreen());
        break;
      case 1: // Cards Play
        final UserController userController = Get.put(UserController());
        if (userController.currentUser.value == null) {
          Get.snackbar(
            'Error',
            'User not logged in',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }

        try {
          // Show loading indicator
          Get.dialog(
            const Center(child: CircularProgressIndicator()),
            barrierDismissible: false,
          );

          // Check if user exists
          final userExists = await ApiService().checkUserExists(
            userController.currentUser.value!.id,
          );

          Get.back(); // Dismiss loading indicator

          if (!userExists) {
            // Logout user if doesn't exist
            userController.clearUser();
            Get.offAll(() => LoginScreen());
            Get.snackbar(
              'Session Expired',
              'Your account no longer exists',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          } else {
            // Proceed to play
            Get.to(
              () => LotteryCardsScreen(),
              transition: Transition.rightToLeft,
            );
          }
        } catch (e) {
          Get.back(); // Dismiss loading indicator
          Get.snackbar(
            'Error',
            'Failed to verify user: $e',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }

        break;
      case 2: // Lottery Sale History
        Get.to(
              () => LotteryHistoryScreen(),
          transition: Transition.rightToLeft,
        );
        break;
      case 3: // Sale Report
        Get.to(() => SalesReportScreen(), transition: Transition.rightToLeft,);
        break;
      case 4: // Result Scanner
        final LotteryController lotteryController = Get.put(LotteryController());
        late final qrScannerService = QRScannerService(
          lotteryController: lotteryController,
        );
        qrScannerService.openQRScanner(context);
        break;
      case 5: // Check Winner
        Get.defaultDialog(
          title: 'Logout',
          middleText: 'Are you sure you want to logout?',
          textConfirm: 'Yes',
          textCancel: 'No',
          confirmTextColor: Colors.white,
          onConfirm: () async {
            Get.back();
            final userController = Get.find<UserController>();
            userController.clearUser();

            Get.snackbar(
              'Logged Out',
              'You have been successfully logged out',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppColors.primaryColor.withOpacity(
                0.8,
              ),
              colorText: Colors.white,
              duration: const Duration(seconds: 2),
            );

            // Navigate to login screen
            Get.offAll(() => LoginScreen());
          },
        );
        break;

    }
  }
}

// Menu item model (simplified - removed route)
class MenuItem {
  final String title;
  final IconData icon;

  MenuItem({required this.title, required this.icon});
}

// Placeholder screen for demonstration
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final Color color;

  const PlaceholderScreen({Key? key, required this.title, required this.color})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: color, elevation: 0),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color, color.withOpacity(0.7)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.construction, size: 80, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Coming Soon',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: color,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
