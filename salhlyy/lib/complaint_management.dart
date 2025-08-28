import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AppColors {
  static const Color primary = Color(0xFF0C5FB3);
  static const Color secondary = Color(0xFF3D82C6);
  static const Color accent = Color.fromARGB(255, 224, 37, 4);
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color textDark = Color(0xFF2D3142);
  static const Color textLight = Color(0xFF8D99AE);
}

class ComplaintManagementPage extends StatefulWidget {
  const ComplaintManagementPage({super.key});

  @override
  State<ComplaintManagementPage> createState() => _ComplaintManagementPageState();
}

class _ComplaintManagementPageState extends State<ComplaintManagementPage> {
  final database = FirebaseDatabase.instance.ref('complaints');
  String _searchQuery = '';
  String _filterStatus = 'all';
  String? _errorMessage;
  String _sortBy = 'timestamp';
  bool _sortAscending = false;

  final List<String> _statusOptions = [
    'all',
    'open',
    'in_progress',
    'resolved',
    'closed'
  ];

  final Map<String, Color> statusColors = {
    'open': Colors.orange,
    'in_progress': Colors.blue,
    'resolved': Colors.green,
    'closed': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      try {
        FirebaseDatabase.instance.setPersistenceEnabled(true);
      } catch (e) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Complaint Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Playfair_Display'),
        ),
        actions: [
          Semantics(
            label: 'Sort complaints',
            child: IconButton(
              icon: const Icon(Icons.sort, color: Colors.white),
              tooltip: 'Sort complaints',
              onPressed: _showSortOptions,
            ),
          ),
          Semantics(
            label: 'Refresh complaints',
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh complaints',
              onPressed: _refreshComplaints,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchFilterBar(),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: AppColors.textDark),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => setState(() => _errorMessage = null),
                      color: AppColors.textDark,
                    )
                  ],
                ),
              ),
            ),
          Expanded(
            child: _buildComplaintsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by subject, user or description',
                hintStyle: TextStyle(color: AppColors.textLight),
                prefixIcon: Icon(Icons.search, color: AppColors.textLight),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppColors.textLight),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.cardColor,
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
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filterStatus,
                icon: Icon(Icons.filter_list, color: AppColors.textLight),
                hint: Text('Status', style: TextStyle(color: AppColors.textLight)),
                items: _statusOptions.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Row(
                      children: [
                        if (status != 'all')
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: statusColors[status] ?? Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          status == 'all'
                              ? 'All Statuses'
                              : status.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(color: AppColors.textDark),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _filterStatus = newValue;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintsList() {
    return StreamBuilder<DatabaseEvent>(
      stream: database.onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: AppColors.accent),
                const SizedBox(height: 16),
                Text(
                  'Error loading complaints',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                TextButton(
                  onPressed: _refreshComplaints,
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
                Icon(Icons.inbox, size: 60, color: AppColors.textLight),
                const SizedBox(height: 16),
                Text(
                  'No complaints found',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                TextButton(
                  onPressed: () => _showAddComplaintDialog(context),
                  child: Text(
                    'Add New Complaint',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        }

        final complaints = data.entries.toList();
        final filteredComplaints = complaints.where((complaint) {
          final complaintData = complaint.value as Map<dynamic, dynamic>;
          final matchesSearch = _searchQuery.isEmpty ||
              (complaintData['description']?.toString().toLowerCase() ?? '')
                  .contains(_searchQuery) ||
              (complaintData['subject']?.toString().toLowerCase() ?? '')
                  .contains(_searchQuery) ||
              (complaintData['name']?.toString().toLowerCase() ?? '')
                  .contains(_searchQuery) ||
              (complaintData['phone']?.toString().toLowerCase() ?? '')
                  .contains(_searchQuery);
          final matchesStatus = _filterStatus == 'all' ||
              complaintData['status']?.toString() == _filterStatus;
          return matchesSearch && matchesStatus;
        }).toList();

        _sortComplaints(filteredComplaints);

        if (filteredComplaints.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_alt_off, size: 60, color: AppColors.textLight),
                const SizedBox(height: 16),
                Text(
                  'No matching complaints found',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _filterStatus = 'all';
                    });
                  },
                  child: Text(
                    'Clear Filters',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredComplaints.length,
          itemBuilder: (context, index) {
            final complaint = filteredComplaints[index];
            final complaintId = complaint.key;
            final complaintData = complaint.value as Map<dynamic, dynamic>;

            final status = complaintData['status']?.toString() ?? 'open';
            final statusColor = statusColors[status] ?? Colors.grey;
            final date = _formatDate(complaintData['timestamp']);

            return Card(
              elevation: 3,
              color: AppColors.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: statusColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                childrenPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.2),
                  child: Icon(
                    _getStatusIcon(status),
                    color: statusColor,
                  ),
                ),
                title: Text(
                  complaintData['subject'] ?? 'No Subject',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildStatusChip(status),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            date,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By: ${complaintData['name'] ?? 'Anonymous'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: AppColors.primary),
                      tooltip: 'Edit status',
                      onPressed: () =>
                          _showEditComplaintDialog(context, complaintId, complaintData),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: AppColors.accent),
                      tooltip: 'Delete complaint',
                      onPressed: () =>
                          _showDeleteConfirmationDialog(context, complaintId),
                    ),
                  ],
                ),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardColor,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        _buildInfoSection(
                          'User Information',
                          Icons.person,
                          [
                            _buildInfoRow('Name:', complaintData['name'] ?? 'Not provided'),
                            _buildInfoRow('Phone:', complaintData['phone'] ?? 'Not provided'),
                            _buildInfoRow('Email:', complaintData['email'] ?? 'Not provided'),
                          ],
                        ),
                        const Divider(height: 32),
                        _buildInfoSection(
                          'Complaint Details',
                          Icons.description,
                          [
                            _buildInfoRow('Description:',
                                complaintData['description'] ?? 'No Description'),
                            if (complaintData['type'] != null)
                              _buildInfoRow('Problem Type:', complaintData['type']),
                            if (complaintData['problemDetails'] != null)
                              _buildInfoRow('Problem Details:', complaintData['problemDetails']),
                          ],
                        ),
                        if (complaintData['lastUpdated'] != null) ...[
                          const Divider(height: 32),
                          _buildInfoSection(
                            'Last Updated',
                            Icons.update,
                            [
                              _buildInfoRow('Date:', _formatDate(complaintData['lastUpdated'])),
                              if (complaintData['updatedBy'] != null)
                                _buildInfoRow('Updated By:', complaintData['updatedBy']),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () =>
                                  _showEditComplaintDialog(context, complaintId, complaintData),
                              icon: Icon(Icons.edit, color: AppColors.primary),
                              label: Text(
                                'Update Status',
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () =>
                                  _showFullComplaintDetails(context, complaintId, complaintData),
                              icon: Icon(Icons.visibility, color: AppColors.primary),
                              label: Text(
                                'View',
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'open':
        return Icons.fiber_new;
      case 'in_progress':
        return Icons.pending;
      case 'resolved':
        return Icons.check_circle_outline;
      case 'closed':
        return Icons.archive_outlined;
      default:
        return Icons.help_outline;
    }
  }

  void _sortComplaints(List<MapEntry<dynamic, dynamic>> complaints) {
    complaints.sort((a, b) {
      final aData = a.value as Map<dynamic, dynamic>;
      final bData = b.value as Map<dynamic, dynamic>;

      dynamic aValue = aData[_sortBy] ?? '';
      dynamic bValue = bData[_sortBy] ?? '';

      int comparison;

      if (_sortBy == 'timestamp' || _sortBy == 'lastUpdated') {
        final aDate = aValue != null ? DateTime.tryParse(aValue.toString()) : null;
        final bDate = bValue != null ? DateTime.tryParse(bValue.toString()) : null;

        if (aDate == null && bDate == null) {
          comparison = 0;
        } else if (aDate == null) {
          comparison = 1;
        } else if (bDate == null) {
          comparison = -1;
        } else {
          comparison = aDate.compareTo(bDate);
        }
      } else {
        comparison = aValue.toString().compareTo(bValue.toString());
      }

      return _sortAscending ? comparison : -comparison;
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.sort, color: AppColors.primary),
                        const SizedBox(width: 16),
                        Text(
                          'Sort Complaints',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  _buildSortOption('Date Created', 'timestamp', setState),
                  _buildSortOption('Last Updated', 'lastUpdated', setState),
                  _buildSortOption('Subject', 'subject', setState),
                  _buildSortOption('Status', 'status', setState),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          this.setState(() {
                            _sortAscending = !_sortAscending;
                          });
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                          color: AppColors.primary,
                        ),
                        label: Text(
                          _sortAscending ? 'Ascending' : 'Descending',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortOption(String label, String value, StateSetter setState) {
    final isSelected = _sortBy == value;

    return ListTile(
      title: Text(
        label,
        style: TextStyle(color: AppColors.textDark),
      ),
      leading: Radio<String>(
        value: value,
        groupValue: _sortBy,
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              this.setState(() {
                _sortBy = newValue;
              });
            });
          }
        },
        activeColor: AppColors.primary,
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withOpacity(0.1),
      onTap: () {
        setState(() {
          this.setState(() {
            _sortBy = value;
          });
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = statusColors[status] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null) return 'No date';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();

      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        return 'Today, ${DateFormat('HH:mm').format(date)}';
      }

      final yesterday = now.subtract(const Duration(days: 1));
      if (date.year == yesterday.year &&
          date.month == yesterday.month &&
          date.day == yesterday.day) {
        return 'Yesterday, ${DateFormat('HH:mm').format(date)}';
      }

      if (now.difference(date).inDays < 7) {
        return '${DateFormat('EEEE').format(date)}, ${DateFormat('HH:mm').format(date)}';
      }

      return DateFormat('MMM dd, yyyy • HH:mm').format(date);
    } catch (e) {
      return timestamp;
    }
  }

  Future<void> _refreshComplaints() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      await database.once();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Complaints refreshed successfully'),
            backgroundColor: AppColors.primary,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error refreshing complaints: $e';
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              setState(() => _errorMessage = null);
            }
          });
        });
      }
    }
  }

  void _showFullComplaintDetails(
      BuildContext context, String complaintId, Map<dynamic, dynamic> complaintData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.cardColor,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: (statusColors[complaintData['status']] ?? Colors.grey).withOpacity(0.2),
                    child: Icon(
                      _getStatusIcon(complaintData['status'] ?? 'open'),
                      color: statusColors[complaintData['status']] ?? Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      complaintData['subject'] ?? 'No Subject',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textDark),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoSection(
                        'Status Information',
                        Icons.info_outline,
                        [
                          _buildInfoRow('Current Status:',
                              (complaintData['status'] ?? 'open').replaceAll('_', ' ').toUpperCase()),
                          _buildInfoRow('Created:', _formatDate(complaintData['timestamp'])),
                          if (complaintData['lastUpdated'] != null)
                            _buildInfoRow('Last Updated:', _formatDate(complaintData['lastUpdated'])),
                          if (complaintData['updatedBy'] != null)
                            _buildInfoRow('Updated By:', complaintData['updatedBy']),
                        ],
                      ),
                      const Divider(height: 32),
                      _buildInfoSection(
                        'User Information',
                        Icons.person,
                        [
                          _buildInfoRow('Name:', complaintData['name'] ?? 'Not provided'),
                          _buildInfoRow('Phone:', complaintData['phone'] ?? 'Not provided'),
                          _buildInfoRow('Email:', complaintData['email'] ?? 'Not provided'),
                        ],
                      ),
                      const Divider(height: 32),
                      _buildInfoSection(
                        'Complaint Details',
                        Icons.description,
                        [
                          _buildInfoRow('Description:',
                              complaintData['description'] ?? 'No Description'),
                          if (complaintData['type'] != null)
                            _buildInfoRow('Problem Type:', complaintData['type']),
                          if (complaintData['problemDetails'] != null)
                            _buildInfoRow('Problem Details:', complaintData['problemDetails']),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textDark),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                    label: const Text(
                      'Update Status',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: const Size(60, 30),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditComplaintDialog(context, complaintId, complaintData);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddComplaintDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final typeController = TextEditingController();
    final problemDetailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.cardColor,
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.all(16),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.add_circle_outline, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Add New Complaint',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: AppColors.textDark),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  TextFormField(
                    controller: subjectController,
                    decoration: InputDecoration(
                      labelText: 'Subject *',
                      hintText: 'Brief subject of the complaint',
                      hintStyle: TextStyle(color: AppColors.textLight),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a subject';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description *',
                      hintText: 'Detailed description of the issue',
                      hintStyle: TextStyle(color: AppColors.textLight),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'User Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      hintText: 'Full name of complainant',
                      hintStyle: TextStyle(color: AppColors.textLight),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      hintText: 'Contact number',
                      hintStyle: TextStyle(color: AppColors.textLight),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary, width: 2),
                      ),
                      prefixIcon: Icon(Icons.phone, color: AppColors.textLight),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final phoneRegExp = RegExp(r'^\+?[\d\s-]{10,}$');
                        if (!phoneRegExp.hasMatch(value)) {
                          return 'Please enter a valid phone number';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Email address',
                      hintStyle: TextStyle(color: AppColors.textLight),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary, width: 2),
                      ),
                      prefixIcon: Icon(Icons.email, color: AppColors.textLight),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final emailRegExp =
                            RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegExp.hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Problem Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: typeController,
                    decoration: InputDecoration(
                      labelText: 'Problem Type',
                      hintText: 'Category of issue',
                      hintStyle: TextStyle(color: AppColors.textLight),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: problemDetailsController,
                    decoration: InputDecoration(
                      labelText: 'Problem Details',
                      hintText: 'Additional details about the problem',
                      hintStyle: TextStyle(color: AppColors.textLight),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: AppColors.textDark),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save, color: Colors.white, size: 16),
                        label: const Text(
                          'Save',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            try {
                              final user = FirebaseAuth.instance.currentUser;
                              await database.push().set({
                                'subject': subjectController.text,
                                'description': descriptionController.text,
                                'status': 'open',
                                'timestamp': DateTime.now().toIso8601String(),
                                'name': nameController.text.isNotEmpty ? nameController.text : null,
                                'phone': phoneController.text.isNotEmpty ? phoneController.text : null,
                                'email': emailController.text.isNotEmpty ? emailController.text : null,
                                'type': typeController.text.isNotEmpty ? typeController.text : null,
                                'problemDetails': problemDetailsController.text.isNotEmpty ? problemDetailsController.text : null,
                                'createdBy': user?.uid ?? 'anonymous',
                              });
                              Navigator.pop(context);
                              if (mounted) {
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Complaint added successfully'),
                                    backgroundColor: AppColors.primary,
                                    action: SnackBarAction(
                                      label: 'Dismiss',
                                      textColor: Colors.white,
                                      onPressed: () {},
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error adding complaint: $e'),
                                    backgroundColor: AppColors.accent,
                                    action: SnackBarAction(
                                      label: 'Dismiss',
                                      textColor: Colors.white,
                                      onPressed: () {},
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      subjectController.dispose();
      descriptionController.dispose();
      nameController.dispose();
      phoneController.dispose();
      emailController.dispose();
      typeController.dispose();
      problemDetailsController.dispose();
    });
  }

  void _showEditComplaintDialog(
      BuildContext context, String complaintId, Map<dynamic, dynamic> complaintData) {
    String selectedStatus = complaintData['status']?.toString() ?? 'open';
    final commentController = TextEditingController();
    final database = FirebaseDatabase.instance.ref('complaints/$complaintId');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.cardColor,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter dialogSetState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_note, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Update Complaint Status',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                            fontFamily: 'Playfair_Display'
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.close, color: AppColors.textDark),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      'Current Status: ${(complaintData['status'] ?? 'open').toString().replaceAll('_', ' ').toUpperCase()}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'New Status',
                        hintStyle: TextStyle(color: AppColors.textLight),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                        prefixIcon: Icon(Icons.sync, color: AppColors.textLight),
                      ),
                      items: _statusOptions.where((status) => status != 'all').map((String status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: statusColors[status] ?? Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(
                                status.replaceAll('_', ' ').toUpperCase(),
                                style: TextStyle(color: AppColors.textDark),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          dialogSetState(() {
                            selectedStatus = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: AppColors.textDark),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.save, color: Colors.white, size: 16),
                          label: const Text(
                            'Update',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: const Size(60, 30),
                          ),
                          onPressed: () async {
                            try {
                              final user = FirebaseAuth.instance.currentUser;
                              final updateData = {
                                'status': selectedStatus,
                                'lastUpdated': DateTime.now().toIso8601String(),
                                'updatedBy': user?.displayName ?? user?.email ?? 'Unknown',
                              };

                              if (commentController.text.isNotEmpty) {
                                updateData['statusComment'] = commentController.text;
                              }

                              await database.update(updateData);

                              // ignore: use_build_context_synchronously
                              Navigator.pop(context);
                              if (mounted) {
                                setState(() {});
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Status updated to ${selectedStatus.replaceAll('_', ' ').toUpperCase()}'),
                                    backgroundColor: AppColors.primary,
                                    action: SnackBarAction(
                                      label: 'Dismiss',
                                      textColor: Colors.white,
                                      onPressed: () {},
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                // ignore: use_build_context_synchronously
                                Navigator.pop(context);
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error updating status: $e'),
                                    backgroundColor: AppColors.accent,
                                    action: SnackBarAction(
                                      label: 'Dismiss',
                                      textColor: Colors.white,
                                      onPressed: () {},
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      commentController.dispose();
    });
  }

  void _showDeleteConfirmationDialog(BuildContext context, String complaintId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.cardColor,
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.accent),
            const SizedBox(width: 8),
            Text(
              'Delete Complaint',
              style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this complaint? This action cannot be undone.',
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
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            label: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () async {
              try {
                await database.child(complaintId).remove();
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                if (mounted) {
                  setState(() {});
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Complaint deleted successfully'),
                      backgroundColor: AppColors.accent,
                      action: SnackBarAction(
                        label: 'Dismiss',
                        textColor: Colors.white,
                        onPressed: () {},
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting complaint: $e'),
                      backgroundColor: AppColors.accent,
                      action: SnackBarAction(
                        label: 'Dismiss',
                        textColor: Colors.white,
                        onPressed: () {},
                      ),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}