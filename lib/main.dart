import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'controllers/lottery_result_controller.dart';
import 'controllers/user_controller.dart';
import 'home_screen_1.dart';
import 'lottery_screen_3.dart';
import 'utils/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize GetStorage
  await GetStorage.init();

  // Put UserController in memory
  Get.put(UserController(), permanent: true);
  Get.put(LotteryResultController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final UserController userController = Get.find<UserController>();

    return GetMaterialApp(
      title: 'Big Rereal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: AppColors.backgroundColor,
      ),
        home: Obx(() => userController.isLoggedIn
            ? LotteryScreen() // If user is logged in, go directly to lottery screen
            : const HomeScreen()),
    );
  }
}