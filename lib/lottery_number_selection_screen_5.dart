import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'utils/app_colors.dart';
import 'checkout_screen.dart';

class LotteryNumberSelectionScreen extends StatefulWidget {
  final String lotteryName;
  int rowCount;
  final int numbersPerRow;
  final double price;
  final int lotteryId;

  LotteryNumberSelectionScreen({
    super.key,
    required this.lotteryName,
    this.rowCount = 1,
    required this.numbersPerRow,
    required this.price,
    required this.lotteryId,
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
  late Timer _timer;

  List<List<int>> selectedNumbersRows = [];
  int activeRowIndex = 0;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.rowCount; i++) {
      selectedNumbersRows.add([]);
    }
    _startTimer();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (seconds > 0) {
          seconds--;
        } else {
          if (minutes > 0) {
            minutes--;
            seconds = 59;
          } else {
            if (hours > 0) {
              hours--;
              minutes = 59;
              seconds = 59;
            } else {
              if (days > 0) {
                days--;
                hours = 23;
                minutes = 59;
                seconds = 59;
              } else {
                timer.cancel();
              }
            }
          }
        }
      });
    });
  }

  void _selectNumber(int number) {
    setState(() {
      List<int> currentRowNumbers = selectedNumbersRows[activeRowIndex];
      if (currentRowNumbers.contains(number)) {
        currentRowNumbers.remove(number);
      } else {
        if (currentRowNumbers.length < widget.numbersPerRow) {
          currentRowNumbers.add(number);
        }
      }
      selectedNumbersRows[activeRowIndex] = currentRowNumbers;
    });
    _animationController.forward(from: 0.0);
  }

  void _clearSelection() {
    setState(() {
      selectedNumbersRows[activeRowIndex] = [];
    });
  }

  void _clearAllSelections() {
    setState(() {
      for (int i = 0; i < selectedNumbersRows.length; i++) {
        selectedNumbersRows[i] = [];
      }
    });
  }

  void _quickPick() {
    setState(() {
      List<int> availableNumbers = List.generate(25, (index) => index + 1);
      availableNumbers.shuffle();
      selectedNumbersRows[activeRowIndex] =
          availableNumbers.take(widget.numbersPerRow).toList();
    });
    _animationController.forward(from: 0.0);
  }

  void _quickPickAll() {
    setState(() {
      for (int i = 0; i < selectedNumbersRows.length; i++) {
        List<int> availableNumbers = List.generate(25, (index) => index + 1);
        availableNumbers.shuffle();
        selectedNumbersRows[i] =
            availableNumbers.take(widget.numbersPerRow).toList();
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

  void _navigateToCheckout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CheckoutScreen(
              selectedNumbers: selectedNumbersRows,
              price: widget.price * widget.rowCount,
              lotteryId: widget.lotteryId,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildAppBar(),
          _buildLotteryHeader(),
          Expanded(child: _buildNumberSelectionGrid()),
          _buildBottomButtons(),
        ],
      ),
    );
  }

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
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.black87,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTimerBlock(days.toString().padLeft(2, '0'), 'Days'),
                  const SizedBox(width: 4),
                  _buildTimerSeparator(':'),
                  const SizedBox(width: 4),
                  _buildTimerBlock(hours.toString().padLeft(2, '0'), 'Hours'),
                  const SizedBox(width: 4),
                  _buildTimerSeparator(':'),
                  const SizedBox(width: 4),
                  _buildTimerBlock(minutes.toString().padLeft(2, '0'), 'Min'),
                  const SizedBox(width: 4),
                  _buildTimerSeparator(':'),
                  const SizedBox(width: 4),
                  _buildTimerBlock(seconds.toString().padLeft(2, '0'), 'Sec'),
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
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
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

  Widget _buildNumberSelectionGrid() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pick Your Numbers (Row ${activeRowIndex + 1})',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: _clearSelection,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
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
                    vertical: 8,
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
                    vertical: 8,
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
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                childAspectRatio: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 25,
              itemBuilder: (context, index) {
                final number = index + 1;
                final isSelected = selectedNumbersRows[activeRowIndex].contains(
                  number,
                );

                return GestureDetector(
                  onTap: () => _selectNumber(number),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppColors.primaryColor : Colors.white,
                      border: Border.all(
                        color:
                            isSelected
                                ? AppColors.primaryColor
                                : Colors.grey.shade300,
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

  Widget _buildBottomButtons() {
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
              onTap: _areAllRowsComplete() ? _navigateToCheckout : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 50,
                decoration: BoxDecoration(
                  color:
                      _areAllRowsComplete()
                          ? AppColors.primaryColor
                          : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    'NEXT (AED ${(widget.price * widget.rowCount).toInt()})',
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
}
