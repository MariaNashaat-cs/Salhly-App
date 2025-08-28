import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'wallet.dart';
import 'fixerinfo.dart';
import 'dart:async';
import 'PlumbingProblem.dart';
import 'electricianproblem.dart';
import 'main.dart';
import 'salhbot.dart';
import 'video.dart';
import 'homepageprofile.dart';
import 'contactus.dart';
import 'help_faq.dart';
import 'history.dart';

// Constants
class AppColors {
  static const Color primary = Color(0xFF0C5FB3);
  static const Color secondary = Color(0xFF3D82C6);
  static const Color accent = Color.fromARGB(255, 224, 37, 4);
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color textDark = Color(0xFF2D3142);
  static const Color textLight = Color(0xFF8D99AE);
}

class AppStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 34,
    fontFamily: 'Playfair_Display',
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 27,
    fontFamily: 'Playfair_Display',
    fontWeight: FontWeight.w500,
    color: AppColors.textDark,
  );

  static const TextStyle categoryTitle = TextStyle(
    fontSize: 22,
    fontFamily: 'Playfair_Display',
    color: AppColors.primary,
    fontWeight: FontWeight.bold,
  );

  static BoxDecoration cardDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    color: AppColors.cardColor,
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.2),
        spreadRadius: 2,
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

class HomePage extends StatefulWidget {
  final String fullName;
  final String phoneNumber;
  const HomePage({super.key, required this.fullName, required this.phoneNumber});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _hideOverlay();
    _searchController.dispose();
    super.dispose();
  }

  void _showOverlay() {
    _hideOverlay();
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 45),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: _buildSearchResults(),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
    });
    
    if (_isSearching) {
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fullName.toLowerCase() != "guest" && !NotificationsPage.hasShownWelcomeNotification) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationsPage.addNotification(
          title: 'Welcome back, ${widget.fullName}!',
          message: 'Thank you for being our valued customer.',
        );
        NotificationsPage.hasShownWelcomeNotification = true;
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: CompositedTransformTarget(
          link: _layerLink,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _handleSearch,
              decoration: InputDecoration(
                hintText: 'Find your service',
                hintStyle: TextStyle(color: AppColors.textLight),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppColors.primary),
                        onPressed: () {
                          _searchController.clear();
                          _handleSearch('');
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: NotificationsPage.unreadNotifications,
            builder: (context, value, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                    onPressed: () {
                      NotificationsPage.unreadNotifications.value = 0;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationsPage()),
                      );
                    },
                  ),
                  if (value > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          value > 9 ? '9+' : '$value',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: AppDrawer(fullName: widget.fullName, phoneNumber: widget.phoneNumber),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WelcomeComponent(fullName: widget.fullName),
              const SlideshowComponent(),
              CategoriesComponent(fullName: widget.fullName, phoneNumber: widget.phoneNumber),
              RecentServicesComponent(phoneNumber: widget.phoneNumber, fullName: widget.fullName),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    bool isGuest = widget.fullName.toLowerCase() == "guest";

    final List<Map<String, dynamic>> services = [
      {
        'name': 'Plumbing',
        'category': 'Home Services',
        'description': 'Fix leaks, install fixtures, and handle all plumbing needs',
        'icon': Icons.plumbing,
      },
      {
        'name': 'Electrical',
        'category': 'Home Services',
        'description': 'Electrical repairs, installations, and maintenance',
        'icon': Icons.electric_bolt,
      },
    ];

    final query = _searchQuery.toLowerCase();
    List<Map<String, dynamic>> filteredServices = [];

    if (query.startsWith('v')) {
      filteredServices = [
        {
          'name': 'Salح',
          'category': 'Video',
          'description': 'Watch helpful DIY videos',
          'icon': Icons.video_library,
        }
      ];
    } else if (query.isNotEmpty) {
      final plumbingKeywords = [
        'plumb', 'sink', 'tap', 'taps', 'water', 'water heater', 'heater',
        'leak', 'pipe', 'drain', 'bathroom', 'kitchen', 'faucet', 'faucets',
        'toilet', 'shower', 'bath', 'flush', 'filter'
      ];
      
      final electricalKeywords = [
        'electric', 'wiring', 'wire', 'power', 'light', 'switch', 'switcher',
        'outlet', 'circuit', 'voltage', 'socket', 'breaker', 'lamp', 'luminaire',
        'ceiling fan', 'fan', 'freezer', 'refrigerator', 'fridge'
      ];

      filteredServices = services.where((service) {
        if (service['name'] == 'Plumbing') {
          return plumbingKeywords.any((keyword) => query.contains(keyword));
        } else if (service['name'] == 'Electrical') {
          return electricalKeywords.any((keyword) => query.contains(keyword));
        }
        return false;
      }).toList();
    }

    if (filteredServices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No results found for "$_searchQuery"',
          style: TextStyle(
            color: AppColors.textLight,
            fontSize: 14,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: filteredServices.map((service) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _searchController.clear();
            _hideOverlay();
            setState(() {
              _isSearching = false;
            });
            if (isGuest) {
              _showGuestPopup(context);
            } else {
              if (service['name'] == 'Plumbing') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlumbingProblemLayout(username: widget.phoneNumber),
                  ),
                );
              } else if (service['name'] == 'Electrical') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ElectricianProblemLayout(username: widget.phoneNumber),
                  ),
                );
              } else if (service['name'] == 'Salح') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoScreen(username: widget.phoneNumber),
                  ),
                );
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  service['icon'] as IconData,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service['name'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        service['description'] as String,
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      )).toList(),
    );
  }

  void _showGuestPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.lock_outline,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text('Account Required'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'images/images/salh.jpg',
                height: 100,
                width: 100,
              ),
              const SizedBox(height: 16),
              const Text(
                'Please sign in or create an account to access this feature.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                );
              },
              child: const Text('Sign In'),
            ),
          ],
        );
      },
    );
  }
}

