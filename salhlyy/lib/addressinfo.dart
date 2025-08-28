import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const AddressInfoLayout(phoneNumber: '+1234567890'),
    );
  }
}

class AddressInfoLayout extends StatefulWidget {
  final String phoneNumber;
  const AddressInfoLayout({super.key, required this.phoneNumber});

  @override
  _AddressInfoLayoutState createState() => _AddressInfoLayoutState();
}

class _AddressInfoLayoutState extends State<AddressInfoLayout> {
  TextEditingController buildingController = TextEditingController();
  TextEditingController aptNoController = TextEditingController();
  TextEditingController floorController = TextEditingController();
  TextEditingController streetController = TextEditingController();
  TextEditingController directionsController = TextEditingController();
  TextEditingController labelController = TextEditingController();

  String selectedType = 'Apartment';
  bool isConfirmEnabled = false;

  LatLng? _currentLocation;
  bool _isLoading = true;
  bool _showMapFullScreen = false;
  final MapController _mapController = MapController();

  late DatabaseReference _databaseReference;

  @override
  void initState() {
    super.initState();
    String sanitizedPhoneNumber = widget.phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    _databaseReference = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(sanitizedPhoneNumber);

    buildingController.addListener(_updateConfirmButtonState);
    aptNoController.addListener(_updateConfirmButtonState);
    floorController.addListener(_updateConfirmButtonState);
    streetController.addListener(_updateConfirmButtonState);

    _getCurrentLocation();
  }

  @override
  void dispose() {
    buildingController.removeListener(_updateConfirmButtonState);
    aptNoController.removeListener(_updateConfirmButtonState);
    floorController.removeListener(_updateConfirmButtonState);
    streetController.removeListener(_updateConfirmButtonState);
    buildingController.dispose();
    aptNoController.dispose();
    floorController.dispose();
    streetController.dispose();
    directionsController.dispose();
    labelController.dispose();
    super.dispose();
  }

  void _updateConfirmButtonState() {
    setState(() {
      if (selectedType == 'Apartment') {
        isConfirmEnabled = buildingController.text.trim().isNotEmpty &&
            aptNoController.text.trim().isNotEmpty &&
            floorController.text.trim().isNotEmpty &&
            streetController.text.trim().isNotEmpty;
      } else if (selectedType == 'House') {
        isConfirmEnabled = buildingController.text.trim().isNotEmpty &&
            streetController.text.trim().isNotEmpty;
      } else if (selectedType == 'Company') {
        isConfirmEnabled = buildingController.text.trim().isNotEmpty &&
            floorController.text.trim().isNotEmpty &&
            streetController.text.trim().isNotEmpty;
      }
    });
  }

