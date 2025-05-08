import 'package:flutter/material.dart';

import '../models/lottery_model.dart';
import '../utils/app_colors.dart';

class PrizeDetailsExpansion extends StatefulWidget {
  final Lottery lottery;

  const PrizeDetailsExpansion({
    Key? key,
    required this.lottery,
  }) : super(key: key);

  @override
  State<PrizeDetailsExpansion> createState() => _PrizeDetailsExpansionState();
}

class _PrizeDetailsExpansionState extends State<PrizeDetailsExpansion> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get non-null prize amounts
    final List<Map<String, dynamic>> prizeData = [];

    // Check Sequence prizes
    if (widget.lottery.tenMatchSequence != null && double.tryParse(widget.lottery.tenMatchSequence!) != null && double.tryParse(widget.lottery.tenMatchSequence!)! > 0) {
      prizeData.add({
        'type': 'Sequence',
        'matches': '10X',
        'amount': double.tryParse(widget.lottery.tenMatchSequence!) ?? 0,
      });
    }

    if (widget.lottery.nineMatchSequence != null && double.tryParse(widget.lottery.nineMatchSequence!) != null && double.tryParse(widget.lottery.nineMatchSequence!)! > 0) {
      prizeData.add({
        'type': 'Sequence',
        'matches': '9X',
        'amount': double.tryParse(widget.lottery.nineMatchSequence!) ?? 0,
      });
    }

    if (widget.lottery.eightMatchSequence != null && double.tryParse(widget.lottery.eightMatchSequence!) != null && double.tryParse(widget.lottery.eightMatchSequence!)! > 0) {
      prizeData.add({
        'type': 'Sequence',
        'matches': '8X',
        'amount': double.tryParse(widget.lottery.eightMatchSequence!) ?? 0,
      });
    }

    if (widget.lottery.sevenMatchSequence != null && double.tryParse(widget.lottery.sevenMatchSequence!) != null && double.tryParse(widget.lottery.sevenMatchSequence!)! > 0) {
      prizeData.add({
        'type': 'Sequence',
        'matches': '7X',
        'amount': double.tryParse(widget.lottery.sevenMatchSequence!) ?? 0,
      });
    }

    if (widget.lottery.sixMatchSequence != null && double.tryParse(widget.lottery.sixMatchSequence!) != null && double.tryParse(widget.lottery.sixMatchSequence!)! > 0) {
      prizeData.add({
        'type': 'Sequence',
        'matches': '6X',
        'amount': double.tryParse(widget.lottery.sixMatchSequence!) ?? 0,
      });
    }

    if (widget.lottery.fiveMatchSequence != null && double.tryParse(widget.lottery.fiveMatchSequence!) != null && double.tryParse(widget.lottery.fiveMatchSequence!)! > 0) {
      prizeData.add({
        'type': 'Sequence',
        'matches': '5X',
        'amount': double.tryParse(widget.lottery.fiveMatchSequence!) ?? 0,
      });
    }

    if (widget.lottery.fourMatchSequence != null && double.tryParse(widget.lottery.fourMatchSequence!) != null && double.tryParse(widget.lottery.fourMatchSequence!)! > 0) {
      prizeData.add({
        'type': 'Sequence',
        'matches': '4X',
        'amount': double.tryParse(widget.lottery.fourMatchSequence!) ?? 0,
      });
    }

    if (widget.lottery.thirdMatchSequence != null && double.tryParse(widget.lottery.thirdMatchSequence!) != null && double.tryParse(widget.lottery.thirdMatchSequence!)! > 0) {
      prizeData.add({
        'type': 'Sequence',
        'matches': '3X',
        'amount': double.tryParse(widget.lottery.thirdMatchSequence!) ?? 0,
      });
    }

    // Check Rumble prizes
    if (widget.lottery.tenMatchRamble != null && double.tryParse(widget.lottery.tenMatchRamble!) != null && double.tryParse(widget.lottery.tenMatchRamble!)! > 0) {
      prizeData.add({
        'type': 'Rumble',
        'matches': '10X',
        'amount': double.tryParse(widget.lottery.tenMatchRamble!) ?? 0,
      });
    }

    if (widget.lottery.nineMatchRamble != null && double.tryParse(widget.lottery.nineMatchRamble!) != null && double.tryParse(widget.lottery.nineMatchRamble!)! > 0) {
      prizeData.add({
        'type': 'Rumble',
        'matches': '9X',
        'amount': double.tryParse(widget.lottery.nineMatchRamble!) ?? 0,
      });
    }

    if (widget.lottery.eightMatchRamble != null && double.tryParse(widget.lottery.eightMatchRamble!) != null && double.tryParse(widget.lottery.eightMatchRamble!)! > 0) {
      prizeData.add({
        'type': 'Rumble',
        'matches': '8X',
        'amount': double.tryParse(widget.lottery.eightMatchRamble!) ?? 0,
      });
    }

    if (widget.lottery.sevenMatchRamble != null && double.tryParse(widget.lottery.sevenMatchRamble!) != null && double.tryParse(widget.lottery.sevenMatchRamble!)! > 0) {
      prizeData.add({
        'type': 'Rumble',
        'matches': '7X',
        'amount': double.tryParse(widget.lottery.sevenMatchRamble!) ?? 0,
      });
    }

    if (widget.lottery.sixMatchRamble != null && double.tryParse(widget.lottery.sixMatchRamble!) != null && double.tryParse(widget.lottery.sixMatchRamble!)! > 0) {
      prizeData.add({
        'type': 'Rumble',
        'matches': '6X',
        'amount': double.tryParse(widget.lottery.sixMatchRamble!) ?? 0,
      });
    }

    if (widget.lottery.fiveMatchRamble != null && double.tryParse(widget.lottery.fiveMatchRamble!) != null && double.tryParse(widget.lottery.fiveMatchRamble!)! > 0) {
      prizeData.add({
        'type': 'Rumble',
        'matches': '5X',
        'amount': double.tryParse(widget.lottery.fiveMatchRamble!) ?? 0,
      });
    }

    if (widget.lottery.fourMatchRamble != null && double.tryParse(widget.lottery.fourMatchRamble!) != null && double.tryParse(widget.lottery.fourMatchRamble!)! > 0) {
      prizeData.add({
        'type': 'Rumble',
        'matches': '4X',
        'amount': double.tryParse(widget.lottery.fourMatchRamble!) ?? 0,
      });
    }

    if (widget.lottery.thirdMatchRamble != null && double.tryParse(widget.lottery.thirdMatchRamble!) != null && double.tryParse(widget.lottery.thirdMatchRamble!)! > 0) {
      prizeData.add({
        'type': 'Rumble',
        'matches': '3X',
        'amount': double.tryParse(widget.lottery.thirdMatchRamble!) ?? 0,
      });
    }

    // Check Chance prizes
    if (widget.lottery.tenMatchChance != null && double.tryParse(widget.lottery.tenMatchChance!) != null && double.tryParse(widget.lottery.tenMatchChance!)! > 0) {
      prizeData.add({
        'type': 'Chance',
        'matches': '10X',
        'amount': double.tryParse(widget.lottery.tenMatchChance!) ?? 0,
      });
    }

    if (widget.lottery.nineMatchChance != null && double.tryParse(widget.lottery.nineMatchChance!) != null && double.tryParse(widget.lottery.nineMatchChance!)! > 0) {
      prizeData.add({
        'type': 'Chance',
        'matches': '9X',
        'amount': double.tryParse(widget.lottery.nineMatchChance!) ?? 0,
      });
    }

    if (widget.lottery.eightMatchChance != null && double.tryParse(widget.lottery.eightMatchChance!) != null && double.tryParse(widget.lottery.eightMatchChance!)! > 0) {
      prizeData.add({
        'type': 'Chance',
        'matches': '8X',
        'amount': double.tryParse(widget.lottery.eightMatchChance!) ?? 0,
      });
    }

    if (widget.lottery.sevenMatchChance != null && double.tryParse(widget.lottery.sevenMatchChance!) != null && double.tryParse(widget.lottery.sevenMatchChance!)! > 0) {
      prizeData.add({
        'type': 'Chance',
        'matches': '7X',
        'amount': double.tryParse(widget.lottery.sevenMatchChance!) ?? 0,
      });
    }

    if (widget.lottery.sixMatchChance != null && double.tryParse(widget.lottery.sixMatchChance!) != null && double.tryParse(widget.lottery.sixMatchChance!)! > 0) {
      prizeData.add({
        'type': 'Chance',
        'matches': '6X',
        'amount': double.tryParse(widget.lottery.sixMatchChance!) ?? 0,
      });
    }

    if (widget.lottery.fiveMatchChance != null && double.tryParse(widget.lottery.fiveMatchChance!) != null && double.tryParse(widget.lottery.fiveMatchChance!)! > 0) {
      prizeData.add({
        'type': 'Chance',
        'matches': '5X',
        'amount': double.tryParse(widget.lottery.fiveMatchChance!) ?? 0,
      });
    }

    if (widget.lottery.fourMatchChance != null && double.tryParse(widget.lottery.fourMatchChance!) != null && double.tryParse(widget.lottery.fourMatchChance!)! > 0) {
      prizeData.add({
        'type': 'Chance',
        'matches': '4X',
        'amount': double.tryParse(widget.lottery.fourMatchChance!) ?? 0,
      });
    }

    if (widget.lottery.thirdMatchChance != null && double.tryParse(widget.lottery.thirdMatchChance!) != null && double.tryParse(widget.lottery.thirdMatchChance!)! > 0) {
      prizeData.add({
        'type': 'Chance',
        'matches': '3X',
        'amount': double.tryParse(widget.lottery.thirdMatchChance!) ?? 0,
      });
    }

    if (widget.lottery.secondMatchChance != null && double.tryParse(widget.lottery.secondMatchChance!) != null && double.tryParse(widget.lottery.secondMatchChance!)! > 0) {
      prizeData.add({
        'type': 'Chance',
        'matches': '2X',
        'amount': double.tryParse(widget.lottery.secondMatchChance!) ?? 0,
      });
    }

    if (widget.lottery.firstMatchChance != null && double.tryParse(widget.lottery.firstMatchChance!) != null && double.tryParse(widget.lottery.firstMatchChance!)! > 0) {
      prizeData.add({
        'type': 'Chance',
        'matches': '1X',
        'amount': double.tryParse(widget.lottery.firstMatchChance!) ?? 0,
      });
    }

    // If no prize data, don't show the section
    if (prizeData.isEmpty) {
      return const SizedBox();
    }

    return Column(
      children: [
        // Header row with expansion icon
        InkWell(
          onTap: _toggleExpanded,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Prize Details',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expandable content
        SizeTransition(
          sizeFactor: _expandAnimation,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.inputFieldBorder.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Table header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Prizes',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'No. Of Matches',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Prize Money',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Table rows
                  ...prizeData.map((prize) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              prize['type'],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              prize['matches'],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'AED ${prize['amount'].toStringAsFixed(2)}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}