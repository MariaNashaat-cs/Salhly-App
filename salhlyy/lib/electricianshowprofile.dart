import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'electriciancheckout.dart';

class ElectricianProfile extends StatefulWidget {
  final String name;
  final String profession;
  final String description;
  final double rating;
  final String profileImage; // Asset path (e.g., 'assets/images/profile.jpg')
  final String phoneNumber;
  final double fixerPrice; // Added fixerPrice parameter
  final List<String> workGallery;
  final Map<String, String> services;
  final String availability;

  const ElectricianProfile({
    super.key,
    required this.name,
    this.profession = 'Electrician',
    required this.description,
    required this.rating,
    required this.profileImage,
    required this.phoneNumber,
    required this.fixerPrice, // Marked as required
    this.workGallery = const [],
    this.services = const {},
    this.availability = 'Available today',
  });

  @override
  _ElectricianProfileState createState() => _ElectricianProfileState();
}

class _ElectricianProfileState extends State<ElectricianProfile> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showFullDescription = false;
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Hero Background
          Container(
            height: MediaQuery.of(context).size.height * 0.3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A446E), Color(0xFF2A6A9E)],
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Top Section with Back Button and Actions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Button
                        Semantics(
                          label: 'Back',
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ),

                        // Action Buttons
                        Row(
                          children: [
                            // Favorite Button
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              child: IconButton(
                                icon: Icon(
                                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: _isFavorite ? Colors.redAccent : Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isFavorite = !_isFavorite;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(_isFavorite
                                          ? 'Added ${widget.name} to favorites'
                                          : 'Removed from favorites'),
                                      duration: const Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Profile Card
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 30, 16, 0),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Card
                        Container(
                          padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Name and profession
                              Text(
                                widget.name,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: isSmallScreen ? 24 : 28,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A446E),
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 4),

                              Text(
                                widget.profession,
                                style: GoogleFonts.openSans(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 12),

                              // Rating
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ...List.generate(
                                    5,
                                    (index) => Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
                                      child: Icon(
                                        index < widget.rating.floor()
                                            ? Icons.star
                                            : index < widget.rating
                                                ? Icons.star_half
                                                : Icons.star_border,
                                        color: Colors.amber,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.rating.toStringAsFixed(1),
                                    style: GoogleFonts.openSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Availability badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green.shade700,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.availability,
                                      style: GoogleFonts.openSans(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Quick action buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildQuickActionButton(
                                    icon: Icons.event,
                                    label: 'Book',
                                    color: const Color(0xFF1A446E),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Electriciancheckout(
                                            phoneNumber: widget.phoneNumber,
                                            fullname: widget.name,
                                            fixerPrice: widget.fixerPrice, // Pass fixerPrice
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Profile Image
                        Positioned(
                          top: -50,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Hero(
                                tag: 'profile_${widget.name}',
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: Image.asset(
                                    widget.profileImage,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey.shade300,
                                      child: const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tab Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
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
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A446E), Color(0xFF2A6A9E)],
                        ),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey.shade700,
                      labelStyle: GoogleFonts.openSans(
                        fontWeight: FontWeight.w600,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.person),
                          text: 'About',
                        ),
                        Tab(
                          icon: Icon(Icons.electrical_services),
                          text: 'Services',
                        ),
                        Tab(
                          icon: Icon(Icons.star),
                          text: 'Reviews',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tab Content
                  SizedBox(
                    height: _getTabContentHeight(_tabController.index),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // About Tab
                        _buildAboutTab(isSmallScreen),

                        // Services Tab
                        _buildServicesTab(isSmallScreen),

                        // Reviews Tab
                        _buildReviewsTab(isSmallScreen),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80), // Space for CTA button
                ],
              ),
            ),
          ),

          // Floating CTA Button
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A446E), Color(0xFF2A6A9E)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A446E).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (_isLoading) return;

                  setState(() {
                    _isLoading = true;
                  });

                  // Simulate loading
                  Future.delayed(const Duration(seconds: 1), () {
                    setState(() {
                      _isLoading = false;
                    });

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Electriciancheckout(
                          phoneNumber: widget.phoneNumber,
                          fullname: widget.name,
                          fixerPrice: widget.fixerPrice, // Pass fixerPrice
                        ),
                      ),
                    );
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Book Appointment',
                            style: GoogleFonts.openSans(
                              fontSize: isSmallScreen ? 18 : 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getTabContentHeight(int tabIndex) {
    switch (tabIndex) {
      case 0: // About
        return 300;
      case 1: // Services
        return 350;
      case 2: // Reviews
        return 400;
      default:
        return 300;
    }
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.openSans(
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // About Tab Content
  Widget _buildAboutTab(bool isSmallScreen) {
    String description;
    if (widget.name == 'Hassanen Ahmed') {
      description =
          'I’ve been an electrician for 15 years, tackling everything from faulty wiring to full installations. I love solving problems and seeing a client’s relief when the lights come back on. Electrical work is complex, but I’m here to make it simple for you.';
    } else if (widget.name == 'Ahmed Hesham') {
      description =
          'With over 10 years as a licensed electrician, I specialize in residential and commercial wiring, repairs, and upgrades. My focus is on safety, precision, and customer satisfaction. Need electrical help? I’ve got you covered!';
    } else if (widget.name == 'Abdo Ibrahim') {
      description =
          'Professional electrician with 12 years of experience in installations, repairs, and system upgrades. From small fixes to large projects, I prioritize quality and reliability. Let’s power up your space together!';
    } else {
      description = widget.description;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About Card
          Container(
            padding: const EdgeInsets.all(20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      color: Color(0xFF1A446E),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'About Me',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A446E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AnimatedCrossFade(
                  firstChild: Text(
                    description,
                    style: GoogleFonts.openSans(
                      fontSize: isSmallScreen ? 15 : 16,
                      height: 1.5,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  secondChild: Text(
                    description,
                    style: GoogleFonts.openSans(
                      fontSize: isSmallScreen ? 15 : 16,
                      height: 1.5,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  crossFadeState: _showFullDescription
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => setState(() => _showFullDescription = !_showFullDescription),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _showFullDescription ? 'Read Less' : 'Read More',
                        style: GoogleFonts.openSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A446E),
                        ),
                      ),
                      Icon(
                        _showFullDescription ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: const Color(0xFF1A446E),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Experience & Qualifications
          Container(
            padding: const EdgeInsets.all(20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.verified,
                      color: Color(0xFF1A446E),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Experience & Qualifications',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A446E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildQualificationItem(
                  icon: Icons.school,
                  title: 'Certified Electrician',
                  subtitle: 'National Electrical Association',
                ),
                const Divider(),
                _buildQualificationItem(
                  icon: Icons.work,
                  title: '10+ Years Experience',
                  subtitle: 'Residential & Commercial Electrical Work',
                ),
                const Divider(),
                _buildQualificationItem(
                  icon: Icons.verified_user,
                  title: 'Licensed & Insured',
                  subtitle: 'For your safety and peace of mind',
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Work Gallery
          Container(
            padding: const EdgeInsets.all(20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.photo_library,
                          color: Color(0xFF1A446E),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Recent Work',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A446E),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Viewing all work samples'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Text(
                        'View All',
                        style: GoogleFonts.openSans(
                          color: const Color(0xFF1A446E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 100,
                            color: Colors.grey.shade200,
                            child: Center(
                              child: Icon(
                                Icons.electrical_services,
                                color: Colors.grey.shade400,
                                size: 32,
                              ),
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
        ],
      ),
    );
  }

  Widget _buildQualificationItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A446E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1A446E),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.openSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Services Tab Content
  Widget _buildServicesTab(bool isSmallScreen) {
    final Map<String, String> services = {
      'Wiring Repair': 'EGP 600+',
      'Lighting Installation': 'EGP 800+',
      'Circuit Breaker Replacement': 'EGP 1000+',
      'Outlet Installation': 'EGP 500+',
      'Electrical Panel Upgrade': 'EGP 2000+',
      'Safety Inspection': 'EGP 700+',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.electrical_services,
                      color: Color(0xFF1A446E),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Services & Pricing',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A446E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Basic call-out fee: EGP 350',
                  style: GoogleFonts.openSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  'Prices may vary based on complexity and materials needed',
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),

                // Service List
                ...services.entries.map((entry) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A446E).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.electrical_services,
                                color: Color(0xFF1A446E),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: GoogleFonts.openSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A446E).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                entry.value,
                                style: GoogleFonts.openSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A446E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (entry.key != services.keys.last)
                        Divider(color: Colors.grey.shade200),
                    ],
                  );
                }),

                const SizedBox(height: 20),

                // Request Custom Quote
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.orange.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade800,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Need a custom service? Contact for a personalized quote',
                          style: GoogleFonts.openSans(
                            fontSize: 14,
                            color: Colors.orange.shade800,
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
    );
  }

  // Reviews Tab Content
  Widget _buildReviewsTab(bool isSmallScreen) {
    final List<Map<String, dynamic>> reviews;
    if (widget.name == 'Hassanen Ahmed') {
      reviews = [
        {
          'username': 'Ahmed Ali',
          'comment': 'Fantastic service! Fixed my wiring issue in no time and ensured everything was safe.',
          'rating': 5,
          'date': '2 days ago',
          'photo': true,
        },
        {
          'username': 'Sara Hassan',
          'comment': 'Installed new lighting in my home. Professional and clean work!',
          'rating': 4,
          'date': '1 week ago',
          'photo': false,
        },
        {
          'username': 'Omar Khaled',
          'comment': 'Very knowledgeable. Explained the electrical problem clearly and fixed it fast.',
          'rating': 5,
          'date': '2 weeks ago',
          'photo': false,
        },
        {
          'username': 'Laila Ahmed',
          'comment': 'Good job on my panel upgrade, though it took a bit longer than expected.',
          'rating': 4,
          'date': '3 weeks ago',
          'photo': true,
        },
      ];
    } else if (widget.name == 'Ahmed Hesham') {
      reviews = [
        {
          'username': 'Mohamed Samir',
          'comment': 'Top-notch electrician! Fixed a tricky circuit issue quickly.',
          'rating': 5,
          'date': '3 days ago',
          'photo': false,
        },
        {
          'username': 'Fatima Ahmed',
          'comment': 'Installed outlets in my office. Very efficient and friendly.',
          'rating': 5,
          'date': '1 week ago',
          'photo': true,
        },
        {
          'username': 'Youssef Mahmoud',
          'comment': 'Great service for my home rewiring. Highly recommend!',
          'rating': 4,
          'date': '2 weeks ago',
          'photo': false,
        },
      ];
    } else if (widget.name == 'Abdo Ibrahim') {
      reviews = [
        {
          'username': 'Ali Mohamed',
          'comment': 'Excellent work on my home’s electrical system. Very reliable!',
          'rating': 5,
          'date': '5 days ago',
          'photo': true,
        },
        {
          'username': 'Noura Ahmed',
          'comment': 'Fixed a short circuit issue perfectly. Clean and professional.',
          'rating': 4,
          'date': '2 weeks ago',
          'photo': false,
        },
        {
          'username': 'Karim Hassan',
          'comment': 'Installed new fixtures with great care. Highly skilled!',
          'rating': 5,
          'date': '3 weeks ago',
          'photo': true,
        },
      ];
    } else {
      reviews = [
        {
          'username': 'Ahmed Ali',
          'comment': 'Great electrical service, quick and reliable!',
          'rating': 5,
          'date': '2 days ago',
          'photo': false,
        },
        {
          'username': 'Sara Hassan',
          'comment': 'Fixed my outlet in no time. Highly recommended!',
          'rating': 4,
          'date': '1 week ago',
          'photo': false,
        },
        {
          'username': 'Omar Khaled',
          'comment': 'Professional and affordable electrical work.',
          'rating': 5,
          'date': '2 weeks ago',
          'photo': false,
        },
      ];
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating Summary
          Container(
            padding: const EdgeInsets.all(20),
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
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.rating.toString(),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A446E),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '/5',
                        style: GoogleFonts.openSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        index < widget.rating.floor()
                            ? Icons.star
                            : index < widget.rating
                                ? Icons.star_half
                                : Icons.star_border,
                        color: Colors.amber,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Based on ${reviews.length} reviews',
                  style: GoogleFonts.openSans(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),

                // Rating Distribution
                _buildRatingBar(5, 0.7),
                _buildRatingBar(4, 0.2),
                _buildRatingBar(3, 0.1),
                _buildRatingBar(2, 0.0),
                _buildRatingBar(1, 0.0),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Filter Options
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            child: Row(
              children: [
                const Icon(
                  Icons.filter_list,
                  color: Color(0xFF1A446E),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Filter Reviews',
                  style: GoogleFonts.openSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A446E),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A446E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'All Reviews',
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          color: const Color(0xFF1A446E),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF1A446E),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Review List
          ...reviews.map((review) => _buildReviewCard(review, isSmallScreen)),

          const SizedBox(height: 20),

          // Load More Button
          if (reviews.length > 3)
            Center(
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Loading more reviews...'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Load More Reviews',
                      style: GoogleFonts.openSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A446E),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_downward,
                      color: Color(0xFF1A446E),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int ratingValue, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Row(
              children: [
                Text(
                  ratingValue.toString(),
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 14,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: percentage,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A446E), Color(0xFF2A6A9E)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '${(percentage * 100).toInt()}%',
              style: GoogleFonts.openSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review, bool isSmallScreen) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF1A446E).withOpacity(0.1),
                child: Text(
                  review['username'].toString()[0],
                  style: GoogleFonts.openSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A446E),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['username'],
                      style: GoogleFonts.openSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => Icon(
                            index < review['rating'] ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          review['date'],
                          style: GoogleFonts.openSans(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.more_vert,
                color: Colors.grey.shade600,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review['comment'],
            style: GoogleFonts.openSans(
              fontSize: 15,
              color: Colors.grey.shade800,
              height: 1.4,
            ),
          ),

          // Photo attachment (if any)
          if (review['photo'] == true)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade200,
                      child: Center(
                        child: Icon(
                          Icons.photo,
                          color: Colors.grey.shade400,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  if (review['username'] == 'Ahmed Ali' || review['username'] == 'Fatima Ahmed')
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Icon(
                              Icons.photo,
                              color: Colors.grey.shade400,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Helpful button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.thumb_up_outlined,
                      color: Colors.grey.shade600,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Helpful',
                      style: GoogleFonts.openSans(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Report',
                style: GoogleFonts.openSans(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}