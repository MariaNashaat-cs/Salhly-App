import 'package:flutter/material.dart';
import 'main.dart';

class FixerHomePage extends StatelessWidget {
  const FixerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEEEC),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon or Image
              const Icon(
                Icons.phone_in_talk,
                size: 100,
                color: Color(0xFF0C5FB3),
              ),
              const SizedBox(height: 30),
              
              // Main Message
              const Text(
                'We will call you soon',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C303C),
                ),
              ),
              const SizedBox(height: 20),
              
              // Subtitle
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Our team will be in touch shortly to discuss your inquiry and evaluate your documents.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0x99000000),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              
              // Home Button
              ElevatedButton(
                onPressed: () {
                   Navigator.pushReplacement(
                     context,
                    MaterialPageRoute(builder: (context) => const SignupScreen()),
                   );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C5FB3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  minimumSize: const Size(200, 50),
                ),
                child: const Text(
                  'Back to Signup',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Playfair_Display',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}