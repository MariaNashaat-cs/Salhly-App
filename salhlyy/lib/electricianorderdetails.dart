import 'package:flutter/material.dart';
import 'chat.dart';
import 'trackorder.dart';
import 'homepage.dart';
import 'refund.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'dart:async';

class Electricianorderdetails extends StatefulWidget {
  final String username;
  final String paymentMethod;
  final String phoneNumber;
  final double totalAmount;
  final String orderId;

  const Electricianorderdetails({
    super.key,
    required this.username,
    required this.paymentMethod,
    required this.phoneNumber,
    required this.totalAmount,
    required this.orderId,
  });

  @override
  State<Electricianorderdetails> createState() => _OrderDetailsLayoutState();
}

class _OrderDetailsLayoutState extends State<Electricianorderdetails> with SingleTickerProviderStateMixin {
  String _fullName = '';
  String _address = '';
  String _appointmentDate = "March 12, 2025";
  String _appointmentTime = "2:00 PM - 4:00 PM";
  String _orderStatus = "In Progress";
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  bool _isInitialized = false;
  bool _isLoading = true;
  String _errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  StreamSubscription? _orderStatusSubscription;

  final List<String> _cancellationReasons = [
    'Changed my mind',
    'Issue was resolved',
    'Found another service provider',
    'Scheduling conflict',
    'Too expensive',
    'Booking was made by mistake',
    'Service provider is not responding',
    'Need to reschedule',
    'Emergency — need to cancel',
    'Other (please specify)'
  ];

