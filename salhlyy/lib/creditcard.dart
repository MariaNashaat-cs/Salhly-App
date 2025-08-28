import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MaterialApp(
    home: PaymentScreen(),
  ));
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // Track whether all fields are valid
  bool _isPayButtonEnabled = false;

  // Callback to update the pay button state
  void _updatePayButtonState(bool isEnabled) {
    setState(() {
      _isPayButtonEnabled = isEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFEEEC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HeaderComponent(),
            SizedBox(height: 20),
            Container(
              width: 335,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'payment details',
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: Color(0x99000000),
                        ),
                      ),
                      Icon(Icons.credit_card, size: 24, color: Colors.blue),
                    ],
                  ),
                  SizedBox(height: 15),
                  CardDetailsComponent(
                    onFieldsValidated: _updatePayButtonState,
                  ),
                  SizedBox(height: 15),
                  SaveCardOptionComponent(),
                ],
              ),
            ),
            SizedBox(height: 20),
            PaymentSummaryComponent(),
            SizedBox(height: 20),
            ActionButtonsComponent(
              isPayButtonEnabled: _isPayButtonEnabled,
              onPayPressed: () {
                // Handle pay button press
                // ignore: avoid_print
                print("Pay button pressed");
              },
              onCancelPressed: () {
                // Handle cancel button press
                // ignore: avoid_print
                print("Cancel button pressed");
              },
              onBackPressed: () {
                // Handle back button press
                // ignore: avoid_print
                print("Back button pressed");
              },
              onNextPressed: () {
                // Handle next button press
                // ignore: avoid_print
                print("Next button pressed");
              },
            ),
          ],
        ),
      ),
    );
  }
}

class HeaderComponent extends StatelessWidget {
  final String title;

  const HeaderComponent({
    super.key,
    this.title = 'Complete payment',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xCC0C5FB3),
            width: 1.0,
          ),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Open Sans',
          fontSize: 27,
          fontWeight: FontWeight.w400,
          color: Color(0xFF0C5FB3),
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

class CardDetailsComponent extends StatefulWidget {
  final Function(bool) onFieldsValidated;

  const CardDetailsComponent({
    super.key,
    required this.onFieldsValidated,
  });

  @override
  // ignore: library_private_types_in_public_api
  _CardDetailsComponentState createState() => _CardDetailsComponentState();
}

class _CardDetailsComponentState extends State<CardDetailsComponent> {
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _mmController = TextEditingController();
  final TextEditingController _yyController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Add listeners to all controllers to check if fields are valid
    _cardNumberController.addListener(_updatePayButtonState);
    _mmController.addListener(_updatePayButtonState);
    _yyController.addListener(_updatePayButtonState);
    _cvvController.addListener(_updatePayButtonState);
  }

  @override
  void dispose() {
    _cardNumberController.removeListener(_updatePayButtonState);
    _mmController.removeListener(_updatePayButtonState);
    _yyController.removeListener(_updatePayButtonState);
    _cvvController.removeListener(_updatePayButtonState);
    _cardNumberController.dispose();
    _mmController.dispose();
    _yyController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  // Check if all fields are valid
  void _updatePayButtonState() {
    bool isCardNumberValid = _cardNumberController.text.replaceAll(' ', '').length == 16;
    bool isMMValid = _mmController.text.length == 2;
    bool isYYValid = _yyController.text.length == 2;
    bool isCVVValid = _cvvController.text.length == 3;

    bool isEnabled = isCardNumberValid && isMMValid && isYYValid && isCVVValid;
    widget.onFieldsValidated(isEnabled);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Card Number Input
        _buildInputField(
          controller: _cardNumberController,
          hintText: "Card Number",
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(19), // 16 digits + 3 spaces
            CardNumberFormatter(), // Add spacing for readability
          ],
        ),
        SizedBox(height: 15),
        // Expiry Date and CVV
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInputField(
              controller: _mmController,
              hintText: "MM",
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              width: 79,
            ),
            _buildInputField(
              controller: _yyController,
              hintText: "YY",
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              width: 79,
            ),
            _buildInputField(
              controller: _cvvController,
              hintText: "CVV",
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              width: 79,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required List<TextInputFormatter> inputFormatters,
    double? width,
  }) {
    return Container(
      width: width ?? double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: Color(0xFFEFEEEC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Color(0x66000000),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Open Sans',
          fontSize: 18,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Color(0x80000000),
            fontSize: 18,
            fontFamily: 'Open Sans',
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 13),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: inputFormatters,
      ),
    );
  }
}

// Custom formatter to add spaces in the card number
class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 16) {
      text = text.substring(0, 16); // Limit to 16 digits
    }
    var formattedText = '';
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formattedText += ' '; // Add a space every 4 digits
      }
      formattedText += text[i];
    }
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class SaveCardOptionComponent extends StatefulWidget {
  final bool initialValue;
  final Function(bool)? onChanged;

  const SaveCardOptionComponent({
    super.key,
    this.initialValue = false,
    this.onChanged,
  });

  @override
  // ignore: library_private_types_in_public_api
  _SaveCardOptionComponentState createState() => _SaveCardOptionComponentState();
}

class _SaveCardOptionComponentState extends State<SaveCardOptionComponent> {
  late bool _isChecked;

  @override
  void initState() {
    super.initState();
    _isChecked = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minWidth: 80,
        maxHeight: 25,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: Checkbox(
              value: _isChecked,
              onChanged: (bool? value) {
                setState(() {
                  _isChecked = value ?? false;
                });
                if (widget.onChanged != null) {
                  widget.onChanged!(_isChecked);
                }
              },
              activeColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'save card',
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Color(0x99000000),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentSummaryComponent extends StatelessWidget {
  final double amount;
  final String currency;

  const PaymentSummaryComponent({
    super.key,
    this.amount = 150.00,
    this.currency = 'EGP',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minWidth: 150,
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          // ignore: deprecated_member_use
          color: Colors.black.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$currency ',
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontSize: 27,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          Text(
            amount.toStringAsFixed(2),
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontSize: 27,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class ActionButtonsComponent extends StatelessWidget {
  final VoidCallback? onPayPressed;
  final VoidCallback? onNextPressed;
  final VoidCallback? onCancelPressed;
  final VoidCallback? onBackPressed;
  final bool isPayButtonEnabled;

  const ActionButtonsComponent({
    super.key,
    this.onPayPressed,
    this.onNextPressed,
    this.onCancelPressed,
    this.onBackPressed,
    required this.isPayButtonEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 335,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pay Button
          SizedBox(
            width: double.infinity,
            height: 67,
            child: ElevatedButton(
              onPressed: isPayButtonEnabled ? onPayPressed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPayButtonEnabled ? Colors.blue : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Pay',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 27,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          // Cancel Button
          TextButton(
            onPressed: onCancelPressed,
            child: Text(
              'cancel',
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 20,
                color: Colors.black54,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          SizedBox(height: 20),
          // Back and Next Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button
              SizedBox(
                width: 58,
                height: 58,
                child: ElevatedButton(
                  onPressed: onBackPressed,
                  style: ElevatedButton.styleFrom(
                    // ignore: deprecated_member_use
                    backgroundColor: Color(0xFF0C5FB3).withOpacity(0.8),
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(17),
                  ),
                  child: Icon(Icons.arrow_back, size: 24, color: Colors.white),
                ),
              ),
              // Next Button
              SizedBox(
                height: 58,
                child: ElevatedButton(
                  onPressed: onNextPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Next',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}