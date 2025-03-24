import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:async';
import 'controllers/lottery_controller.dart';
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
  final MobileScannerController scannerController = MobileScannerController();
  final LotteryController lotteryController = Get.put(LotteryController());

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
                child:IconButton(
                  icon: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppColors.textDark,
                    size: 22,
                  ),
                  onPressed: () => _openQRScanner(context),
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

  void _openQRScanner(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_scanner, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text(
                      'Scan Your Ticket',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        scannerController.stop();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: MobileScanner(
                  controller: scannerController,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                      // Close the scanner
                      scannerController.stop();
                      Navigator.pop(context);

                      // Process the scanned QR code
                      _processQRCode(context, barcodes.first.rawValue!);
                    }
                  },
                  // overlayBuilder: CustomPaint(
                  //   painter: ScannerOverlayPainter(
                  //     borderColor: AppColors.primaryColor,
                  //     borderRadius: 10,
                  //     borderLength: 30,
                  //     borderWidth: 10,
                  //     cutOutSize: MediaQuery.of(context).size.width * 0.7,
                  //   ),
                  // ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                child: Text(
                  'Position the QR code inside the box to check your ticket',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      // Make sure scanner is stopped when bottom sheet is closed
      scannerController.stop();
    });
  }

  void _processQRCode(BuildContext context, String qrData) {
    try {
      // Parse QR data in format "lotteryId_BIGR{lotteryCode}"
      final parts = qrData.split('_');
      if (parts.length != 2) {
        throw Exception('Invalid QR code format');
      }

      final lotteryId = int.parse(parts[0]);
      final ticketId = parts[1];

      // Find the lottery by ID
      final lottery = lotteryController.lotteries.firstWhere(
            (l) => l.id == lotteryId,
        orElse: () => throw Exception('Lottery not found'),
      );

      // In a real app, you would check with the backend if the ticket is a winner
      // For this example, we'll generate a random result
      final bool isWinner = DateTime.now().millisecondsSinceEpoch % 2 == 0;

      // Show result dialog with animation
      _showResultDialog(context, isWinner, lottery);
    } catch (e) {
      print('Error processing QR code: $e');
      _showErrorDialog(context, 'Invalid Ticket', 'The scanned ticket is invalid or expired.');
    }
  }

  void _showResultDialog(BuildContext context, bool isWinner, dynamic lottery) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Simple animation instead of Lottie
                SizedBox(
                  height: 150,
                  width: 150,
                  child: isWinner
                      ? _buildWinnerAnimation()
                      : _buildTryAgainAnimation(),
                ),
                const SizedBox(height: 20),
                // Result text
                Text(
                  isWinner ? 'CONGRATULATIONS!' : 'BETTER LUCK NEXT TIME!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isWinner ? Colors.green[600] : Colors.red[600],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isWinner
                      ? 'You won AED ${lottery.winningPrice}!'
                      : 'Don\'t give up! Try again for a chance to win big!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 24),
                // Close button
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    isWinner ? 'CLAIM PRIZE' : 'TRY AGAIN',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Simple winner animation using built-in Flutter animations
  Widget _buildWinnerAnimation() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Trophy icon
            Icon(
              Icons.emoji_events,
              size: 80,
              color: Colors.amber[600],
            ),
            // Animated circles around trophy
            ...List.generate(8, (index) {
              final angle = index * (2 * 3.14159 / 8);
              return Positioned(
                left: 75 + math.cos(angle) * 50 * value,
                top: 75 + math.sin(angle) * 50 * value,
                child: Opacity(
                  opacity: value,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.amber[300],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
            // Star animation
            AnimatedBuilder(
              animation: AnimationController(
                duration: const Duration(milliseconds: 1500),
                vsync: const _TickerProviderImpl(),
              )..repeat(),
              builder: (context, child) {
                return Transform.rotate(
                  angle: value * 2 * 3.14159,
                  child: Icon(
                    Icons.star,
                    size: 120 * value,
                    color: Colors.amber.withOpacity(0.3),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Simple try again animation using built-in Flutter animations
  Widget _buildTryAgainAnimation() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Rotating circle
            Transform.rotate(
              angle: value * 2 * 3.14159,
              child: CircularProgressIndicator(
                value: value,
                color: Colors.red[300],
                strokeWidth: 8,
              ),
            ),
            // Sad face icon
            Icon(
              Icons.sentiment_dissatisfied,
              size: 80,
              color: Colors.red[600],
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

}

// Custom overlay painter for the scanner
class ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  ScannerOverlayPainter({
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
    required this.borderLength,
    required this.cutOutSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: cutOutSize,
      height: cutOutSize,
    );

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          scanArea,
          Radius.circular(borderRadius),
        ),
      );

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Draw background with hole
    canvas.drawPath(
      Path.combine(PathOperation.difference, backgroundPath, cutoutPath),
      backgroundPaint,
    );

    // Draw corners
    final cornerSize = borderLength;

    // Top left corner
    canvas.drawPath(
      Path()
        ..moveTo(scanArea.left, scanArea.top + borderRadius)
        ..lineTo(scanArea.left, scanArea.top)
        ..lineTo(scanArea.left + cornerSize, scanArea.top),
      borderPaint,
    );

    // Top right corner
    canvas.drawPath(
      Path()
        ..moveTo(scanArea.right - cornerSize, scanArea.top)
        ..lineTo(scanArea.right, scanArea.top)
        ..lineTo(scanArea.right, scanArea.top + cornerSize),
      borderPaint,
    );

    // Bottom right corner
    canvas.drawPath(
      Path()
        ..moveTo(scanArea.right, scanArea.bottom - cornerSize)
        ..lineTo(scanArea.right, scanArea.bottom)
        ..lineTo(scanArea.right - cornerSize, scanArea.bottom),
      borderPaint,
    );

    // Bottom left corner
    canvas.drawPath(
      Path()
        ..moveTo(scanArea.left + cornerSize, scanArea.bottom)
        ..lineTo(scanArea.left, scanArea.bottom)
        ..lineTo(scanArea.left, scanArea.bottom - cornerSize),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(ScannerOverlayPainter oldDelegate) => false;
}

// Helper class for animations
class _TickerProviderImpl extends TickerProvider {
  const _TickerProviderImpl();

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

// Extension to add missing functions
extension MathFunctions on num {
  double cos(double angle) => math.cos(angle);
  double sin(double angle) => math.sin(angle);
}