  String? _selectedReason;
  String? _otherReason;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _initializeAndFetch();
    debugPrint('Payment method initialized: ${widget.paymentMethod}');
  }

  @override
  void dispose() {
    _animationController.dispose();
    _orderStatusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeAndFetch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _initializeFirebase();
      await _fetchUserData();
      await _fetchOrderStatus();
      _animationController.forward();
      _setupOrderStatusListener();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeFirebase() async {
    try {
      if (!_isInitialized) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        _isInitialized = true;
      }
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
      throw Exception('Failed to initialize Firebase');
    }
  }

  Future<void> _fetchOrderStatus() async {
    try {
      final snapshot = await _database
          .child('serviceRequests')
          .child(widget.orderId)
          .get();

      if (snapshot.exists) {
        final orderData = snapshot.value as Map<dynamic, dynamic>;
        final status = orderData['status'] as String?;
        
        if (status != null && status.isNotEmpty) {
          setState(() {
            _orderStatus = status;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching order status: $e');
    }
  }

  void _setupOrderStatusListener() {
    _orderStatusSubscription = _database
        .child('serviceRequests')
        .child(widget.orderId)
        .child('status')
        .onValue
        .listen((event) {
      if (mounted && event.snapshot.value != null) {
        setState(() {
          _orderStatus = event.snapshot.value as String;
        });
      }
    });
  }

  Future<void> _fetchUserData() async {
    try {
      debugPrint('Fetching user data for phone number: ${widget.phoneNumber}');

      if (widget.phoneNumber.isNotEmpty) {
        final snapshot = await _database
            .child('users')
            .child(widget.phoneNumber)
            .get();

        if (snapshot.exists) {
          final userData = snapshot.value as Map<dynamic, dynamic>;
          final fullName = userData['fullName'] as String?;

          // Get selected address
          final selectedAddress = userData['selectedAddress'] as String?;
          if (selectedAddress != null && selectedAddress.isNotEmpty) {
            setState(() {
              _address = selectedAddress;
            });
          }

          // Get current electrician appointment data
          if (userData['current_electrician_appointment'] != null) {
            final appointmentData = userData['current_electrician_appointment'] as Map<dynamic, dynamic>;
            setState(() {
              _appointmentDate = appointmentData['formattedDate'] as String;
              _appointmentTime = appointmentData['formattedTime'] as String;
            });
          }

          debugPrint('Retrieved full name: $fullName');
          debugPrint('Retrieved address: $_address');
          debugPrint('Retrieved appointment date: $_appointmentDate');
          debugPrint('Retrieved appointment time: $_appointmentTime');

          if (fullName != null && fullName.isNotEmpty) {
            setState(() {
              _fullName = fullName;
            });
          }
        } else {
          debugPrint('No user data found for phone number: ${widget.phoneNumber}');
        }
      } else {
        debugPrint('Phone number is empty');
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      throw Exception('Failed to fetch user data');
    }
  }


  Future<void> _updateServiceRequestStatus(String orderId, String newStatus) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      await _database
          .child('serviceRequests')
          .child(orderId)
          .update({
        'status': newStatus,
        'updatedAt': ServerValue.timestamp,
      });

      await _database
          .child('users')
          .child(widget.phoneNumber)
          .child('orders')
          .child(orderId)
          .update({
        'status': newStatus,
        'updatedAt': ServerValue.timestamp,
      });
      
      setState(() {
        _orderStatus = newStatus;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to update status: ${e.toString()}';
      });
      debugPrint('Error updating service request status: $e');
    }
  }

  void _showCancelConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.cancel_outlined, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  const Text('Cancel Request'),
                ],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Please select a reason for cancellation:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    ..._cancellationReasons.map((reason) {
                      return RadioListTile<String>(
                        title: Text(reason),
                        value: reason,
                        groupValue: _selectedReason,
                        onChanged: (String? value) {
                          setState(() {
                            _selectedReason = value;
                            if (value != 'Other (please specify)') {
                              _otherReason = null;
                            }
                          });
                        },
                        activeColor: const Color(0xFF0C5FB3),
                        dense: true,
                      );
                    }),
                    if (_selectedReason == 'Other (please specify)')
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 8, right: 16),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Please specify your reason',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF0C5FB3), width: 2),
                            ),
                          ),
                          onChanged: (value) {
                            _otherReason = value;
                          },
                          maxLines: 3,
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Back',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_selectedReason == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a reason for cancellation'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (_selectedReason == 'Other (please specify)' && (_otherReason == null || _otherReason!.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please specify your reason'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);
                    final reason = _selectedReason == 'Other (please specify)' ? _otherReason : _selectedReason;

                    // Update status and save cancellation reason
                    await _updateServiceRequestStatus(widget.orderId, 'canceled');
                    await _database
                        .child('serviceRequests')
                        .child(widget.orderId)
                        .update({
                      'cancellationReason': reason,
                    });

                    // Debug payment method
                    debugPrint('Payment method for navigation: ${widget.paymentMethod}');

                    // Navigate to RefundPage for card payments
                    if (widget.paymentMethod.toLowerCase().contains('card') ||
                        widget.paymentMethod.toLowerCase().contains('visa') ||
                        widget.paymentMethod.toLowerCase().contains('credit') ||
                        widget.paymentMethod.toLowerCase().contains('debit')) {
                      debugPrint('Navigating to RefundPage');
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => RefundPage(
                            totalAmount: "${widget.totalAmount.toStringAsFixed(1)} L.E",
                            userId: widget.phoneNumber,
                            fullName: _fullName,
                            phoneNumber: widget.phoneNumber,
                          ),
                        ),
                      );
                    } else {
                      debugPrint('No navigation to RefundPage: payment method is ${widget.paymentMethod}');
                    }

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 10),
                            Text('Service request has been canceled'),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C5FB3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Confirm Cancellation'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading 
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF0C5FB3)),
                SizedBox(height: 16),
                Text('Loading order details...'),
              ],
            ),
          )
        : _errorMessage.isNotEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red[700]),
                    const SizedBox(height: 16),
                    Text(
                      'Error',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red[700]),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _initializeAndFetch,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C5FB3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : FadeTransition(
                opacity: _fadeAnimation,
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 140),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  UserInfoComponent(
                                    name: _fullName.isNotEmpty ? _fullName : widget.username,
                                    phoneNumber: widget.phoneNumber,
                                    address: _address.isNotEmpty ? _address : "123 Main St, Cairo, Egypt",
                                  ),
                                  const SizedBox(height: 20),
                                  RequestInfoComponent(
                                    serviceType: "Electrical Repair",
                                    status: _orderStatus,
                                    appointmentDate: _appointmentDate,
                                    appointmentTime: _appointmentTime,
                                    paymentAmount: "${widget.totalAmount.toStringAsFixed(1)} L.E",
                                    paymentMethod: widget.paymentMethod,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(right: 6),
                                                child: ElevatedButton.icon(
                                                  onPressed: _orderStatus == 'canceled' ? null : () {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (context) => OrderTrackingScreen(
                                                          fullName: _fullName,
                                                          phoneNumber: widget.phoneNumber,
                                                          orderId: widget.orderId,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  icon: const Icon(Icons.location_on, size: 20),
                                                  label: const Text('Track Order'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF0C5FB3).withOpacity(0.8),
                                                    disabledBackgroundColor: Colors.grey[400],
                                                    foregroundColor: Colors.white,
                                                    disabledForegroundColor: Colors.white70,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(20.0),
                                                    ),
                                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(left: 6),
                                                child: ElevatedButton.icon(
                                                  onPressed: _orderStatus == 'canceled' ? null : () {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (context) => ChatApp(phoneNumber: widget.phoneNumber),
                                                      ),
                                                    );
                                                  },
                                                  icon: const Icon(Icons.chat, size: 20),
                                                  label: const Text('Chat with Electrician'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF0C5FB3).withOpacity(0.8),
                                                    disabledBackgroundColor: Colors.grey[400],
                                                    foregroundColor: Colors.white,
                                                    disabledForegroundColor: Colors.white70,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(20.0),
                                                    ),
                                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (_orderStatus != 'canceled')
                                          Padding(
                                            padding: const EdgeInsets.only(top: 12),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  width: MediaQuery.of(context).size.width * 0.45,
                                                  child: ElevatedButton.icon(
                                                    onPressed: _showCancelConfirmationDialog,
                                                    icon: const Icon(Icons.cancel, size: 20),
                                                    label: const Text('Cancel Order'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: const Color(0xFF0C5FB3).withOpacity(0.8),
                                                      foregroundColor: Colors.white,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(20.0),
                                                      ),
                                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                                    ),
                                                  ),
                                                ),
                                              ],
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
                        ],
                      ),
                    ),
                    Positioned(
                      top: 60,
                      left: 20,
                      child: Row(
                        children: [
                          HeaderComponent(
                            username: widget.username,
                            phoneNumber: widget.phoneNumber,
                            fullName: _fullName,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Order Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0C5FB3).withOpacity(0.9),
                              fontFamily: 'Playfair_Display',
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

class HeaderComponent extends StatelessWidget {
  final double width;
  final double height;
  final Color backgroundColor;
  final String username;
  final String phoneNumber;
  final String fullName;

  const HeaderComponent({
    super.key,
    this.width = 60.0,
    this.height = 58.0,
    this.backgroundColor = const Color(0xFF0C5FB3),
    required this.username,
    required this.phoneNumber,
    required this.fullName,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'homeButton',
      child: Container(
        constraints: BoxConstraints(minWidth: width),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(
                    fullName: username,
                    phoneNumber: phoneNumber,
                  ),
                ),
              );
            },
            child: const Center(
              child: Icon(
                Icons.home,
                size: 32,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UserInfoComponent extends StatelessWidget {
  final String name;
  final String address;
  final String phoneNumber;

  const UserInfoComponent({
    super.key,
    required this.name,
    required this.address,
    required this.phoneNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C5FB3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person, color: Color(0xFF0C5FB3)),
              ),
              const SizedBox(width: 12),
              Text(
                'Customer Information',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Playfair_Display',
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0C5FB3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.account_circle, 'Name', name),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.phone, 'Phone', phoneNumber),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on, 'Address', address),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StatusIndicator extends StatelessWidget {
  final String status;

  const StatusIndicator({super.key, required this.status});

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'in progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'canceled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (status.toLowerCase()) {
      case 'in progress':
        return Icons.autorenew;
      case 'completed':
        return Icons.check_circle;
      case 'canceled':
        return Icons.cancel;
      case 'pending':
        return Icons.hourglass_top;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: 16,
            color: _getStatusColor(),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(),
            ),
          ),
        ],
      ),
    );
  }
}

