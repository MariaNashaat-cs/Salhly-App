import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'profile.dart';

class VerificationScreen extends StatefulWidget {
  final String phoneNumber;
  const VerificationScreen({super.key, required this.phoneNumber});

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(5, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(5, (index) => FocusNode());
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  int _resendTimer = 30;
  bool _canResend = false;
  bool _isOtpFilled = false;
  bool _isVerifying = false;
  String? _errorMessage;

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    startTimer();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    for (var i = 0; i < _controllers.length; i++) {
      final controller = _controllers[i];
      controller.addListener(() {
        _checkOtpFilled();
        if (controller.text.isNotEmpty && i < _controllers.length - 1) {
          FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void startTimer() {
    if (_resendTimer > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _resendTimer--;
            if (_resendTimer == 0) {
              _canResend = true;
            } else {
              startTimer();
            }
          });
        }
      });
    }
  }

  void _checkOtpFilled() {
    setState(() {
      _isOtpFilled = _controllers.every((controller) => controller.text.isNotEmpty);
      if (_isOtpFilled) {
        _errorMessage = null;
      }
    });
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });
    
    HapticFeedback.mediumImpact();
    await _animationController.forward();
    await _animationController.reverse();
    
    await Future.delayed(const Duration(seconds: 1));
    
    final otp = _controllers.map((controller) => controller.text).join();
    
    try {
      if (otp == "12345") {
        await _database.child('users').child(widget.phoneNumber).update({
          'verified': true,
        });

        final snapshot = await _database.child('users').child(widget.phoneNumber).get();
        if (snapshot.exists) {
          final _ = snapshot.value as Map<dynamic, dynamic>;
        }

        if (mounted) {
          setState(() => _isVerifying = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone number verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(
                    phoneNumber: widget.phoneNumber,
                  ),
                ),
              );
            }
          });
        }
      } else {
        throw Exception('Invalid verification code');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _errorMessage = "Invalid verification code. Please try again.";
          for (var controller in _controllers) {
            controller.clear();
          }
          FocusScope.of(context).requestFocus(_focusNodes[0]);
        });
      }
    }
  }

  void _onKeyPressed(String value) {
    HapticFeedback.selectionClick();
    for (var i = 0; i < _controllers.length; i++) {
      if (_controllers[i].text.isEmpty) {
        _controllers[i].text = value;
        if (i < _controllers.length - 1) {
          FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
        }
        break;
      }
    }
  }

  void _onDeletePressed() {
    HapticFeedback.lightImpact();
    for (var i = _controllers.length - 1; i >= 0; i--) {
      if (_controllers[i].text.isNotEmpty) {
        _controllers[i].clear();
        FocusScope.of(context).requestFocus(_focusNodes[i]);
        break;
      } else if (i > 0 && _controllers[i-1].text.isNotEmpty) {
        _controllers[i-1].clear();
        FocusScope.of(context).requestFocus(_focusNodes[i-1]);
        break;
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final String? text = data?.text;
    
    if (text != null && text.length >= 5) {
      final digits = text.replaceAll(RegExp(r'[^0-9]'), '').substring(0, 5);
      if (digits.length == 5) {
        for (var i = 0; i < 5; i++) {
          _controllers[i].text = digits[i];
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEE),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Back to previous screen',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Verify phone number',
                  style: TextStyle(fontFamily: 'playfair', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Enter the 5-digit verification code',
                  style: TextStyle(fontFamily: 'playfair', fontSize: 22, color: Color.fromRGBO(0, 0, 0, 0.52), fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sent to ${widget.phoneNumber}',
                  style: const TextStyle(fontSize: 16, color: Color.fromRGBO(0, 0, 0, 0.7)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => _buildOtpField(index),
                  ),
                ),
                const SizedBox(height: 8),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _canResend
                          ? () {
                              setState(() {
                                _resendTimer = 30;
                                _canResend = false;
                                startTimer();
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Verification code resent')),
                              );
                            }
                          : null,
                      child: Text(
                        _canResend ? 'Resend code' : 'Resend code in $_resendTimer',
                        style: TextStyle(
                          fontSize: 17,
                          color: _canResend ? const Color(0xFF0C5FB3) : const Color.fromRGBO(12, 95, 179, 0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: _pasteFromClipboard,
                      child: const Text(
                        'Paste code',
                        style: TextStyle(
                          fontSize: 17,
                          color: Color(0xFF0C5FB3),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ScaleTransition(
                  scale: _animation,
                  child: SizedBox(
                    width: 240,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isOtpFilled && !_isVerifying ? _verifyOtp : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isOtpFilled ? const Color(0xFF0C5FB3) : const Color(0xFFD3D1D8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
                        elevation: 2,
                      ),
                      child: _isVerifying
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Confirm',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: _isOtpFilled ? Colors.white : const Color.fromRGBO(0, 0, 0, 0.7),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Semantics(
                  label: 'Number keypad for verification code entry',
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var row in [
                          ['1', '2', '3'],
                          ['4', '5', '6'],
                          ['7', '8', '9'],
                          [' ', '0', '⌫']
                        ])
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: row.map((key) {
                              if (key == ' ') {
                                return const SizedBox(width: 90); // Increased spacing for larger buttons
                              } else if (key == '⌫') {
                                return _buildKeyButton(const Icon(Icons.backspace_outlined, size: 30), _onDeletePressed);
                              } else {
                                return _buildKeyButton(Text(key, style: const TextStyle(fontSize: 30)), () => _onKeyPressed(key));
                              }
                            }).toList(),
                          ),
                      ],
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

  Widget _buildOtpField(int index) {
    return Container(
      width: 50,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _focusNodes[index].hasFocus 
              ? const Color(0xFF0C5FB3) 
              : _controllers[index].text.isNotEmpty 
                  ? const Color.fromRGBO(128, 128, 128, 0.5)
                  : const Color.fromRGBO(128, 128, 128, 0.3),
          width: _focusNodes[index].hasFocus ? 2 : 1,
        ),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.none,
        showCursor: false,
        maxLength: 1,
        onChanged: (value) {
          if (value.length == 1 && index < 4) {
            FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
          }
        },
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildKeyButton(Widget child, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), // Increased padding for larger spacing
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50), // Slightly larger radius for bigger buttons
        elevation: 2,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 80, // Increased width
            height: 80, // Increased height
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}