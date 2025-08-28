import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

// Define the AppColors class to match ServiceRequestManagementPage
class AppColors {
  static const Color primary = Color(0xFF0C5FB3);
  static const Color secondary = Color(0xFF3D82C6);
  static const Color accent = Color.fromARGB(255, 224, 37, 4);
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color textDark = Color(0xFF2D3142);
  static const Color textLight = Color(0xFF8D99AE);
}

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final DatabaseReference _analyticsRef = FirebaseDatabase.instance.ref('analytics');
  
  @override
  void initState() {
    super.initState();
    _initializeAnalytics();
  }

  Future<void> _initializeAnalytics() async {
    try {
      // Check if analytics data exists
      final snapshot = await _analyticsRef.get();
      if (!snapshot.exists) {
        // Initialize with default values if no data exists
        await _analyticsRef.set({
          'userCount': 0,
          'fixerCount': 0,
          'serviceRequestsCount': 0,
          'averageRating': 0.0,
          'lastUpdated': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Error initializing analytics: $e');
    }
  }

  Future<void> _updateAnalytics() async {
    try {
      // Get counts from other collections
      final usersRef = FirebaseDatabase.instance.ref('users');
      final fixersRef = FirebaseDatabase.instance.ref('fixers');
      final requestsRef = FirebaseDatabase.instance.ref('serviceRequests');
      final ratingsRef = FirebaseDatabase.instance.ref('ratings');

      // Get all counts
      final usersSnapshot = await usersRef.get();
      final fixersSnapshot = await fixersRef.get();
      final requestsSnapshot = await requestsRef.get();
      final ratingsSnapshot = await ratingsRef.get();

      // Debug logging
      debugPrint('Users snapshot exists: ${usersSnapshot.exists}');
      if (usersSnapshot.exists) {
        debugPrint('Users data: ${usersSnapshot.value}');
        debugPrint('Number of users: ${usersSnapshot.children.length}');
      }

      // Calculate average rating
      double averageRating = 0.0;
      if (ratingsSnapshot.exists) {
        final ratings = ratingsSnapshot.value as Map<dynamic, dynamic>;
        final totalRatings = ratings.length;
        if (totalRatings > 0) {
          final sum = ratings.values.fold<double>(0, (sum, rating) => sum + (rating['rating'] ?? 0.0));
          averageRating = sum / totalRatings;
        }
      }

      // Update analytics with proper counting
      final userCount = usersSnapshot.exists ? usersSnapshot.children.length : 0;
      final fixerCount = fixersSnapshot.exists ? fixersSnapshot.children.length : 0;
      final requestCount = requestsSnapshot.exists ? requestsSnapshot.children.length : 0;

      debugPrint('Updating analytics with:');
      debugPrint('User count: $userCount');
      debugPrint('Fixer count: $fixerCount');
      debugPrint('Request count: $requestCount');
      debugPrint('Average rating: $averageRating');

      await _analyticsRef.update({
        'userCount': userCount,
        'fixerCount': fixerCount,
        'serviceRequestsCount': requestCount,
        'averageRating': averageRating,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error updating analytics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'Salحly Analytics',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600,fontFamily: 'Playfair_Display'),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _updateAnalytics,
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _analyticsRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: AppColors.accent, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading analytics',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _updateAnalytics,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Retry',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>?;
          if (data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 48, color: AppColors.textLight),
                  const SizedBox(height: 16),
                  Text(
                    'No analytics data available',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initializeAnalytics,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Initialize Analytics',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _updateAnalytics,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMetricCard(
                    context,
                    'Total Users',
                    '${data['userCount'] ?? 0}',
                    Icons.people,
                    AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  _buildMetricCard(
                    context,
                    'Total Fixers',
                    '${data['fixerCount'] ?? 0}',
                    Icons.handyman,
                    AppColors.secondary,
                  ),
                  const SizedBox(height: 16),
                  _buildMetricCard(
                    context,
                    'Total Requests',
                    '${data['serviceRequestsCount'] ?? 0}',
                    Icons.request_quote,
                    AppColors.primary.withOpacity(0.8),
                  ),
                  const SizedBox(height: 16),
                  _buildMetricCard(
                    context,
                    'Average Rating',
                    '${(data['averageRating'] ?? 0.0).toStringAsFixed(1)} ⭐',
                    Icons.star,
                    AppColors.secondary.withOpacity(0.8),
                  ),
                  const SizedBox(height: 16),
                  if (data['lastUpdated'] != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Last updated: ${DateTime.parse(data['lastUpdated']).toString()}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: AppColors.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}