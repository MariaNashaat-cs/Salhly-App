import 'package:flutter/material.dart';
import 'dart:async';
import 'rating.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String fullName;
  final String phoneNumber;
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.fullName,
    required this.phoneNumber,
    required this.orderId,
  });

  @override
  _OrderTrackingScreenState createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with SingleTickerProviderStateMixin {
  int currentStep = 0;
  final int totalSteps = 4;
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  final List<Map<String, dynamic>> trackingSteps = [
    {
      'icon': Icons.access_time_rounded,
      'title': 'Order Confirmed',
      'description': 'Your order has been received and is being processed',
      'color': const Color(0xFF4E97FD),
    },
    {
      'icon': Icons.delivery_dining_rounded,
      'title': 'On the Way',
      'description': 'Your fixer is on the way to your location',
      'color': const Color(0xFF4E97FD),
    },
    {
      'icon': Icons.location_on_rounded,
      'title': 'Nearby',
      'description': 'Your fixer is nearby. Please prepare for the service',
      'color': const Color(0xFF4E97FD),
    },
    {
      'icon': Icons.check_circle_rounded,
      'title': 'Completed',
      'description': 'Your service is complete. Thank you!',
      'color': const Color(0xFF4E97FD),
    },
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _progressAnimation = Tween<double>(
      begin: 0,
      end: (currentStep + 1) / totalSteps,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _updateServiceRequestStatus() async {
    try {
      await _database
          .child('serviceRequests')
          .child(widget.orderId)
          .update({
        'status': 'completed',
        'completedAt': ServerValue.timestamp,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service request completed successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating service request: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _cancelServiceRequest() async {
    try {
      await _database
          .child('serviceRequests')
          .child(widget.orderId)
          .update({
        'status': 'cancelled',
        'cancelledAt': ServerValue.timestamp,
      });

      _timer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service request cancelled successfully'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling service request: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (currentStep < totalSteps - 1) {
        setState(() {
          currentStep++;
          _progressAnimation = Tween<double>(
            begin: _progressAnimation.value,
            end: (currentStep + 1) / totalSteps,
          ).animate(CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ));
          _animationController.reset();
          _animationController.forward();

          if (currentStep == totalSteps - 1) {
            _updateServiceRequestStatus();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _makePhoneCall() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: widget.phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch phone call'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showCancelConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Service'),
        content: const Text('Are you sure you want to cancel this service request?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No', style: TextStyle(color: Color(0xFF666666))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelServiceRequest();
            },
            child: const Text('Yes', style: TextStyle(color: Color(0xFF0C5FB3))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.035;
    final iconSize = screenWidth * 0.055;
    final progressCircleSize = screenWidth * 0.32;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF0C5FB3), size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Track Your Service',
          style: TextStyle(
            fontFamily: 'Playfair_Display',
            fontSize: screenWidth * 0.042,
            color: const Color(0xFF0C5FB3),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    // Order ID, status, and call button card
                    Container(
                      margin: EdgeInsets.all(padding),
                      padding: EdgeInsets.all(padding),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Order #${widget.orderId}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: screenWidth * 0.037,
                                  color: const Color(0xFF333333),
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: padding * 0.8,
                                      vertical: padding * 0.4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE6F2FF),
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: Text(
                                      'In Progress',
                                      style: TextStyle(
                                        color: const Color(0xFF0C5FB3),
                                        fontWeight: FontWeight.w500,
                                        fontSize: screenWidth * 0.032,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: padding * 0.5),
                                  IconButton(
                                    icon: Icon(
                                      Icons.phone,
                                      color: const Color(0xFF0C5FB3),
                                      size: iconSize * 0.8,
                                    ),
                                    onPressed: _makePhoneCall,
                                    tooltip: 'Call Electrician',
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: padding * 0.9),
                          Row(
                            children: [
                              Icon(Icons.av_timer,
                                  color: const Color(0xFF0C5FB3),
                                  size: iconSize),
                              SizedBox(width: padding * 0.5),
                              Text(
                                'Estimated Arrival:',
                                style: TextStyle(
                                  color: const Color(0xFF666666),
                                  fontSize: screenWidth * 0.032,
                                ),
                              ),
                              SizedBox(width: padding * 0.3),
                              Text(
                                '10:45 AM',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF333333),
                                  fontSize: screenWidth * 0.032,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Progress circle
                    Container(
                      padding: EdgeInsets.all(padding * 1.3),
                      margin: EdgeInsets.symmetric(horizontal: padding),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, child) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: progressCircleSize,
                                    height: progressCircleSize,
                                    child: CircularProgressIndicator(
                                      value: _progressAnimation.value,
                                      strokeWidth: 6,
                                      backgroundColor: const Color(0xFFE6E7E9),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                              Color(0xFF0C5FB3)),
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        '${(_progressAnimation.value * 100).toInt()}%',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.052,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0C5FB3),
                                        ),
                                      ),
                                      Text(
                                        'Completed',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.037,
                                          color: const Color(0xFF666666),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                          SizedBox(height: padding * 1.3),
                          Text(
                            trackingSteps[currentStep]['description'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: screenWidth * 0.037,
                              color: const Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tracking steps timeline
                    Container(
                      height: screenHeight * 0.32,
                      margin: EdgeInsets.all(padding),
                      padding: EdgeInsets.all(padding),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        itemCount: trackingSteps.length,
                        itemBuilder: (context, index) {
                          final isActive = index <= currentStep;
                          final isLast = index == trackingSteps.length - 1;

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: iconSize,
                                    height: iconSize,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? const Color(0xFF0C5FB3)
                                          : const Color(0xFFE6E7E9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      trackingSteps[index]['icon'],
                                      color: isActive
                                          ? Colors.white
                                          : const Color(0xFF999999),
                                      size: iconSize * 0.6,
                                    ),
                                  ),
                                  if (!isLast)
                                    Container(
                                      width: 1.5,
                                      height: 22,
                                      color: isActive && index < currentStep
                                          ? const Color(0xFF0C5FB3)
                                          : const Color(0xFFE6E7E9),
                                    ),
                                ],
                              ),
                              SizedBox(width: padding * 0.9),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      trackingSteps[index]['title'],
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.037,
                                        fontWeight: FontWeight.bold,
                                        color: isActive
                                            ? const Color(0xFF333333)
                                            : const Color(0xFF999999),
                                      ),
                                    ),
                                    SizedBox(height: padding * 0.3),
                                    Text(
                                      trackingSteps[index]['description'],
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.032,
                                        color: isActive
                                            ? const Color(0xFF666666)
                                            : const Color(0xFF999999),
                                      ),
                                    ),
                                    SizedBox(height: padding * 0.7),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // Cancel button (visible when not completed)
                    if (currentStep < totalSteps - 1)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: padding,
                          vertical: padding * 0.5,
                        ),
                        child: ElevatedButton(
                          onPressed: _showCancelConfirmationDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: padding * 0.9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                            minimumSize: Size(double.infinity, screenWidth * 0.11),
                            elevation: 0,
                          ),
                          child: Text(
                            'Cancel Service',
                            style: TextStyle(
                              fontSize: screenWidth * 0.037,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    // Finish order button
                    if (currentStep == totalSteps - 1)
                      Padding(
                        padding: EdgeInsets.all(padding),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RatingScreen(
                                  fullName: widget.fullName,
                                  phoneNumber: widget.phoneNumber,
                                  orderId: widget.orderId,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0C5FB3),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: padding * 0.9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                            minimumSize: Size(double.infinity, screenWidth * 0.11),
                            elevation: 0,
                          ),
                          child: Text(
                            'Finish Service',
                            style: TextStyle(
                              fontSize: screenWidth * 0.037,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}