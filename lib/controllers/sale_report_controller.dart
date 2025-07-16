// In sale_report_controller.dart
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../api_service/api_service.dart';
import '../controllers/user_controller.dart';
import '../models/user_lottery_modal.dart';

class SalesReportController extends GetxController {
  final ApiService _apiService = ApiService();
  final UserController _userController = Get.find();

  // Observable variables
  // final startDate = DateTime.now().subtract(const Duration(days: 10)).obs;
  // final endDate = DateTime.now().obs;
  final startDate = DateTime.now().obs;
  final endDate = DateTime.now().add(const Duration(days: 1)).obs;
  final totalSales = 0.0.obs;
  final totalWinnings = 0.0.obs;
  final userCommission = 0.0.obs;
  final payableToAdmin = 0.0.obs;
  final isLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final RxList<UserLottery> filteredLotteries = <UserLottery>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadReport();
  }

  Future<void> loadReport() async {
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    final userId = _userController.currentUser.value?.id ?? 0;
    if (userId <= 0) {
      hasError.value = true;
      errorMessage.value = 'User not logged in';
      isLoading.value = false;
      return;
    }

    try {
      // Format dates for API
      final fromDate = DateFormat('yyyy-MM-dd').format(startDate.value);
      final toDate = DateFormat('yyyy-MM-dd').format(endDate.value);

      final response = await _apiService.fetchSalesReport(
        userId: userId,
        fromDate: fromDate,
        toDate: toDate,
      );

      if (response['success'] == true) {
        final data = response['data'];
        _updateFromResponse(data);
      } else {
        throw response['message'] ?? 'Failed to load report';
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void _updateFromResponse(Map<String, dynamic> data) {
    // Update totals
    totalSales.value = (data['total_sales'] as num).toDouble();
    totalWinnings.value = (data['total_winnings'] as num).toDouble();
    userCommission.value = (data['user_commission'] as num).toDouble();
    payableToAdmin.value = (data['paid_to_admin'] as num).toDouble();

    // Update tickets list
    filteredLotteries.clear();
    final tickets = data['tickets'] as List;
    filteredLotteries.addAll(
      tickets.map((ticket) => UserLottery.fromJson(ticket)).toList(),
    );
  }

  // Helper method to format date for display
  String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }
}