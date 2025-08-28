import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'homepage.dart';

class RatingScreen extends StatefulWidget {
  final String fullName;
  final String phoneNumber;
  final String? orderId;

  const RatingScreen({
    super.key,
    required this.fullName,
    required this.phoneNumber,
    this.orderId,
  });

  @override
  // ignore: library_private_types_in_public_api
  _RatingScreenState createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> with SingleTickerProviderStateMixin {
  int _selectedRating = 4;
  final TextEditingController _reviewController = TextEditingController();
  late AnimationController _animationController;
  bool _isSubmitting = false;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToHomepage(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(
          fullName: widget.fullName,
          phoneNumber: widget.phoneNumber,
        ),
      ),
    );
  }

  Future<void> _submitReview() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    if (_animationController.isAnimating) {
      _animationController.stop();
    }

    await _animationController.forward();
    await _animationController.reverse();

    try {
      await _database.child('ratings').push().set({
        'rating': _selectedRating,
        'review': _reviewController.text,
        'customerPhone': widget.phoneNumber,
        'customerName': widget.fullName,
        'timestamp': ServerValue.timestamp,
      });

      if (widget.orderId != null) {
        await _database.child('serviceRequests').child(widget.orderId!).update({
          'rating': _selectedRating,
          'review': _reviewController.text,
          'ratedAt': ServerValue.timestamp,
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thank you, ${widget.fullName}, for your feedback!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _navigateToHomepage(context);
        }
      });
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting review: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  String getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Very Dissatisfied';
      case 2:
        return 'Dissatisfied';
      case 3:
        return 'Neutral';
      case 4:
        return 'Satisfied';
      case 5:
        return 'Very Satisfied';
      default:
        return 'Satisfied';
    }
  }

  Color getRatingColor(int rating) {
    switch (rating) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber;
      case 4:
        return const Color(0xFF0C5FB3);
      case 5:
        return Colors.green;
      default:
        return const Color(0xFF0C5FB3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              children: [
                const SizedBox(height: 65),
                const SizedBox(height: 19),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        'Hello ${widget.fullName.split(' ')[0]}, I hope you had a wonderful experience!',
                        style: const TextStyle(
                          fontFamily: 'Playfair_Display',
                          fontSize: 18,
                          color: Color(0xFF0C5FB3),
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'How was Your Last Request?',
                        style: TextStyle(
                          fontSize: 27,
                          fontFamily: 'Playfair_Display',
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF0C5FB3),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                        decoration: BoxDecoration(
                          color: getRatingColor(_selectedRating).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          getRatingText(_selectedRating),
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Playfair_Display',
                            color: getRatingColor(_selectedRating),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedRating = index + 1;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                index < _selectedRating ? Icons.star : Icons.star_border,
                                size: 40,
                                color: getRatingColor(_selectedRating),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _reviewController,
                    maxLines: 5,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Inter',
                    ),
                    decoration: InputDecoration(
                      hintText: 'Please share your experience with us...',
                      hintStyle: TextStyle(
                        color: Colors.black.withOpacity(0.4),
                        fontSize: 16,
                        fontFamily: 'Inter',
                      ),
                      contentPadding: const EdgeInsets.all(20),
                      border: InputBorder.none,
                      counterText: '',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 15, right: 10, bottom: 70),
                        child: Icon(Icons.feedback_outlined, color: Color(0xFF0C5FB3)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C5FB3),
                    disabledBackgroundColor: const Color(0xFF0C5FB3).withOpacity(0.7),
                    minimumSize: const Size(248, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 25,
                            fontFamily: 'Open Sans',
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}