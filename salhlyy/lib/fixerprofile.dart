import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase Core
import 'package:firebase_database/firebase_database.dart'; // Firebase Realtime Database
import 'fixerhomepage.dart';
import 'main.dart';

class AppColors {
  static const Color primary = Color(0xFF0C5FB3);
  static const Color secondary = Color(0xFF3D82C6);
  static const Color accent = Color.fromARGB(255, 224, 37, 4);
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color textDark = Color(0xFF2D3142);
  static const Color textLight = Color(0xFF8D99AE);
  static const Color success = Colors.green;
  static const Color error = Colors.redAccent;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const Fixerprofile());
}

class Fixerprofile extends StatelessWidget {
  final String? role;
  final String? experience;
  final dynamic profileImage;
  final dynamic idImage;
  final dynamic criminalRecordImage;

  const Fixerprofile({
    super.key,
    this.role,
    this.experience,
    this.profileImage,
    this.idImage,
    this.criminalRecordImage,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fixer Profile',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
        ),
      ),
      home: ProfileommaPage(
        role: role,
        experience: experience,
        profileImage: profileImage,
        idImage: idImage,
        criminalRecordImage: criminalRecordImage,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ProfileommaPage extends StatefulWidget {
  final String? role;
  final String? experience;
  final dynamic profileImage;
  final dynamic idImage;
  final dynamic criminalRecordImage;

  const ProfileommaPage({
    super.key,
    this.role,
    this.experience,
    this.profileImage,
    this.idImage,
    this.criminalRecordImage,
  });

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfileommaPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Reference to the Firebase Realtime Database
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  // Check if the phone number already exists in the database
  Future<bool> _checkPhoneNumberExists(String phoneNumber) async {
    try {
      final snapshot = await _databaseReference
          .child('fixers')
          .orderByChild('phoneNumber')
          .equalTo(phoneNumber)
          .once();

      // Check if the snapshot has any data (i.e., phone number exists)
      return snapshot.snapshot.value != null;
    } catch (e) {
      print('Error checking phone number: $e');
      return false;
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Check if the phone number already exists
      bool phoneNumberExists = await _checkPhoneNumberExists(_phoneNumberController.text);

      if (phoneNumberExists) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Phone number already exists! Please use a different number.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        return; // Stop the save operation
      }

      try {
        // Generate a unique ID for the fixer
        String fixerId = _databaseReference.child('fixers').push().key!;

        // Prepare the data to be saved
        Map<String, dynamic> fixerData = {
          'fullName': _fullNameController.text,
          'phoneNumber': _phoneNumberController.text,
          'specialization': widget.role ?? 'Not specified',
          'yearsOfExperience': widget.experience ?? 'Not specified',
          'createdAt': DateTime.now().toIso8601String(),
        };

        // Save the data to the "fixers" node
        await _databaseReference.child('fixers').child(fixerId).set(fixerData);

        setState(() => _isLoading = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile saved successfully!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const FixerHomePage()),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving profile: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Fixer Profile', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    _buildProfileAvatar(),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _fullNameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        if (value.length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _phoneNumberController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (!RegExp(r'^\d{11}$').hasMatch(value)) {
                          return 'Phone number must be exactly 11 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    if (widget.role != null)
                      _buildInfoField('Specialization', widget.role!, Icons.build),
                    const SizedBox(height: 20),
                    if (widget.experience != null)
                      _buildInfoField('Years of Experience', widget.experience!, Icons.work),
                    const SizedBox(height: 20),
                    if (widget.idImage != null)
                      _buildImageField('Personal ID', widget.idImage),
                    const SizedBox(height: 20),
                    if (widget.criminalRecordImage != null)
                      _buildImageField('Criminal Record', widget.criminalRecordImage),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save Profile', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: AppColors.cardColor,
          child: widget.profileImage != null
              ? ClipOval(
                  child: kIsWeb
                      ? Image.memory(
                          widget.profileImage as Uint8List,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                          errorBuilder: (context, error, stackTrace) => _defaultAvatar(),
                        )
                      : Image.file(
                          widget.profileImage as File,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                          errorBuilder: (context, error, stackTrace) => _defaultAvatar(),
                        ),
                )
              : _defaultAvatar(),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.edit, size: 20, color: Colors.white),
        ),
      ],
    );
  }

  Widget _defaultAvatar() {
    return Icon(Icons.person, size: 60, color: AppColors.textLight);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Enter your ${label.toLowerCase()}',
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.textLight.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppColors.cardColor,
        labelStyle: TextStyle(color: AppColors.textLight),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }

  Widget _buildInfoField(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 14, color: AppColors.textLight)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageField(String label, dynamic imageData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: kIsWeb
                ? Image.memory(
                    imageData as Uint8List,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _imageError(),
                  )
                : Image.file(
                    imageData as File,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _imageError(),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _imageError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 30),
          const SizedBox(height: 8),
          Text(
            'Error loading image',
            style: TextStyle(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textLight)),
          ),
          TextButton(
                onPressed: () {
                   Navigator.pushReplacement(
                     context,
                    MaterialPageRoute(builder: (context) => const SignupScreen()),
                   );
                },
            child: const Text('Logout', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
}