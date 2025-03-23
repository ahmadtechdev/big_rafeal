import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'api_service/api_service.dart';
import 'controllers/user_controller.dart';
import 'utils/app_colors.dart';
import 'lottery_screen_3.dart';

// controllers/login_controller.dart
import '../models/user_model.dart';


class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final apiService = ApiService();

  // Get the user controller
  final UserController userController = Get.find<UserController>();

  var isLoading = false.obs;
  var isPasswordVisible = false.obs;

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade800,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 10,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }

  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade800,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 10,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
    );
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  bool _validateInputs() {
    if (emailController.text
        .trim()
        .isEmpty) {
      _showErrorSnackbar('Please enter your email');
      return false;
    }

    if (!GetUtils.isEmail(emailController.text.trim())) {
      _showErrorSnackbar('Please enter a valid email');
      return false;
    }

    if (passwordController.text.isEmpty) {
      _showErrorSnackbar('Please enter your password');
      return false;
    }

    return true;
  }

  Future<void> login() async {
    // Validate inputs first
    if (!_validateInputs()) return;

    isLoading.value = true;

    try {
      final response = await apiService.loginUser(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // Handle the successful login response
      if (response['success'] == true) {
        // Parse and save user data
        final userData = response['user'];
        final user = User.fromJson(userData);

        // Save user in the user controller with 30-day expiration (default)
        userController.setUser(user);

        _showSuccessSnackbar('Login successful!');

        // Clear text fields
        emailController.clear();
        passwordController.clear();

        // Navigate to the lottery screen after a short delay to show the success message
        Future.delayed(const Duration(milliseconds: 500), () {
          Get.offAll(() => LotteryScreen(), transition: Transition.fadeIn);
        });
      } else {
        // Handle unsuccessful login
        _showErrorSnackbar(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      _showErrorSnackbar(e.toString());
    } finally {
      isLoading.value = false;
    }

    @override
    void onClose() {
      emailController.dispose();
      passwordController.dispose();
      super.onClose();
    }
  }
}
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginController controller = Get.put(LoginController());
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Stack(
          children: [
            // Top curved background
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: size.height * 0.3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryColor,
                      AppColors.secondaryColor,
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Get.back(),
                        ),
                        SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text(
                            'Welcome Back',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text(
                            'Sign in to continue',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Main content
            Positioned(
              top: size.height * 0.22,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Email field with animation
                      TweenAnimationBuilder(
                        duration: const Duration(milliseconds: 600),
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, double value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, (1 - value) * 20),
                              child: child,
                            ),
                          );
                        },
                        child: TextField(
                          controller: controller.emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.inputFieldBackground,
                            hintText: 'Email',
                            hintStyle: TextStyle(color: Colors.grey.shade600),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.transparent),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
                            ),
                            prefixIcon: Icon(Icons.email_outlined, color: AppColors.primaryColor),
                            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Password field with animation
                      TweenAnimationBuilder(
                        duration: const Duration(milliseconds: 800),
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, double value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, (1 - value) * 20),
                              child: child,
                            ),
                          );
                        },
                        child: Obx(() => TextField(
                          controller: controller.passwordController,
                          obscureText: !controller.isPasswordVisible.value,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.inputFieldBackground,
                            hintText: 'Password',
                            hintStyle: TextStyle(color: Colors.grey.shade600),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.transparent),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
                            ),
                            prefixIcon: Icon(Icons.lock_outline, color: AppColors.primaryColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                controller.isPasswordVisible.value ? Icons.visibility_off : Icons.visibility,
                                color: AppColors.textGrey,
                              ),
                              onPressed: controller.togglePasswordVisibility,
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          ),
                          onSubmitted: (_) => controller.login(),
                        )),
                      ),

                      // Forgot password link
                      // Align(
                      //   alignment: Alignment.centerRight,
                      //   child: TextButton(
                      //     onPressed: () {
                      //       // Forgot password action
                      //     },
                      //     child: Text(
                      //       'Forgot Password?',
                      //       style: TextStyle(
                      //         color: AppColors.primaryColor,
                      //         fontWeight: FontWeight.w500,
                      //       ),
                      //     ),
                      //   ),
                      // ),

                      const SizedBox(height: 30),

                      // Login button with animation
                      TweenAnimationBuilder(
                        duration: const Duration(milliseconds: 1000),
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, double value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, (1 - value) * 20),
                              child: child,
                            ),
                          );
                        },
                        child: Obx(() => ElevatedButton(
                          onPressed: controller.isLoading.value ? null : controller.login,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white, backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: Center(
                                child: controller.isLoading.value
                                    ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                                    : Text(
                                  'Sign In',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )),
                      ),

                      const SizedBox(height: 30),

                      // Register option
                      // TweenAnimationBuilder(
                      //   duration: const Duration(milliseconds: 1200),
                      //   tween: Tween<double>(begin: 0, end: 1),
                      //   builder: (context, double value, child) {
                      //     return Opacity(
                      //       opacity: value,
                      //       child: child,
                      //     );
                      //   },
                      //   child: Row(
                      //     mainAxisAlignment: MainAxisAlignment.center,
                      //     children: [
                      //       Text(
                      //         'Contact the to get your Credentials ',
                      //         style: TextStyle(
                      //           color: AppColors.textGrey,
                      //           fontSize: 16,
                      //         ),
                      //       ),
                      //       // TextButton(
                      //       //   onPressed: () {
                      //       //     // Get.to(() => const RegisterScreen(), transition: Transition.rightToLeft);
                      //       //   },
                      //       //   child: Text(
                      //       //     'Credentials',
                      //       //     style: TextStyle(
                      //       //       color: AppColors.primaryColor,
                      //       //       fontSize: 16,
                      //       //       fontWeight: FontWeight.bold,
                      //       //     ),
                      //       //   ),
                      //       // ),
                      //     ],
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}