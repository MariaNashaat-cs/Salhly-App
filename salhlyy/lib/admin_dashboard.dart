import 'package:flutter/material.dart';
import 'user_managment.dart';
import 'technician_management.dart';
import 'service_request_management.dart';
import 'complaint_management.dart';
import 'analytics_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'main.dart';

class AppTheme {
  static const Color primary = Color(0xFF0C5FB3);
  static const Color secondary = Color(0xFF3D82C6);
  static const Color accent = Color.fromARGB(255, 224, 37, 4);
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color textDark = Color(0xFF2D3142);
  static const Color textLight = Color(0xFF8D99AE);
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  bool _isAuthenticated = false;
  bool _isLoading = true;
  final _passwordController = TextEditingController();
  final _adminPassword = '3absomaria'; // Preserved password
  Timer? _sessionTimer;
  final int _sessionTimeout = 30; // Session timeout in minutes

  @override
  void initState() {
    super.initState();
    // Check if user is already authenticated
    _checkAuthentication();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _sessionTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    final authStatus = prefs.getBool('admin_authenticated') ?? false;
    final lastActive = prefs.getInt('last_active_time') ?? 0;
    
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final isSessionValid = (currentTime - lastActive) < (_sessionTimeout * 60 * 1000);
    
    setState(() {
      _isAuthenticated = authStatus && isSessionValid;
      _isLoading = false;
    });
    
    if (_isAuthenticated) {
      _startSessionTimer();
      _updateLastActiveTime();
    } else {
      // Use addPostFrameCallback to ensure the context is available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _promptForPassword();
      });
    }
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _updateLastActiveTime();
    });
  }

  Future<void> _updateLastActiveTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_active_time', DateTime.now().millisecondsSinceEpoch);
  }

  void _promptForPassword() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Admin Access', style: TextStyle(color: AppTheme.textDark)),
        content: TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Enter Admin Password',
            labelStyle: TextStyle(color: AppTheme.textLight),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primary, width: 2),
            ),
          ),
          obscureText: true,
          onSubmitted: (value) {
            _validatePassword();
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Exit admin dashboard
            },
            child: Text('Cancel', style: TextStyle(color: AppTheme.textLight)),
          ),
          ElevatedButton(
            onPressed: _validatePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Submit'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppTheme.cardColor,
      ),
    );
  }

  Future<void> _validatePassword() async {
    if (_passwordController.text == _adminPassword) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('admin_authenticated', true);
      await _updateLastActiveTime();
      
      setState(() {
        _isAuthenticated = true;
      });
      
      _startSessionTimer();
      
      if (mounted) Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Login successful. Welcome to the admin dashboard!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid password. Please try again.'),
          backgroundColor: AppTheme.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      _passwordController.clear();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _updateLastActiveTime();
  }

  final List<Widget> _pages = [
    const UserManagementPage(),
    const TechnicianManagementPage(),
    const ServiceRequestManagementPage(),
    const ComplaintManagementPage(),
    const AnalyticsPage(),
  ];

  final List<String> _pageTitles = [
    'User Management',
    'Technician Management',
    'Service Requests',
    'Complaints Management',
    'Analytics',
  ];

  final List<IconData> _pageIcons = [
    Icons.people,
    Icons.handyman,
    Icons.request_page,
    Icons.report_problem,
    Icons.analytics,
  ];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (!_isAuthenticated) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: AppTheme.primary),
              const SizedBox(height: 16),
              Text(
                'Admin Authentication Required',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _promptForPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Login as Admin'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: Text('Salحly Admin '),
        elevation: 0,
      ),
      drawer: Drawer(
        backgroundColor: AppTheme.cardColor,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: AppTheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 30,
                        child: Icon(Icons.admin_panel_settings, size: 35, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Salحly Admin',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Dashboard',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _pageTitles.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(
                      _pageIcons[index],
                      color: _selectedIndex == index ? AppTheme.primary : AppTheme.textLight,
                    ),
                    title: Text(
                      _pageTitles[index],
                      style: TextStyle(
                        color: _selectedIndex == index ? AppTheme.primary : AppTheme.textDark,
                        fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: _selectedIndex == index,
                    selectedTileColor: AppTheme.primary.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () {
                      _onItemTapped(index);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.info_outline, color: AppTheme.textLight),
              title: Text('About', style: TextStyle(color: AppTheme.textDark)),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: AppTheme.accent),
              title: Text('Logout', style: TextStyle(color: AppTheme.accent)),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      body: SafeArea(
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width < 600
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor: AppTheme.primary,
              unselectedItemColor: AppTheme.textLight,
              backgroundColor: AppTheme.cardColor,
              type: BottomNavigationBarType.fixed,
              items: [
                BottomNavigationBarItem(icon: Icon(_pageIcons[0]), label: 'Users'),
                BottomNavigationBarItem(icon: Icon(_pageIcons[1]), label: 'Technicians'),
                BottomNavigationBarItem(icon: Icon(_pageIcons[2]), label: 'Services'),
                BottomNavigationBarItem(icon: Icon(_pageIcons[3]), label: 'Complaints'),
                BottomNavigationBarItem(icon: Icon(_pageIcons[4]), label: 'Analytics'),
              ],
            )
          : null,
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About Salحly Admin', style: TextStyle(color: AppTheme.textDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Salحly Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            Text('Version 1.0.0', style: TextStyle(color: AppTheme.textLight)),
            const SizedBox(height: 16),
            Text('Copyright ©️ 2025 Salحly', style: TextStyle(color: AppTheme.textLight)),
            const SizedBox(height: 8),
            Text('All rights reserved', style: TextStyle(color: AppTheme.textLight)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppTheme.cardColor,
      ),
    );
  }
}