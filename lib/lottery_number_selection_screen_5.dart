
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery_app/widget/qr_scanner_service.dart';
import 'dart:async';
import 'controllers/lottery_controller.dart';
import 'utils/app_colors.dart';
import 'checkout_screen.dart';

// ignore: must_be_immutable
class LotteryNumberSelectionScreen extends StatefulWidget {
  final String lotteryName;
  int rowCount;
  final int numbersPerRow;
  final double price;
  final int lotteryId;
  final String endDate;
  final int maxNumber;
  String? announcedResult;
  final Map<String, String> sequenceRewards;
  final Map<String, String> rumbleRewards;
  final Map<String, String> chanceRewards;
  final String lotteryCategory;

  LotteryNumberSelectionScreen({
    super.key,
    required this.lotteryName,
    this.rowCount = 1,
    required this.numbersPerRow,
    required this.price,
    required this.lotteryId,
    required this.endDate,
    required this.maxNumber,
    this.announcedResult = "0",
    required this.sequenceRewards,
    required this.rumbleRewards,
    required this.chanceRewards,
    required this.lotteryCategory,
  });

  @override
  State<LotteryNumberSelectionScreen> createState() =>
      _LotteryNumberSelectionScreenState();
}

class _LotteryNumberSelectionScreenState
    extends State<LotteryNumberSelectionScreen>
    with SingleTickerProviderStateMixin {
  int days = 0;
  int hours = 0;
  int minutes = 7;
  int seconds = 27;
  Timer? _timer;
  late DateTime endDateTime;
  Duration timeLeft = Duration.zero;

  List<List<int>> selectedNumbersRows = [];
  int activeRowIndex = 0;
  // Add these new variables for category selection
  bool sequenceSelected = false;
  bool rumbleSelected = false;
  bool chanceSelected = false;

  // Calculate combination code based on selected categories
  int get combinationCode {
    // If all available categories are selected, return the combined code
    if (sequenceSelected && rumbleSelected && chanceSelected &&
        isCategoryAvailable(6)) {
      return 6;
    }
    if (sequenceSelected && rumbleSelected && isCategoryAvailable(2)) return 2;
    if (sequenceSelected && chanceSelected && isCategoryAvailable(4)) return 4;
    if (rumbleSelected && chanceSelected && isCategoryAvailable(5)) return 5;
    if (sequenceSelected && isCategoryAvailable(0)) return 0;
    if (rumbleSelected && isCategoryAvailable(1)) return 1;
    if (chanceSelected && isCategoryAvailable(3)) return 3;

    // Default to first available category
    return availableCombinationCodes.first;
  }

  // Add this method to determine available categories
  List<int> get availableCombinationCodes {
    switch (widget.lotteryCategory) {
      case '0': // Standard - only sequence
        return [0];
      case '1': // Rumble - only sequence
        return [1];
      case '2': // Sequence + Rumble
        return [0, 1, 2];
      case '3': // Chance only
        return [3];
      case '4': // Sequence + Chance
        return [0, 3, 4];
      case '5': // Rumble + Chance
        return [1, 3, 5];
      case '6': // All types
        return [0, 1, 2, 3, 4, 5, 6];
      default:
        return [0]; // Default to sequence only
    }
  }

  // Helper to check if a category is available
  bool isCategoryAvailable(int code) {
    return availableCombinationCodes.contains(code);
  }



  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.rowCount; i++) {
      selectedNumbersRows.add([]);
    }

    // Parse the end date with format handling
    endDateTime = _parseDate(widget.endDate);

    // Initialize timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimeLeft();
    });

    // Calculate initial time
    _updateTimeLeft();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  // Helper method to parse both date formats
  DateTime _parseDate(String dateString) {

    try {
      // First try parsing as ISO format (with T)
      return DateTime.parse(dateString);
    } catch (e) {
      try {
        // If that fails, try replacing space with T for SQL-style format
        if (dateString.contains(' ')) {
          return DateTime.parse(dateString.replaceFirst(' ', 'T'));
        }
        // If neither works, fallback to current time + 1 day
        return DateTime.now().add(const Duration(days: 1));
      } catch (e) {
        // Ultimate fallback
        return DateTime.now().add(const Duration(days: 1));
      }
    }
  }

  void _updateTimeLeft() {
    final now = DateTime.now();
    if (now.isAfter(endDateTime)) {
      timeLeft = Duration.zero;
      _timer?.cancel();
      if (mounted) setState(() {});
    } else {
      timeLeft = endDateTime.difference(now);
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _selectNumber(int number) {
    setState(() {
      List<int> currentRowNumbers = selectedNumbersRows[activeRowIndex];
      if (currentRowNumbers.length < widget.numbersPerRow) {
        currentRowNumbers.add(number);
      }
      selectedNumbersRows[activeRowIndex] = currentRowNumbers;
    });
    _animationController.forward(from: 0.0);
  }

  void _clearSelection() {
    setState(() {
      if (selectedNumbersRows[activeRowIndex].isNotEmpty) {
        selectedNumbersRows[activeRowIndex].removeLast();
      }
    });
  }


  void _quickPick() {
    setState(() {
      final startNumber = widget.maxNumber < 10 ? 0 : 1;
      List<int> availableNumbers = List.generate(widget.maxNumber, (index) => index + startNumber);
      availableNumbers.shuffle();
      selectedNumbersRows[activeRowIndex] = availableNumbers.take(widget.numbersPerRow).toList();
    });
    _animationController.forward(from: 0.0);
  }

  void _quickPickAll() {
    setState(() {
      final startNumber = widget.maxNumber < 10 ? 0 : 1;
      for (int i = 0; i < selectedNumbersRows.length; i++) {
        List<int> availableNumbers = List.generate(widget.maxNumber, (index) => index + startNumber);
        availableNumbers.shuffle();
        selectedNumbersRows[i] = availableNumbers.take(widget.numbersPerRow).toList();
      }
    });
    _animationController.forward(from: 0.0);
  }

  void _increaseRowCount() {
    setState(() {
      if (widget.rowCount < 10) {
        widget.rowCount++;
        selectedNumbersRows.add([]);
      }
    });
  }

  void _decreaseRowCount() {
    setState(() {
      if (widget.rowCount > 1) {
        widget.rowCount--;
        selectedNumbersRows.removeLast();
        if (activeRowIndex >= selectedNumbersRows.length) {
          activeRowIndex = selectedNumbersRows.length - 1;
        }
      }
    });
  }

  void _setActiveRow(int index) {
    setState(() {
      activeRowIndex = index;
    });
    _animationController.forward(from: 0.0);
  }

  bool _isRowComplete(int rowIndex) {
    return selectedNumbersRows[rowIndex].length == widget.numbersPerRow;
  }

  bool _areAllRowsComplete() {
    for (int i = 0; i < selectedNumbersRows.length; i++) {
      if (selectedNumbersRows[i].length != widget.numbersPerRow) {
        return false;
      }
    }
    return true;
  }

  final LotteryController lotteryController = Get.put(LotteryController());

  late final qrScannerService = QRScannerService(lotteryController: lotteryController);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildAppBar(),
          _buildLotteryHeader(),
          _buildCategorySelection(),
          Expanded(child: _buildNumberSelectionGrid()),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  // Add this new method to build category selection UI
// Helper method to get combination name

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  Get.back();
                },
                child: const Icon(Icons.arrow_back, color: Colors.black87),
              ),
              SizedBox(
                height: 40,
                width: 100,
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Center(
                        child: Text(
                          'Big Rafeal',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child:IconButton(
                  icon: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppColors.textDark,
                    size: 22,
                  ),
                  // Update this line to use the service
                  onPressed: () => qrScannerService.openQRScanner(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Update the timer display in _buildAppBar()
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTimerBlock(timeLeft.inDays.toString().padLeft(2, '0'), 'Days'),
                  const SizedBox(width: 4),
                  _buildTimerSeparator(':'),
                  const SizedBox(width: 4),
                  _buildTimerBlock((timeLeft.inHours % 24).toString().padLeft(2, '0'), 'Hrs'),
                  const SizedBox(width: 4),
                  _buildTimerSeparator(':'),
                  const SizedBox(width: 4),
                  _buildTimerBlock((timeLeft.inMinutes % 60).toString().padLeft(2, '0'), 'Min'),
                  const SizedBox(width: 4),
                  _buildTimerSeparator(':'),
                  const SizedBox(width: 4),
                  _buildTimerBlock((timeLeft.inSeconds % 60).toString().padLeft(2, '0'), 'Sec'),
                ],
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  'Price: AED ${(widget.price * widget.rowCount).toInt()}',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBlock(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: timeLeft.inSeconds <= 3600 ? Colors.red : Colors.black87,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSeparator(String separator) {
    return Text(
      separator,
      style: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    );
  }

  Widget _buildLotteryHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppColors.primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.lotteryName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: _decreaseRowCount,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.remove,
                            color: Colors.black87,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      color: Colors.white,
                      child: Center(
                        child: Text(
                          '${widget.rowCount}',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _increaseRowCount,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.add,
                            color: Colors.black87,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.rowCount,
              itemBuilder: (context, index) {
                final isActive = index == activeRowIndex;
                final isComplete = _isRowComplete(index);

                return GestureDetector(
                  onTap: () => _setActiveRow(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 60,
                    margin: EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color:
                            isComplete
                                ? Colors.green
                                : isActive
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Row ${index + 1}',
                            style: TextStyle(
                              color:
                                  isActive
                                      ? AppColors.primaryColor
                                      : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          if (isComplete)
                            Icon(
                              Icons.check_circle,
                              color: isActive ? Colors.green : Colors.white,
                              size: 14,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < widget.numbersPerRow; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 38,
                      height: 40,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Center(
                        child:
                            i < selectedNumbersRows[activeRowIndex].length
                                ? Text(
                                  selectedNumbersRows[activeRowIndex][i]
                                      .toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.primaryColor,
                                  ),
                                )
                                : null,
                      ),
                    ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _clearSelection,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Icon(Icons.close, color: Colors.red, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _quickPick,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.refresh,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

// Updated _buildCategorySelection method for horizontal scrolling and compact design
  Widget _buildCategorySelection() {
    final canSelectSequence = isCategoryAvailable(0);
    final canSelectRumble = isCategoryAvailable(1);
    final canSelectChance = isCategoryAvailable(3);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      height: 60,
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Play Type:',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'AED ${totalPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (canSelectSequence)
                  _buildSelectionOption(
                    'Straight',
                    sequenceSelected,
                        (value) {
                      setState(() {
                        sequenceSelected = value;
                        // Ensure at least one category is selected
                        if (!sequenceSelected && !rumbleSelected && !chanceSelected) {
                          sequenceSelected = true;
                        }
                      });
                    },
                  ),
                if (canSelectSequence && canSelectRumble) const SizedBox(width: 8),
                if (canSelectRumble)
                  _buildSelectionOption(
                    'Rumble',
                    rumbleSelected,
                        (value) {
                      setState(() {
                        rumbleSelected = value;
                        if (!sequenceSelected && !rumbleSelected && !chanceSelected) {
                          // Default to first available category
                          if (canSelectSequence) {
                            sequenceSelected = true;
                          } else if (canSelectRumble) {
                            rumbleSelected = true;
                          } else if (canSelectChance) {
                            chanceSelected = true;
                          }
                        }
                      });
                    },
                  ),
                if ((canSelectSequence || canSelectRumble) && canSelectChance)
                  const SizedBox(width: 8),
                if (canSelectChance)
                  _buildSelectionOption(
                    'Chance',
                    chanceSelected,
                        (value) {
                      setState(() {
                        chanceSelected = value;
                        if (!sequenceSelected && !rumbleSelected && !chanceSelected) {
                          // Default to first available category
                          if (canSelectSequence) {
                            sequenceSelected = true;
                          } else if (canSelectRumble) {
                            rumbleSelected = true;
                          } else if (canSelectChance) {
                            chanceSelected = true;
                          }
                        }
                      });
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
// Updated _buildSelectionOption to be more compact
  Widget _buildSelectionOption(String title, bool isSelected, Function(bool) onChanged) {
    return InkWell(
      onTap: () => onChanged(!isSelected),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppColors.primaryColor.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: isSelected ? AppColors.primaryColor : Colors.black87,
              ),
            ),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primaryColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primaryColor : Colors.grey,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(
                Icons.check,
                size: 10,
                color: Colors.white,
              )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

// Updated _buildNumberSelectionGrid to maximize space for number picking
  Widget _buildNumberSelectionGrid() {
    final startNumber = widget.maxNumber < 10 ? 0 : 1;
    final itemCount = widget.maxNumber < 10 ? widget.maxNumber + 1 : widget.maxNumber;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pick Your Numbers (Row ${activeRowIndex + 1})',
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (sequenceSelected || rumbleSelected || chanceSelected)
                Text(
                  'Combo: ${_getCombinationName(combinationCode)}',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: _clearSelection,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _quickPick,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Quick Pick',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _quickPickAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Quick All',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                childAspectRatio: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                final number = index + startNumber;
                final isSelected = selectedNumbersRows[activeRowIndex].contains(number);

                return GestureDetector(
                  onTap: () => _selectNumber(number),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppColors.primaryColor : Colors.white,
                      border: Border.all(
                        color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        number.toString(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
    );
  }

// Updated _navigateToCheckout method to enforce category selection
  void _navigateToCheckout() {
    if (DateTime.now().isAfter(endDateTime)) {
      Get.snackbar(
        'Lottery Expired',
        'This lottery draw has ended and cannot be played',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (!_areAllRowsComplete()) {
      Get.snackbar(
        'Incomplete Selection',
        'Please complete all number selections',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

// Check if at least one available category is selected
    if (!sequenceSelected && !rumbleSelected && !chanceSelected) {
      Get.snackbar(
        'Category Required',
        'Please select at least one play type',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      // Default to first available category
      setState(() {
        if (isCategoryAvailable(0)) {
          sequenceSelected = true;
        } else if (isCategoryAvailable(1)) {
          rumbleSelected = true;
        } else if (isCategoryAvailable(3)) {
          chanceSelected = true;
        }
      });
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          selectedNumbers: selectedNumbersRows,
          price: totalPrice, // Use the calculated total price
          lotteryId: widget.lotteryId,
          combinationCode: combinationCode,
          sequence: sequenceSelected,
          chance: chanceSelected,
          rumble: rumbleSelected,

        ),
      ),
    );
  }

// Updated _buildBottomButtons to show the calculated price with all selections
  Widget _buildBottomButtons() {
    final bool isExpired = widget.announcedResult == '1';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${widget.rowCount}",
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Text(
                    "Rows",
                    style: TextStyle(color: Colors.black87, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: isExpired
                  ? null
                  : _areAllRowsComplete()
                  ? _navigateToCheckout
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 50,
                decoration: BoxDecoration(
                  color: DateTime.now().isAfter(endDateTime)
                      ? Colors.grey
                      : _areAllRowsComplete()
                      ? AppColors.primaryColor
                      : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    isExpired
                        ? 'LOTTERY EXPIRED'
                        : 'NEXT (AED ${totalPrice.toStringAsFixed(0)})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

// Updated getter for totalPrice to include all selected categories
  double get totalPrice {
    // For lotteries with numberLottery > 5, price doesn't increase with category selection
    if (widget.numbersPerRow > 5) {
      return widget.price ;
    } else {
      // Original pricing logic for lotteries with numberLottery <= 5
      int selectedCategoryCount = 0;
      if (sequenceSelected && isCategoryAvailable(0)) selectedCategoryCount++;
      if (rumbleSelected && isCategoryAvailable(1)) selectedCategoryCount++;
      if (chanceSelected && isCategoryAvailable(3)) selectedCategoryCount++;

      // Ensure at least one available category is selected
      if (selectedCategoryCount == 0) {
        if (isCategoryAvailable(0)) {
          sequenceSelected = true;
          selectedCategoryCount = 1;
        } else if (isCategoryAvailable(1)) {
          rumbleSelected = true;
          selectedCategoryCount = 1;
        } else if (isCategoryAvailable(3)) {
          chanceSelected = true;
          selectedCategoryCount = 1;
        }
      }

      return widget.price * selectedCategoryCount;
    }
  }
// Helper method to get simplified combination name
  String _getCombinationName(int code) {
    switch (code) {
      case 0: return 'Sequence';
      case 1: return 'Rumble';
      case 2: return 'Seq+Rum';
      case 3: return 'Chance';
      case 4: return 'Seq+Cha';
      case 5: return 'Rum+Cha';
      case 6: return 'All Types';
      default: return 'Custom';
    }
  }

}