  void _confirmAddress() async {
    if (!isConfirmEnabled) return;

    Map<String, String> addressData = {
      'type': selectedType,
      'building': buildingController.text.trim(),
      'aptNo': selectedType == 'Apartment' ? aptNoController.text.trim() : '',
      'floor': selectedType == 'Apartment' || selectedType == 'Company' ? floorController.text.trim() : '',
      'street': streetController.text.trim(),
      'directions': directionsController.text.trim(),
      'label': labelController.text.trim(),
      'latitude': _currentLocation?.latitude.toString() ?? '',
      'longitude': _currentLocation?.longitude.toString() ?? '',
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      await _databaseReference.child('address').set(addressData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address saved successfully!')),
      );

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Confirm Address',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0C5FB3),
              fontFamily: 'Playfair_Display',
            ),
            textAlign: TextAlign.center,
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Please confirm your address details:',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            selectedType == 'Apartment'
                                ? Icons.apartment
                                : selectedType == 'House'
                                    ? Icons.home
                                    : Icons.business,
                            color: const Color(0xFF0C5FB3),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${addressData['type']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF0C5FB3),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _buildAddressDetailRow('Building', addressData['building']!),
                      if (addressData['aptNo']!.isNotEmpty)
                        _buildAddressDetailRow('Apt.No', addressData['aptNo']!),
                      if (addressData['floor']!.isNotEmpty)
                        _buildAddressDetailRow('Floor', addressData['floor']!),
                      _buildAddressDetailRow('Street', addressData['street']!),
                      if (addressData['directions']!.isNotEmpty)
                        _buildAddressDetailRow('Directions', addressData['directions']!),
                      if (addressData['label']!.isNotEmpty)
                        _buildAddressDetailRow('Label', addressData['label']!),
                      if (addressData['latitude']!.isNotEmpty)
                        _buildAddressDetailRow('Latitude', addressData['latitude']!),
                      if (addressData['longitude']!.isNotEmpty)
                        _buildAddressDetailRow('Longitude', addressData['longitude']!),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                  side: const BorderSide(color: Color(0xFF0C5FB3)),
                ),
              ),
              child: const Text(
                'Edit',
                style: TextStyle(
                  color: Color(0xFF0C5FB3),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, addressData);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0C5FB3),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Confirm',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save address: $e')),
      );
    }
  }

  Widget _buildAddressDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isLoading = false;
      });
      _showLocationServicesDialog();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoading = false;
        });
        _showPermissionDeniedDialog();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isLoading = false;
      });
      _showPermissionPermanentlyDeniedDialog();
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showLocationErrorDialog();
    }
  }

  void _showLocationServicesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text('Please enable location services to use the map feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Denied'),
        content: const Text('We need location permission to show your current location on the map.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Denied'),
        content: const Text('Location permission is permanently denied. Please enable it in app settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLocationErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Error'),
        content: const Text('There was an error getting your location. Please try again later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _updateMarkerPosition(LatLng newPosition) {
    setState(() {
      _currentLocation = newPosition;
    });
  }

  void _toggleMapFullScreen() {
    setState(() {
      _showMapFullScreen = !_showMapFullScreen;
    });
  }

  void _centerOnCurrentLocation() async {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15.0);
    } else {
      try {
        Position position = await Geolocator.getCurrentPosition();
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_currentLocation!, 15.0);
      } catch (e) {
        _showLocationErrorDialog();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showMapFullScreen) {
      return Scaffold(
        body: Stack(
          children: [
            _buildMapWidget(fullScreen: true),
            Positioned(
              top: 40,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: _toggleMapFullScreen,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.my_location, color: Colors.black),
                onPressed: _centerOnCurrentLocation,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: _toggleMapFullScreen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C5FB3),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text(
                    'Confirm Location',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFf5f5f7),
      appBar: AppBar(
        title: const Text(
          'Address Information',
          style: TextStyle(
            fontSize: 24,
            fontFamily: 'Playfair_Display',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0C5FB3),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Address Type',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                alignment: Alignment.center,
                child: HeaderComponent(
                  onSelectionChanged: (selected) {
                    setState(() {
                      selectedType = selected;
                      _updateConfirmButtonState();
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pin Your Location',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _toggleMapFullScreen,
                        icon: const Icon(Icons.open_in_full, size: 16),
                        label: const Text('Expand', style: TextStyle(fontSize: 14)),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF0C5FB3),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap on the map to select your exact location',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: SizedBox(
                      height: 170,
                      width: double.infinity,
                      child: _buildMapWidget(fullScreen: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Address Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              InputFieldsComponent(
                buildingController: buildingController,
                aptNoController: aptNoController,
                floorController: floorController,
                streetController: streetController,
                directionsController: directionsController,
                labelController: labelController,
                selectedType: selectedType,
              ),
              const SizedBox(height: 24),
              FooterComponent(
                onConfirm: _confirmAddress,
                onBack: () {
                  Navigator.of(context).pop();
                },
                isConfirmEnabled: isConfirmEnabled,
                selectedType: selectedType,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapWidget({required bool fullScreen}) {
    return _isLoading
        ? Container(
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF0C5FB3)),
                  const SizedBox(height: 10),
                  Text('Getting your location...', style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            ),
          )
        : _currentLocation == null
            ? Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off, size: 40, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text('Unable to fetch location'),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _getCurrentLocation,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              )
            : Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentLocation!,
                      initialZoom: fullScreen ? 15.0 : 13.0,
                      onTap: (tapPosition, point) {
                        _updateMarkerPosition(point);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentLocation!,
                            width: 40.0,
                            height: 40.0,
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Color(0xFF0C5FB3),
                                    size: 32.0,
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 2,
                                        spreadRadius: 0.5,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!fullScreen)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.my_location, color: Color(0xFF0C5FB3), size: 20),
                          onPressed: _centerOnCurrentLocation,
                          padding: const EdgeInsets.all(6),
                        ),
                      ),
                    ),
                ],
              );
  }
}

