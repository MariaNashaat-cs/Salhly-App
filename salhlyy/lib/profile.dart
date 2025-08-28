import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'homepage.dart';

class ProfilePage extends StatefulWidget {
  final String phoneNumber;
  const ProfilePage({super.key, required this.phoneNumber});

  @override
  // ignore: library_private_types_in_public_api
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _selectedGender = '';
  String? _selectedGovernorate;
  bool _isSubmitting = false;
  bool _isDatabaseInitialized = false;

  // Firebase Realtime Database reference
  DatabaseReference? _databaseReference;

  // Animation variables
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // App theme colors
  final Color _primaryColor = const Color(0xFF0C5FB3);
  final Color _backgroundColor = const Color(0xFFF9FAFC);
  final Color _errorColor = const Color(0xFFE53935);

  // List of governorates
  static const List<String> _governorates = [
    'Cairo',
    'Giza',
    'Alexandria',
    'Sharqia',
    'Dakahlia',
    'Beheira',
    'Gharbia',
    'Monufia',
    'Qalyubia',
    'Damietta',
    'Port Said',
    'Ismailia',
    'Suez',
    'Kafr El Sheikh',
    'Faiyum',
    'Beni Suef',
    'Minya',
    'Asyut',
    'Sohag',
    'Qena',
    'Luxor',
    'Aswan',
    'Red Sea',
    'New Valley',
    'Matrouh',
    'North Sinai',
    'South Sinai',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateFormState);
    _emailController.addListener(_updateFormState);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      String sanitizedPhoneNumber = widget.phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
      _databaseReference = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(sanitizedPhoneNumber);

      setState(() {
        _isDatabaseInitialized = true;
      });
    } catch (e) {
      setState(() {
        _isDatabaseInitialized = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize database: $e'),
            backgroundColor: _errorColor,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updateFormState() {
    setState(() {});
  }

  void _selectGender(String gender) {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    setState(() {
      _selectedGender = gender;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }

    if (!_isDatabaseInitialized || _databaseReference == null || _selectedGender.isEmpty || _selectedGovernorate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all fields and ensure database is initialized.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      print('Submitting data: ${_nameController.text}, $_selectedGender, $_selectedGovernorate');
      await _databaseReference!.update({
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'gender': _selectedGender,
        'governorate': _selectedGovernorate,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              fullName: _nameController.text.trim(),
              phoneNumber: widget.phoneNumber,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error during submission: $e');
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create profile: $e'),
            backgroundColor: _errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 360;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Create Profile',
          style: TextStyle(
            fontFamily: 'Playfair_Display',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: _primaryColor,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.05,
              vertical: size.height * 0.02,
            ),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: _isDatabaseInitialized
                    ? Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Choose Your Avatar',
                              style: TextStyle(
                                fontFamily: 'Playfair_Display',
                                fontSize: isSmallScreen ? 22 : 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildAvatarOption('Male', 'images/images/man.png'),
                                const SizedBox(width: 20),
                                _buildAvatarOption('Female', 'images/images/woman.png'),
                              ],
                            ),
                            const SizedBox(height: 30),
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey[300])),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'Personal Information',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.grey[300])),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildInputLabel('Full Name'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _nameController,
                              hintText: 'Enter your full name',
                              prefixIcon: Icons.person_outline,
                              focusNode: _nameFocus,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Name is required';
                                final RegExp nameRegex = RegExp(r'^[a-zA-Z\s]+$');
                                if (!nameRegex.hasMatch(value)) return 'Name should contain only letters';
                                final nameParts = value.split(' ').where((part) => part.isNotEmpty).toList();
                                if (nameParts.length < 2) return 'Please enter your full name';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildInputLabel('E-mail'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _emailController,
                              hintText: 'Enter your email',
                              prefixIcon: Icons.email_outlined,
                              focusNode: _emailFocus,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Email is required';
                                final RegExp emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                                if (!emailRegex.hasMatch(value)) return 'Please enter a valid email address';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildInputLabel('Governorate'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedGovernorate,
                              hint: const Text('Select your governorate'),
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.location_on_outlined, color: Colors.grey[600]),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: _primaryColor, width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: _errorColor, width: 1),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: _errorColor, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                                errorStyle: TextStyle(color: _errorColor),
                              ),
                              items: _governorates.map((String governorate) {
                                return DropdownMenuItem<String>(
                                  value: governorate,
                                  child: Text(governorate),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedGovernorate = newValue;
                                });
                              },
                              validator: (value) => value == null ? 'Please select a governorate' : null,
                            ),
                            const SizedBox(height: 20),
                            _buildInputLabel('Gender'),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildGenderChip('Male'),
                                const SizedBox(width: 16),
                                _buildGenderChip('Female'),
                              ],
                            ),
                            const SizedBox(height: 36),
                            SizedBox(
                              width: size.width * 0.6,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isSubmitting || _selectedGender.isEmpty || _selectedGovernorate == null || !_isDatabaseInitialized
                                    ? null
                                    : _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.0,
                                        ),
                                      )
                                    : const Text(
                                        'Continue',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      )
                    : const Center(
                        child: CircularProgressIndicator(),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarOption(String gender, String imagePath) {
    final bool isSelected = _selectedGender == gender;

    return GestureDetector(
      onTap: () => _selectGender(gender),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: isSelected ? _scaleAnimation.value : 1.0,
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? _primaryColor : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        // ignore: deprecated_member_use
                        backgroundColor: isSelected ? _primaryColor.withOpacity(0.2) : Colors.grey[200],
                        child: ClipOval(
                          child: Image.asset(
                            imagePath,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            Icons.check_circle,
                            color: _primaryColor,
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  gender,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? _primaryColor : Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    FocusNode? focusNode,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: Colors.grey[600]),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _errorColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[100],
        errorStyle: TextStyle(color: _errorColor),
      ),
      onChanged: (value) {
        setState(() {}); // Update state on every change to re-enable/disable button
      },
    );
  }

  Widget _buildGenderChip(String gender) {
    final bool isSelected = _selectedGender == gender;
    return InkWell(
      onTap: () => _selectGender(gender),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: _primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              gender == 'Male' ? Icons.male : Icons.female,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              gender,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}