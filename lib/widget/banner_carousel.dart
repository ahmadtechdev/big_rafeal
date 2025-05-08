import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import '../controllers/lottery_controller.dart';
import '../models/banner_model.dart';
import '../models/lottery_model.dart';

class BannerCarousel extends StatefulWidget {
  final LotteryController lotteryController;
  final int totalLotteries;
  final Lottery activeLottery;

  const BannerCarousel({
    super.key,
    required this.lotteryController,
    required this.totalLotteries,
    required this.activeLottery,
  });

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  late PageController _pageController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    // Fetch banners
    widget.lotteryController.fetchBanners();

    // Start timer after a short delay to allow fetching
    Future.delayed(const Duration(milliseconds: 500), () {
      _startCarousel();
    });
  }

  void _startCarousel() {
    // Cancel existing timer if any
    _timer?.cancel();

    // Start new timer
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      // Get total pages (default banner + API banners)
      final totalItems = 1 + widget.lotteryController.banners.length;
      if (totalItems > 1) {
        // Calculate next page with wrapping
        final nextPage = (_pageController.page!.round() + 1) % totalItems;

        // Animate to next page
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final banners = widget.lotteryController.banners;
      final isLoading = widget.lotteryController.isLoadingBanners.value;

      // Calculate total carousel items (default banner + API banners)
      final totalItems = 1 + banners.length;

      if (isLoading && banners.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: Colors.white));
      }

      return SizedBox(
        height: 180, // Set appropriate height
        child: PageView.builder(
          controller: _pageController,
          itemCount: totalItems,
          itemBuilder: (context, index) {
            // First item is the default banner
            if (index == 0) {
              return _buildDefaultBanner();
            } else {
              // Show API banners
              final banner = banners[index - 1];
              return _buildApiBanner(banner);
            }
          },
        ),
      );
    });
  }

  Widget _buildDefaultBanner() {
    return Column(
      children: [
        // Prize showcase
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            children: [
              // Prize info
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Today\'s Jackpot',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AED',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.activeLottery.highestPrize.toString(),
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 10.0,
                                  color: Colors.black.withOpacity(0.2),
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.totalLotteries} Active Lotteries',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Winner illustration
              Expanded(
                flex: 2,
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(seconds: 1),
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.scale(
                        scale: 0.8 + (0.2 * value),
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.emoji_events,
                              size: 50,
                              color: Colors.amber[300],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApiBanner(BannerModal banner) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        banner.image,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 180,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: const Center(
              child: Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 40,
              ),
            ),
          );
        },
      ),
    );
  }
}