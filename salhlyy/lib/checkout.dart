import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'orderdetails.dart'; // Import OrderDetailsLayout

class AppTheme {
  static const Color primaryColor = Color(0xFF0C5FB3);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Color(0xFFD9D9D9);
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Color(0x99000000);

  static const double borderRadiusLarge = 24.0;
  static const double borderRadiusMedium = 16.0;
  static const double borderRadiusSmall = 10.0;

  static const TextStyle headingLarge = TextStyle(
    fontFamily: 'Playfair_Display',
    fontSize: 25,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: primaryColor,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Open Sans',
    fontSize: 20,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Open Sans',
    fontSize: 18,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle buttonText = TextStyle(
    fontFamily: 'Open Sans',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
}

class CheckoutLayout extends StatefulWidget {
  final String phoneNumber;
  final String fullname;
  final double fixerPrice;
  final double serviceFee;
  final double taxAmount;
  final double discountAmount;
  final Function(double)? onTotalChanged;

  const CheckoutLayout({
    super.key,
    required this.phoneNumber,
    required this.fullname,
    required this.fixerPrice,
    this.serviceFee = 20.0,
    this.taxAmount = 5.0,
    this.discountAmount = 0.0,
    this.onTotalChanged,
  });

  @override
  State<CheckoutLayout> createState() => _CheckoutLayoutState();
}

class _CheckoutLayoutState extends State<CheckoutLayout> {
  bool _isProcessingPayment = false;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final ValueNotifier<double> _totalAmountNotifier = ValueNotifier<double>(0.0);
  Map<String, dynamic> plumbingProblems = {};
  double _currentDiscountAmount = 0.0;
  bool isLoading = true;
  bool _useWalletBalance = false;
  double _currentWalletBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    _loadPlumbingProblems();
    _currentDiscountAmount = widget.discountAmount;
    _loadUserBalance();
  }

  @override
  void dispose() {
    _totalAmountNotifier.dispose();
    super.dispose();
  }

  void _updateTotalAmount(double newTotal) {
    _totalAmountNotifier.value = newTotal;
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
    }
  }

  Future<void> _loadPlumbingProblems() async {
    try {
      final snapshot = await _database
          .child('users')
          .child(widget.phoneNumber)
          .child('plumbingproblem')
          .get();

      if (snapshot.exists) {
        debugPrint('Raw plumbing problems data: ${snapshot.value}');
        final problems = snapshot.value as Map<dynamic, dynamic>;
        debugPrint('Problems map: $problems');
        
        // Convert the problem data to the correct format
        Map<String, dynamic> formattedProblems = {};
        problems.forEach((key, value) {
          if (value is Map) {
            formattedProblems[key.toString()] = Map<String, dynamic>.from(value);
          }
        });
        debugPrint('Formatted problems: $formattedProblems');

        setState(() {
          plumbingProblems = formattedProblems;
          isLoading = false;
          final total = widget.fixerPrice + widget.serviceFee + widget.taxAmount - widget.discountAmount;
          widget.onTotalChanged?.call(total);
        });
      } else {
        debugPrint('No plumbing problems found in snapshot');
        setState(() {
          isLoading = false;
          final total = widget.fixerPrice + widget.serviceFee + widget.taxAmount - widget.discountAmount;
          widget.onTotalChanged?.call(total);
        });
      }
    } catch (e) {
      debugPrint('Error loading plumbing problems: $e');
      debugPrint('Error stack trace: ${e is Error ? e.stackTrace : null}');
      setState(() {
        isLoading = false;
        final total = widget.fixerPrice + widget.serviceFee + widget.taxAmount - widget.discountAmount;
        widget.onTotalChanged?.call(total);
      });
    }
  }