// WELCOME COMPONENT
class WelcomeComponent extends StatelessWidget {
  final String fullName;
  const WelcomeComponent({super.key, required this.fullName});

  @override
  Widget build(BuildContext context) {
    String timeBasedGreeting() {
      var hour = DateTime.now().hour;
      if (hour < 12) return 'Good morning';
      if (hour < 17) return 'Good afternoon';
      return 'Good evening';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${timeBasedGreeting()},',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  fullName.toLowerCase() == 'guest' ? 'Welcome, Guest' : 'Welcome, $fullName',
                  style: AppStyles.heading2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.all(0),
                  shape: const CircleBorder(),
                  elevation: 0,
                  minimumSize: const Size(80, 80),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'images/images/chatbot1.png',
                      width: 80,
                      height: 60,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ask Salح Bot',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// SLIDESHOW COMPONENT
class SlideshowComponent extends StatefulWidget {
  const SlideshowComponent({super.key});

  @override
  State<SlideshowComponent> createState() => _SlideshowComponentState();
}

class _SlideshowComponentState extends State<SlideshowComponent> {
  final PageController _pageController = PageController(viewportFraction: 1);
  int _currentPage = 0;
  final List<Map<String, dynamic>> slides = [
    {
      'image': 'images/images/electrician2.avif',
      'title': 'Professional Plumbing Services',
      'subtitle': 'Expert plumbers at your doorstep',
    },
    {
      'image': 'images/images/Picture1.jpg',
      'title': 'Electrical Repairs & Installation',
      'subtitle': 'Fast and reliable service',
    },
  ];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % slides.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemCount: slides.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          slides[index]['image'],
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                              stops: const [0.6, 1.0],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                slides[index]['title'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                slides[index]['subtitle'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                Positioned(
                  bottom: 10,
                  right: 16,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      slides.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentPage == index ? 16 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// CATEGORIES COMPONENT
class CategoriesComponent extends StatelessWidget {
  final String fullName;
  final String phoneNumber;
  const CategoriesComponent({super.key, required this.fullName, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    bool isGuest = fullName.toLowerCase() == "guest";

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Categories',
                  style: AppStyles.heading1,
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildCategoryCard(
                context,
                'Plumber',
                'images/images/plumber.png',
                'Leak repairs, installations & more',
                Icons.plumbing,
                isGuest
                    ? () => _showGuestPopup(context)
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlumbingProblemLayout(username: phoneNumber),
                          ),
                        ),
              ),
              _buildCategoryCard(
                context,
                'Electrician',
                'images/images/electrician.jpg',
                'Wiring, fixtures & repairs',
                Icons.electric_bolt,
                isGuest
                    ? () => _showGuestPopup(context)
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ElectricianProblemLayout(username: phoneNumber),
                          ),
                        ),
              ),
              _buildCategoryCard(
                context,
                'Salح',
                'images/images/salh.jpg',
                'Video consultations & support',
                Icons.video_call,
                isGuest
                    ? () => _showGuestPopup(context)
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoScreen(username: fullName),
                          ),
                        ),
              ),
              _buildCategoryCard(
                context,
                'Marketplace',
                'images/images/marketplace.jpg',
                'Browse tools & spare parts',
                Icons.shopping_cart,
                isGuest
                    ? () => _showGuestPopup(context)
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MarketplaceScreen(fullName: fullName),
                          ),
                        ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    String imagePath,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: AppColors.primary.withOpacity(0.1),
      child: Container(
        decoration: AppStyles.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.asset(
                    imagePath,
                    height: 90,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGuestPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.lock_outline,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text('Account Required'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'images/images/salh.jpg',
                height: 100,
                width: 100,
              ),
              const SizedBox(height: 16),
              const Text(
                'Please sign in or create an account to access this feature.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                );
              },
              child: const Text('Sign In'),
            ),
          ],
        );
      },
    );
  }
}

