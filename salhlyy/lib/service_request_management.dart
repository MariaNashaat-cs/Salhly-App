import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'dart:math';

// Define the AppColors class to match ComplaintManagementPage
class AppColors {
  static const Color primary = Color(0xFF0C5FB3);
  static const Color secondary = Color(0xFF3D82C6);
  static const Color accent = Color.fromARGB(255, 224, 37, 4);
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color textDark = Color(0xFF2D3142);
  static const Color textLight = Color(0xFF8D99AE);
}

class ServiceRequestManagementPage extends StatefulWidget {
  const ServiceRequestManagementPage({super.key});

  @override
  State<ServiceRequestManagementPage> createState() => _ServiceRequestManagementPageState();
}

class _ServiceRequestManagementPageState extends State<ServiceRequestManagementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DatabaseReference database;
  late Stream<DatabaseEvent> _requestsStream;
  
  // Search and filter variables
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'newest';
  String _filterCategory = 'all';
  
  // Status map for color coding
  final Map<String, Color> _statusColors = {
    'pending': Colors.amber,
    'completed': Colors.green,
    'canceled': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    database = FirebaseDatabase.instance.ref('serviceRequests');
    _requestsStream = database.onValue;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  void _refreshData() {
    setState(() {
      _requestsStream = database.onValue;
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _statusTabs => ['pending', 'completed', 'canceled'];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Service Requests',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Playfair_Display'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterOptions,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search requests...',
                    hintStyle: TextStyle(color: AppColors.textLight),
                    prefixIcon: Icon(Icons.search, color: AppColors.textLight),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: AppColors.textLight),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
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
                    filled: true,
                    fillColor: AppColors.cardColor,
                  ),
                  style: TextStyle(color: AppColors.textDark),
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  _buildTab('Pending', Icons.hourglass_empty),
                  _buildTab('Completed', Icons.check_circle),
                  _buildTab('Canceled', Icons.cancel),
                ],
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder(
        stream: _requestsStream,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          debugPrint('StreamBuilder rebuild - hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}');
          
          if (snapshot.hasError) {
            debugPrint('StreamBuilder error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: AppColors.accent),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(fontSize: 18, color: AppColors.textDark),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final data = snapshot.data!.snapshot.value;
          if (data == null) {
            debugPrint('No data available in snapshot');
            return Center(
              child: Text(
                'No requests found',
                style: TextStyle(fontSize: 18, color: AppColors.textDark),
              ),
            );
          }

          debugPrint('Received data: ${data.toString().substring(0, min(100, data.toString().length))}...');

          return TabBarView(
            controller: _tabController,
            children: _statusTabs.map((status) => _buildRequestList(data, status)).toList(),
          );
        },
      ),
    );
  }

  Widget _buildTab(String title, IconData icon) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: AppColors.cardColor,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter & Sort',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const Divider(color: Colors.grey),
              Text(
                'Sort by:',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
              ),
              RadioListTile<String>(
                title: Text('Newest First', style: TextStyle(color: AppColors.textDark)),
                value: 'newest',
                groupValue: _sortBy,
                activeColor: AppColors.primary,
                onChanged: (value) {
                  setState(() => _sortBy = value!);
                },
              ),
              RadioListTile<String>(
                title: Text('Oldest First', style: TextStyle(color: AppColors.textDark)),
                value: 'oldest',
                groupValue: _sortBy,
                activeColor: AppColors.primary,
                onChanged: (value) {
                  setState(() => _sortBy = value!);
                },
              ),
              RadioListTile<String>(
                title: Text('Price: High to Low', style: TextStyle(color: AppColors.textDark)),
                value: 'price_high',
                groupValue: _sortBy,
                activeColor: AppColors.primary,
                onChanged: (value) {
                  setState(() => _sortBy = value!);
                },
              ),
              RadioListTile<String>(
                title: Text('Price: Low to High', style: TextStyle(color: AppColors.textDark)),
                value: "price_low",
                groupValue: _sortBy,
                activeColor: AppColors.primary,
                onChanged: (value) {
                  setState(() => _sortBy = value!);
                },
              ),
              const Divider(color: Colors.grey),
              Text(
                'Category:',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
              ),
              DropdownButton<String>(
                value: _filterCategory,
                isExpanded: true,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => _filterCategory = newValue);
                  }
                },
                items: <String>['all', 'plumbing', 'electrical', 'carpentry', 'cleaning', 'other']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value == 'all' ? 'All Categories' : value.toUpperCase(),
                      style: TextStyle(color: AppColors.textDark),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _refreshData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestList(dynamic data, String status) {
    debugPrint('Raw data type: ${data.runtimeType}');
    
    final Map<String, dynamic> requestsMap = Map<String, dynamic>.from(data as Map);
    
    debugPrint('Building request list for status: $status');
    debugPrint('Total requests in map: ${requestsMap.length}');
    
    var requests = requestsMap.entries.where((entry) {
      final requestData = Map<String, dynamic>.from(entry.value as Map);
      final requestStatus = requestData['status']?.toString().toLowerCase();
      
      debugPrint('Request ${entry.key} status: $requestStatus');
      
      return requestStatus == status;
    }).toList();

    debugPrint('Filtered requests for status $status: ${requests.length}');

    if (_searchQuery.isNotEmpty) {
      requests = requests.where((entry) {
        final requestData = Map<String, dynamic>.from(entry.value as Map);
        final searchableFields = [
          requestData['customerPhone']?.toString().toLowerCase() ?? '',
          requestData['fixerName']?.toString().toLowerCase() ?? '',
          requestData['category']?.toString().toLowerCase() ?? '',
          requestData['description']?.toString().toLowerCase() ?? '',
        ];
        return searchableFields.any((field) => field.contains(_searchQuery));
      }).toList();
    }

    if (_filterCategory != 'all') {
      requests = requests.where((entry) {
        final requestData = Map<String, dynamic>.from(entry.value as Map);
        return requestData['category']?.toString().toLowerCase() == _filterCategory;
      }).toList();
    }

    requests.sort((a, b) {
      final aData = Map<String, dynamic>.from(a.value as Map);
      final bData = Map<String, dynamic>.from(b.value as Map);
      
      switch (_sortBy) {
        case 'newest':
          return _getTimestamp(bData).compareTo(_getTimestamp(aData));
        case 'oldest':
          return _getTimestamp(aData).compareTo(_getTimestamp(bData));
        case 'price_high':
          final aPrice = double.tryParse(aData['totalAmount']?.toString() ?? '0') ?? 0;
          final bPrice = double.tryParse(bData['totalAmount']?.toString() ?? '0') ?? 0;
          return bPrice.compareTo(aPrice);
        case 'price_low':
          final aPrice = double.tryParse(aData['totalAmount']?.toString() ?? '0') ?? 0;
          final bPrice = double.tryParse(bData['totalAmount']?.toString() ?? '0') ?? 0;
          return aPrice.compareTo(bPrice);
        default:
          return _getTimestamp(bData).compareTo(_getTimestamp(aData));
      }
    });

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getStatusIcon(status),
              size: 64,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${status.replaceAll('_', ' ')} requests found',
              style: TextStyle(fontSize: 18, color: AppColors.textDark),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _refreshData();
      },
      color: AppColors.primary,
      child: ListView.builder(
        itemCount: requests.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) => _buildRequestCard(requests[index], status),
      ),
    );
  }

  int _getTimestamp(Map<dynamic, dynamic> data) {
    return int.tryParse(data['createdAt']?.toString() ?? '0') ?? 0;
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'completed':
        return Icons.check_circle;
      case 'canceled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildRequestCard(MapEntry<dynamic, dynamic> request, String status) {
    final requestId = request.key;
    final requestData = Map<String, dynamic>.from(request.value as Map);
    final statusColor = _statusColors[status] ?? Colors.grey;
    
    final formattedId = requestId.toString().substring(0, 6).toUpperCase();
    final createdDate = _formatDate(requestData['createdAt']?.toString());
    final amount = requestData['totalAmount']?.toString() ?? 'Not set';
    final customerPhone = requestData['customerPhone']?.toString() ?? 'Not provided';
    final category = requestData['category']?.toString() ?? 'Not specified';
    final fixerName = requestData['fixerName']?.toString() ?? 'Not assigned';

    debugPrint('Building card for request $requestId with status: $status');
    debugPrint('Problems data: ${requestData['problems']}');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.5), width: 2),
      ),
      color: AppColors.cardColor,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(_getStatusIcon(status), color: statusColor),
        ),
        title: Row(
          children: [
            Text(
              '#$formattedId',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '$category • $createdDate',
          style: TextStyle(color: AppColors.textLight),
        ),
        trailing: Text(
          '$amount L.E',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailSection(
                  'Request Details',
                  Icons.info_outline,
                  [
                    _buildInfoRow('ID:', Text('#$formattedId')),
                    _buildInfoRow('Category:', Text(category)),
                    _buildInfoRow('Problem:', Text(_getProblemDescription(requestData['problems']))),
                    _buildInfoRow('Amount:', Text('$amount L.E')),
                    _buildInfoRow('Payment Method:', Text(requestData['paymentMethod']?.toString().toUpperCase() ?? 'Not set')),
                    if (requestData['description'] != null)
                      _buildInfoRow('Description:', Text(requestData['description'].toString())),
                  ],
                ),
                
                const Divider(color: Colors.grey),
                
                _buildDetailSection(
                  'People',
                  Icons.people_outline,
                  [
                    _buildInfoRow('Customer:', Text(customerPhone)),
                    _buildInfoRow('Fixer:', Text(fixerName), trailing: fixerName != 'Not assigned' 
                      ? null
                      : status == 'pending' 
                          ? TextButton(
                              onPressed: () => _showFixerAssignmentDialog(requestId.toString()),
                              child: Text('Assign', style: TextStyle(color: AppColors.primary)),
                            )
                          : null
                    ),
                  ],
                ),
                
                const Divider(color: Colors.grey),
                
                _buildDetailSection(
                  'Timeline',
                  Icons.timeline,
                  [
                    _buildTimelineItem('Created', _formatDate(requestData['createdAt']?.toString()), Icons.add_circle_outline),
                    if (status == 'completed')
                      _buildTimelineItem('Completed', _formatDate(requestData['completedAt']?.toString() ?? ''), Icons.check_circle_outline),
                    if (status == 'canceled')
                      _buildTimelineItem('Canceled', _formatDate(requestData['canceledAt']?.toString() ?? ''), Icons.cancel_outlined),
                  ],
                ),
                
                if (status == 'canceled' && requestData['cancellationReason'] != null) ...[
                  const Divider(color: Colors.grey),
                  _buildDetailSection(
                    'Cancellation Details',
                    Icons.error_outline,
                    [
                      _buildInfoRow('Reason:', Text(requestData['cancellationReason'].toString())),
                    ],
                  ),
                ],
                
                if (status == 'completed') ...[
                  const Divider(color: Colors.grey),
                  _buildDetailSection(
                    'Feedback',
                    Icons.star_outline,
                    [
                      if (requestData['rating'] != null)
                        _buildInfoRow('Rating:', _buildStarRating(requestData['rating'])),
                      if (requestData['review'] != null)
                        _buildInfoRow('Review:', Text(requestData['review'].toString())),
                    ],
                  ),
                ],
                
                const SizedBox(height: 16),
                _buildActionButtons(context, requestId.toString(), status, requestData),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailSection(String title, IconData icon, List<Widget> children) {
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
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildTimelineItem(String label, String timestamp, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textLight),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.textDark),
          ),
          const Spacer(),
          Text(
            timestamp,
            style: TextStyle(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(dynamic rating) {
    final int starCount = int.tryParse(rating.toString()) ?? 0;
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < starCount ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        );
      }),
    );
  }

  Widget _buildInfoRow(String label, Widget value, {Widget? trailing}) {
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
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
            ),
          ),
          Expanded(
            child: DefaultTextStyle(
              style: TextStyle(color: AppColors.textDark),
              child: value,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  String _getProblemDescription(dynamic problems) {
    debugPrint('Problems type: ${problems.runtimeType}');
    debugPrint('Problems value: $problems');

    if (problems == null) return 'Not provided';
    
    if (problems is Map) {
      final StringBuffer buffer = StringBuffer();
      
      problems.forEach((key, value) {
        if (key == 'note') {
          buffer.write('Note: $value\n');
        } else if (value is Map) {
          buffer.write('• $key\n');
          if (value.containsKey('max') || value.containsKey('min')) {
            buffer.write('  Price Range: ');
            if (value.containsKey('min')) buffer.write('${value['min']} L.E');
            if (value.containsKey('max')) buffer.write(' - ${value['max']} L.E');
            buffer.write('\n');
          }
        } else {
          buffer.write('• $key: $value\n');
        }
      });
      
      final result = buffer.toString().trim();
      debugPrint('Formatted problem description: $result');
      return result;
    }
    
    return problems.toString();
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null) return 'Not set';
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
      final formatter = DateFormat('MMM dd, yyyy • HH:mm');
      return formatter.format(date);
    } catch (e) {
      return timestamp;
    }
  }

  Widget _buildActionButtons(BuildContext context, String requestId, String status, Map<dynamic, dynamic> requestData) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (status == 'pending') ...[
            _actionButton(
              label: 'Complete',
              icon: Icons.check_circle,
              color: Colors.green,
              onPressed: () => _updateRequestStatus(context, requestId, 'completed'),
            ),
            const SizedBox(width: 4),
          ],
          _actionButton(
            label: 'Edit',
            icon: Icons.edit,
            color: Colors.orange,
            onPressed: () => _showEditDialog(context, requestId, requestData),
          ),
          const SizedBox(width: 4),
          _actionButton(
            label: 'Delete',
            icon: Icons.delete,
            color: AppColors.accent,
            onPressed: () => _showDeleteConfirmation(context, requestId),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(0, 36),
      ),
    );
  }

  void _showFixerAssignmentDialog(String requestId) {
    final TextEditingController fixerController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.cardColor,
        title: Text(
          'Assign Fixer',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: fixerController,
              decoration: InputDecoration(
                labelText: 'Fixer Name',
                hintStyle: TextStyle(color: AppColors.textLight),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              style: TextStyle(color: AppColors.textDark),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textDark)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (fixerController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Please enter a fixer name'),
                    backgroundColor: AppColors.accent,
                    action: SnackBarAction(
                      label: 'Dismiss',
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  ),
                );
                return;
              }
              
              try {
                await database.child(requestId).update({
                  'fixerName': fixerController.text,
                });
                if (mounted) {
                  Navigator.pop(context);
                  _refreshData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Fixer ${fixerController.text} assigned successfully'),
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
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error assigning fixer: $e'),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Assign', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, String requestId, Map<dynamic, dynamic> requestData) {
    final TextEditingController totalAmountController = TextEditingController(
      text: requestData['totalAmount']?.toString() ?? '',
    );
    final TextEditingController descriptionController = TextEditingController(
      text: requestData['description']?.toString() ?? '',
    );
    String? selectedPaymentMethod = requestData['paymentMethod']?.toString() ?? 'cash';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.cardColor,
        title: Text(
          'Edit Request',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: totalAmountController,
                decoration: InputDecoration(
                  labelText: 'Total Amount (L.E)',
                  hintStyle: TextStyle(color: AppColors.textLight),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                keyboardType: TextInputType.number,
                style: TextStyle(color: AppColors.textDark),
              ),
              const SizedBox(height: 16),
              Text(
                'Payment Method:',
                style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
              ),
              RadioListTile<String>(
                title: Text('Cash', style: TextStyle(color: AppColors.textDark)),
                value: 'cash',
                groupValue: selectedPaymentMethod,
                activeColor: AppColors.primary,
                onChanged: (value) {
                  selectedPaymentMethod = value;
                },
              ),
              RadioListTile<String>(
                title: Text('Credit Card', style: TextStyle(color: AppColors.textDark)),
                value: 'credit_card',
                groupValue: selectedPaymentMethod,
                activeColor: AppColors.primary,
                onChanged: (value) {
                  selectedPaymentMethod = value;
                },
              ),
              RadioListTile<String>(
                title: Text('Online Payment', style: TextStyle(color: AppColors.textDark)),
                value: 'online',
                groupValue: selectedPaymentMethod,
                activeColor: AppColors.primary,
                onChanged: (value) {
                  selectedPaymentMethod = value;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
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
                style: TextStyle(color: AppColors.textDark),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textDark)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await database.child(requestId).update({
                  'totalAmount': totalAmountController.text,
                  'paymentMethod': selectedPaymentMethod,
                  'description': descriptionController.text,
                  'lastUpdated': DateTime.now().millisecondsSinceEpoch.toString(),
                });
                if (mounted) {
                  Navigator.pop(context);
                  _refreshData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Request updated successfully'),
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
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating request: $e'),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _updateRequestStatus(BuildContext context, String requestId, String newStatus) {
    if (newStatus == 'canceled') {
      _showCancelConfirmationDialog(context, requestId);
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppColors.cardColor,
          title: Text(
            'Mark as ${newStatus.replaceAll('_', ' ')}',
            style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Are you sure you want to mark this request as ${newStatus.replaceAll('_', ' ')}?',
            style: TextStyle(color: AppColors.textLight),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppColors.textDark)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final updates = <String, dynamic>{
                    'status': newStatus,
                    'lastUpdated': DateTime.now().millisecondsSinceEpoch.toString(),
                  };
                  
                  if (newStatus == 'completed') {
                    updates['completedAt'] = DateTime.now().millisecondsSinceEpoch.toString();
                  }
                  
                  await database.child(requestId).update(updates);
                  
                  if (mounted) {
                    Navigator.pop(context);
                    _refreshData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Request marked as ${newStatus.replaceAll('_', ' ')}'),
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
                    Navigator.pop(context);
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirm', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  void _showCancelConfirmationDialog(BuildContext context, String requestId) {
    String? selectedReason;
    String? otherReason;
    final List<String> cancellationReasons = [
      'Changed mind',
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppColors.cardColor,
          title: Text(
            'Cancel Request',
            style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Please select a reason for cancellation:',
                  style: TextStyle(color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                ...cancellationReasons.map((reason) {
                  return RadioListTile<String>(
                    title: Text(reason, style: TextStyle(color: AppColors.textDark)),
                    value: reason,
                    groupValue: selectedReason,
                    activeColor: AppColors.primary,
                    onChanged: (String? value) {
                      setState(() {
                        selectedReason = value;
                        if (value != 'Other (please specify)') {
                          otherReason = null;
                        }
                      });
                    },
                  );
                }),
                if (selectedReason == 'Other (please specify)')
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Please specify your reason',
                        hintStyle: TextStyle(color: AppColors.textLight),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      style: TextStyle(color: AppColors.textDark),
                      onChanged: (value) {
                        otherReason = value;
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppColors.textDark)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedReason == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please select a reason for cancellation'),
                      backgroundColor: AppColors.accent,
                      action: SnackBarAction(
                        label: 'Dismiss',
                        textColor: Colors.white,
                        onPressed: () {},
                      ),
                    ),
                  );
                  return;
                }
                if (selectedReason == 'Other (please specify)' && (otherReason == null || otherReason!.isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please specify your reason'),
                      backgroundColor: AppColors.accent,
                      action: SnackBarAction(
                        label: 'Dismiss',
                        textColor: Colors.white,
                        onPressed: () {},
                      ),
                    ),
                  );
                  return;
                }

                final reason = selectedReason == 'Other (please specify)' ? otherReason : selectedReason;
                
                try {
                  await database.child(requestId).update({
                    'status': 'canceled',
                    'cancellationReason': reason,
                    'canceledAt': DateTime.now().millisecondsSinceEpoch.toString(),
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    _refreshData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Request has been canceled'),
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
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error canceling request: $e'),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirm', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String requestId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.cardColor,
        title: Text(
          'Delete Request',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, color: AppColors.accent, size: 64),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to delete this request? This action cannot be undone.',
              style: TextStyle(color: AppColors.textLight),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textDark)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              try {
                await database.child(requestId).remove();
                if (mounted) {
                  Navigator.pop(context);
                  _refreshData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Request deleted successfully'),
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
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting request: $e'),
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
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}