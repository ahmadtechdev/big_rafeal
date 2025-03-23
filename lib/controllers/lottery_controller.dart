// controllers/lottery_controller.dart
import 'package:get/get.dart';
import '../api_service/api_service.dart';
import '../models/lottery_model.dart';


class LotteryController extends GetxController {
  var lotteries = <Lottery>[].obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs;

  final ApiService _apiService = ApiService();

  // Filter lotteries by number_lottery
  List<Lottery> getLotteriesByNumberLottery(String numberLottery) {
    return lotteries.where((lottery) => lottery.numberLottery.toString() == numberLottery).toList();
  }

  @override
  void onInit() {
    fetchLotteries();
    super.onInit();
  }

  Future<void> fetchLotteries() async {
    try {
      isLoading(true);
      errorMessage('');

      final result = await _apiService.fetchLotteries();
      lotteries.value = result;

      print('Successfully loaded ${lotteries.length} lotteries');
    } catch (e) {
      errorMessage('$e');
      print('Error fetching lotteries: $e');
    } finally {
      isLoading(false);
    }
  }

  // Refresh lottery data
  void refreshLotteries() {
    fetchLotteries();
  }
}