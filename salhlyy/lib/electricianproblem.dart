import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'video.dart'; // Ensure this file exists
import 'electrician_description.dart';
import 'homepage.dart'; // Ensure this file exists

// Initialize Firebase in main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class HeaderComponent extends StatelessWidget {
  final String title;

  const HeaderComponent({super.key, this.title = 'What needs fixing?'});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.9,
        minHeight: 45,
        maxHeight: 45, // Set a finite maxHeight to normalize constraints
      ),
      alignment: Alignment.center,
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Playfair_Display',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0C5FB3),
          decoration: TextDecoration.none,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class ProblemListComponent extends StatefulWidget {
  final List<Map<String, dynamic>> problems;
  final Function(Set<String>, Map<String, Map<String, int>>) onSelectionChanged;
  final bool isGuest;
  final String phoneNumber;

  const ProblemListComponent({
    super.key,
    this.problems = const [
      {'name': 'Socket', 'icon': Icons.power},
      {'name': 'Luminaire', 'icon': Icons.light},
      {'name': 'Switcher', 'icon': Icons.toggle_on},
      {'name': 'Wiring', 'icon': Icons.electrical_services},
      {'name': 'Ceiling Fan', 'icon': Icons.air},
      {'name': 'Lamp', 'icon': Icons.lightbulb},
      {'name': 'Freezer', 'icon': Icons.kitchen},
      {'name': 'Refrigerator', 'icon': Icons.kitchen},
      {'name': 'Others', 'icon': Icons.build},
    ],
    required this.onSelectionChanged,
    required this.isGuest,
    required this.phoneNumber,
  });

  @override
  _ProblemListComponentState createState() => _ProblemListComponentState();
}

class _ProblemListComponentState extends State<ProblemListComponent> {
  Set<String> selectedProblems = {};
  Map<String, Map<String, int>> problemPriceRanges = {};

  @override
  void initState() {
    super.initState();
  }

  String _sanitizeKey(String key) {
    return key
        .replaceAll('.', '-')
        .replaceAll('#', '-')
        .replaceAll('\$', '-')
        .replaceAll('/', '-')
        .replaceAll('[', '-')
        .replaceAll(']', '-');
  }

  Future<void> _saveProblems() async {
    try {
      Map<String, dynamic> sanitizedPriceRanges = {};
      problemPriceRanges.forEach((key, value) {
        String sanitizedKey = _sanitizeKey(key);
        sanitizedPriceRanges[sanitizedKey] = value;
      });

      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(widget.phoneNumber)
          .update({
        'electricalproblem': sanitizedPriceRanges,
      });
    } catch (e) {
      // Handle error silently as per original code
    }
  }

  void _showGuestPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Account Required'),
          content: const Text('You need an account to access this feature. Please sign up or log in to continue.'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage(fullName: "Guest", phoneNumber: "guest")),
                );
              },
              child: const Text('OK', style: TextStyle(fontSize: 16, color: Color(0xFF0C5FB3))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.85,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.problems.map((problem) => _buildProblemItem(problem['name'], problem['icon'], context)).toList(),
      ),
    );
  }

  Widget _buildProblemItem(String problem, IconData icon, BuildContext context) {
    final isSelected = selectedProblems.contains(problem);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (widget.isGuest) {
              _showGuestPopup(context);
            } else {
              if (selectedProblems.contains(problem)) {
                setState(() {
                  selectedProblems.remove(problem);
                  problemPriceRanges.remove(problem);
                });
              } else {
                switch (problem) {
                  case 'Socket':
                    problemPriceRanges[problem] = {'min': 100, 'max': 300};
                    break;
                  case 'Luminaire':
                    problemPriceRanges[problem] = {'min': 200, 'max': 1000};
                    break;
                  case 'Switcher':
                    problemPriceRanges[problem] = {'min': 80, 'max': 200};
                    break;
                  case 'Wiring':
                    problemPriceRanges[problem] = {'min': 500, 'max': 2000};
                    break;
                  case 'Ceiling Fan':
                    problemPriceRanges[problem] = {'min': 150, 'max': 600};
                    break;
                  case 'Lamp':
                    problemPriceRanges[problem] = {'min': 50, 'max': 150};
                    break;
                  case 'Freezer':
                    problemPriceRanges[problem] = {'min': 300, 'max': 1500};
                    break;
                  case 'Refrigerator':
                    problemPriceRanges[problem] = {'min': 400, 'max': 2000};
                    break;
                  case 'Others':
                    problemPriceRanges[problem] = {'min': 100, 'max': 500};
                    break;
                  default:
                    problemPriceRanges[problem] = {'min': 100, 'max': 200};
                }

                if (problem == 'Lamp' || problem == 'Wiring') {
                  _showHelpDialog(problem, context);
                } else {
                  setState(() {
                    selectedProblems.add(problem);
                  });
                }
              }
              widget.onSelectionChanged(selectedProblems, problemPriceRanges);
              _saveProblems();
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE6EEF7) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF0C5FB3).withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
              border: Border.all(
                color: isSelected ? const Color(0xFF0C5FB3) : const Color(0xFFC4C4C4),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 24,
                      color: isSelected ? const Color(0xFF0C5FB3) : Colors.grey,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      problem,
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 19,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? const Color(0xFF0C5FB3) : Colors.black,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0C5FB3) : const Color(0xFFEFEEEC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0C5FB3) : const Color(0xFFC4C4C4),
                      width: 1,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHelpDialog(String problem, BuildContext context) {
    setState(() {
      selectedProblems.add(problem);
    });
    _saveProblems();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                problem == 'Lamp' ? Icons.lightbulb : Icons.electrical_services,
                color: const Color(0xFF0C5FB3),
              ),
              const SizedBox(width: 10),
              const Text('DIY Solution Available', style: TextStyle(fontSize: 20)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'We have step-by-step video tutorials that can help you fix the $problem yourself!',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 120,
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      size: 40,
                      color: const Color(0xFF0C5FB3).withOpacity(0.8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Skip', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoScreen(username: widget.phoneNumber),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C5FB3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Watch Tutorial'),
            ),
          ],
        );
      },
    );
  }
}

