import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';
import 'electrician_address&date.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MaterialApp(home: ElectricianDateTimePickerScreen(phoneNumber: 'guest')));
}

class ElectricianDateTimePickerScreen extends StatefulWidget {
  final String phoneNumber;
  const ElectricianDateTimePickerScreen({super.key, required this.phoneNumber});

  @override
  _ElectricianDateTimePickerScreenState createState() => _ElectricianDateTimePickerScreenState();
}

class _ElectricianDateTimePickerScreenState extends State<ElectricianDateTimePickerScreen> with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _showCalendar = false;
  bool _isDateAndTimeSelected = false;
  AnimationController? _animationController;
  Animation<double>? _animation;
  final TextEditingController _hourController = TextEditingController();
  final TextEditingController _minuteController = TextEditingController();
  String _selectedPeriod = 'AM';

  final Color brandBlue = const Color(0xFF0C5FB3);
  final Color brandLightBlue = const Color(0xFF5B9BD5);
  final Color brandBackground = const Color(0xFFF5F5F7);
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    );
    
    // Initialize the text controllers with current time
    _hourController.text = (_selectedTime.hourOfPeriod == 0 ? 12 : _selectedTime.hourOfPeriod).toString();
    _minuteController.text = _selectedTime.minute.toString().padLeft(2, '0');
    _selectedPeriod = _selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _toggleCalendar() {
    setState(() {
      _showCalendar = !_showCalendar;
      if (_showCalendar) {
        _animationController?.forward();
      } else {
        _animationController?.reverse();
      }
    });
  }

  void _updateSelectedTime() {
    try {
      int hour = int.parse(_hourController.text);
      int minute = int.parse(_minuteController.text);

      // Validate hour and minute values
      if (hour < 1 || hour > 12) {
        _showErrorSnackBar('Please enter a valid hour (1-12)');
        return;
      }
      if (minute < 0 || minute > 59) {
        _showErrorSnackBar('Please enter a valid minute (0-59)');
        return;
      }

      // Convert from 12-hour to 24-hour format if PM
      if (_selectedPeriod == 'PM' && hour < 12) {
        hour += 12;
      } else if (_selectedPeriod == 'AM' && hour == 12) {
        hour = 0;
      }

      setState(() {
        _selectedTime = TimeOfDay(hour: hour, minute: minute);
        _isDateAndTimeSelected = true;
      });
    } catch (e) {
      _showErrorSnackBar('Please enter valid time values');
    }
  }

  void _togglePeriod() {
    setState(() {
      _selectedPeriod = _selectedPeriod == 'AM' ? 'PM' : 'AM';
      _updateSelectedTime();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: Colors.redAccent,
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('EEEE, MMMM d, y').format(dateTime);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _saveToRealtimeDatabase() async {
    try {
      if (widget.phoneNumber == 'guest') {
        throw Exception('Please sign in to book an electrician appointment');
      }

      final userSnapshot = await _database.child('users').child(widget.phoneNumber).get();

      if (!userSnapshot.exists) {
        throw Exception('User not found');
      }

      final DateTime combinedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Create appointment data
      Map<String, dynamic> appointmentData = {
        'dateTime': combinedDateTime.toIso8601String(),
        'formattedDate': _formatDate(_selectedDate),
        'formattedTime': _formatTime(_selectedTime),
        'status': 'pending',
        'type': 'electrician',
        'timeData': {
          'hour': _selectedTime.hour,
          'minute': _selectedTime.minute,
          'period': _selectedTime.period == DayPeriod.am ? 'AM' : 'PM'
        }
      };

      // Save only the current appointment, overwriting any previous ones
      await _database
          .child('users')
          .child(widget.phoneNumber)
          .child('current_electrician_appointment')
          .set(appointmentData);

    } catch (e) {
      if (e.toString().contains('Please sign in') && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            backgroundColor: Colors.redAccent,
            content: Text(
              e.toString(),
              style: const TextStyle(color: Colors.white),
            ),
            action: SnackBarAction(
              label: 'Sign In',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/signup');
              },
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            backgroundColor: Colors.redAccent,
            content: Text(
              'Error saving electrician appointment: $e',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  void _confirmSelection() {
    if (_isDateAndTimeSelected) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      _saveToRealtimeDatabase().then((_) {
        if (mounted) {
          Navigator.pop(context);
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => ElectricianAddressAndDate(
                selectedDate: _selectedDate,
                selectedTime: _selectedTime,
                phoneNumber: widget.phoneNumber,
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                return SlideTransition(position: animation.drive(tween), child: child);
              },
            ),
          );
        }
      }).catchError((e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              backgroundColor: Colors.redAccent,
              content: Text(
                'Error saving appointment: $e',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandBackground,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: brandBlue,
        title: const Text(
          'Select Date & Time',
          style: TextStyle(
            fontFamily: 'Playfair_Display',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'When do you need the electrician service?',
                        style: TextStyle(
                          fontFamily: 'Playfair_Display',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: brandBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildDateSelector(),
                    const SizedBox(height: 10),
                    _buildCalendarSection(),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Enter your preferred time',
                        style: TextStyle(
                          fontFamily: 'Playfair_Display',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: brandBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildCustomTimePicker(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: _toggleCalendar,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 3),
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: brandBlue,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(_selectedDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                _showCalendar ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: brandBlue,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarSection() {
    if (_animation == null) {
      return Container();
    }

    return SizeTransition(
      sizeFactor: _animation!,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 3),
              blurRadius: 6,
            ),
          ],
        ),
        child: TableCalendar(
          firstDay: DateTime.now(),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: _selectedDate,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDate, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDate = selectedDay;
              _toggleCalendar();
              _isDateAndTimeSelected = true;
            });
          },
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              color: brandBlue,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            leftChevronIcon: Icon(
              Icons.chevron_left,
              color: brandBlue,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right,
              color: brandBlue,
            ),
            headerMargin: const EdgeInsets.only(bottom: 8),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: brandBlue),
            weekendStyle: TextStyle(color: brandLightBlue),
          ),
          calendarStyle: CalendarStyle(
            selectedDecoration: BoxDecoration(
              color: brandBlue,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: brandLightBlue.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            outsideDaysVisible: false,
            weekendTextStyle: const TextStyle(color: Colors.red),
          ),
          calendarBuilders: CalendarBuilders(
            outsideBuilder: (context, day, focusedDay) {
              return Container();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTimePicker() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Custom Time',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: brandBlue,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hour input field
              Container(
                width: 70,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _hourController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      _updateSelectedTime();
                    }
                  },
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: 'HH',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  ':',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Minute input field
              Container(
                width: 70,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _minuteController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      _updateSelectedTime();
                    }
                  },
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: 'MM',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // AM/PM Toggle Button
              InkWell(
                onTap: _togglePeriod,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: brandBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _selectedPeriod,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Selected Time: ${_formatTime(_selectedTime)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: brandBlue,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Please enter a time between 1:00 AM and 12:59 PM for morning appointments, or between 1:00 PM and 12:59 AM for afternoon/evening appointments.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: brandBlue,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.arrow_back, size: 24, color: Colors.white),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '3 of 4',
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 27,
                fontWeight: FontWeight.w400,
                color: brandBlue,
              ),
            ),
          ),
          GestureDetector(
            onTap: _isDateAndTimeSelected ? _confirmSelection : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: _isDateAndTimeSelected ? brandBlue : Colors.grey,
                borderRadius: BorderRadius.circular(30),
                boxShadow: _isDateAndTimeSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: const Text(
                'Next',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}