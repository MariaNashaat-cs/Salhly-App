import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // For formatting timestamps
import 'user_dialog.dart'; // Assuming this is your custom dialog

class AppColors {
  static const Color primary = Color(0xFF0C5FB3);
  static const Color secondary = Color(0xFF3D82C6);
  static const Color accent = Color.fromARGB(255, 224, 37, 4);
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A); // Darker text color
  static const Color textLight = Color(0xFF4A4A4A); // Darker light text color
}

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final database = FirebaseDatabase.instance.ref('users');
  String _searchQuery = '';

  bool _matchesSearch(dynamic userData) {
    if (userData is! Map<dynamic, dynamic>) return false;

    if (_searchQuery.isEmpty) return true;

    final searchLower = _searchQuery.toLowerCase();
    final name = (userData['fullName'] ?? '').toString().toLowerCase();
    final email = (userData['email'] ?? '').toString().toLowerCase();
    final phone = (userData['phoneNumber'] ?? '').toString().toLowerCase();

    return name.contains(searchLower) || email.contains(searchLower) || phone.contains(searchLower);
  }

  String _formatOrders(Map<dynamic, dynamic>? orders) {
    if (orders == null) return 'No orders available';
    final orderList = orders.entries.map((entry) {
      final order = entry.value as Map<dynamic, dynamic>;
      final timestamp = order['timestamp'] as int?;
      final formattedTimestamp = timestamp != null
          ? DateFormat('MMMM d, yyyy, h:mm a').format(DateTime.fromMillisecondsSinceEpoch(timestamp))
          : 'N/A';
      return '- Order #${order['orderNumber']}:\n'
          '  Status: ${order['status']}\n'
          '  Total Amount: ${order['totalAmount']}\n'
          '  Fixer: ${order['fixerName']}\n'
          '  Payment Method: ${order['paymentMethod']}\n'
          '  Timestamp: $formattedTimestamp\n'
          '  Fixer Price: ${order['fixerPrice'] ?? 'N/A'}\n'
          '  Discount: ${order['discountAmount'] ?? 0}\n'
          '  ${order['status'] == 'canceled' ? 'Cancellation Reason: ${order['cancellationReason'] ?? 'N/A'}\n' : ''}';
    }).join('\n');
    return orderList.isEmpty ? 'No orders available' : orderList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'User Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Playfair_Display'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search users by name, email, or phone',
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
                  _searchQuery = value;
                });
              },
            ),
          ),
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
                          'Error loading users',
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
                          'No users found',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        TextButton(
                          onPressed: () => showDialog(
                            context: context,
                            builder: (context) => const UserDialog(),
                          ),
                          child: Text(
                            'Add New User',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final users = data.entries
                    .where((entry) => _matchesSearch(entry.value))
                    .toList();

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: AppColors.textLight),
                        const SizedBox(height: 16),
                        Text(
                          'No users match your search',
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
                            });
                          },
                          child: Text(
                            'Clear Search',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final userId = user.key;
                    final userData = user.value as Map<dynamic, dynamic>;

                    return Card(
                      elevation: 3,
                      color: AppColors.cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text(
                            (userData['fullName'] as String?)?.isNotEmpty == true
                                ? (userData['fullName'] as String).substring(0, 1).toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Text(
                          userData['fullName']?.toString() ?? 'No Name',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        subtitle: Text(
                          userData['phoneNumber']?.toString() ?? 'No Phone',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textLight,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(),
                                _buildInfoRow('Email', userData['email']?.toString() ?? 'No Email'),
                                _buildInfoRow('Gender', userData['gender']?.toString() ?? 'Not Specified'),
                                if (userData['countryCode'] != null || userData['countryName'] != null)
                                  _buildInfoRow(
                                    'Location',
                                    '${userData['countryName']?.toString() ?? ''} (${userData['countryCode']?.toString() ?? ''})',
                                  ),
                                if (userData['selectedAddress'] != null)
                                  _buildInfoRow('Address', userData['selectedAddress'].toString()),
                                if (userData['verified'] != null)
                                  _buildInfoRow('Verified', userData['verified'].toString()),
                                if (userData['timestamp'] != null)
                                  _buildInfoRow(
                                    'Timestamp',
                                    userData['timestamp'] is int
                                        ? DateFormat('MMMM d, yyyy, h:mm a').format(
                                            DateTime.fromMillisecondsSinceEpoch(userData['timestamp'] as int),
                                          )
                                        : 'N/A',
                                  ),
                                // Orders Section
                                if (userData['orders'] != null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    'Orders',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatOrders(userData['orders']),
                                    style: TextStyle(color: AppColors.textLight),
                                  ),
                                ],
                                // Appointments Section
                                if (userData['appointments'] != null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    'Appointments',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    userData['appointments'].toString(),
                                    style: TextStyle(color: AppColors.textLight),
                                  ),
                                ],
                                // Problems Section
                                if (userData['plumbingproblem'] != null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    'Plumbing Problem',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    userData['plumbingproblem'].toString(),
                                    style: TextStyle(color: AppColors.textLight),
                                  ),
                                ],
                                if (userData['electricalproblem'] != null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    'Electrical Problem',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    userData['electricalproblem'].toString(),
                                    style: TextStyle(color: AppColors.textLight),
                                  ),
                                ],
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
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (context) => UserDialog(userId: userId, userData: userData),
                                      ),
                                    ),
                                    TextButton.icon(
                                      icon: Icon(Icons.delete, color: AppColors.accent),
                                      label: Text(
                                        'Delete',
                                        style: TextStyle(color: AppColors.accent),
                                      ),
                                      onPressed: () => _confirmDelete(
                                          context, userId, userData['fullName']?.toString() ?? 'this user'),
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
            ),
          ),
        ],
      ),
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

  void _confirmDelete(BuildContext context, String userId, String name) {
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
              database.child(userId).remove();
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
}