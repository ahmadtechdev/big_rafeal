// controllers/lottery_controller.dart
import 'dart:async';

import 'package:get/get.dart';
import '../api_service/api_service.dart';
import '../models/banner_model.dart';
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

  // Add these properties to your LotteryController class
  final RxList<BannerModal> banners = <BannerModal>[].obs;
  final RxBool isLoadingBanners = false.obs;
  final RxString bannerErrorMessage = ''.obs;
  final RxInt currentBannerIndex = 0.obs;

// Add this method to your LotteryController class
  Future<void> fetchBanners() async {
    try {
      isLoadingBanners.value = true;
      bannerErrorMessage.value = '';

      final ApiService apiService = ApiService();
      final fetchedBanners = await apiService.fetchBanners();

      banners.value = fetchedBanners;
      isLoadingBanners.value = false;
    } catch (e) {
      bannerErrorMessage.value = e.toString();
      isLoadingBanners.value = false;
    }
  }

// Add this method to your LotteryController class
  void startBannerCarousel() {
    // Reset to first banner
    currentBannerIndex.value = 0;

    // Start timer to cycle through banners every 4 seconds
    Timer.periodic(const Duration(seconds: 4), (timer) {
      // If there are banners from the API
      if (banners.isNotEmpty) {
        // Calculate next index. If at end, go back to start (showing current banner)
        currentBannerIndex.value = (currentBannerIndex.value + 1) % (banners.length + 1);
      }
    });
  }

  Future<void> fetchLotteries() async {
    try {
      isLoading(true);
      // print(result);
      final result = await _apiService.fetchLotteries();
      lotteries.value = result;

    } catch (e) {
      errorMessage('$e');
    } finally {
      isLoading(false);
    }
  }


  // Refresh lottery data
  void refreshLotteries() {
    fetchLotteries();
  }
}