// RECENT SERVICES COMPONENT
class RecentServicesComponent extends StatefulWidget {
  final String phoneNumber;
  final String fullName;
  const RecentServicesComponent({super.key, required this.phoneNumber, required this.fullName});

  @override
  State<RecentServicesComponent> createState() => _RecentServicesComponentState();
}

class _RecentServicesComponentState extends State<RecentServicesComponent> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref('serviceRequests');
  List<Map<dynamic, dynamic>> _recentServices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentServices();
  }

  Future<void> _loadRecentServices() async {
    try {
      final snapshot = await _database.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _recentServices = data.entries
              .map((entry) {
                final order = Map<dynamic, dynamic>.from(entry.value as Map);
                order['key'] = entry.key;
                return order;
              })
              .where((order) =>
                  order['customerPhone'] == widget.phoneNumber &&
                  (order['status'] ?? '').toLowerCase() == 'completed')
              .toList()
              ..sort((a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading services: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp.toString()));
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String _getServiceImage(String category) {
    switch (category.toLowerCase()) {
      case 'plumbing':
        return 'images/images/plumber.png';
      case 'electrical':
        return 'images/images/electrician.jpg';
      default:
        return 'images/images/default_service.png'; // Ensure you have a default image
    }
  }

  String _getProblemNames(Map<dynamic, dynamic>? problems, String category) {
    if (problems == null || problems.isEmpty) return 'Unknown Service';
    String prefix = category.toLowerCase() == 'plumbing' ? 'Plumbing' : 'Electrician';
    List<String> problemNames = problems.keys.map((key) => '$prefix ${key.toString()}').toList();
    return problemNames.join(', ');
  }

  void _showGuestPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.lock_outline,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text('Account Required'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'images/images/salh.jpg',
                height: 100,
                width: 100,
              ),
              const SizedBox(height: 16),
              const Text(
                'Please sign in or create an account to access this feature.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                );
              },
              child: const Text('Sign In'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isGuest = widget.fullName.toLowerCase() == "guest";
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Services',
                  style: AppStyles.heading1,
                ),
                TextButton(
                  onPressed: () {
                    if (isGuest) {
                      _showGuestPopup(context);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HistoryPage(
                            phoneNumber: widget.phoneNumber,
                            fullName: widget.fullName,
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _recentServices.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.history,
                              size: 60,
                              color: AppColors.textLight.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No recent services',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentServices.length > 3 ? 3 : _recentServices.length,
                      itemBuilder: (context, index) {
                        final service = _recentServices[index];
                        final rating = service['rating']?.toString() ?? 'N/A';
                        final problems = service['problems'] as Map<dynamic, dynamic>?;
                        final category = service['category'] ?? 'Unknown';
                        final problemNames = _getProblemNames(problems, category);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                _getServiceImage(category),
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(
                              problemNames,
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
                                  _formatTimestamp(service['createdAt']),
                                  style: TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Completed',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Colors.amber,
                                    ),
                                    Text(
                                      ' $rating',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Text(
                              'EGP ${service['totalAmount'] ?? '0'}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}

// DRAWER (MENU)
class AppDrawer extends StatefulWidget {
  final String fullName;
  final String? walletBalance;
  final String phoneNumber;

  const AppDrawer({
    super.key,
    required this.fullName,
    this.walletBalance,
    required this.phoneNumber,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildUserInfo(context),
          const Divider(),
          _buildMenuGroup(
            'Services',
            [
              _buildMenuItem(
                context,
                'Home',
                Icons.home_rounded,
                () => Navigator.pop(context),
              ),
              _buildMenuItem(
                context,
                'Notifications',
                Icons.notifications_outlined,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsPage()),
                ),
              ),
            ],
          ),
          const Divider(),
          _buildMenuGroup(
            'Account',
            [
              _buildMenuItem(
                context,
                'Profile',
                Icons.person_outline,
                () {
                  if (widget.fullName.toLowerCase() == "guest") {
                    _showGuestPopup(context);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomePageProfile(
                          phoneNumber: widget.phoneNumber,
                          fullName: widget.fullName,
                        ),
                      ),
                    );
                  }
                },
              ),
              _buildMenuItem(
                context,
                'Wallet',
                Icons.account_balance_wallet_outlined,
                () {
                  if (widget.fullName.toLowerCase() == "guest") {
                    _showGuestPopup(context);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WalletScreen(
                          userId: widget.phoneNumber,
                          fullName: widget.fullName,
                          phoneNumber: widget.phoneNumber,
                        ),
                      ),
                    );
                  }
                },
              ),
              _buildMenuItem(
                context,
                'History',
                Icons.history,
                () {
                  if (widget.fullName.toLowerCase() == "guest") {
                    _showGuestPopup(context);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HistoryPage(
                          phoneNumber: widget.phoneNumber,
                          fullName: widget.fullName,
                        ),
                      ),
                    );
                  }
                },
              ),
              _buildMenuItem(
                context,
                'Address',
                Icons.location_on_outlined,
                () => _handleRestrictedAction(context),
              ),
            ],
          ),
          const Divider(),
          _buildMenuGroup(
            'More',
            [
              _buildMenuItem(
                context,
                'Settings',
                Icons.settings_outlined,
                () => _handleRestrictedAction(context),
              ),
              _buildMenuItem(
                context,
                'Be a Fixer',
                Icons.build_outlined,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FixerInfo()),
                ),
              ),
              _buildMenuItem(
                context,
                'Help & FAQs',
                Icons.help_outline,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpFAQPage()),
                ),
              ),
              _buildMenuItem(
                context,
                'Contact Us',
                Icons.support_agent,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ContactUsPage()),
                ),
              ),
            ],
          ),
          const Divider(),
          _buildMenuItem(
            context,
            'Logout',
            Icons.logout,
            () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SignupScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return widget.fullName.toLowerCase() == "guest"
        ? Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Sign in to access all features',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                                );
                              },
                              child: const Text('Sign In'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        : ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(
                widget.fullName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              widget.fullName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              'Customer',
            ),
          );
  }

  void _handleRestrictedAction(BuildContext context) {
    if (widget.fullName.toLowerCase() == "guest") {
      _showGuestPopup(context);
    } else {
      // Navigate to appropriate page (implement as needed)
    }
  }

  Widget _buildMenuGroup(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        ListTile(
          leading: Icon(
            icon,
            color: title == 'Logout' ? Colors.red : AppColors.primary,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: title == 'Logout' ? Colors.red : AppColors.textDark,
            ),
          ),
          onTap: () {
            if (title != 'Home' && title != 'Notifications' && title != 'Logout' && widget.fullName.toLowerCase() == "guest") {
              _showGuestPopup(context);
            } else {
              onTap();
            }
          },
        ),
        if (title != 'Logout')
          Divider(
            height: 1,
            indent: 70,
            endIndent: 16,
          ),
      ],
    );
  }

  void _showGuestPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.lock_outline,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text('Account Required'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'images/images/salh.jpg',
                height: 100,
                width: 100,
              ),
              const SizedBox(height: 16),
              const Text(
                'Please sign in or create an account to access this feature.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                );
              },
              child: const Text('Sign In'),
            ),
          ],
        );
      },
    );
  }
}

