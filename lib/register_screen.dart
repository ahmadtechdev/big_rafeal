import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'api_service/api_service.dart';
import 'utils/app_colors.dart';


class RegisterController extends GetxController {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final apiService = ApiService();

  var isLoading = false.obs;

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

  bool _validateInputs() {
    if (nameController.text.trim().isEmpty) {
      _showErrorSnackbar('Please enter your full name');
      return false;
    }

    if (emailController.text.trim().isEmpty) {
      _showErrorSnackbar('Please enter your email');
      return false;
    }

    if (!GetUtils.isEmail(emailController.text.trim())) {
      _showErrorSnackbar('Please enter a valid email');
      return false;
    }

    if (passwordController.text.isEmpty) {
      _showErrorSnackbar('Please enter a password');
      return false;
    }

    if (passwordController.text.length < 6) {
      _showErrorSnackbar('Password must be at least 6 characters');
      return false;
    }

    if (phoneController.text.trim().isEmpty) {
      _showErrorSnackbar('Please enter your phone number');
      return false;
    }

    return true;
  }

  Future<void> register() async {
    // Validate inputs first
    if (!_validateInputs()) return;

    isLoading.value = true;

    try {
      await apiService.registerUser(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        phone: phoneController.text.trim(),
      );

      isLoading.value = false;

      _showSuccessSnackbar('Registration successful! Please login.');

      // Clear fields
      nameController.clear();
      emailController.clear();
      passwordController.clear();
      phoneController.clear();

      // Navigate back to login screen after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        Get.back();
      });
    } catch (e) {
      isLoading.value = false;
      _showErrorSnackbar(e.toString());
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final RegisterController controller = Get.put(RegisterController());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Register',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryColor,
              AppColors.secondaryColor,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'UWIN',
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Name field
                  TextField(
                    controller: controller.nameController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.inputFieldBackground,
                      hintText: 'Full Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.person, color: AppColors.primaryColor),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),
                  // Email field
                  TextField(
                    controller: controller.emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.inputFieldBackground,
                      hintText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.email, color: AppColors.primaryColor),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),
                  // Password field
                  TextField(
                    controller: controller.passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.inputFieldBackground,
                      hintText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.lock, color: AppColors.primaryColor),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),
                  // Phone field
                  TextField(
                    controller: controller.phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.inputFieldBackground,
                      hintText: 'Phone Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.phone, color: AppColors.primaryColor),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => controller.register(),
                  ),
                  const SizedBox(height: 30),

                  // Register button
                  Obx(() => GestureDetector(
                    onTap: controller.isLoading.value ? null : controller.register,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: controller.isLoading.value
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          'Register',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )),
                  const SizedBox(height: 20),
                  // Login option
                  TextButton(
                    onPressed: () {
                      Get.back();
                    },
                    child: const Text(
                      'Already have an account? Login',
                      style: TextStyle(
                        color: Colors.white,
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
    );
  }
}