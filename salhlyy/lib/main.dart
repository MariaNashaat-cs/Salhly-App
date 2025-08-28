import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'homepage.dart'; // Import HomePage
import 'verification.dart'; // Assuming this exists
import 'admin_dashboard.dart'; // Import AdminDashboardPage
import 'fixerinfo.dart';

// Define app theme colors for consistency
class AppTheme {
  static const Color primaryColor = Color(0xFF0C5FB3);
  static const Color primaryColorLight = Color(0x990C5FB3);
  static const Color secondaryColor = Color(0xFF1A446E);
  static const Color backgroundColor = Color(0xFFEFEEEC);
  static const Color textDark = Color(0xFF2C303C);
  static const Color textLight = Color(0x99000000);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppTheme.primaryColor,
        scaffoldBackgroundColor: AppTheme.backgroundColor,
        fontFamily: 'Roboto',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            minimumSize: const Size(324, 51),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _subtitleAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..forward();

    _bounceAnimation = Tween<double>(begin: -200.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.7, curve: Curves.easeInOut),
      ),
    );

    _subtitleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 0.9, curve: Curves.easeInOut),
      ),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.linear),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 300), () {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const SignupScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF042749), AppTheme.primaryColor],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _bounceAnimation.value),
                            child: Text(
                              'S',
                              style: TextStyle(
                                fontSize: 150,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 15,
                                    offset: const Offset(2, 2),
                                  ),
                                  Shadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 5,
                                    offset: const Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _textAnimation.value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - _textAnimation.value)),
                              child: const Text(
                                'One Click, One Fix',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                  fontFamily: 'Playfair_Display',
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _subtitleAnimation.value,
                            child: Transform.translate(
                              offset: Offset(0, 15 * (1 - _subtitleAnimation.value)),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                                child: Text(
                                  'Your home repair solution',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                    child: LinearProgressIndicator(
                      value: _progressAnimation.value,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPhoneValid = false;
  bool _isLoading = false;

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  String selectedCountryCode = "+20"; // Default Egypt
  String selectedCountryName = "Egypt";
  String fullPhoneNumber = "";

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validatePhoneNumber);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validatePhoneNumber() {
    setState(() {
      String phoneNumber = _phoneController.text.trim();
      if (selectedCountryCode == "+20") {
        _isPhoneValid = phoneNumber.length == 11 &&
            RegExp(r'^01[0125][0-9]{8}$').hasMatch(phoneNumber);
      } else {
        _isPhoneValid = phoneNumber.length >= 7 && phoneNumber.length <= 15 &&
            RegExp(r'^[0-9]+$').hasMatch(phoneNumber);
      }
    });
  }

  Future<void> _storePhoneNumber(String phoneNumber) async {
    try {
      setState(() => _isLoading = true);
      await _database.child('users').child(phoneNumber).set({
        'phoneNumber': phoneNumber,
        'countryCode': selectedCountryCode,
        'countryName': selectedCountryName,
        'timestamp': ServerValue.timestamp,
        'verified': false,
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerificationScreen(phoneNumber: phoneNumber),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Error storing phone number: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> validateAndProceed() async {
    final phoneNumber = _phoneController.text.trim();
    bool isValid = false;

    if (selectedCountryCode.isEmpty) {
      _showErrorSnackBar('Please select a country code.');
      return;
    }

    if (phoneNumber.isEmpty) {
      _showErrorSnackBar('Phone number cannot be empty.');
      return;
    }

    if (selectedCountryCode == "+20") {
      isValid = phoneNumber.length == 11 && RegExp(r'^01[0125][0-9]{8}$').hasMatch(phoneNumber);
    } else {
      isValid = phoneNumber.length >= 7 &&
          phoneNumber.length <= 15 &&
          RegExp(r'^[0-9]+$').hasMatch(phoneNumber);
    }

    setState(() {
      _isPhoneValid = isValid;
    });

    if (isValid) {
      final fullPhoneNumber = "$selectedCountryCode$phoneNumber";

      // Check if it's the admin number
      if (phoneNumber == '01111111111') {
        _showPasswordDialog();
        return;
      }

      try {
        setState(() => _isLoading = true);
        final snapshot = await _database.child('users').child(fullPhoneNumber).get();

        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          final fullName = data['fullName'] as String? ?? 'User';
          _showSuccessSnackBar('Welcome back, $fullName!');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(
                fullName: fullName,
                phoneNumber: fullPhoneNumber,
              ),
            ),
          );
          return;
        } else {
          await _storePhoneNumber(fullPhoneNumber);
          _showSuccessSnackBar('New number stored! Proceed to verification.');
        }
      } catch (e) {
        _showErrorSnackBar('Error checking phone number: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      String errorMessage = selectedCountryCode == "+20"
          ? 'Please enter a valid Egyptian phone number starting with 010, 011, 012, or 015 (11 digits).'
          : 'Please enter a valid phone number (7–15 digits, numbers only).';
      _showErrorSnackBar(errorMessage);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      if (!await launchUrl(Uri.parse(url))) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      _showErrorSnackBar('Could not open link: $e');
    }
  }

  void _showPasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Admin Access Required'),
        content: TextField(
          controller: _passwordController,
          decoration: const InputDecoration(
            labelText: 'Enter Admin Password',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_passwordController.text == '3absomaria') {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid password')),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: 280,
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage('https://dashboard.codeparrot.ai/api/image/Z6qBwPrycnbNR_nN/group-18.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to Salحly',
                      style: TextStyle(
                        fontFamily: 'Playfair_Display',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please enter your mobile number to verify your account.',
                      style: TextStyle(
                        fontFamily: 'Playfair_Display',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withOpacity(0.6),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text(
                          'Mobile Number:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                        ),
                        const Spacer(),
                        Text(
                          'Required',
                          style: TextStyle(fontSize: 14, color: AppTheme.primaryColor, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    IntlPhoneField(
                      controller: _phoneController,
                      initialCountryCode: 'EG', // Set Egypt as default
                      disableLengthCheck: true, // Disable built-in length validation
                      decoration: InputDecoration(
                        hintText: 'Enter your phone number',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _phoneController.text.isEmpty
                                ? Colors.grey.shade300
                                : _isPhoneValid
                                    ? Colors.green
                                    : Colors.red.shade300,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _phoneController.text.isEmpty
                                ? Colors.grey.shade300
                                : _isPhoneValid
                                    ? Colors.green
                                    : Colors.red.shade300,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _isPhoneValid ? Colors.green : AppTheme.primaryColor,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(15),
                        counterText: '', // Hide character counter
                        suffixIcon: _phoneController.text.isNotEmpty
                            ? Icon(
                                _isPhoneValid ? Icons.check_circle : Icons.error,
                                color: _isPhoneValid ? Colors.green : Colors.red.shade300,
                              )
                            : null,
                      ),
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(selectedCountryCode == "+20" ? 11 : 15),
                      ],
                      onChanged: (phone) {
                        setState(() {
                          selectedCountryCode = phone.countryCode;
                          selectedCountryName = phone.countryISOCode;
                          fullPhoneNumber = phone.completeNumber;
                        });
                        _validatePhoneNumber();
                      },
                      onCountryChanged: (country) {
                        setState(() {
                          selectedCountryCode = '+${country.dialCode}';
                          selectedCountryName = country.name;
                          // Clear phone number when country changes to avoid invalid input
                          _phoneController.clear();
                          _isPhoneValid = false;
                        });
                        _validatePhoneNumber();
                      },
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      keyboardType: TextInputType.phone,
                      dropdownIcon: const Icon(Icons.arrow_drop_down),
                      dropdownTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      textInputAction: TextInputAction.done,
                      autovalidateMode: AutovalidateMode.disabled,
                      invalidNumberMessage: null, // Disable default error message
                    ),
                    if (_phoneController.text.isNotEmpty && !_isPhoneValid)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 5),
                        child: Text(
                          selectedCountryCode == "+20"
                              ? 'Please enter a valid Egyptian number (e.g., 01012345678)'
                              : 'Please enter a valid phone number (7–15 digits)',
                          style: TextStyle(fontSize: 12, color: Colors.red.shade400),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton(
                        onPressed: _isPhoneValid && !_isLoading ? validateAndProceed : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isPhoneValid ? AppTheme.primaryColor : Colors.grey.shade300,
                          disabledBackgroundColor: Colors.grey.shade300,
                          elevation: _isPhoneValid ? 2 : 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          minimumSize: const Size(324, 51),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                      color: _isPhoneValid ? Colors.white : Colors.grey.shade600,
                                    ),
                                  ),
                                  if (_isPhoneValid && !_isLoading)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                    ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.grey.shade300.withOpacity(0.1), Colors.grey.shade300],
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or', style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.grey.shade300, Colors.grey.shade300.withOpacity(0.1)],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: () => _launchUrl("https://www.icloud.com/"),
                        child: Container(
                          height: 51,
                          width: 324,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                'https://dashboard.codeparrot.ai/api/image/Z6qBwPrycnbNR_nN/8-ed-3-d-547.png',
                                width: 30,
                                height: 30,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Continue with Apple',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: GestureDetector(
                        onTap: () => _launchUrl("https://accounts.google.com/v3/signin/identifier"),
                        child: Container(
                          height: 51,
                          width: 324,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                'https://dashboard.codeparrot.ai/api/image/Z6qBwPrycnbNR_nN/download-2.png',
                                width: 30,
                                height: 30,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Continue with Google',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomePage(fullName: "Guest", phoneNumber: "guest"),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            width: double.infinity,
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Continue as a guest',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Icon(Icons.person_outline, size: 18, color: AppTheme.primaryColor),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => FixerInfo()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 1),
                            width: double.infinity,
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Be a fixer',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Icon(Icons.build_outlined, size: 18, color: AppTheme.primaryColor),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 