class HeaderComponent extends StatefulWidget {
  final Function(String)? onSelectionChanged;

  const HeaderComponent({super.key, this.onSelectionChanged});

  @override
  _HeaderComponentState createState() => _HeaderComponentState();
}

class _HeaderComponentState extends State<HeaderComponent> {
  String _selectedOption = 'Apartment';

  void _updateSelection(String option) {
    setState(() {
      _selectedOption = option;
    });
    widget.onSelectionChanged?.call(option);
  }

  Widget _buildOption(String text, bool isSelected) {
    return GestureDetector(
      onTap: () => _updateSelection(text),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        width: 105,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0C5FB3) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0C5FB3) : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0C5FB3).withOpacity(0.3),
                    spreadRadius: 0.5,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 0.5,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  )
                ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black.withOpacity(0.7),
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildOption('Apartment', _selectedOption == 'Apartment'),
        const SizedBox(width: 8),
        _buildOption('House', _selectedOption == 'House'),
        const SizedBox(width: 8),
        _buildOption('Company', _selectedOption == 'Company'),
      ],
    );
  }
}

class InputFieldsComponent extends StatelessWidget {
  final TextEditingController buildingController;
  final TextEditingController aptNoController;
  final TextEditingController floorController;
  final TextEditingController streetController;
  final TextEditingController directionsController;
  final TextEditingController labelController;
  final String selectedType;

  const InputFieldsComponent({
    super.key,
    required this.buildingController,
    required this.aptNoController,
    required this.floorController,
    required this.streetController,
    required this.directionsController,
    required this.labelController,
    required this.selectedType,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputFieldWithLabel('Building Name', buildingController, true),
          const SizedBox(height: 16),
          if (selectedType == 'Apartment')
            Row(
              children: [
                Expanded(
                  child: _buildInputFieldWithLabel('Apt. No', aptNoController, true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputFieldWithLabel('Floor', floorController, true),
                ),
              ],
            ),
          if (selectedType == 'Company')
            _buildInputFieldWithLabel('Floor', floorController, true),
          if (selectedType == 'Apartment' || selectedType == 'Company') const SizedBox(height: 16),
          _buildInputFieldWithLabel('Street', streetController, true),
          const SizedBox(height: 16),
          _buildInputFieldWithLabel('Additional Directions', directionsController, false),
          const SizedBox(height: 16),
          _buildInputFieldWithLabel('Address Label', labelController, false),
        ],
      ),
    );
  }

  Widget _buildInputFieldWithLabel(String label, TextEditingController controller, bool isRequired) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF444444),
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 0.5,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 15),
              border: InputBorder.none,
              hintText: isRequired ? 'Enter $label' : 'Optional',
              hintStyle: TextStyle(
                fontSize: 16,
                color: Colors.black.withOpacity(0.4),
              ),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => controller.clear(),
                      color: Colors.grey,
                    )
                  : null,
            ),
            onChanged: (value) {
              if (value.trim().isEmpty) {
                controller.value = controller.value.copyWith(
                  text: '',
                  selection: const TextSelection.collapsed(offset: 0),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

class FooterComponent extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onBack;
  final bool isConfirmEnabled;
  final String selectedType;

  const FooterComponent({
    super.key,
    required this.onConfirm,
    required this.onBack,
    required this.isConfirmEnabled,
    required this.selectedType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 0, right: 12),
            child: ElevatedButton(
              onPressed: onBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0C5FB3),
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(14),
                elevation: 2,
                minimumSize: const Size(48, 48),
              ),
              child: const Icon(Icons.arrow_back, size: 24),
            ),
          ),
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 48,
                child: ElevatedButton(
                  onPressed: isConfirmEnabled ? onConfirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isConfirmEnabled ? const Color(0xFF0C5FB3) : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: isConfirmEnabled ? 2 : 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Confirm Address',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: isConfirmEnabled ? Colors.white : Colors.grey.shade200,
                      ),
                    ],
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