import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:url_launcher/url_launcher.dart';


// Enhanced color scheme
class AppColors {
  static const Color primaryColor = Color(0xFF1E88E5); // Brighter blue
  static const Color secondaryColor = Color(0xFF42A5F5);
  static const Color accentColor = Color.fromARGB(255, 6, 100, 163);
  static const Color backgroundColor = Color(0xFFF8F9FB); // Slightly lighter
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF2D3142); // Darker text
  static const Color textSecondary = Color(0xFF6B7280); // Gray text
}

class AppTextStyles {
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24, // Increased size
    fontWeight: FontWeight.w700,
    fontFamily: 'Playfair_Display',
    color: Color(0xFF2D3142), // Darker for better contrast
    letterSpacing: -0.5, // Tighter spacing
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontFamily: 'Open Sans',
    color: Color(0xFF2D3142),
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontFamily: 'Open Sans',
    color: Color(0xFF2D3142),
    height: 1.5, // Better line height
  );
}

// Video data model
class Video {
  final String title;
  final List<String> tools;
  final String duration;
  final String imageUrl;
  final String videoUrl;
  final String difficulty;
  final double rating;

  Video({
    required this.title,
    required this.tools,
    required this.duration,
    required this.imageUrl,
    required this.videoUrl,
    required this.difficulty,
    required this.rating,
  });
}

