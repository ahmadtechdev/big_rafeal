import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'lottery_screen_3.dart';
import 'utils/app_colors.dart';

class TicketDetailsScreen extends StatefulWidget {
  final List<List<int>> selectedNumbersRows;
  final double price;
  final String ticketId;
  final String verificationCode;
  final String purchaseDateTime;
  final String product;

  const TicketDetailsScreen({
    super.key,
    required this.selectedNumbersRows,
    required this.price,
    required this.ticketId,
    required this.verificationCode,
    required this.purchaseDateTime,
    required this.product,
  });

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  late PageController _rowPageController;
  int _currentRowIndex = 0;

  @override
  void initState() {
    super.initState();
    _rowPageController = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _rowPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          _buildAppBar(context),
          _buildTicketTitle(),
          Expanded(
            child: SingleChildScrollView(
              child: _buildTicketInfo(),
            ),
          ),
          _buildBackButton(context),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 12),
      color: AppColors.cardColor,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.primaryColor),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          SizedBox(
            height: 40,
            width: 100,
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.cardColor,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColors.primaryColor),
                  ),
                  child: Text(
                    'BR',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
          ),
          const Spacer(),
          // Empty space to balance the back button
          SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTicketTitle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'MY TICKET',
          style: TextStyle(
            color: AppColors.textLight,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildTicketInfo() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo (centered at the top of the ticket)
          Center(
            child: Container(
              height: 50,
              width: 120,
              margin: const EdgeInsets.only(top: 24, bottom: 20),
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.cardColor,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: AppColors.primaryColor),
                    ),
                    child: Text(
                      'BR',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Ticket info items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildInfoRow('Verification Code', widget.verificationCode),
                const Divider(height: 24, color: AppColors.dividerColor, thickness: 1),
                _buildInfoRow('Price (inclusive VAT 5%)', 'AED ${widget.price}'),
                const Divider(height: 24, color: AppColors.dividerColor, thickness: 1),
                _buildInfoRow('Purchased On', widget.purchaseDateTime),
                const Divider(height: 24, color: AppColors.dividerColor, thickness: 1),
                _buildInfoRow('Product', widget.product),
                const Divider(height: 24, color: AppColors.dividerColor, thickness: 1),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Numbers rows section title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Your Selected Numbers',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Row indicator
          SizedBox(
            height: 30,
            child: Center(
              child: Text(
                'Row ${_currentRowIndex + 1} of ${widget.selectedNumbersRows.length}',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Horizontal scrollable cards for number rows
          SizedBox(
            height: 120,
            child: PageView.builder(
              controller: _rowPageController,
              itemCount: widget.selectedNumbersRows.length,
              onPageChanged: (index) {
                setState(() {
                  _currentRowIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return _buildNumbersCard(widget.selectedNumbersRows[index], index);
              },
            ),
          ),

          // Navigation dots
          SizedBox(
            height: 30,
            child: Center(
              child: widget.selectedNumbersRows.length > 1
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.selectedNumbersRows.length,
                      (index) => _buildDotIndicator(index == _currentRowIndex),
                ),
              )
                  : SizedBox(), // No indicators if only one row
            ),
          ),

          const SizedBox(height: 20),

          // Ticket ID (at the bottom)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.inputFieldBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.inputFieldBorder),
              ),
              child: Row(
                children: [
                  Text(
                    'Ticket ID',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.ticketId,
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNumbersCard(List<int> numbers, int rowIndex) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.inputFieldBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _currentRowIndex == rowIndex
              ? AppColors.primaryColor
              : AppColors.inputFieldBorder,
          width: _currentRowIndex == rowIndex ? 2 : 1,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: numbers.map((number) {
              return Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cardColor,
                  border: Border.all(color: AppColors.primaryColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    number.toString().padLeft(2, '0'),
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildDotIndicator(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? AppColors.primaryColor : AppColors.dividerColor,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () {
          Get.offAll(()=>LotteryScreen());
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: AppColors.textLight,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
        child: const Text(
          'BACK TO HOME',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}