class NavigationComponent extends StatelessWidget {
  final VoidCallback? onBackPressed;
  final VoidCallback? onNextPressed;
  final int currentPage;
  final int totalPages;
  final bool isNextEnabled;

  const NavigationComponent({
    super.key,
    this.onBackPressed,
    this.onNextPressed,
    this.currentPage = 1,
    this.totalPages = 4,
    this.isNextEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: onBackPressed,
            child: Container(
              width: 60,
              height: 60,
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
              child: const Center(
                child: Icon(
                  Icons.arrow_back,
                  size: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '$currentPage of $totalPages',
              style: const TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 27,
                fontWeight: FontWeight.w400,
                color: Color(0xFF0C5FB3),
              ),
            ),
          ),
          InkWell(
            onTap: isNextEnabled ? onNextPressed : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: isNextEnabled ? const Color(0xFF0C5FB3) : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(30),
                boxShadow: isNextEnabled
                    ? [
                        BoxShadow(
                          color: const Color(0xFF0C5FB3).withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  const Text(
                    'Next',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ElectricianProblemLayout extends StatefulWidget {
  final String username;
  const ElectricianProblemLayout({super.key, required this.username});

  String get phoneNumber => username;

  @override
  _ElectricianProblemLayoutState createState() => _ElectricianProblemLayoutState();
}

class _ElectricianProblemLayoutState extends State<ElectricianProblemLayout> {
  Set<String> selectedProblems = {};
  Map<String, Map<String, int>> problemPriceRanges = {};

  void _updateSelectedProblems(Set<String> problems, Map<String, Map<String, int>> priceRanges) {
    setState(() {
      selectedProblems = problems;
      problemPriceRanges = priceRanges;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Electrical Service',
          style: TextStyle(
            fontFamily: 'Playfair_Display',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0C5FB3),
        elevation: 4,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Help'),
                  content: const Text('Select the areas that need electrical service. You can select multiple options.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                // Uncomment if you have the background image
                // image: DecorationImage(
                //   image: const AssetImage('assets/bg_pattern.png'),
                //   fit: BoxFit.cover,
                //   colorFilter: ColorFilter.mode(
                //     Colors.white.withOpacity(0.1),
                //     BlendMode.dstATop,
                //   ),
                // ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(height: 24),
                    const HeaderComponent(title: 'What needs fixing?'),
                    const SizedBox(height: 10),
                    Container(
                      width: 60,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C5FB3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: SingleChildScrollView(
                        child: ProblemListComponent(
                          onSelectionChanged: _updateSelectedProblems,
                          isGuest: widget.username == "Guest",
                          phoneNumber: widget.phoneNumber,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 0,
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (selectedProblems.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Selected: ${selectedProblems.length} ${selectedProblems.length == 1 ? 'item' : 'items'}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          NavigationComponent(
                            onBackPressed: () => Navigator.pop(context),
                            onNextPressed: selectedProblems.isNotEmpty
                                ? () {
                                    if (widget.username == "Guest") {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text('Account Required'),
                                            content: const Text('You need an account to proceed further. Please sign up or log in to continue.'),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pushReplacement(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) => const HomePage(fullName: "Guest", phoneNumber: "guest")),
                                                  );
                                                },
                                                child: const Text('OK', style: TextStyle(fontSize: 16, color: Color(0xFF0C5FB3))),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ElectricianDescription(
                                            problemPriceRanges: problemPriceRanges,
                                            phoneNumber: widget.phoneNumber,
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            isNextEnabled: selectedProblems.isNotEmpty,
                          ),
                        ],
                      ),
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
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Electrical Service',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ElectricianProblemLayout(username: "exampleUser"),
    );
  }
}