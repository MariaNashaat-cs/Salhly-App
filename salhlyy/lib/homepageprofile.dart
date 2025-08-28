import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class HomePageProfile extends StatefulWidget {
  final String phoneNumber;
  final String fullName;

  const HomePageProfile({
    super.key,
    required this.phoneNumber,
    required this.fullName,
  });

  @override
  State<HomePageProfile> createState() => _HomePageProfileState();
}

class _HomePageProfileState extends State<HomePageProfile> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _selectedGender = '';
  String _selectedGovernorate = '';
  bool _isSubmitting = false;
  bool _isEditing = false;
  DatabaseReference? _databaseReference;
  Color _profileColor = Colors.blue;

  // List of available avatar colors
  final List<Color> _avatarColors = [
    Colors.blue,
    Colors.purple,
    Colors.teal,
    Colors.amber,
    Colors.deepOrange,
    Colors.indigo,
    Colors.pink,
  ];

  // List of Egyptian governorates
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
    print('InitState called'); // Debug print
    _initializeDatabase();
    _loadProfileData();
    _phoneController.text = widget.phoneNumber;
    
    // Generate a consistent color based on the phone number
    final int colorIndex = widget.phoneNumber.hashCode % _avatarColors.length;
    _profileColor = _avatarColors[colorIndex.abs()];
  }

  void _initializeDatabase() {
    _databaseReference = FirebaseDatabase.instance.ref().child('users').child(widget.phoneNumber);
  }

  Future<void> _loadProfileData() async {
    try {
      final snapshot = await _databaseReference!.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        print('Firebase data: $data'); // Debug print
        
        // Extract the gender value and remove any quotes
        String genderValue = data['gender']?.toString() ?? '';
        if (genderValue.startsWith('"') && genderValue.endsWith('"')) {
          genderValue = genderValue.substring(1, genderValue.length - 1);
        }

        // Extract the governorate value and remove any quotes
        String governorateValue = data['governorate']?.toString() ?? '';
        if (governorateValue.startsWith('"') && governorateValue.endsWith('"')) {
          governorateValue = governorateValue.substring(1, governorateValue.length - 1);
        }

        print('Gender from Firebase (cleaned): $genderValue'); // Debug print
        print('Governorate from Firebase (cleaned): $governorateValue'); // Debug print
        
        setState(() {
          _nameController.text = data['fullName']?.toString() ?? widget.fullName;
          _emailController.text = data['email']?.toString() ?? '';
          _selectedGender = genderValue;
          _selectedGovernorate = governorateValue;
          print('Selected gender after setting: $_selectedGender'); // Debug print
          print('Selected governorate after setting: $_selectedGovernorate'); // Debug print
          
          // If color is saved in database, use it
          if (data['profileColor'] != null) {
            _profileColor = Color(data['profileColor']);
          }
        });
      } else {
        _nameController.text = widget.fullName;
        print('No data exists in Firebase'); // Debug print
      }
    } catch (e) {
      print('Error loading profile data: $e'); // Debug print
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      print('Updating profile with gender: $_selectedGender, governorate: $_selectedGovernorate'); // Debug print
      final updates = {
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'gender': _selectedGender,
        'governorate': _selectedGovernorate,
        // ignore: deprecated_member_use
        'profileColor': _profileColor.value,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      print('Update data: $updates'); // Debug print
      
      await _databaseReference!.update(updates);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Profile updated successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      setState(() {
        _isEditing = false;
        _isSubmitting = false;
      });
    } catch (e) {
      print('Error updating profile: $e'); // Debug print
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getInitials() {
    if (_nameController.text.isEmpty) {
      return widget.fullName.isNotEmpty ? widget.fullName[0].toUpperCase() : '?';
    }
    
    final nameParts = _nameController.text.split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return _nameController.text[0].toUpperCase();
  }

  void _changeAvatarColor() {
    if (!_isEditing) return;
    
    setState(() {
      final currentIndex = _avatarColors.indexOf(_profileColor);
      final nextIndex = (currentIndex + 1) % _avatarColors.length;
      _profileColor = _avatarColors[nextIndex];
    });
  }

  @override
  Widget build(BuildContext context) {
    print('Build called, current gender: $_selectedGender, governorate: $_selectedGovernorate'); // Debug print
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _profileColor.withOpacity(0.7),
        foregroundColor: Colors.white,
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isEditing)
            TextButton.icon(
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('Save', style: TextStyle(color: Colors.white)),
              onPressed: _isSubmitting ? null : _updateProfile,
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              tooltip: 'Edit Profile',
            ),
        ],
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile header with avatar
                  Container(
                    color: _profileColor.withOpacity(0.7),
                    padding: const EdgeInsets.only(bottom: 30),
                    child: Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _changeAvatarColor,
                            child: Stack(
                              children: [
                                Hero(
                                  tag: 'profile-avatar',
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundColor: _profileColor,
                                    child: Text(
                                      _getInitials(),
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_isEditing)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: _profileColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.color_lens,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _nameController.text.isNotEmpty
                                ? _nameController.text
                                : widget.fullName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Form fields in a card
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Personal Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(),
                              const SizedBox(height: 16),
                              
                              // Name field
                              buildFormField(
                                controller: _nameController,
                                focusNode: _nameFocus,
                                icon: Icons.person,
                                label: 'Full Name',
                                hint: 'Enter your full name',
                                enabled: _isEditing,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your full name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Email field
                              buildFormField(
                                controller: _emailController,
                                focusNode: _emailFocus,
                                icon: Icons.email,
                                label: 'Email Address',
                                hint: 'Enter your email address',
                                keyboardType: TextInputType.emailAddress,
                                enabled: _isEditing,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!value.contains('@') || !value.contains('.')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Phone number field (read-only)
                              buildFormField(
                                controller: _phoneController,
                                focusNode: _phoneFocus,
                                icon: Icons.phone,
                                label: 'Phone Number',
                                enabled: false,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 16),
                              
                              // Gender field
                              Container(
                                padding: const EdgeInsets.all(16),
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _isEditing
                                          ? buildGenderDropdown()
                                          : Row(
                                              children: [
                                                Icon(Icons.person_outline, color: _profileColor),
                                                const SizedBox(width: 10),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Gender',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    Text(
                                                      _selectedGender,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Governorate field
                              Container(
                                padding: const EdgeInsets.all(16),
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _isEditing
                                          ? buildGovernorateDropdown()
                                          : Row(
                                              children: [
                                                Icon(Icons.location_city, color: _profileColor),
                                                const SizedBox(width: 10),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Governorate',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    Text(
                                                      _selectedGovernorate,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  if (_isEditing)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _profileColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Profile',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget buildFormField({
    TextEditingController? controller,
    FocusNode? focusNode,
    String? initialValue,
    IconData? icon,
    required String label,
    String? hint,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      focusNode: focusNode,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: _profileColor) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _profileColor, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        filled: !enabled,
        fillColor: enabled ? Colors.transparent : Colors.grey.shade100,
      ),
      validator: validator,
    );
  }

  Widget buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender.isNotEmpty ? _selectedGender : null,
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: Icon(Icons.person_outline, color: _profileColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _profileColor, width: 2),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'Female', child: Text('Female')),
        DropdownMenuItem(value: 'Male', child: Text('Male')),
        DropdownMenuItem(value: 'Other', child: Text('Other')),
        DropdownMenuItem(value: 'Prefer not to say', child: Text('Prefer not to say')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedGender = value!;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select your gender';
        }
        return null;
      },
      icon: Icon(Icons.arrow_drop_down, color: _profileColor),
    );
  }

  Widget buildGovernorateDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGovernorate.isNotEmpty ? _selectedGovernorate : null,
      decoration: InputDecoration(
        labelText: 'Governorate',
        prefixIcon: Icon(Icons.location_city, color: _profileColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _profileColor, width: 2),
        ),
      ),
      items: _governorates.map((String governorate) {
        return DropdownMenuItem<String>(
          value: governorate,
          child: Text(governorate),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedGovernorate = value!;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select your governorate';
        }
        return null;
      },
      icon: Icon(Icons.arrow_drop_down, color: _profileColor),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }
}