import 'package:flutter/material.dart';
import 'dart:async';
import 'wallet.dart';

class RefundPage extends StatefulWidget {
  final String totalAmount;
  final String userId;
  final String fullName;
  final String phoneNumber;

  const RefundPage({super.key, required this.totalAmount, required this.userId,required this.fullName,
    required this.phoneNumber,});

  @override
  State<RefundPage> createState() => _RefundPageState();
}

class _RefundPageState extends State<RefundPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _animationController.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleRefund(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Clean the amount string: remove everything except numbers and the first decimal point
      String amountStr = widget.totalAmount.replaceAll(RegExp(r'[^0-9.]'), '');
      // Ensure only one decimal point remains by splitting and taking the first part after the decimal
      final parts = amountStr.split('.');
      if (parts.length > 2) {
        // If there are multiple decimal points, keep only the first one
        amountStr = '${parts[0]}.${parts[1]}';
      } else if (parts.length == 2 && parts[1].isEmpty) {
        // Handle case like "225.0." by removing the trailing decimal point
        amountStr = parts[0];
      }

      // Parse the cleaned string to a double
      final amount = double.tryParse(amountStr);
      if (amount == null) {
        throw Exception('Invalid refund amount format: ${widget.totalAmount}');
      }
      
      // Add the refund to the wallet
      await WalletManager.addRefund(widget.userId, amount);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Show success dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  SizedBox(width: 10),
                  Text('Success'),
                ],
              ),
              content: Text(
                'Your refund of ${widget.totalAmount} has been added to your wallet.',
                style: const TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Navigate to WalletScreen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => WalletScreen(userId: widget.userId,fullName: widget.fullName, 
                          phoneNumber: widget.phoneNumber),
                      ),
                    );
                  },
                  child: const Text('View Wallet'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Show error dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 28),
                  SizedBox(width: 10),
                  Text('Error'),
                ],
              ),
              content: Text(
                'Failed to process refund: $e',
                style: const TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF0C5FB3)),
        title: const Text(
          'Refund',
          style: TextStyle(
            color: Color(0xFF0C5FB3),
            fontWeight: FontWeight.w600,
            fontFamily: 'Playfair_Display',
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              const Color(0xFFE8F1F8),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.wallet_rounded,
                        size: 48,
                        color: Color(0xFF0C5FB3),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Refund Amount',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Playfair_Display',
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F8F8),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF0C5FB3).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                widget.totalAmount,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0C5FB3),
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Refund Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Status', 'Pending', Colors.orange),
                      const Divider(height: 24),
                      _buildInfoRow('Method', 'Original Payment Method', null),
                      const Divider(height: 24),
                      _buildInfoRow('Processing Time', '1-3 Business Days', null),
                    ],
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _handleRefund(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C5FB3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 5,
                    shadowColor: const Color(0xFF0C5FB3).withOpacity(0.5),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Confirm Refund',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color? valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}