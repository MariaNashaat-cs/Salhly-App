import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'homepage.dart';
import 'dart:async';

class WalletScreen extends StatefulWidget {
  final String userId;
  final String fullName;
  final String phoneNumber;

  const WalletScreen({
    super.key, 
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  double _balance = 0.0;
  List<Map<String, dynamic>> _transactions = [];
  StreamSubscription? _balanceSubscription;
  StreamSubscription? _transactionsSubscription;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
    _setupRealtimeListeners();
  }

  @override
  void dispose() {
    _balanceSubscription?.cancel();
    _transactionsSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeListeners() {
    _balanceSubscription = _database.child('wallets/${widget.userId}/balance').onValue.listen((event) {
      if (mounted) {
        setState(() {
          if (event.snapshot.value != null) {
            if (event.snapshot.value is double) {
              _balance = event.snapshot.value as double;
            } else if (event.snapshot.value is int) {
              _balance = (event.snapshot.value as int).toDouble();
            } else if (event.snapshot.value is String) {
              _balance = double.tryParse(event.snapshot.value as String) ?? 0.0;
            }
          }
        });
      }
    });

    _transactionsSubscription = _database.child('wallets/${widget.userId}/transactions').onValue.listen((event) {
      if (mounted) {
        setState(() {
          if (event.snapshot.value != null) {
            final transactionsMap = event.snapshot.value as Map<dynamic, dynamic>;
            _transactions = transactionsMap.entries.map((entry) {
              final transaction = entry.value as Map<dynamic, dynamic>;
              double amount = transaction['amount'] is double 
                  ? transaction['amount'] 
                  : (transaction['amount'] is int 
                      ? (transaction['amount'] as int).toDouble()
                      : double.tryParse(transaction['amount'].toString()) ?? 0.0);
              
              return {
                'type': transaction['type'] as String,
                'amount': amount,
                'date': transaction['date'] as String,
              };
            }).toList();
          } else {
            _transactions = [];
          }
        });
      }
    });
  }

  Future<void> _loadWalletData() async {
    try {
      final balanceSnapshot = await _database.child('wallets/${widget.userId}/balance').get();
      final transactionsSnapshot = await _database.child('wallets/${widget.userId}/transactions').get();

      if (mounted) {
        setState(() {
          if (balanceSnapshot.value != null) {
            if (balanceSnapshot.value is double) {
              _balance = balanceSnapshot.value as double;
            } else if (balanceSnapshot.value is int) {
              _balance = (balanceSnapshot.value as int).toDouble();
            } else if (balanceSnapshot.value is String) {
              _balance = double.tryParse(balanceSnapshot.value as String) ?? 0.0;
            } else {
              _balance = 0.0;
            }
          } else {
            _balance = 0.0;
          }

          if (transactionsSnapshot.value != null) {
            final transactionsMap = transactionsSnapshot.value as Map<dynamic, dynamic>;
            _transactions = transactionsMap.entries.map((entry) {
              final transaction = entry.value as Map<dynamic, dynamic>;
              double amount = transaction['amount'] is double 
                  ? transaction['amount'] 
                  : (transaction['amount'] is int 
                      ? (transaction['amount'] as int).toDouble()
                      : double.tryParse(transaction['amount'].toString()) ?? 0.0);
              
              return {
                'type': transaction['type'] as String,
                'amount': amount,
                'date': transaction['date'] as String,
              };
            }).toList();
          } else {
            _transactions = [];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading wallet data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        backgroundColor: const Color(0xFF0C5FB3),
        automaticallyImplyLeading: false, // Remove back arrow
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
             Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HomePage(
                          fullName: widget.fullName, 
                          phoneNumber: widget.phoneNumber,
                        )),
                      );
            },
            tooltip: 'Go to Homepage',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Balance',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_balance.toStringAsFixed(2)} L.E',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0C5FB3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Transaction History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _transactions.isEmpty
                  ? const Center(
                      child: Text(
                        'No transactions yet',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = _transactions[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              transaction['type'] == 'refund'
                                  ? Icons.arrow_circle_up
                                  : Icons.arrow_circle_down,
                              color: transaction['type'] == 'refund'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            title: Text(
                              transaction['type'] == 'refund'
                                  ? 'Refund'
                                  : 'Payment',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              transaction['date'] ?? '',
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                            trailing: Text(
                              '${transaction['amount'].toStringAsFixed(2)} L.E',
                              style: TextStyle(
                                color: transaction['type'] == 'refund'
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class WalletManager {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();

  static Future<void> addRefund(String userId, double amount) async {
    try {
      final balanceSnapshot = await _database.child('wallets/$userId/balance').get();
      double currentBalance = 0.0;

      if (balanceSnapshot.value != null) {
        if (balanceSnapshot.value is double) {
          currentBalance = balanceSnapshot.value as double;
        } else if (balanceSnapshot.value is int) {
          currentBalance = (balanceSnapshot.value as int).toDouble();
        } else if (balanceSnapshot.value is String) {
          currentBalance = double.tryParse(balanceSnapshot.value as String) ?? 0.0;
        }
      }

      await _database.child('wallets/$userId/balance').set((currentBalance + amount));

      final transactionRef = _database.child('wallets/$userId/transactions').push();
      await transactionRef.set({
        'type': 'refund',
        'amount': amount,
        'date': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to add refund: $e');
    }
  }

  static Future<double> getBalance(String userId) async {
    try {
      final snapshot = await _database.child('wallets/$userId/balance').get();
      if (snapshot.value != null) {
        if (snapshot.value is double) {
          return snapshot.value as double;
        } else if (snapshot.value is int) {
          return (snapshot.value as int).toDouble();
        } else if (snapshot.value is String) {
          return double.tryParse(snapshot.value as String) ?? 0.0;
        }
      }
      return 0.0;
    } catch (e) {
      throw Exception('Failed to get balance: $e');
    }
  }

  static Future<void> makePayment(String userId, double amount) async {
    try {
      final balanceSnapshot = await _database.child('wallets/$userId/balance').get();
      double currentBalance = 0.0;

      if (balanceSnapshot.value != null) {
        if (balanceSnapshot.value is double) {
          currentBalance = balanceSnapshot.value as double;
        } else if (balanceSnapshot.value is int) {
          currentBalance = (balanceSnapshot.value as int).toDouble();
        } else if (balanceSnapshot.value is String) {
          currentBalance = double.tryParse(balanceSnapshot.value as String) ?? 0.0;
        }
      }

      if (currentBalance < amount) {
        throw Exception('Insufficient balance');
      }

      await _database.child('wallets/$userId/balance').set((currentBalance - amount));

      final transactionRef = _database.child('wallets/$userId/transactions').push();
      await transactionRef.set({
        'type': 'payment',
        'amount': amount,
        'date': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to make payment: $e');
    }
  }
}