class VideoScreen extends StatefulWidget {
  final String username;
  const VideoScreen({super.key, required this.username});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> with SingleTickerProviderStateMixin {
  bool _isElectricianSelected = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _debounceTimer;
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;

  // Sample video data
  final List<Video> _electricianVideos = [
    Video(
      title: 'Changing Ceiling Lamp',
      tools: ['Screwdriver', 'Electrical Tape', 'Voltage Tester'],
      duration: '0:58',
      imageUrl: 'images/images/lightbulb4.png',
      videoUrl: 'videos/LampChange.mp4',
      difficulty: 'Beginner',
      rating: 4.8,
    ),
    Video(
      title: 'DoorBell',
      tools: ['Wire Stripper', 'Screwdriver', 'Pliers'],
      duration: '0:53',
      imageUrl: 'images/images/doorbell2.png',
      videoUrl: 'videos/doorbell.mp4',
      difficulty: 'Intermediate',
      rating: 4.6,
    ),
    Video(
      title: 'Fridge Lamp',
      tools: ['Voltage Tester', 'Insulated Gloves'],
      duration: '0:31',
      imageUrl: 'images/images/fridge1.png',
      videoUrl: 'videos/fridgelamp.mp4',
      difficulty: 'Beginner',
      rating: 4.9,
    ),
  ];

  final List<Video> _plumbingVideos = [
    Video(
      title: 'Water Tap',
      tools: ['Adjustable Wrench', 'Replacement Shower Head', 'Teflon Tape'],
      duration: '0:50',
      imageUrl: 'images/images/watertap.png',
      videoUrl: 'videos/shower-head.mp4',
      difficulty: 'Beginner',
      rating: 4.7,
    ),
   
    Video(
      title: 'Filter',
      tools: ['Plunger', 'Drain Snake', 'Baking Soda'],
      duration: '0:51',
      imageUrl: 'images/images/filter.png',
      videoUrl: 'videos/filter.mp4',
      difficulty: 'Beginner',
      rating: 4.8,
    ),
    Video(
      title: 'Water Heater',
      tools: ['Pipe Wrench', 'Plumber\'s Putty', 'Bucket'],
      duration: '0:54',
      imageUrl: 'images/images/waterheater.jpg',
      videoUrl: 'videos/waterheater.mp4',
      difficulty: 'Advanced',
      rating: 4.6,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _isElectricianSelected = _tabController.index == 0;
      });
    });

    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  Iterable<Video> get _filteredVideos {
    final videos = _isElectricianSelected ? _electricianVideos : _plumbingVideos;
    if (_searchQuery.isEmpty) return videos;

    return videos.where((video) =>
        video.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        video.tools.any((tool) => tool.toLowerCase().contains(_searchQuery.toLowerCase())) ||
        video.difficulty.toLowerCase().contains(_searchQuery.toLowerCase()));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: AppColors.primaryColor,
        fontFamily: 'Open Sans',
        scaffoldBackgroundColor: AppColors.backgroundColor,
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: AppColors.backgroundColor,
            statusBarIconBrightness: Brightness.dark,
          ),
        ),
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.backgroundColor,
        body: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  backgroundColor: AppColors.backgroundColor,
                  elevation: 0,
                  expandedHeight: 250,
                  leading: GestureDetector(
                    onTap: () {
                      // Navigate back to HomePage
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(left: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            // ignore: deprecated_member_use
                            color: AppColors.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  actions: [
  GestureDetector(
    onTap: () async {
      final url = Uri.parse('https://sal7ly.wbshake.com/team/');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the link'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    },
    child: Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.view_in_ar,
        color: Colors.white,
      ),
    ),
  ),
],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primaryColor,
                                      // ignore: deprecated_member_use
                                      AppColors.primaryColor.withOpacity(0.7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      // ignore: deprecated_member_use
                                      color: AppColors.primaryColor.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.transparent,
                                  child: Text(
                                    widget.username.isNotEmpty ? widget.username[0].toUpperCase() : "U",
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 18),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back,',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    widget.username,
                                    style: AppTextStyles.headingStyle,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(_isSearchFocused ? 16 : 27),
                              boxShadow: [
                                BoxShadow(
                                  color: _isSearchFocused
                                      // ignore: deprecated_member_use
                                      ? AppColors.primaryColor.withOpacity(0.15)
                                      // ignore: deprecated_member_use
                                      : Colors.black.withOpacity(0.05),
                                  blurRadius: _isSearchFocused ? 15 : 10,
                                  offset: const Offset(0, 5),
                                  spreadRadius: _isSearchFocused ? 2 : 0,
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              decoration: InputDecoration(
                                hintText: 'Search for DIY videos...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 15,
                                ),
                                prefixIcon: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: EdgeInsets.all(_isSearchFocused ? 12 : 8),
                                  child: Icon(
                                    Icons.search,
                                    color: _isSearchFocused
                                        ? AppColors.primaryColor
                                        : AppColors.textSecondary,
                                    size: _isSearchFocused ? 22 : 20,
                                  ),
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchQuery = '';
                                          });
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(27),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    // ignore: deprecated_member_use
                                    color: AppColors.primaryColor.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                              onChanged: (value) {
                                if (_debounceTimer?.isActive ?? false) {
                                  _debounceTimer?.cancel();
                                }

                                _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(48),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            // ignore: deprecated_member_use
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: AppColors.primaryColor,
                        indicatorWeight: 3,
                        labelColor: AppColors.primaryColor,
                        unselectedLabelColor: AppColors.textSecondary,
                        labelStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Playfair_Display',
                        ),
                        indicator: UnderlineTabIndicator(
                          borderSide: BorderSide(
                            width: 3.0,
                            color: AppColors.primaryColor,
                          ),
                          insets: const EdgeInsets.symmetric(horizontal: 30.0),
                        ),
                        tabs: const [
                          Tab(text: 'Electrician'),
                          Tab(text: 'Plumbing'),
                        ],
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _searchQuery.isNotEmpty
                  ? _buildSearchResults()
                  : _buildRegularContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegularContent() {
    return Column(
      children: [
        if (_filteredVideos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Featured Video',
                      style: AppTextStyles.subheadingStyle,
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'See All',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: AppColors.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                EnhancedFeaturedVideoCard(video: _filteredVideos.first),
              ],
            ),
          ),
        
        const SizedBox(height: 8),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Popular Videos',
                      style: AppTextStyles.subheadingStyle,
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryColor,
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        'View All',
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredVideos.length > 1
                      ? _filteredVideos.length - 1
                      : 0,
                  itemBuilder: (context, index) {
                    final videoList = _filteredVideos.toList();
                    final videoIndex = index + 1;
                    return EnhancedVideoCard(
                      video: videoList[videoIndex],
                      accentColor: AppColors.accentColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPlayerWidget(
                              videoUrl: videoList[videoIndex].videoUrl,
                              title: videoList[videoIndex].title,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return _filteredVideos.isEmpty
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_off,
                  size: 70,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No videos found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try a different search term',
                  style: TextStyle(
                    fontSize: 14,
                    // ignore: deprecated_member_use
                    color: AppColors.textSecondary.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Clear Search'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Search Results',
                          style: AppTextStyles.subheadingStyle,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            // ignore: deprecated_member_use
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${_filteredVideos.length} videos',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Results for "$_searchQuery"',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredVideos.length,
                  itemBuilder: (context, index) {
                    final video = _filteredVideos.elementAt(index);
                    return EnhancedVideoCard(
                      video: video,
                      accentColor: AppColors.accentColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPlayerWidget(
                              videoUrl: video.videoUrl,
                              title: video.title,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }
}

// Enhanced Featured Video Card
class EnhancedFeaturedVideoCard extends StatelessWidget {
  final Video video;

  const EnhancedFeaturedVideoCard({required this.video, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              video.imageUrl.isNotEmpty ? video.imageUrl : 'images/images/placeholder.png',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    // ignore: deprecated_member_use
                    Colors.black.withOpacity(0.3),
                    // ignore: deprecated_member_use
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.4, 0.65, 1.0],
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: AppColors.accentColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  video.difficulty,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      video.duration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          offset: Offset(1, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 32,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: video.tools.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accentColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                // ignore: deprecated_member_use
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getToolIcon(video.tools[index]),
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                video.tools[index],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        video.rating.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.visibility,
                        // ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.9),
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoPlayerWidget(
                            videoUrl: video.videoUrl,
                            title: video.title,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            // ignore: deprecated_member_use
                            color: AppColors.primaryColor.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getToolIcon(String tool) {
    final toolLower = tool.toLowerCase();
    if (toolLower.contains('screwdriver')) return Icons.build;
    if (toolLower.contains('tape')) return Icons.line_style;
    if (toolLower.contains('tester') || toolLower.contains('multimeter')) return Icons.flash_on;
    if (toolLower.contains('wrench')) return Icons.build_circle;
    if (toolLower.contains('plier')) return Icons.plumbing;
    if (toolLower.contains('glove')) return Icons.accessibility_new;
    if (toolLower.contains('snake') || toolLower.contains('plunger')) return Icons.plumbing;
    if (toolLower.contains('shower')) return Icons.shower;
    if (toolLower.contains('baking')) return Icons.science;
    return Icons.handyman;
  }
}

// Enhanced Video Card Widget
class EnhancedVideoCard extends StatelessWidget {
  final Video video;
  final Color accentColor;
  final VoidCallback onTap;

  const EnhancedVideoCard({
    required this.video,
    required this.accentColor,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Row(
              children: [
                Hero(
                  tag: 'video_${video.title}',
                  child: SizedBox(
                    width: 130,
                    height: 120,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          video.imageUrl.isNotEmpty ? video.imageUrl : 'images/images/placeholder.png',
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                // ignore: deprecated_member_use
                                Colors.black.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              // ignore: deprecated_member_use
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              video.duration,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              // ignore: deprecated_member_use
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            // ignore: deprecated_member_use
                            color: _getDifficultyColor(video.difficulty).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            video.difficulty,
                            style: TextStyle(
                              color: _getDifficultyColor(video.difficulty),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          video.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: video.tools.map<Widget>((tool) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                // ignore: deprecated_member_use
                                color: accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  // ignore: deprecated_member_use
                                  color: accentColor.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                tool,
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              video.rating.toString(),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.visibility,
                              color: AppColors.textSecondary,
                              size: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String title;

  const VideoPlayerWidget({
    required this.videoUrl,
    required this.title,
    super.key,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.asset(widget.videoUrl);
      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        placeholder: Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryColor,
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 50,
                ),
                SizedBox(height: 16),
                Text(
                  'Error loading video: $errorMessage',
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );

      setState(() {});
    } catch (e) {
      // Show error UI
      setState(() {});
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.backgroundColor,
      ),
      body: Center(
        child: _chewieController != null
            ? Chewie(controller: _chewieController!)
            : const CircularProgressIndicator(),
      ),
    );
  }
}