class RequestInfoComponent extends StatelessWidget {
  final String serviceType;
  final String status;
  final String appointmentDate;
  final String appointmentTime;
  final String paymentAmount;
  final String paymentMethod;

  const RequestInfoComponent({
    super.key,
    this.serviceType = "Electrical Repair",
    this.status = "In Progress",
    required this.appointmentDate,
    required this.appointmentTime,
    required this.paymentAmount,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C5FB3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.electrical_services, color: Color(0xFF0C5FB3)),
              ),
              const SizedBox(width: 12),
              Text(
                'Service Request Details',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Playfair_Display',
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0C5FB3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildServiceRow('Service Type', serviceType, Icons.electrical_services),
          const Divider(height: 24),
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  StatusIndicator(status: status),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          _buildServiceRow('Appointment Date', appointmentDate, Icons.calendar_today),
          const Divider(height: 24),
          _buildServiceRow('Appointment Time', appointmentTime, Icons.access_time),
          const Divider(height: 24),
          _buildServiceRow('Payment Amount', paymentAmount, Icons.attach_money),
          const Divider(height: 24),
          _buildPaymentMethodRow(paymentMethod.toUpperCase(), Icons.payment),
        ],
      ),
    );
  }

  Widget _buildServiceRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodRow(String value, IconData icon) {
    IconData methodIcon;
    Color iconColor;
    
    if (value.toLowerCase() == 'card') {
      methodIcon = Icons.credit_card;
      iconColor = Colors.indigo;
    } else if (value.toLowerCase() == 'cash') {
      methodIcon = Icons.money;
      iconColor = Colors.green[700]!;
    } else {
      methodIcon = Icons.payment;
      iconColor = Colors.blue;
    }
    
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(methodIcon, size: 18, color: iconColor),
                const SizedBox(width: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}