// NOTIFICATIONS PAGE
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static final List<Map<String, String>> notifications = [];
  static final ValueNotifier<int> unreadNotifications = ValueNotifier<int>(0);
  static bool hasShownWelcomeNotification = false;

  static void addNotification({required String title, required String message}) {
    notifications.add({
      'title': title,
      'message': message,
      'time': DateTime.now().toString(),
    });
    unreadNotifications.value++;
  }

  @override
  Widget build(BuildContext context) {
    unreadNotifications.value = 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear All Notifications'),
                    content: const Text('Are you sure you want to clear all notifications?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          notifications.clear();
                          unreadNotifications.value = 0;
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'ll notify you when something arrives',
                    style: TextStyle(
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final DateTime notificationTime = DateTime.parse(notification['time']!);
                final String timeAgo = _getTimeAgo(notificationTime);

                return Dismissible(
                  key: Key(notification['time']!),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    notifications.removeAt(index);
                  },
                  child: Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.notifications_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        notification['title']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            notification['message']!,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textLight,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _getTimeAgo(DateTime notificationTime) {
    final now = DateTime.now();
    final difference = now.difference(notificationTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return '${notificationTime.day}/${notificationTime.month}/${notificationTime.year}';
    }
  }
}

// MARKETPLACE SCREEN
class MarketplaceScreen extends StatelessWidget {
  final String fullName;
  const MarketplaceScreen({super.key, required this.fullName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'images/images/marketplace.jpg',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            Text(
              'Coming Soon!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'We\'re working hard to bring you a great marketplace experience. Check back soon!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textLight,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Return to Home'),
            ),
          ],
        ),
      ),
    );
  }
}