import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/app_state.dart';
import '../../models/vehicle.dart';
import '../../widgets/vehicle_card.dart';
import '../login_screen.dart';
import 'inbox_screen.dart';
import 'edit_profile_screen.dart';
import 'vehicle_history_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();



  // Form keys and controllers for custom vehicle addition
  final _addFormKey = GlobalKey<FormState>();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _modelNameController = TextEditingController();
  final _rateController = TextEditingController();
  VehicleType _selectedVehicleType = VehicleType.car;
  bool _isAvailable = true;

  String? _pickedOutsidePhotoPath;
  String? _pickedInsidePhotoPath;

  Future<void> _pickImage({required bool isOutside}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          if (isOutside) {
            _pickedOutsidePhotoPath = image.path;
          } else {
            _pickedInsidePhotoPath = image.path;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Simulate automatic GPS location activation on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocationFlow();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _modelNameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _initLocationFlow() async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // First, check location service status
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      _showLocationServiceDialog();
    } else {
      // If service is enabled, trigger location fetching
      appState.triggerLocationOn();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check location service when returning from settings
      _checkLocationServiceStatusOnResume();
    }
  }

  Future<void> _checkLocationServiceStatusOnResume() async {
    final appState = Provider.of<AppState>(context, listen: false);
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled && (appState.currentAddress == 'Location Unavailable' || appState.currentAddress == 'Fetching...')) {
      appState.triggerLocationOn();
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.location_off_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Location Services Off', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Your device location services are turned off. Please enable location to find vehicles near you.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                // Trigger normal initialization to show Location Unavailable screen
                Provider.of<AppState>(context, listen: false).triggerLocationOn();
              },
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await Geolocator.openLocationSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF536DFE),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Open Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: _currentIndex == 0
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GaadiSaathi',
                      style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (appState.isFetchingLocation) ...[
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              color: Color(0xFF536DFE),
                              strokeWidth: 1.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Fetching...',
                              style: TextStyle(color: context.textColor54, fontSize: 11, fontWeight: FontWeight.normal),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ] else ...[
                          const Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 12),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              appState.currentAddress,
                              style: TextStyle(color: context.textColor54, fontSize: 11, fontWeight: FontWeight.normal),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                )
              : Text(
                  _currentIndex == 1 ? 'Add Vehicle' : 'My Profile',
                  style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold),
                ),
          actions: _currentIndex == 0
              ? [
                  _buildChatAction(context, appState),
                  const SizedBox(width: 8),
                ]
              : null,
        ),
        body: _currentIndex == 0
            ? _buildBrowseTab(appState)
            : _currentIndex == 1
                ? _buildAddRequestTab(appState)
                : _buildProfileTab(appState),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Theme.of(context).cardColor,
          selectedItemColor: const Color(0xFF536DFE),
          unselectedItemColor: context.textColor30,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_rounded),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline_rounded),
              label: 'Add',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseTab(AppState appState) {
    final vehicles = appState.filteredVehicles;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (val) {
              appState.setSearchQuery(val);
            },
            style: TextStyle(color: context.textColor),
            decoration: InputDecoration(
              hintText: 'Search model, owner name...',
              hintStyle: TextStyle(color: context.textColor30),
              prefixIcon: Icon(Icons.search_rounded, color: context.textColor30),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: context.textColor30),
                      onPressed: () {
                        _searchController.clear();
                        appState.setSearchQuery('');
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).cardColor,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.transparent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF536DFE)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Category Filter Tabs
          _buildCategoryFilterRow(appState),
          const SizedBox(height: 16),

          // Vehicles List Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VEHICLES WITHIN RANGE',
                style: TextStyle(
                  color: context.textColor30,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              if (appState.isLocationOn)
                Text(
                  '${vehicles.length} Active Services',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Vehicle List
          if (!appState.isLocationOn)
            const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF536DFE)),
              ),
            )
          else if (vehicles.isEmpty)
            _buildEmptyStateCard(appState)
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                return VehicleCard(vehicle: vehicles[index]);
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterRow(AppState appState) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: 'All Vehicles',
            isSelected: appState.selectedCategoryFilter == null,
            onTap: () => appState.setCategoryFilter(null),
          ),
          ...VehicleType.values.map((type) {
            final isSelected = appState.selectedCategoryFilter == type;
            return _buildFilterChip(
              label: type.displayName,
              isSelected: isSelected,
              onTap: () => appState.setCategoryFilter(type),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF536DFE) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : (context.isDarkMode ? const Color(0xFF2E3B4E) : const Color(0xFFE2E8F0)),
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : context.textColor70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard(AppState appState) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.car_crash_rounded, color: context.textColor30, size: 48),
          const SizedBox(height: 16),
          Text(
            'No Vehicles in this Range',
            style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no active vehicles registered within ${appState.searchRadiusKm.toStringAsFixed(1)} Km. Try widening the search radius.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textColor54, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildAddRequestTab(AppState appState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Form(
              key: _addFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add your vehicle details to list it on our platform for get early bookings.',
                    style: TextStyle(
                      color: context.textColor54,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Owner Name Input
                  TextFormField(
                    controller: _ownerNameController,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(color: context.textColor, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Owner Name',
                      labelStyle: TextStyle(color: context.textColor30),
                      prefixIcon: Icon(Icons.person_outline_rounded, color: context.textColor30, size: 18),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: context.isDarkMode ? const Color(0x1AFFFFFF) : const Color(0x15000000), width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF536DFE)),
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Enter owner name' : null,
                  ),
                  const SizedBox(height: 12),

                  // Phone Number Input
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: context.textColor, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: TextStyle(color: context.textColor30),
                      prefixIcon: Icon(Icons.phone_rounded, color: context.textColor30, size: 18),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: context.isDarkMode ? const Color(0x1AFFFFFF) : const Color(0x15000000), width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF536DFE)),
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Enter phone number' : null,
                  ),
                  const SizedBox(height: 12),

                  // Address Input
                  TextFormField(
                    controller: _addressController,
                    maxLines: 1,
                    style: TextStyle(color: context.textColor, fontSize: 14),
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      labelStyle: TextStyle(color: context.textColor30),
                      prefixIcon: Icon(Icons.location_on_rounded, color: context.textColor30, size: 18),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.my_location_rounded, color: Color(0xFF536DFE), size: 20),
                        tooltip: 'Use Current Location',
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          messenger.clearSnackBars();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Fetching location...'),
                                ],
                              ),
                              duration: Duration(days: 1),
                            ),
                          );
                          await appState.fetchCurrentLocation();
                          messenger.clearSnackBars();
                          _addressController.text = appState.currentAddress;
                        },
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: context.isDarkMode ? const Color(0x1AFFFFFF) : const Color(0x15000000), width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF536DFE)),
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Enter address' : null,
                  ),
                  const SizedBox(height: 20),

                  // Vehicle Type Option (give option below)
                  Text(
                    'VEHICLE TYPE',
                    style: TextStyle(
                      color: context.textColor30,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: VehicleType.values.map((type) {
                      final isSelected = _selectedVehicleType == type;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedVehicleType = type;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF536DFE) : Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : (context.isDarkMode ? const Color(0xFF2E3B4E) : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                type.displayName,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : context.textColor70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Model Name Input
                  TextFormField(
                    controller: _modelNameController,
                    style: TextStyle(color: context.textColor, fontSize: 14),
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Vehicle Model Name',
                      labelStyle: TextStyle(color: context.textColor30),
                      prefixIcon: Icon(Icons.commute_rounded, color: context.textColor30, size: 18),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: context.isDarkMode ? const Color(0x1AFFFFFF) : const Color(0x15000000), width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF536DFE)),
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Enter model name' : null,
                  ),
                  const SizedBox(height: 12),

                  // Charge per Km Input
                  TextFormField(
                    controller: _rateController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: context.textColor, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Charge per Km (₹)',
                      labelStyle: TextStyle(color: context.textColor30),
                      prefixIcon: Icon(Icons.currency_rupee_rounded, color: context.textColor30, size: 18),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: context.isDarkMode ? const Color(0x1AFFFFFF) : const Color(0x15000000), width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF536DFE)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Enter rate per Km';
                      if (double.tryParse(value) == null) return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Availability Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: context.isDarkMode ? const Color(0x1AFFFFFF) : const Color(0x15000000),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Availability Status',
                                style: TextStyle(
                                  color: context.textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isAvailable ? 'Service is ON (Available for bookings)' : 'Service is OFF (Unavailable)',
                                style: TextStyle(
                                  color: _isAvailable ? const Color(0xFF10B981) : context.textColor30,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _isAvailable,
                          activeThumbColor: const Color(0xFF10B981),
                          activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.3),
                          onChanged: (value) {
                            setState(() {
                              _isAvailable = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  Text(
                    'VEHICLE PHOTOS',
                    style: TextStyle(
                      color: context.textColor30,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Outside Photo Picker
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickImage(isOutside: true),
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: context.isDarkMode ? const Color(0x1AFFFFFF) : const Color(0x15000000),
                                width: 1.5,
                              ),
                            ),
                            child: _pickedOutsidePhotoPath != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      File(_pickedOutsidePhotoPath!),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF536DFE), size: 24),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Outside Photo',
                                        style: TextStyle(color: context.textColor54, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Inside Photo Picker
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickImage(isOutside: false),
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: context.isDarkMode ? const Color(0x1AFFFFFF) : const Color(0x15000000),
                                width: 1.5,
                              ),
                            ),
                            child: _pickedInsidePhotoPath != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      File(_pickedInsidePhotoPath!),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF536DFE), size: 24),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Inside Photo',
                                        style: TextStyle(color: context.textColor54, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    onPressed: () async {
                      if (!_addFormKey.currentState!.validate()) return;
                      final appState = Provider.of<AppState>(context, listen: false);
                      final messenger = ScaffoldMessenger.of(context);

                      // Enforce image uploads
                      if (_pickedOutsidePhotoPath == null || _pickedInsidePhotoPath == null) {
                        messenger.clearSnackBars();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Please select both Outside and Inside photos of the vehicle.'),
                            backgroundColor: Colors.orangeAccent,
                          ),
                        );
                        return;
                      }

                      // Show loading SnackBar
                      messenger.clearSnackBars();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text('Adding Vehicle...'),
                            ],
                          ),
                          duration: Duration(days: 1),
                        ),
                      );

                      String? finalOutsideUrl;
                      String? finalInsideUrl;

                      // Upload outside photo
                      if (_pickedOutsidePhotoPath != null) {
                        finalOutsideUrl = await appState.uploadToCloudinary(_pickedOutsidePhotoPath!);
                        if (finalOutsideUrl == null) {
                          messenger.clearSnackBars();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Failed to upload Outside photo. Please try again.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }
                      }

                      // Upload inside photo
                      if (_pickedInsidePhotoPath != null) {
                        finalInsideUrl = await appState.uploadToCloudinary(_pickedInsidePhotoPath!);
                        if (finalInsideUrl == null) {
                          messenger.clearSnackBars();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Failed to upload Inside photo. Please try again.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }
                      }

                      // Clear SnackBar
                      messenger.clearSnackBars();

                      // Create and add new vehicle
                      final newVehicle = Vehicle(
                        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                        ownerName: _ownerNameController.text.trim(),
                        ownerGmail: appState.currentGmail ?? 'guest.customer@gmail.com',
                        type: _selectedVehicleType,
                        model: _modelNameController.text.trim(),
                        insidePhotoUrl: finalInsideUrl!,
                        outsidePhotoUrl: finalOutsideUrl!,
                        ratePerKm: double.tryParse(_rateController.text.trim()) ?? 0.0,
                        isServiceOn: _isAvailable,
                        latitude: appState.customerLatitude + (Random().nextDouble() - 0.5) * 0.02,
                        longitude: appState.customerLongitude + (Random().nextDouble() - 0.5) * 0.02,
                        phoneNumber: _phoneController.text.trim(),
                        address: _addressController.text.trim(),
                      );

                      appState.addCustomVehicle(newVehicle);

                      if (!mounted) return;
                      setState(() {
                        _ownerNameController.clear();
                        _phoneController.clear();
                        _addressController.clear();
                        _modelNameController.clear();
                        _rateController.clear();
                        _isAvailable = true;
                        _pickedOutsidePhotoPath = null;
                        _pickedInsidePhotoPath = null;
                      });

                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Vehicle Registered & Listed Successfully!'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF536DFE),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Add Vehicle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MY REGISTERED VEHICLES',
                style: TextStyle(
                  color: context.textColor30,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              if (appState.myVehicles.isNotEmpty)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VehicleHistoryScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      color: Color(0xFF536DFE),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (appState.myVehicles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.commute_rounded, color: context.textColor30, size: 36),
                    const SizedBox(height: 12),
                    Text(
                      'No Vehicles Added Yet',
                      style: TextStyle(color: context.textColor30, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vehicles you register will show here.',
                      style: TextStyle(color: context.textColor30.withValues(alpha: 0.8), fontSize: 11),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appState.myVehicles.length > 1 ? 1 : appState.myVehicles.length,
              itemBuilder: (context, idx) {
                final vehicle = appState.myVehicles[idx];
                return VehicleCard(vehicle: vehicle);
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileTab(AppState appState) {
    final name = appState.currentUserName ?? 'Guest User';
    final email = appState.currentGmail ?? 'guest.customer@gmail.com';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'G';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFF536DFE),
                  backgroundImage: appState.currentUserPhotoUrl != null && appState.currentUserPhotoUrl!.isNotEmpty
                      ? NetworkImage(appState.currentUserPhotoUrl!)
                      : null,
                  child: appState.currentUserPhotoUrl != null && appState.currentUserPhotoUrl!.isNotEmpty
                      ? null
                      : Text(
                          initial,
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(color: context.textColor54, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Settings Section Title
          Text(
            'SETTINGS & PREFERENCES',
            style: TextStyle(
              color: context.textColor30,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),

          // Settings List
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.isDarkMode ? const Color(0x0AFFFFFF) : const Color(0x08000000)),
            ),
            child: Column(
              children: [
                _buildSettingTile(
                  context: context,
                  icon: Icons.person_outline_rounded,
                  title: 'Edit Profile',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                    );
                  },
                ),
                _buildDivider(context),
                _buildSettingTile(
                  context: context,
                  icon: Icons.history_rounded,
                  title: 'Vehicle History',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VehicleHistoryScreen(),
                      ),
                    );
                  },
                ),
                _buildDivider(context),
                // Theme Settings (custom trailing)
                ListTile(
                  leading: const Icon(Icons.palette_outlined, color: Color(0xFF536DFE)),
                  title: Text('Theme Settings', style: TextStyle(color: context.textColor, fontSize: 14)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        appState.themeMode == ThemeMode.system
                            ? 'System'
                            : appState.themeMode == ThemeMode.dark
                                ? 'Dark'
                                : 'Light',
                        style: TextStyle(color: context.textColor30, fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, color: context.textColor30, size: 20),
                    ],
                  ),
                  onTap: () => _showThemeBottomSheet(context, appState),
                ),
                _buildDivider(context),
                _buildSettingTile(
                  context: context,
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  onTap: () => _handleEmailLaunch(context),
                ),
                _buildDivider(context),
                _buildSettingTile(
                  context: context,
                  icon: Icons.security_rounded,
                  title: 'Privacy Policy',
                  onTap: () => _handlePrivacyPolicyLaunch(context),
                ),
                _buildDivider(context),
                _buildSettingTile(
                  context: context,
                  icon: Icons.share_outlined,
                  title: 'Share App',
                  onTap: () => _handleShareApp(context),
                ),
                _buildDivider(context),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  title: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Color(0x80FF5252), size: 20),
                  onTap: () => _showLogoutConfirmDialog(context, appState),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Text(
                  'GaadiSaathi',
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: context.textColor30,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF536DFE)),
      title: Text(title, style: TextStyle(color: context.textColor, fontSize: 14)),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(color: context.textColor54, fontSize: 11))
          : null,
      trailing: Icon(Icons.chevron_right_rounded, color: context.textColor30, size: 20),
      onTap: onTap,
    );
  }

  Future<void> _handleEmailLaunch(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'dhirendrasuman001@gmail.com',
      query: 'subject=Support%20Request%20-%20GaadiSaathi',
    );

    try {
      await launchUrl(emailLaunchUri);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open email client. Contact: dhirendrasuman001@gmail.com'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handlePrivacyPolicyLaunch(BuildContext context) async {
    final Uri privacyUri = Uri.parse('https://surajchaurasia84.github.io/GaadiSaathi/');
    try {
      await launchUrl(privacyUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open privacy policy link.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: context.isDarkMode ? const Color(0x0AFFFFFF) : const Color(0x08000000),
    );
  }


  void _handleShareApp(BuildContext context) {
    SharePlus.instance.share(
      ShareParams(
        text: 'Hey! Check out GaadiSaathi - Your ultimate peer-to-peer vehicle rental partner. '
            'Rent cars, e-rickshaws, or loading vehicles easily or start earning by listing yours!\n\n'
            'Download now from Google Play Store:\n'
            'https://play.google.com/store/apps/details?id=com.gaadisaathi.rent.apps',
        title: 'Share GaadiSaathi App',
      ),
    );
  }

  void _showLogoutConfirmDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Confirm Log Out',
            style: TextStyle(
              color: context.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: TextStyle(
              color: context.textColor54,
              fontSize: 14,
            ),
          ),
          actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: context.textColor54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                appState.logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Log Out',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChatAction(BuildContext context, AppState appState) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.chat_bubble_outline_rounded, color: context.textColor),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const InboxScreen()),
            );
          },
        ),
        if (appState.hasAnyUnreadMessages)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  void _showThemeBottomSheet(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Theme.of(context).cardColor,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose Theme',
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildThemeOption(
                context: context,
                appState: appState,
                title: 'System Default',
                icon: Icons.brightness_auto_rounded,
                iconColor: Colors.blue,
                mode: ThemeMode.system,
              ),
              const SizedBox(height: 8),
              _buildThemeOption(
                context: context,
                appState: appState,
                title: 'Light Mode',
                icon: Icons.light_mode_rounded,
                iconColor: Colors.orange,
                mode: ThemeMode.light,
              ),
              const SizedBox(height: 8),
              _buildThemeOption(
                context: context,
                appState: appState,
                title: 'Dark Mode',
                icon: Icons.dark_mode_rounded,
                iconColor: Colors.purple,
                mode: ThemeMode.dark,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required AppState appState,
    required String title,
    required IconData icon,
    required Color iconColor,
    required ThemeMode mode,
  }) {
    final isSelected = appState.themeMode == mode;
    return InkWell(
      onTap: () {
        appState.setThemeMode(mode);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: context.textColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF536DFE),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
