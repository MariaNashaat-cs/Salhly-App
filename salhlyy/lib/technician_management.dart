import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF0C5FB3);
  static const Color secondary = Color(0xFF3D82C6);
  static const Color accent = Color.fromARGB(255, 224, 37, 4);
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color textDark = Color(0xFF2D3142);
  static const Color textLight = Color(0xFF8D99AE);
}

class TechnicianManagementPage extends StatefulWidget {
  const TechnicianManagementPage({super.key});

  @override
  State<TechnicianManagementPage> createState() => _TechnicianManagementPageState();
}

class _TechnicianManagementPageState extends State<TechnicianManagementPage> with SingleTickerProviderStateMixin {
  final database = FirebaseDatabase.instance.ref('fixers');
  String _searchQuery = '';
  String _sortBy = 'fullName';
  bool _sortAscending = true;
  TabController? _tabController;
  final List<String> _specializations = ['Electrician', 'Plumber'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _specializations.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  // Refresh function to force rebuild and re-fetch data
  void _refreshTechnicians() {
    setState(() {
      // This will trigger a rebuild of the StreamBuilder, re-fetching the data
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Technician Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Playfair_Display'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort, color: Colors.white),
            onPressed: _showSortOptions,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshTechnicians,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          tabs: _specializations.map((spec) => Tab(text: spec)).toList(),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search technicians...',
                hintStyle: TextStyle(color: AppColors.textLight),
                prefixIcon: Icon(Icons.search, color: AppColors.textLight),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear, color: AppColors.textLight),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Single StreamBuilder to listen to the database once
          Expanded(
            child: StreamBuilder(
              stream: database.onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 60, color: AppColors.accent),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading technicians',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() {}),
                          child: Text(
                            'Try Again',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>?;
                if (data == null || data.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off, size: 60, color: AppColors.textLight),
                        const SizedBox(height: 16),
                        Text(
                          'No technicians found',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showAddFixerDialog(context),
                          child: Text(
                            'Add New Technician',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: _specializations.map((specialization) {
                    List<MapEntry<dynamic, dynamic>> fixers = data.entries.toList();

                    // Apply search filter
                    if (_searchQuery.isNotEmpty) {
                      fixers = fixers.where((fixer) {
                        final fixerData = fixer.value as Map<dynamic, dynamic>;
                        final name = fixerData['fullName']?.toString().toLowerCase() ?? '';
                        final phone = fixerData['phoneNumber']?.toString().toLowerCase() ?? '';
                        return name.contains(_searchQuery.toLowerCase()) ||
                            phone.contains(_searchQuery.toLowerCase());
                      }).toList();
                    }

                    // Apply specialization filter based on current tab
                    fixers = fixers.where((fixer) {
                      final fixerData = fixer.value as Map<dynamic, dynamic>;
                      final spec = fixerData['specialization']?.toString() ?? '';
                      return spec == specialization;
                    }).toList();

                    // Apply sorting
                    fixers.sort((a, b) {
                      final aData = a.value as Map<dynamic, dynamic>;
                      final bData = b.value as Map<dynamic, dynamic>;
                      String aValue = aData[_sortBy]?.toString() ?? '';
                      String bValue = bData[_sortBy]?.toString() ?? '';
                      if (_sortBy == 'yearsOfExperience') {
                        final aNum = int.tryParse(aValue) ?? 0;
                        final bNum = int.tryParse(bValue) ?? 0;
                        return _sortAscending ? aNum.compareTo(bNum) : bNum.compareTo(aNum);
                      }
                      return _sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
                    });

                    return fixers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 60, color: AppColors.textLight),
                                const SizedBox(height: 16),
                                Text(
                                  'No $specialization technicians found',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _showAddFixerDialog(context),
                                  child: Text(
                                    'Add New Technician',
                                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: fixers.length,
                            itemBuilder: (context, index) {
                              final fixer = fixers[index];
                              final fixerId = fixer.key;
                              final fixerData = fixer.value as Map<dynamic, dynamic>;

                              // Calculate time ago
                              String timeAgo = 'N/A';
                              if (fixerData['createdAt'] != null) {
                                try {
                                  final createdDate = DateTime.parse(fixerData['createdAt']);
                                  final difference = DateTime.now().difference(createdDate);
                                  if (difference.inDays > 365) {
                                    timeAgo = '${(difference.inDays / 365).floor()} years ago';
                                  } else if (difference.inDays > 30) {
                                    timeAgo = '${(difference.inDays / 30).floor()} months ago';
                                  } else if (difference.inDays > 0) {
                                    timeAgo = '${difference.inDays} days ago';
                                  } else if (difference.inHours > 0) {
                                    timeAgo = '${difference.inHours} hours ago';
                                  } else {
                                    timeAgo = '${difference.inMinutes} minutes ago';
                                  }
                                } catch (e) {
                                  timeAgo = fixerData['createdAt'];
                                }
                              }

                              return Card(
                                elevation: 3,
                                color: AppColors.cardColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: _getColorForSpecialization(fixerData['specialization']),
                                            radius: 24,
                                            child: Text(
                                              (fixerData['fullName'] as String?)?.isNotEmpty == true
                                                  ? (fixerData['fullName'] as String).substring(0, 1).toUpperCase()
                                                  : '?',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  fixerData['fullName'] ?? 'No Name',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.textDark,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  fixerData['specialization'] ?? 'No Specialization',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: AppColors.textLight,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          _buildStatusIndicator(fixerData),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      Row(
                                        children: [
                                          Icon(Icons.phone, size: 16, color: AppColors.secondary),
                                          const SizedBox(width: 8),
                                          Text(
                                            fixerData['phoneNumber'] ?? 'N/A',
                                            style: TextStyle(color: AppColors.textDark),
                                          ),
                                          const SizedBox(width: 24),
                                          Icon(Icons.work, size: 16, color: AppColors.secondary),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${fixerData['yearsOfExperience'] ?? '0'} years',
                                            style: TextStyle(color: AppColors.textDark),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.access_time, size: 16, color: AppColors.secondary),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Added: $timeAgo',
                                            style: TextStyle(color: AppColors.textDark),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            icon: Icon(Icons.edit, color: AppColors.primary),
                                            label: Text(
                                              'Edit',
                                              style: TextStyle(color: AppColors.primary),
                                            ),
                                            onPressed: () => _showEditFixerDialog(context, fixerId, fixerData),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton.icon(
                                            icon: Icon(Icons.delete, color: AppColors.accent),
                                            label: Text(
                                              'Delete',
                                              style: TextStyle(color: AppColors.accent),
                                            ),
                                            onPressed: () => _confirmDelete(
                                                context, fixerId, fixerData['fullName'] ?? 'this technician'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFixerDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Add Technician',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(Map<dynamic, dynamic> fixerData) {
    final specialization = fixerData['specialization']?.toString() ?? '';
    bool isAvailable = specialization.length % 2 == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isAvailable ? AppColors.primary.withOpacity(0.1) : AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.do_not_disturb,
            size: 14,
            color: isAvailable ? AppColors.primary : AppColors.accent,
          ),
          const SizedBox(width: 4),
          Text(
            isAvailable ? 'Available' : 'Busy',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isAvailable ? AppColors.primary : AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForSpecialization(String? specialization) {
    if (specialization == null) return AppColors.textLight;
    switch (specialization.toLowerCase()) {
      case 'electrician':
        return AppColors.primary;
      case 'plumber':
        return AppColors.secondary;
      default:
        return AppColors.accent;
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: AppColors.cardColor,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sort Technicians',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      TextButton.icon(
                        icon: Icon(
                          _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                          color: AppColors.primary,
                        ),
                        label: Text(
                          _sortAscending ? 'Ascending' : 'Descending',
                          style: TextStyle(color: AppColors.primary),
                        ),
                        onPressed: () {
                          setState(() {
                            _sortAscending = !_sortAscending;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(),
                _buildSortOption('Name', 'fullName'),
                _buildSortOption('Experience', 'yearsOfExperience'),
                _buildSortOption('Date Added', 'createdAt'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String label, String field) {
    final isSelected = _sortBy == field;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: AppColors.textDark,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      leading: Icon(Icons.sort, color: AppColors.primary),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withOpacity(0.1),
      onTap: () {
        setState(() {
          _sortBy = field;
        });
        Navigator.pop(context);
      },
    );
  }

  void _confirmDelete(BuildContext context, String fixerId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Confirm Deletion',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete $name? This action cannot be undone.',
          style: TextStyle(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textDark),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              database.child(fixerId).remove();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$name has been deleted'),
                  backgroundColor: AppColors.accent,
                  action: SnackBarAction(
                    label: 'Dismiss',
                    textColor: Colors.white,
                    onPressed: () {},
                  ),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddFixerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final experienceController = TextEditingController();
    String? selectedSpecialization;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.person_add, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Add New Technician',
              style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter a phone number';
                    if (!RegExp(r'^\d{10}$').hasMatch(value)) return 'Please enter a valid 10-digit phone number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Specialization',
                    prefixIcon: Icon(Icons.work, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  items: _specializations.map((value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) => selectedSpecialization = newValue,
                  validator: (value) => value == null || value.isEmpty ? 'Please select a specialization' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: experienceController,
                  decoration: InputDecoration(
                    labelText: 'Years of Experience',
                    prefixIcon: Icon(Icons.timeline, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter years of experience';
                    if (int.tryParse(value) == null) return 'Please enter a valid number';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textDark)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await database.push().set({
                  'fullName': nameController.text,
                  'phoneNumber': phoneController.text,
                  'specialization': selectedSpecialization,
                  'yearsOfExperience': experienceController.text,
                  'createdAt': DateTime.now().toIso8601String(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${nameController.text} has been added'),
                    backgroundColor: AppColors.primary,
                    action: SnackBarAction(
                      label: 'Dismiss',
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditFixerDialog(BuildContext context, String fixerId, Map<dynamic, dynamic> fixerData) {
    final nameController = TextEditingController(text: fixerData['fullName']);
    final phoneController = TextEditingController(text: fixerData['phoneNumber']);
    final experienceController = TextEditingController(text: fixerData['yearsOfExperience']);
    String? selectedSpecialization = fixerData['specialization'];

    final formKey = GlobalKey<FormState>();
    final database = FirebaseDatabase.instance.ref('fixers/$fixerId');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.edit, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Edit Technician',
              style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter a phone number';
                    if (!RegExp(r'^\d{10}$').hasMatch(value)) return 'Please enter a valid 10-digit phone number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Specialization',
                    prefixIcon: Icon(Icons.work, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  value: selectedSpecialization,
                  items: _specializations.map((value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) => selectedSpecialization = newValue,
                  validator: (value) => value == null || value.isEmpty ? 'Please select a specialization' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: experienceController,
                  decoration: InputDecoration(
                    labelText: 'Years of Experience',
                    prefixIcon: Icon(Icons.timeline, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter years of experience';
                    if (int.tryParse(value) == null) return 'Please enter a valid number';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textDark)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await database.update({
                  'fullName': nameController.text,
                  'phoneNumber': phoneController.text,
                  'specialization': selectedSpecialization,
                  'yearsOfExperience': experienceController.text,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${nameController.text} has been updated'),
                    backgroundColor: AppColors.primary,
                    action: SnackBarAction(
                      label: 'Dismiss',
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}