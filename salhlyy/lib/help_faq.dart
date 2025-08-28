import 'package:flutter/material.dart';
import 'contactus.dart';

class HelpFAQPage extends StatelessWidget {
  const HelpFAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & FAQs'),
        backgroundColor: const Color(0xFF0C5FB3),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontFamily: 'Playfair_Display',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C303C),
                ),
              ),
              const SizedBox(height: 24),
              _buildFAQItem(
                'How do I book a service?',
                'To book a service, simply select the service category you need, choose the specific service, and follow the booking process. You can select multiple services if needed.',
              ),
              _buildFAQItem(
                'How are service prices determined?',
                'Service prices are based on the type of service, complexity, and materials required. You\'ll see the estimated price range before confirming your booking.',
              ),
              _buildFAQItem(
                'Can I cancel or reschedule my booking?',
                'Yes, you can cancel or reschedule your booking up to 2 hours before the scheduled time. Go to your bookings section to make changes.',
              ),
              _buildFAQItem(
                'How do I pay for services?',
                'You can pay through the app using various payment methods including credit/debit cards, digital wallets, or cash on delivery.',
              ),
              _buildFAQItem(
                'What if I\'m not satisfied with the service?',
                'If you\'re not satisfied with the service, please contact our customer support within 24 hours. We\'ll work to resolve the issue or provide a refund if appropriate.',
              ),
              _buildFAQItem(
                'How do I become a service provider?',
                'To become a service provider, go to the "Be a Fixer" section in the app menu and follow the registration process. You\'ll need to provide necessary documents and information.',
              ),
              const SizedBox(height: 24),
              const Text(
                'Still need help?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C303C),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ContactUsPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C5FB3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Contact Support'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C303C),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              answer,
              style: const TextStyle(
                color: Color(0x99000000),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}