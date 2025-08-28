import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedComplaintType = 'General Inquiry';
  bool _isSubmitting = false;

  // Track field completion for the progress indicator
  final Map<String, bool> _fieldCompletion = {
    'name': false,
    'email': false,
    'phone': false,
    'subject': false,
    'description': false,
  };

  final List<String> _complaintTypes = [
    'General Inquiry',
    'Service Issue',
    'Payment Problem',
    'Technical Support',
    'Feature Request',
    'Other'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  double get _completionPercentage {
    int completedFields = _fieldCompletion.values.where((value) => value).length;
    return completedFields / _fieldCompletion.length;
  }

  void _updateFieldStatus(String field, String value) {
    setState(() {
      _fieldCompletion[field] = value.trim().isNotEmpty;
    });
  }

  Future<void> _submitComplaint() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      
      try {
        final database = FirebaseDatabase.instance.ref('complaints');
        final complaintId = DateTime.now().millisecondsSinceEpoch.toString();
        
        await database.child(complaintId).set({
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'subject': _subjectController.text,
          'description': _descriptionController.text,
          'type': _selectedComplaintType,
          'status': 'open',
          'timestamp': DateTime.now().toIso8601String(),
          'complaintId': complaintId,
        });

        if (mounted) {
          _showSuccessDialog(complaintId);
          _formKey.currentState!.reset();
          
          // Reset field completion tracking
          for (var key in _fieldCompletion.keys) {
            _fieldCompletion[key] = false;
          }
          setState(() {
            _selectedComplaintType = 'General Inquiry';
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error submitting complaint: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }
  
  void _showSuccessDialog(String complaintId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complaint Submitted'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thank you for your feedback!'),
            const SizedBox(height: 8),
            Text('Your complaint ID is: $complaintId'),
            const SizedBox(height: 16),
            const Text('We will review your complaint and get back to you soon.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us'),
        backgroundColor: theme.primaryColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Submit a Complaint',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Playfair_Display'
                      ),
                    ),
                    Tooltip(
                      message: 'Form completion: ${(_completionPercentage * 100).toInt()}%',
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          value: _completionPercentage,
                          backgroundColor: Colors.grey[300],
                          strokeWidth: 5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Type selector with icons
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        value: _selectedComplaintType,
                        decoration: const InputDecoration(
                          labelText: 'Complaint Type',
                          border: InputBorder.none,
                        ),
                        icon: const Icon(Icons.arrow_drop_down_circle),
                        items: _complaintTypes.map((String type) {
                          IconData iconData;
                          switch (type) {
                            case 'General Inquiry':
                              iconData = Icons.help_outline;
                              break;
                            case 'Service Issue':
                              iconData = Icons.build;
                              break;
                            case 'Payment Problem':
                              iconData = Icons.payment;
                              break;
                            case 'Technical Support':
                              iconData = Icons.computer;
                              break;
                            case 'Feature Request':
                              iconData = Icons.lightbulb_outline;
                              break;
                            default:
                              iconData = Icons.category;
                          }
                          
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Row(
                              children: [
                                Icon(iconData, size: 20, color: theme.primaryColor),
                                const SizedBox(width: 10),
                                Text(type),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedComplaintType = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                    suffixIcon: _fieldCompletion['name'] == true 
                        ? const Icon(Icons.check_circle, color: Colors.green) 
                        : null,
                  ),
                  onChanged: (value) => _updateFieldStatus('name', value),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email),
                    suffixIcon: _fieldCompletion['email'] == true 
                        ? const Icon(Icons.check_circle, color: Colors.green) 
                        : null,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) => _updateFieldStatus('email', value),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Phone field with country code
                IntlPhoneField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: const OutlineInputBorder(),
                    suffixIcon: _fieldCompletion['phone'] == true 
                        ? const Icon(Icons.check_circle, color: Colors.green) 
                        : null,
                  ),
                  initialCountryCode: 'EG', // Set default to Egypt
                  onChanged: (phone) => _updateFieldStatus('phone', phone.completeNumber),
                ),
                const SizedBox(height: 16),
                
                // Subject field
                TextFormField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.subject),
                    suffixIcon: _fieldCompletion['subject'] == true 
                        ? const Icon(Icons.check_circle, color: Colors.green) 
                        : null,
                  ),
                  onChanged: (value) => _updateFieldStatus('subject', value),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a subject';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 80),
                      child: Icon(Icons.description),
                    ),
                    suffixIcon: _fieldCompletion['description'] == true 
                        ? const Padding(
                            padding: EdgeInsets.only(bottom: 80),
                            child: Icon(Icons.check_circle, color: Colors.green),
                          ) 
                        : null,
                  ),
                  maxLines: 5,
                  onChanged: (value) => _updateFieldStatus('description', value),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    if (value.length < 20) {
                      return 'Please provide more details (at least 20 characters)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Submit button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitComplaint,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send),
                            SizedBox(width: 8),
                            Text('Submit Complaint'),
                          ],
                        ),
                ),
                
                const SizedBox(height: 16),
                
                // Response time expectation
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, color: theme.primaryColor),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'We typically respond to complaints within 24-48 hours during business days.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}