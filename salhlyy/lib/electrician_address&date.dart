import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'electrician_address_info.dart';
import 'electricianfixerlist.dart';

class ElectricianAddressAndDate extends StatefulWidget {
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final String phoneNumber;

  const ElectricianAddressAndDate({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.phoneNumber,
  });

  @override
  _ElectricianAddressAndDateState createState() => _ElectricianAddressAndDateState();
}

class _ElectricianAddressAndDateState extends State<ElectricianAddressAndDate> {
  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  TextEditingController addressController = TextEditingController();
  List<String> savedAddresses = ["El Narges Extensions, New Cairo"];
  String? selectedAddress;
  late DatabaseReference _databaseReference;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.selectedDate;
    selectedTime = widget.selectedTime;
    addressController.addListener(_updateButtonState);

    // Validate phone number
    if (widget.phoneNumber.isEmpty || !RegExp(r'^\+?[0-9]+$').hasMatch(widget.phoneNumber)) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    String sanitizedPhoneNumber = widget.phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    _databaseReference = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(sanitizedPhoneNumber)
        .child('address');

    _loadSelectedAddress();
  }

  @override
  void dispose() {
    addressController.removeListener(_updateButtonState);
    addressController.dispose();
    super.dispose();
  }

  void _loadSelectedAddress() async {
    setState(() {
      isLoading = true;
    });

    try {
      DataSnapshot snapshot = await _databaseReference.get();
      if (snapshot.exists) {
        Map<dynamic, dynamic>? addressData = snapshot.value as Map<dynamic, dynamic>?;
        if (addressData != null) {
          String formattedAddress = _formatAddressFromData(addressData);
          setState(() {
            selectedAddress = formattedAddress;
            addressController.text = formattedAddress;
            if (!savedAddresses.contains(formattedAddress)) {
              savedAddresses.add(formattedAddress);
            }
          });
        }
      }

      setState(() {
        isLoading = false;
        if (savedAddresses.isNotEmpty && selectedAddress == null) {
          selectedAddress = savedAddresses.first;
          addressController.text = selectedAddress!;
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load address: $e')),
      );
    }
  }

  Future<void> _saveSelectedAddress(String address) async {
    try {
      String sanitizedPhoneNumber = widget.phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(sanitizedPhoneNumber)
          .update({
        'selectedAddress': address
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save selected address: $e')),
      );
    }
  }

  String _formatAddressFromData(Map<dynamic, dynamic> addressData) {
    String baseAddress = "${addressData['type']}, ${addressData['building']}, ${addressData['street']}";
    if (addressData['floor']?.isNotEmpty == true) {
      baseAddress += ", Floor: ${addressData['floor']}";
    }
    if (addressData['aptNo']?.isNotEmpty == true) {
      baseAddress += ", Apt: ${addressData['aptNo']}";
    }
    if (addressData['latitude']?.isNotEmpty == true && addressData['longitude']?.isNotEmpty == true) {
      baseAddress += ", Lat: ${addressData['latitude']}, Lon: ${addressData['longitude']}";
    }
    return baseAddress;
  }

  void _navigateToAddressInfo() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ElectricianAddressInfoLayout(phoneNumber: widget.phoneNumber),
      ),
    );

    if (result != null && result is Map<String, String>) {
      setState(() {
        String formattedAddress = _formatAddressFromData(result);
        savedAddresses.add(formattedAddress);
        selectedAddress = formattedAddress;
        addressController.text = formattedAddress;
      });
    }
  }

  String _formatDateTime(DateTime date, TimeOfDay time) {
    final monthNames = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    final month = monthNames[date.month - 1];
    final day = date.day;
    final year = date.year;
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$month $day, $year, $hour:$minute $period';
  }

  void _updateButtonState() {
    setState(() {});
  }

  void _navigateToFixerList() {
    if (addressController.text.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Electricianfixerlist(
          selectedAddress: addressController.text,
          selectedDate: selectedDate,
          selectedTime: selectedTime,
          phoneNumber: widget.phoneNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Set Appointment',
          style: TextStyle(
            fontFamily: 'Playfair_Display',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0C5FB3),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: const Color(0xFF0C5FB3),
                  strokeWidth: 3,
                ),
              ),
            )
          : SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Date & Time', Icons.event),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0C5FB3).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_today,
                                    color: Color(0xFF0C5FB3),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatDateTime(selectedDate, selectedTime),
                                        style: const TextStyle(
                                          fontFamily: 'Open Sans',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Your selected appointment time',
                                        style: TextStyle(
                                          fontFamily: 'Open Sans',
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          _buildSectionHeader('Address Details', Icons.location_on),
                          const SizedBox(height: 12),
                          _buildAddressSelectionBox(),
                          const SizedBox(height: 20),
                          _buildSavedAddressesSection(),
                          const SizedBox(height: 10),
                          _buildNewAddressButton(),
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF0C5FB3),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Open Sans',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSelectionBox() {
    return GestureDetector(
      onTap: _navigateToAddressInfo,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            )
          ],
          border: Border.all(
            color: const Color(0xFF0C5FB3).withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                addressController.text.isEmpty ? "Select or add an address" : addressController.text,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: addressController.text.isEmpty ? Colors.grey.shade500 : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0C5FB3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.edit_location_alt_outlined,
                size: 20,
                color: Color(0xFF0C5FB3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedAddressesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.bookmark_outline,
              size: 16,
              color: Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              'Your saved addresses',
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.3,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: savedAddresses.length,
            itemBuilder: (context, index) {
              final address = savedAddresses[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: selectedAddress == address
                        ? const Color(0xFF0C5FB3).withOpacity(0.4)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedAddress = address;
                          addressController.text = address;
                          _saveSelectedAddress(address);
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: ListTile(
                          leading: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedAddress == address
                                    ? const Color(0xFF0C5FB3)
                                    : Colors.grey[400]!,
                                width: 2,
                              ),
                            ),
                            child: selectedAddress == address
                                ? const Center(
                                    child: Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Color(0xFF0C5FB3),
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            address,
                            style: const TextStyle(
                              fontFamily: 'Open Sans',
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          contentPadding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 8,
                            bottom: 8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNewAddressButton() {
    return TextButton.icon(
      onPressed: _navigateToAddressInfo,
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF0C5FB3).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add, size: 18, color: Color(0xFF0C5FB3)),
      ),
      label: const Text(
        'Add New Address',
        style: TextStyle(
          fontFamily: 'Open Sans',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0C5FB3),
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final bool isAddressSelected = addressController.text.isNotEmpty;

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
                color: const Color(0xFF0C5FB3),
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
            child: const Text(
              '4 of 4',
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 27,
                fontWeight: FontWeight.w400,
                color: Color(0xFF0C5FB3),
              ),
            ),
          ),
          GestureDetector(
            onTap: isAddressSelected ? _navigateToFixerList : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: isAddressSelected ? const Color(0xFF0C5FB3) : Colors.grey,
                borderRadius: BorderRadius.circular(30),
                boxShadow: isAddressSelected
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