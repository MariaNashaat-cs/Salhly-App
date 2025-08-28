import 'dart:async';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'fixerprofile.dart';

class AppColors {
  static const Color primary = Color(0xFF0C5FB3);
  static const Color secondary = Color(0xFF3D82C6);
  static const Color accent = Color.fromARGB(255, 224, 37, 4);
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color textDark = Color(0xFF2D3142);
  static const Color textLight = Color(0xFF8D99AE);
  static const Color success = Colors.green;
  static const Color warning = Color(0xFFFFA000);
}

class FixerInfo extends StatefulWidget {
  const FixerInfo({super.key});

  @override
  State<FixerInfo> createState() => _FixerInfoState();
}

class _FixerInfoState extends State<FixerInfo> {
  static const double _borderRadius = 15.0;
  static const double _padding = 16.0;
  static const double _spacing = 20.0;

  String selectedRole = '';
  final List<String> roles = ['Plumber', 'Electrician'];

  final TextEditingController _experienceController = TextEditingController();

  dynamic _profileImage;
  dynamic _idImage;
  dynamic _criminalRecordImage;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(String imageType) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery, // Directly open the gallery
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
        requestFullMetadata: false,
      );

      if (pickedFile != null && mounted) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            switch (imageType) {
              case 'profile':
                _profileImage = bytes;
                break;
              case 'id':
                _idImage = bytes;
                break;
              case 'criminalRecord':
                _criminalRecordImage = bytes;
                break;
            }
          });
        } else {
          setState(() {
            File imageFile = File(pickedFile.path);
            switch (imageType) {
              case 'profile':
                _profileImage = imageFile;
                break;
              case 'id':
                _idImage = imageFile;
                break;
              case 'criminalRecord':
                _criminalRecordImage = imageFile;
                break;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _experienceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen size to ensure proper scaling
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(_padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: screenSize.height * 0.02),
                _buildWelcomeSection(),
                SizedBox(height: screenSize.height * 0.015),
                _buildInfoPrompt(),
                SizedBox(height: screenSize.height * 0.02),
                _buildFormFields(screenSize),
                SizedBox(height: screenSize.height * 0.03),
                _buildSubmitButton(),
                SizedBox(height: screenSize.height * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(top: 9.0),
          child: Text(
            'Salحly',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontFamily: 'Playfair_Display',
              shadows: [
                Shadow(
                  color: AppColors.primary.withOpacity(0.2),
                  offset: const Offset(1, 1),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Center(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to the family',
                style: TextStyle(
                  fontSize: 24,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Playfair_Display',
                ),
              ),
              const SizedBox(width: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.favorite,
                  color: AppColors.accent,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: 100,
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPrompt() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          'Please add all your info:',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Open Sans',
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields(Size screenSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImageUploadField('Profile Photo', Icons.camera_alt, 'profile', _profileImage, screenSize),
        const SizedBox(height: _spacing),
        _buildImageUploadField('Personal ID', Icons.badge, 'id', _idImage, screenSize),
        const SizedBox(height: _spacing),
        _buildImageUploadField('Criminal Record', Icons.insert_drive_file, 'criminalRecord', _criminalRecordImage, screenSize),
        const SizedBox(height: _spacing),
        _buildTextField('Years of Experience', Icons.work, _experienceController),
        const SizedBox(height: _spacing),
        _buildSpecializationSection(),
      ],
    );
  }

  Widget _buildSpecializationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Select your specialization:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
            fontFamily: 'Open Sans',
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: SizedBox(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: roles.map((role) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildRoleButton(role),
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: Container(
        width: 120,
        height: 45,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(120, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Submit',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Open Sans',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadField(String label, IconData icon, String imageType, dynamic imageData, Size screenSize) {
    // Adjust height based on screen size
    final double containerHeight = imageData != null ? screenSize.height * 0.18 : 65;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: containerHeight,
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(_borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: imageData != null 
              ? AppColors.primary.withOpacity(0.2) 
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: imageData != null
          ? _buildImagePreview(label, imageType, imageData)
          : _buildImageUploadPrompt(label, icon, imageType),
    );
  }

  Widget _buildImagePreview(String label, String imageType, dynamic imageData) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Open Sans',
                ),
              ),
              InkWell(
                onTap: () {
                  if (mounted) {
                    setState(() {
                      if (imageType == 'profile') {
                        _profileImage = null;
                      } else if (imageType == 'id') {
                        _idImage = null;
                      } else if (imageType == 'criminalRecord') {
                        _criminalRecordImage = null;
                      }
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: AppColors.accent, size: 18),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  backgroundColor: Colors.black,
                  child: Stack(
                    children: [
                      InteractiveViewer(
                        child: kIsWeb
                            ? Image.memory(
                                imageData as Uint8List,
                                fit: BoxFit.contain,
                              )
                            : Image.file(
                                imageData as File,
                                fit: BoxFit.contain,
                              ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: kIsWeb
                  ? Image.memory(
                      imageData as Uint8List,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
                    )
                  : Image.file(
                      imageData as File,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildImageUploadPrompt(String label, IconData icon, String imageType) {
    return GestureDetector(
      onTap: () => _pickImage(imageType), // Directly open the gallery
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            Text(
              'Upload $label',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textDark,
                fontFamily: 'Open Sans',
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.primary.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppColors.accent, size: 24),
          const SizedBox(height: 6),
          Text(
            'Error loading image',
            style: TextStyle(color: AppColors.accent, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller) {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(_borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: label,
                hintStyle: TextStyle(
                  color: AppColors.textLight,
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleButton(String role) {
    final isSelected = selectedRole == role;
    return GestureDetector(
      onTap: () {
        if (mounted) {
          setState(() => selectedRole = role);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        height: 45,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                )
              : null,
          color: isSelected ? null : AppColors.cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.primary.withOpacity(isSelected ? 0 : 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? AppColors.primary.withOpacity(0.3) 
                  : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            role,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.primary,
              fontFamily: 'Open Sans',
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    bool isValid = _validateForm();

    if (isValid && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Fixerprofile(
            role: selectedRole,
            experience: _experienceController.text,
            profileImage: _profileImage,
            idImage: _idImage,
            criminalRecordImage: _criminalRecordImage,
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Information submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  bool _validateForm() {
    if (_experienceController.text.isEmpty) {
      _showErrorSnackBar('Please enter your years of experience');
      return false;
    }

    if (_profileImage == null) {
      _showErrorSnackBar('Please upload your profile photo');
      return false;
    }

    if (_idImage == null) {
      _showErrorSnackBar('Please upload your ID photo');
      return false;
    }

    if (_criminalRecordImage == null) {
      _showErrorSnackBar('Please upload your criminal record');
      return false;
    }

    if (selectedRole.isEmpty) {
      _showErrorSnackBar('Please select your specialization');
      return false;
    }

    return true;
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.accent,
        ),
      );
    }
  }
}