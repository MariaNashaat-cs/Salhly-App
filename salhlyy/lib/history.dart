import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'trackorder.dart';

class HistoryPage extends StatefulWidget {
  final String phoneNumber;
  final String fullName;
  const HistoryPage({
    super.key, 
    required this.phoneNumber,
    required this.fullName,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref('serviceRequests');
  List<Map<dynamic, dynamic>> _orders = [];
  bool _isLoading = true;
  
  // For filtering
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Pending', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final snapshot = await _database.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _orders = data.entries
              .map((entry) {
                final order = Map<dynamic, dynamic>.from(entry.value as Map);
                order['key'] = entry.key;
                return order;
              })
              .where((order) => order['customerPhone'] == widget.phoneNumber)
              .toList();
          
          _orders.sort((a, b) => 
            (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0)
          );
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error loading orders: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<dynamic, dynamic>> get _filteredOrders {
    if (_selectedFilter == 'All') {
      return _orders;
    } else {
      return _orders.where((order) => 
        (order['status'] ?? '').toLowerCase() == _selectedFilter.toLowerCase()
      ).toList();
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green.shade700;
      case 'pending':
        return Colors.amber.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'pending':
        return Icons.pending_outlined;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp.toString()));
      return DateFormat('MMM dd, yyyy · HH:mm').format(date);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  Future<void> _cancelOrder(String orderKey) async {
    try {
      await _database.child(orderKey).update({'status': 'cancelled'});
      _showSnackBar('Order cancelled successfully');
      await _loadOrders(); // Refresh the orders list
    } catch (e) {
      _showSnackBar('Error cancelling order: $e', isError: true);
    }
  }

  void _trackOrder(Map<dynamic, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderTrackingScreen(
          orderId: order['orderId'],
          fullName: widget.fullName,
          phoneNumber: widget.phoneNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.bold,fontFamily: 'Playfair_Display')),
        centerTitle: true,
        backgroundColor: Color(0xFF0C5FB3),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                // Filter chips
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filterOptions.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (isSelected) {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            },
                            backgroundColor: Colors.white,
                            selectedColor: theme.primaryColor.withOpacity(0.1),
                            checkmarkColor: theme.primaryColor,
                            labelStyle: TextStyle(
                              color: isSelected ? theme.primaryColor : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? theme.primaryColor : Colors.grey.shade300,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                
                Expanded(
                  child: _filteredOrders.isEmpty
                    ? _buildEmptyState()
                    : _buildOrdersList(),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedFilter == 'All' ? Icons.shopping_bag_outlined : _getStatusIcon(_selectedFilter),
            size: 80, 
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'All' 
                ? 'No orders found' 
                : 'No ${_selectedFilter.toLowerCase()} orders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'All'
                ? 'Your order history will appear here'
                : 'Try selecting a different filter',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return ListView.builder(
      itemCount: _filteredOrders.length,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemBuilder: (context, index) {
        final order = _filteredOrders[index];
        final createdDate = _formatTimestamp(order['createdAt']);
        final status = (order['status'] ?? '').toLowerCase();
        final isPending = status == 'pending';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              childrenPadding: EdgeInsets.zero,
              leading: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                  size: 24,
                ),
              ),
              title: Text(
                'Order #${order['orderId']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    createdDate,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusChip(status),
                ],
              ),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('Category', order['category'] ?? 'N/A'),
                            _buildInfoRow('Fixer Name', order['fixerName'] ?? 'N/A'),
                            _buildInfoRow('Fixer Price', 'L.E${order['fixerPrice'] ?? 0}'),
                            _buildInfoRow('Total Amount', 'L.E${order['totalAmount'] ?? 0}'),
                            _buildInfoRow('Payment Method', order['paymentMethod'] ?? 'N/A'),
                            
                            if (order['description'] != null)
                              _buildInfoRow('Description', order['description']),
                              
                            if (order['problems'] != null)
                              _buildInfoRow('Problems', order['problems'].toString()),
                          ],
                        ),
                      ),
                      
                      if (isPending)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _trackOrder(order),
                                  icon: const Icon(Icons.location_on_outlined),
                                  label: const Text('Track Order'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Cancel Order'),
                                        content: const Text('Are you sure you want to cancel this order?'),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('No'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _cancelOrder(order['key']);
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                            child: const Text('Yes, Cancel'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.cancel_outlined),
                                  label: const Text('Cancel'),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.red),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    textStyle: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}