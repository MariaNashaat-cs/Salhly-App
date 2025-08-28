import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'electriciancheckout.dart';
import 'electricianshowprofile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Open Sans Hebrew',
        primaryColor: const Color(0xFF1A446E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A446E),
          primary: const Color(0xFF1A446E),
        ),
      ),
      home: Electricianfixerlist(
        selectedAddress: '',
        selectedDate: null,
        selectedTime: null,
        phoneNumber: 'exampleUser',
      ),
    );
  }
}

class Electricianfixerlist extends StatefulWidget {
  final String selectedAddress;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final String phoneNumber;

  const Electricianfixerlist({
    super.key,
    required this.selectedAddress,
    required this.selectedDate,
    required this.selectedTime,
    required this.phoneNumber,
  });

  @override
  State<Electricianfixerlist> createState() => _FixersListState();
}

class _FixersListState extends State<Electricianfixerlist> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> electricians = [
    {
      'imageUrl': 'images/images/ammar.jpeg',
      'name': 'Ammar Yasser',
      'rating': 4.8,
      'price': 150,
      'specialty': 'Electrician',
      'description': '24/7 emergency electrical services. Specializes in power outages, wiring issues, and urgent repairs. Fast and reliable.',
      'jobsCompleted': 234,
      'isEnhanced': true,
      'availableNow': true,
      'estimatedArrival': '15 min',
    },
    {
      'imageUrl': 'images/images/mark.jpeg',
      'name': 'Mark Gerges',
      'rating': 4.5,
      'price': 180,
      'specialty': 'Electrician',
      'description': 'Expert in home lighting installations and smart home systems. Certified for modern electrical setups and renovations.',
      'jobsCompleted': 189,
      'isEnhanced': true,
      'availableNow': true,
      'estimatedArrival': '25 min',
    },
    {
      'imageUrl': 'images/images/rojie.jpeg',
      'name': 'Rojie Ramy',
      'rating': 4.7,
      'price': 200,
      'specialty': 'Electrician',
      'description': 'Specializes in commercial electrical systems, large-scale wiring, and maintenance for offices and businesses.',
      'jobsCompleted': 156,
      'isEnhanced': false,
      'availableNow': false,
      'estimatedArrival': '45 min',
    },
    {
      'imageUrl': 'images/images/amgad.jpeg',
      'name': 'Amgad Tarek',
      'rating': 4.3,
      'price': 120,
      'specialty': 'Electrician',
      'description': 'Experienced in residential electrical repairs, circuit breaker installations, and routine maintenance services.',
      'jobsCompleted': 98,
      'isEnhanced': false,
      'availableNow': true,
      'estimatedArrival': '30 min',
    },
    {
      'imageUrl': 'images/images/harry styles.jpeg',
      'name': 'Hassan Ibrahim',
      'rating': 4.9,
      'price': 250,
      'specialty': 'Electrical Expert',
      'description': '25 years of experience in all electrical systems. Expert in complex wiring and system troubleshooting.',
      'jobsCompleted': 312,
      'isEnhanced': true,
      'availableNow': false,
      'estimatedArrival': '50 min',
    },
  ];

  List<Map<String, dynamic>> visibleElectricians = [];
  List<Map<String, dynamic>> filteredElectricians = [];
  bool isLoading = true;
  late AnimationController _controller;
  String sortOption = 'recommended';

  Future<void> _fetchAndApplyPriceRange() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(widget.phoneNumber)
          .child('electricalproblem')
          .get();

      double totalMinPrice = 0.0; // To sum up all min prices
      double totalMaxPrice = 0.0; // To sum up all max prices

      if (snapshot.exists) {
        final problemsData = Map<String, dynamic>.from(snapshot.value as Map);

        // Sum the min and max prices of all individual problems
        for (var problem in problemsData.entries) {
          final priceRange = Map<String, dynamic>.from(problem.value);
          final min = (priceRange['min'] as num).toDouble();
          final max = (priceRange['max'] as num).toDouble();
          totalMinPrice += min;
          totalMaxPrice += max;
        }

        // Ensure the summed prices are finite, otherwise use fallback
        totalMinPrice = totalMinPrice.isFinite ? totalMinPrice : 1000.0;
        totalMaxPrice = totalMaxPrice.isFinite ? totalMaxPrice : 5000.0;

        // Distribute prices across fixers based on the total estimate range
        final int numFixers = electricians.length;
        if (numFixers > 1) {
          final step = (totalMaxPrice - totalMinPrice) / (numFixers - 1);
          for (int i = 0; i < numFixers; i++) {
            electricians[i]['price'] = (totalMinPrice + i * step).round();
          }
        } else if (numFixers == 1) {
          electricians[0]['price'] = ((totalMinPrice + totalMaxPrice) / 2).round();
        }
      } else {
        // Fallback if no data exists
        totalMinPrice = 1000.0;
        totalMaxPrice = 5000.0;
        final step = (totalMaxPrice - totalMinPrice) / (electricians.length - 1);
        for (int i = 0; i < electricians.length; i++) {
          electricians[i]['price'] = (totalMinPrice + i * step).round();
        }
      }
    } catch (e) {
      print('Error fetching price range: $e');
      // Fallback in case of error
      const totalMinPrice = 1000.0;
      const totalMaxPrice = 5000.0;
      final step = (totalMaxPrice - totalMinPrice) / (electricians.length - 1);
      for (int i = 0; i < electricians.length; i++) {
        electricians[i]['price'] = (totalMinPrice + i * step).round();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fetchAndApplyPriceRange().then((_) {
      setState(() {
        filteredElectricians = List.from(electricians);
        isLoading = false;
      });

      for (int i = 0; i < filteredElectricians.length; i++) {
        Future.delayed(Duration(milliseconds: 100 * i), () {
          if (mounted) {
            setState(() {
              visibleElectricians.add(filteredElectricians[i]);
            });
            _controller.forward(from: 0.0);
          }
        });
      }
    });
  }

  void sortElectricians(String option) {
    setState(() {
      sortOption = option;

      switch (option) {
        case 'price_low':
          filteredElectricians.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
          break;
        case 'price_high':
          filteredElectricians.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
          break;
        case 'rating':
          filteredElectricians.sort((a, b) => (b['rating'] as num).compareTo(a['rating'] as num));
          break;
        case 'jobs':
          filteredElectricians.sort((a, b) => (b['jobsCompleted'] as int).compareTo(a['jobsCompleted'] as int));
          break;
        default:
          filteredElectricians.sort((a, b) {
            if (a['isEnhanced'] != b['isEnhanced']) {
              return a['isEnhanced'] ? -1 : 1;
            }
            return (b['rating'] as num).compareTo(a['rating'] as num);
          });
      }

      visibleElectricians = List.from(filteredElectricians);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(
              width: double.infinity,
              height: 50,
              child: HeaderComponent(),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: TitleComponent(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.sort, color: Color(0xFF1A446E), size: 20),
                    onSelected: sortElectricians,
                    tooltip: 'Sort by',
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'recommended',
                        child: Text('Recommended', style: TextStyle(fontSize: 12)),
                      ),
                      const PopupMenuItem<String>(
                        value: 'rating',
                        child: Text('Highest Rating', style: TextStyle(fontSize: 12)),
                      ),
                      const PopupMenuItem<String>(
                        value: 'price_low',
                        child: Text('Lowest Price', style: TextStyle(fontSize: 12)),
                      ),
                      const PopupMenuItem<String>(
                        value: 'price_high',
                        child: Text('Highest Price', style: TextStyle(fontSize: 12)),
                      ),
                      const PopupMenuItem<String>(
                        value: 'jobs',
                        child: Text('Most Jobs Completed', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: isLoading
                  ? _buildSkeletonList()
                  : visibleElectricians.isEmpty
                      ? const Center(
                          child: Text(
                            'No electricians available',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: visibleElectricians.length,
                          itemBuilder: (context, index) {
                            final electrician = visibleElectricians[index];
                            return FixerCardComponent(
                              imageUrl: electrician['imageUrl'],
                              name: electrician['name'],
                              rating: electrician['rating'],
                              price: electrician['price'],
                              specialty: electrician['specialty'],
                              description: electrician['description'],
                              jobsCompleted: electrician['jobsCompleted'],
                              phoneNumber: widget.phoneNumber,
                              isEnhanced: electrician['isEnhanced'],
                              availableNow: electrician['availableNow'],
                              estimatedArrival: electrician['estimatedArrival'],
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 80,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        width: 40,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class HeaderComponent extends StatelessWidget {
  final VoidCallback? onBack;

  const HeaderComponent({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: double.infinity,
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onBack ?? () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(50),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C5FB3).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 13),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TitleComponent extends StatelessWidget {
  final String title;

  const TitleComponent({super.key, this.title = 'Electricians List'});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      constraints: const BoxConstraints(minWidth: 140),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Playfair_Display',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              decoration: TextDecoration.none,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            'Find the right professional',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class FixerCardComponent extends StatelessWidget {
  final String imageUrl;
  final String name;
  final num rating;
  final num price;
  final String specialty;
  final String description;
  final int jobsCompleted;
  final bool isEnhanced;
  final bool availableNow;
  final String estimatedArrival;
  final String phoneNumber;

  const FixerCardComponent({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.rating,
    required this.price,
    required this.description,
    required this.specialty,
    required this.jobsCompleted,
    required this.phoneNumber,
    this.isEnhanced = false,
    this.availableNow = false,
    required this.estimatedArrival,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'fixer-$name',
      child: Material(
        type: MaterialType.transparency,
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => ElectricianProfile(
                  name: name,
                  description: description,
                  rating: rating.toDouble(),
                  profileImage: imageUrl,
                  profession: specialty,
                  phoneNumber: phoneNumber,
                  fixerPrice: price.toDouble(),
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 0.05);
                  const end = Offset.zero;
                  const curve = Curves.easeOutQuint;
                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);
                  return SlideTransition(position: offsetAnimation, child: child);
                },
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            constraints: const BoxConstraints(maxHeight: 160, minHeight: 140),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isEnhanced
                                        ? [const Color(0xFF1A446E), const Color(0xFF3B9AE1)]
                                        : [Colors.grey.shade100, Colors.grey.shade300],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(2),
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundImage: AssetImage(imageUrl),
                                ),
                              ),
                              if (isEnhanced)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF1A446E), Color(0xFF3B9AE1)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF1A446E).withOpacity(0.2),
                                          spreadRadius: 1,
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.verified,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (availableNow) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF22CC6B).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF22CC6B),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Available',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF22CC6B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  specialty,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xCC000000),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  description,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.black.withOpacity(0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFE6F2FF), Color(0xFFD4E6F9)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF1A446E).withOpacity(0.1),
                                            blurRadius: 3,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        '${price.toInt()} EGP',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A446E),
                                        ),
                                      ),
                                    ),
                                    if (isEnhanced)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1A446E).withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.verified_user,
                                              size: 19,
                                              color: Color(0xFF1A446E),
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Enhanced',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1A446E),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFEECC), Color(0xFFFFF8E1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF9900).withOpacity(0.1),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Text(
                                  rating.toString(),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF9900),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.star,
                                  color: Color(0xFFFF9900),
                                  size: 12,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: const Color(0xFFF5F5F5),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ElectricianProfile(
                      name: name,
                      rating: rating.toDouble(),
                      description: description,
                      profileImage: imageUrl,
                      profession: specialty,
                      phoneNumber: phoneNumber,
                      fixerPrice: price.toDouble(),
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: Color(0xFF1A446E),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Profile',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A446E),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Material(
            color: const Color(0xFF1A446E),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Electriciancheckout(
                      phoneNumber: phoneNumber,
                      fullname: name,
                      fixerPrice: price.toDouble(),
                    ),
                  ),
                );
              },
              splashColor: Colors.white.withOpacity(0.1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A446E), Color(0xFF3B9AE1)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Book Now',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}