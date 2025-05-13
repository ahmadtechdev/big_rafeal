// Create a new file lottery_sale_controller.dart
import 'package:get/get.dart';
import '../api_service/api_service.dart';
import '../models/user_lottery_modal.dart';

class LotterySaleController extends GetxController {
  final ApiService _apiService = ApiService();
  final RxList<UserLottery> tickets = <UserLottery>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  Future<void> loadTickets(int userId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final result = await _apiService.fetchUserTickets(userId);
      tickets.assignAll(result);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}