  Future<void> _loadUserBalance() async {
    try {
      final snapshot = await _database
          .child('wallets')
          .child(widget.phoneNumber)
          .child('balance')
          .get();

      if (snapshot.exists && mounted) {
        setState(() {
          _currentWalletBalance = double.parse(snapshot.value.toString());
          _useWalletBalance = true;
        });
      } else {
        if (mounted) {
          setState(() {
            _useWalletBalance = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user balance: $e');
      if (mounted) {
        setState(() {
          _useWalletBalance = false;
        });
      }
    }
  }

  Future<void> _saveOrderToFirebase(String paymentMethod, double totalAmount) async {
    try {
      String orderId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Calculate and update wallet balance if used
      if (_useWalletBalance && _currentWalletBalance > 0) {
        final totalBeforeBalance = widget.fixerPrice + widget.serviceFee + widget.taxAmount - widget.discountAmount;
        final usedBalance = min(_currentWalletBalance, totalBeforeBalance);
        final newBalance = _currentWalletBalance - usedBalance;
        
        // Update wallet balance in Firebase
        await _database
            .child('wallets')
            .child(widget.phoneNumber)
            .update({
          'balance': newBalance,
        });
      }

      // Save the order
      await _database
          .child('users')
          .child(widget.phoneNumber)
          .child('orders')
          .child(orderId)
          .set({
        'orderNumber': '#${orderId.substring(6)}',
        'paymentMethod': paymentMethod,
        'totalAmount': totalAmount,
        'fixerName': widget.fullname,
        'fixerPrice': widget.fixerPrice,
        'status': 'completed',
        'timestamp': ServerValue.timestamp,
        'discountAmount': _currentDiscountAmount,
        'walletBalanceUsed': _useWalletBalance ? min(_currentWalletBalance, totalAmount) : 0.0,
      });

      // Create a service request
      await _database
          .child('serviceRequests')
          .child(orderId)
          .set({
        'orderId': orderId,
        'category': 'Plumbing',
        'status': 'pending',
        'customerPhone': widget.phoneNumber,
        'fixerName': widget.fullname,
        'fixerPrice': widget.fixerPrice,
        'totalAmount': totalAmount,
        'paymentMethod': paymentMethod,
        'createdAt': ServerValue.timestamp,
        'description': 'Service request created from order #${orderId.substring(6)}',
        'problems': plumbingProblems,
      });

      // Navigate to OrderDetailsLayout with all parameters including orderId
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailsLayout(
              username: widget.fullname,
              paymentMethod: paymentMethod,
              phoneNumber: widget.phoneNumber,
              totalAmount: totalAmount,
              orderId: orderId,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving order to Firebase: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Go back',
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontFamily: 'Playfair_Display',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildProgressStep(
                            icon: Icons.shopping_cart,
                            label: 'Cart',
                            isActive: true,
                          ),
                          _buildProgressStep(
                            icon: Icons.payment,
                            label: 'Payment',
                            isActive: true,
                          ),
                          _buildProgressStep(
                            icon: Icons.check_circle,
                            label: 'Complete',
                            isActive: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const PaymentMethodComponent(),
                    const SizedBox(height: 20),
                    PromoCodeComponent(
                      onApply: (discount) {
                        setState(() {
                          _currentDiscountAmount = discount;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    EnhancedOrderSummaryComponent(
                      phoneNumber: widget.phoneNumber,
                      fixerPrice: widget.fixerPrice,
                      fixerName: widget.fullname,
                      serviceFee: widget.serviceFee,
                      discountAmount: _currentDiscountAmount,
                      taxAmount: widget.taxAmount,
                      onTotalChanged: _updateTotalAmount,
                      onWalletUsageChanged: (useBalance, balance) {
                        setState(() {
                          _useWalletBalance = useBalance;
                          _currentWalletBalance = balance;
                        });
                      },
                    ),
                    const SizedBox(height: 30),
                    ValueListenableBuilder<double>(
                      valueListenable: _totalAmountNotifier,
                      builder: (context, total, child) {
                        return PaymentButtonComponent(
                          amount: '${total.toStringAsFixed(1)} L.E',
                          isLoading: _isProcessingPayment,
                          onPressed: _isProcessingPayment
                              ? null
                              : () async {
                                  setState(() {
                                    _isProcessingPayment = true;
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Row(
                                        children: [
                                          CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            strokeWidth: 2,
                                          ),
                                          SizedBox(width: 16),
                                          Text('Processing payment...'),
                                        ],
                                      ),
                                      duration: Duration(seconds: 2),
                                      backgroundColor: AppTheme.primaryColor,
                                    ),
                                  );

                                  await Future.delayed(const Duration(seconds: 2));
                                  
                                  await _saveOrderToFirebase(
                                      PaymentMethodComponent.selectedMethod, total);

                                  setState(() {
                                    _isProcessingPayment = false;
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.white),
                                          SizedBox(width: 16),
                                          Text('Payment Successful!'),
                                        ],
                                      ),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock, size: 16, color: Colors.grey),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Your payment information is secure and encrypted',
                              style: TextStyle(
                                fontFamily: 'Open Sans',
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            if (_isProcessingPayment)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStep({
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : Colors.grey.shade600,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontSize: 14,
            color: isActive ? AppTheme.primaryColor : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class PaymentMethodComponent extends StatefulWidget {
  final String defaultMethod;
  static String selectedMethod = 'cash';

  const PaymentMethodComponent({super.key, this.defaultMethod = 'cash'});

  @override
  _PaymentMethodComponentState createState() => _PaymentMethodComponentState();
}

class _PaymentMethodComponentState extends State<PaymentMethodComponent> {
  late String selectedMethod;
  String _formattedCardNumber = '';
  bool _cardAdded = false;

  @override
  void initState() {
    super.initState();
    selectedMethod = widget.defaultMethod;
    PaymentMethodComponent.selectedMethod = widget.defaultMethod;
  }

  void _onCardAdded(String formattedCardNumber) {
    setState(() {
      _formattedCardNumber = formattedCardNumber;
      _cardAdded = true;
    });
  }

  Widget _buildPaymentOption({
    required String title,
    required IconData icon,
    required String value,
    String? subtitle,
  }) {
    bool isSelected = selectedMethod == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMethod = value;
          PaymentMethodComponent.selectedMethod = value;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          border: isSelected 
              ? Border.all(color: AppTheme.primaryColor, width: 2) 
              : Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected ? Colors.white : AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 18,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          fontSize: 14,
                          color: isSelected ? AppTheme.primaryColor.withOpacity(0.8) : Colors.black54,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Choose your payment method',
            style: AppTheme.headingLarge,
            semanticsLabel: 'Choose your payment method section',
          ),
        ),
        const SizedBox(height: 20),
        _buildPaymentOption(
          title: 'Cash on Delivery',
          icon: Icons.payments_outlined,
          value: 'cash',
          subtitle: 'Pay when you receive your order',
        ),
        const SizedBox(height: 16),
        _buildPaymentOption(
          title: 'Credit/Debit Card',
          icon: Icons.credit_card,
          value: 'card',
          subtitle: 'Secure online payment',
        ),
        if (selectedMethod == 'card' || _cardAdded)
          EnhancedCreditCardForm(
            onCardAdded: _onCardAdded,
            formattedCardNumber: _formattedCardNumber,
            cardAdded: _cardAdded,
          ),
      ],
    );
  }
}

class EnhancedCreditCardForm extends StatefulWidget {
  final Function(String)? onCardAdded;
  final String formattedCardNumber;
  final bool cardAdded;

  const EnhancedCreditCardForm({
    super.key,
    this.onCardAdded,
    this.formattedCardNumber = '',
    this.cardAdded = false,
  });

  @override
  _EnhancedCreditCardFormState createState() => _EnhancedCreditCardFormState();
}

class _EnhancedCreditCardFormState extends State<EnhancedCreditCardForm> {
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _cardAdded = false;
  String _formattedCardNumber = '';
  String _cardType = '';
  bool _rememberCard = false;

  Map<String, String> _errors = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _cardAdded = widget.cardAdded;
    _formattedCardNumber = widget.formattedCardNumber;
  }

  void _updateCardType(String cardNumber) {
    if (cardNumber.isEmpty) {
      setState(() => _cardType = '');
      return;
    }

    final cleanNumber = cardNumber.replaceAll(' ', '');

    if (cleanNumber.startsWith('4')) {
      setState(() => _cardType = 'Visa');
    } else if (cleanNumber.startsWith('5')) {
      setState(() => _cardType = 'Mastercard');
    } else if (cleanNumber.startsWith('3')) {
      setState(() => _cardType = 'Amex');
    } else if (cleanNumber.startsWith('6')) {
      setState(() => _cardType = 'Discover');
    } else {
      setState(() => _cardType = '');
    }
  }

  bool _isValidCardNumber(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(' ', '');
    if (cleanNumber.isEmpty || cleanNumber.length < 13) return false;

    int sum = 0;
    bool alternate = false;
    for (int i = cleanNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cleanNumber[i]);
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }
      sum += digit;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  bool _isValidExpiryDate(String expiryDate) {
    if (expiryDate.length != 5 || !expiryDate.contains('/')) {
      return false;
    }

    final parts = expiryDate.split('/');
    if (parts.length != 2) {
      return false;
    }

    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);

    if (month == null || year == null || month < 1 || month > 12) {
      return false;
    }

    final now = DateTime.now();
    final currentYear = now.year % 100;
    final currentMonth = now.month;

    return (year > currentYear || (year == currentYear && month >= currentMonth));
  }

  bool _validateInputs() {
    Map<String, String> newErrors = {};

    final cardNumber = _cardNumberController.text.replaceAll(' ', '');
    if (cardNumber.isEmpty) {
      newErrors['cardNumber'] = 'Card number is required';
    } else if (cardNumber.length < 13 || cardNumber.length > 19) {
      newErrors['cardNumber'] = 'Invalid card number length';
    } else if (!_isValidCardNumber(cardNumber)) {
      newErrors['cardNumber'] = 'Invalid card number';
    }

    if (_nameController.text.isEmpty) {
      newErrors['name'] = 'Cardholder name is required';
    }

    if (_expiryDateController.text.isEmpty) {
      newErrors['expiryDate'] = 'Expiry date is required';
    } else if (!_isValidExpiryDate(_expiryDateController.text)) {
      newErrors['expiryDate'] = 'Invalid or expired date';
    }

    if (_cvvController.text.isEmpty) {
      newErrors['cvv'] = 'CVV is required';
    } else if (_cvvController.text.length < 3 || _cvvController.text.length > 4) {
      newErrors['cvv'] = 'Invalid CVV';
    }

    setState(() {
      _errors = newErrors;
    });

    return newErrors.isEmpty;
  }

  void _addCard() async {
    if (_isSubmitting) return;

    if (!_validateInputs()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    final cardNumber = _cardNumberController.text.replaceAll(' ', '');

    setState(() {
      _cardAdded = true;
      _formattedCardNumber = '•••• ${cardNumber.substring(cardNumber.length - 4)}';
      _isSubmitting = false;
    });

    if (widget.onCardAdded != null) {
      widget.onCardAdded!(_formattedCardNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: _cardAdded ? _buildCardDetailsBox() : _buildCreditCardForm(),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    String? error,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffix,
    Function(String)? onChanged,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Open Sans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: error != null ? Colors.red : Colors.white.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            obscureText: obscureText,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLength: maxLength,
            onChanged: onChanged,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              border: InputBorder.none,
              suffixIcon: suffix,
              counterText: '',
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              error,
              style: const TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCreditCardForm() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Card Details',
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildInputField(
            controller: _cardNumberController,
            label: 'Card Number',
            error: _errors['cardNumber'],
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(19),
              _CardNumberFormatter(),
            ],
            onChanged: _updateCardType,
            suffix: _cardType.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Image.asset(
                      _cardType == 'Visa'
                          ? 'images/images/visa_logo.jpeg'
                          : _cardType == 'Mastercard'
                              ? 'images/images/mastercard_logo.jpeg'
                              : _cardType == 'Amex'
                                  ? 'images/amex_logo.png'
                                  : 'images/card_generic.png',
                      width: 40,
                      height: 30,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _nameController,
            label: 'Cardholder Name',
            error: _errors['name'],
            keyboardType: TextInputType.name,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _expiryDateController,
                  label: 'Expiry Date (MM/YY)',
                  error: _errors['expiryDate'],
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    _ExpiryDateFormatter(),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInputField(
                  controller: _cvvController,
                  label: 'Security Code (CVV)',
                  error: _errors['cvv'],
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  suffix: const Tooltip(
                    message: 'The 3 or 4 digit code on the back of your card',
                    child: Icon(Icons.help_outline, color: Colors.white70, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _rememberCard,
                  onChanged: (value) {
                    setState(() {
                      _rememberCard = value ?? false;
                    });
                  },
                  fillColor: WidgetStateProperty.resolveWith<Color>(
                    (Set<WidgetState> states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return Colors.transparent;
                    },
                  ),
                  checkColor: AppTheme.primaryColor,
                  side: const BorderSide(color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Save this card for future payments',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _addCard,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey,
                foregroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                minimumSize: const Size(200, 54),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    )
                  : const Text(
                      'ADD CARD',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardDetailsBox() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _cardAdded = false;
        });
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Card Details',
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _cardAdded = false;
                    });
                  },
                  tooltip: 'Edit card details',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  if (_cardType.isNotEmpty)
                    Image.asset(
                      _cardType == 'Visa'
                          ? 'images/images/visa_logo.jpeg'
                          : _cardType == 'Mastercard'
                              ? 'images/images/mastercard_logo.jpeg'
                              : _cardType == 'Amex'
                                  ? 'images/amex_logo.png'
                                  : 'images/card_generic.png',
                      width: 50,
                      height: 30,
                    ),
                  const SizedBox(width: 16),
                  Text(
                    _formattedCardNumber,
                    style: const TextStyle(
                      fontFamily: 'Open Sans',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  if (_nameController.text.isNotEmpty)
                    Text(
                      _nameController.text.split(' ').first,
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Default payment method',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PromoCodeComponent extends StatefulWidget {
  final Function(double)? onApply;
  final String? initialPromoCode;

  const PromoCodeComponent({
    super.key,
    this.onApply,
    this.initialPromoCode,
  });

  @override
  _PromoCodeComponentState createState() => _PromoCodeComponentState();
}

class _PromoCodeComponentState extends State<PromoCodeComponent> {
  final TextEditingController _promoController = TextEditingController();
  bool _isApplying = false;
  bool _promoApplied = false;
  String? _errorMessage;
  double _discountAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _promoController.text = widget.initialPromoCode ?? '';
  }

  void _applyPromoCode() async {
    final code = _promoController.text.trim();

    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a promo code';
      });
      return;
    }

    setState(() {
      _isApplying = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    if (code == "SAVE10") {
      setState(() {
        _isApplying = false;
        _promoApplied = true;
        _discountAmount = 100.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Promo code applied! 10% discount'),
          backgroundColor: Colors.green,
        ),
      );

      if (widget.onApply != null) {
        widget.onApply!(_discountAmount);
      }
    } else if (code == "S20") {
      setState(() {
        _isApplying = false;
        _promoApplied = true;
        _discountAmount = 20.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Promo code applied! 20 L.E discount'),
          backgroundColor: Colors.green,
        ),
      );

      if (widget.onApply != null) {
        widget.onApply!(_discountAmount);
      }
    } else if (code == "S50") {
      setState(() {
        _isApplying = false;
        _promoApplied = true;
        _discountAmount = 0.05;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Promo code applied! 5% discount'),
          backgroundColor: Colors.green,
        ),
      );

      if (widget.onApply != null) {
        widget.onApply!(_discountAmount);
      }
    } else {
      setState(() {
        _isApplying = false;
        _errorMessage = 'Invalid promo code';
      });
    }
  }

  void _removePromoCode() {
    setState(() {
      _promoApplied = false;
      _promoController.clear();
      _discountAmount = 0.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Promo code removed'),
      ),
    );

    if (widget.onApply != null) {
      widget.onApply!(0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 69,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _promoController,
                enabled: !_promoApplied,
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 16,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter promo code',
                  hintStyle: TextStyle(
                    fontFamily: 'Open Sans',
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  prefixIcon: _promoApplied
                      ? const Icon(Icons.local_offer, color: Colors.green)
                      : const Icon(Icons.local_offer_outlined, color: AppTheme.primaryColor),
                  errorText: _errorMessage,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _promoApplied
                ? ElevatedButton.icon(
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Remove'),
                    onPressed: _removePromoCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade300,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      minimumSize: const Size(110, 40),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _isApplying ? null : _applyPromoCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      minimumSize: const Size(110, 40),
                    ),
                    child: _isApplying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Apply',
                            style: TextStyle(
                              fontFamily: 'Open Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
          ],
        ),
      ),
    );
  }
}

class EnhancedOrderSummaryComponent extends StatefulWidget {
  final String phoneNumber;
  final double fixerPrice;
  final String fixerName;
  final double serviceFee;
  final double discountAmount;
  final double taxAmount;
  final Function(double) onTotalChanged;
  final Function(bool, double)? onWalletUsageChanged;

  const EnhancedOrderSummaryComponent({
    super.key,
    required this.phoneNumber,
    required this.fixerPrice,
    required this.fixerName,
    this.serviceFee = 20.0,
    this.discountAmount = 0.0,
    this.taxAmount = 5.0,
    required this.onTotalChanged,
    this.onWalletUsageChanged,
  });

  @override
  State<EnhancedOrderSummaryComponent> createState() => _EnhancedOrderSummaryComponentState();
}

class _EnhancedOrderSummaryComponentState extends State<EnhancedOrderSummaryComponent> {
  Map<String, dynamic> plumbingProblems = {};
  bool isLoading = true;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  double _userBalance = 0.0;
  bool _useWalletBalance = false;

  @override
  void initState() {
    super.initState();
    _loadPlumbingProblems();
    _loadUserBalance();
  }

  Future<void> _loadUserBalance() async {
    try {
      final snapshot = await _database
          .child('wallets')
          .child(widget.phoneNumber)
          .child('balance')
          .get();

      if (snapshot.exists && mounted) {
        setState(() {
          _userBalance = double.parse(snapshot.value.toString());
          _useWalletBalance = true;
        });
      } else {
        if (mounted) {
          setState(() {
            _useWalletBalance = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user balance: $e');
      if (mounted) {
        setState(() {
          _useWalletBalance = false;
        });
      }
    }
  }

  Future<void> _loadPlumbingProblems() async {
    try {
      final snapshot = await _database
          .child('users')
          .child(widget.phoneNumber)
          .child('plumbingproblem')
          .get();

      if (snapshot.exists) {
        final problems = snapshot.value as Map<dynamic, dynamic>;
        
        Map<String, dynamic> formattedProblems = {};
        problems.forEach((key, value) {
          if (value is Map) {
            formattedProblems[key.toString()] = Map<String, dynamic>.from(value);
          }
        });

        if (mounted) {
          setState(() {
            plumbingProblems = formattedProblems;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading plumbing problems: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  double get totalAmount {
    double total = widget.fixerPrice + widget.serviceFee + widget.taxAmount - widget.discountAmount;
    if (_useWalletBalance && _userBalance > 0) {
      double balanceToUse = min(_userBalance, total);
      total = max(0, total - balanceToUse);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onTotalChanged(total);
    });
    return total;
  }

  double get totalBeforeDiscount {
    return widget.fixerPrice + widget.serviceFee + widget.taxAmount;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: AppTheme.headingMedium,
          ),
          const SizedBox(height: 24),
Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  decoration: BoxDecoration(
    color: const Color(0xFF0C5FB3).withOpacity(0.05),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: const Color(0xFF0C5FB3).withOpacity(0.1),
    ),
  ),
  child: Column(
    mainAxisSize: MainAxisSize.min, // Keep column as small as possible
    crossAxisAlignment: CrossAxisAlignment.center, // Center align all content
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center, // Center the top row
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF0C5FB3).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Color(0xFF0C5FB3),
              size: 16,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Use my balance:',
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontSize: 16, // Increased font size
              fontWeight: FontWeight.w600,
              color: Color(0xFF0C5FB3),
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Row(
        mainAxisAlignment: MainAxisAlignment.center, // Center the balance and switch
        children: [
          Text(
            'EGP ${_userBalance.toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: 'Open Sans',
              fontSize: 18, // Increased font size for balance
              fontWeight: FontWeight.w700,
              color: Color(0xFF0C5FB3),
            ),
          ),
          const SizedBox(width: 4),
          Switch(
            value: _useWalletBalance,
            onChanged: (value) {
              setState(() {
                _useWalletBalance = value;
                widget.onTotalChanged(totalAmount);
                widget.onWalletUsageChanged?.call(_useWalletBalance, _userBalance);
              });
            },
            activeColor: const Color(0xFF0C5FB3),
            activeTrackColor: const Color(0xFF0C5FB3).withOpacity(0.4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Makes the switch smaller
            // Removed scale: 0.8
          ),
        ],
      ),
    ],
  ),
),
          const SizedBox(height: 24),
          _buildSummaryRow('${widget.fixerName} Service', '${widget.fixerPrice.toStringAsFixed(1)} L.E'),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              debugPrint('Building problems list. Problems: $plumbingProblems');
              return Column(
                children: [
                  for (var entry in plumbingProblems.entries)
                    if (entry.key != 'note' && entry.key != 'images' && entry.key != 'video' && entry.key != 'audios') ...[
                      _buildSummaryRow('Problem: ${entry.key}', 'Included'),
                      const SizedBox(height: 8),
                    ],
                ],
              );
            },
          ),
          _buildSummaryRow('Service fee', '${widget.serviceFee.toStringAsFixed(1)} L.E'),
          const SizedBox(height: 8),
          _buildSummaryRow('Tax', '${widget.taxAmount.toStringAsFixed(1)} L.E'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.grey),
          ),
          if (widget.discountAmount > 0) ...[
            _buildSummaryRow(
              'Total before discount',
              '${totalBeforeDiscount.toStringAsFixed(1)} L.E',
              style: const TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: _buildSummaryRow(
                'Discount',
                '-${widget.discountAmount.toStringAsFixed(1)} L.E',
                isDiscount: true,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: Colors.grey),
            ),
          ],
          if (_useWalletBalance) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0C5FB3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF0C5FB3).withOpacity(0.3)),
              ),
              child: _buildSummaryRow(
                'Balance Applied',
                '-${min(_userBalance, totalBeforeDiscount - widget.discountAmount).toStringAsFixed(1)} L.E',
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0C5FB3),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: Colors.grey),
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total to pay',
                style: TextStyle(
                  fontFamily: 'Playfair_Display',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${totalAmount.toStringAsFixed(1)} L.E',
                style: const TextStyle(
                  fontFamily: 'Playfair_Display',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isDiscount = false, TextStyle? style}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: style ?? const TextStyle(
            fontFamily: 'Open Sans',
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: style ?? TextStyle(
            fontFamily: 'Open Sans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDiscount ? Colors.green : Colors.black87,
          ),
        ),
      ],
    );
  }
}

class PaymentButtonComponent extends StatelessWidget {
  final String amount;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PaymentButtonComponent({
    super.key,
    this.amount = '150L.E',
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          disabledBackgroundColor: Colors.grey,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          elevation: 4,
          shadowColor: AppTheme.primaryColor.withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Processing...',
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lock, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Pay $amount',
                style: const TextStyle(
                  fontSize: 22,
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 16) {
      return oldValue;
    }

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i + 1 != text.length) {
        buffer.write(' ');
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 4) {
      return oldValue;
    }

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && text.length > 2) {
        buffer.write('/');
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}