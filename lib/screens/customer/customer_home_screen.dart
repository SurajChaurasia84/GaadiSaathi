import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/app_state.dart';
import '../../models/vehicle.dart';
import '../../widgets/vehicle_card.dart';
import '../../widgets/premium_button.dart';
import '../login_screen.dart';
import '../chat_screen.dart';
import 'inbox_screen.dart';
import 'edit_profile_screen.dart';
import 'vehicle_history_screen.dart';
import 'my_profile_detail_screen.dart';
import 'shop_detail_screen.dart';
import '../../widgets/ad_banner_widget.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> with WidgetsBindingObserver {
  static const bool _showPremiumButton = false; // Toggle to true after publishing to reactivate Premium button
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String? _customTabSelection;

  late final Stream<QuerySnapshot> _shopsStream;
  late final Stream<QuerySnapshot> _driversStream;
  late final Stream<QuerySnapshot> _serviceCentersStream;

  String _selectedAddTab = 'Vehicle';

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

  // Shop properties
  final _shopFormKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _shopPhoneController = TextEditingController();
  final _shopOwnerController = TextEditingController();
  final _shopAddressController = TextEditingController();
  String? _pickedShopPhotoPath;

  // Driver properties
  final _driverFormKey = GlobalKey<FormState>();
  final _driverNameController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  final _driverAddressController = TextEditingController();
  String? _pickedLicensePhotoPath;

  // Service Center properties
  final _serviceCenterFormKey = GlobalKey<FormState>();
  final _serviceCenterNameController = TextEditingController();
  final _serviceCenterPhoneController = TextEditingController();
  final _serviceCenterAddressController = TextEditingController();

  // Ads properties
  final _adFormKey = GlobalKey<FormState>();
  final _adTitleController = TextEditingController();
  final _adDescController = TextEditingController();
  final _adPhoneController = TextEditingController();
  final _adAddressController = TextEditingController();
  String? _pickedAdPhotoPath;

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

  Future<void> _pickLicenseImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _pickedLicensePhotoPath = image.path;
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

  Future<void> _pickShopImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _pickedShopPhotoPath = image.path;
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

  Future<void> _pickAdImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _pickedAdPhotoPath = image.path;
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
    // Initialize streams to prevent flicker and stream resets on rebuild
    _shopsStream = FirebaseFirestore.instance.collection('shops').orderBy('timestamp', descending: true).snapshots();
    _driversStream = FirebaseFirestore.instance.collection('drivers').orderBy('timestamp', descending: true).snapshots();
    _serviceCentersStream = FirebaseFirestore.instance.collection('service_centers').orderBy('timestamp', descending: true).snapshots();

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

    _shopNameController.dispose();
    _shopPhoneController.dispose();
    _shopOwnerController.dispose();
    _shopAddressController.dispose();

    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _driverAddressController.dispose();

    _serviceCenterNameController.dispose();
    _serviceCenterPhoneController.dispose();
    _serviceCenterAddressController.dispose();

    _adTitleController.dispose();
    _adDescController.dispose();
    _adPhoneController.dispose();
    _adAddressController.dispose();
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
        appBar: _currentIndex == 1
            ? null
            : AppBar(
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
                        'My Profile',
                        style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold),
                      ),
                actions: _currentIndex == 0
                    ? [
                        if (_showPremiumButton) ...[
                          const Center(
                            child: PremiumButton(),
                          ),
                          const SizedBox(width: 8),
                        ],
                        _buildChatAction(context, appState),
                        const SizedBox(width: 8),
                      ]
                    : _currentIndex == 2
                        ? [
                            if (_showPremiumButton) ...[
                              const Center(
                                child: PremiumButton(),
                              ),
                              const SizedBox(width: 16),
                            ]
                          ]
                        : null,
              ),
        body: _currentIndex == 0
            ? _buildBrowseTab(appState)
            : _currentIndex == 1
                ? _buildAddRequestTab(appState)
                : _buildProfileTab(appState),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AdBannerWidget(),
            BottomNavigationBar(
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
              hintText: 'Search vehicle, owner, location...',
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

          if (_customTabSelection == null) ...[
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
          ],

          // Content List
          if (_customTabSelection == 'Shop')
            _buildShopsList(appState)
          else if (_customTabSelection == 'Driver')
            _buildDriversList(appState)
          else if (_customTabSelection == 'Service Center')
            _buildServiceCentersList(appState)
          else if (!appState.isLocationOn)
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
    if (appState.selectedCategoryFilter != null) {
      _customTabSelection = null;
    }

    final isAllSelected = appState.selectedCategoryFilter == null && _customTabSelection == null;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: 'All Vehicles',
            isSelected: isAllSelected,
            onTap: () {
              setState(() {
                _customTabSelection = null;
              });
              appState.setCategoryFilter(null);
            },
          ),
          ...VehicleType.values.map((type) {
            final isSelected = appState.selectedCategoryFilter == type && _customTabSelection == null;
            return _buildFilterChip(
              label: type.displayName,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _customTabSelection = null;
                });
                appState.setCategoryFilter(type);
              },
            );
          }),
          _buildFilterChip(
            label: 'Shop',
            isSelected: _customTabSelection == 'Shop',
            onTap: () {
              setState(() {
                _customTabSelection = 'Shop';
              });
              appState.setCategoryFilter(null);
            },
          ),
          _buildFilterChip(
            label: 'Driver',
            isSelected: _customTabSelection == 'Driver',
            onTap: () {
              setState(() {
                _customTabSelection = 'Driver';
              });
              appState.setCategoryFilter(null);
            },
          ),
          _buildFilterChip(
            label: 'Service Center',
            isSelected: _customTabSelection == 'Service Center',
            onTap: () {
              setState(() {
                _customTabSelection = 'Service Center';
              });
              appState.setCategoryFilter(null);
            },
          ),
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

  Widget _buildAddTabSelector() {
    final tabs = ['Vehicle', 'Shop', 'Driver', 'Service Center', 'Ads'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _selectedAddTab == tab;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedAddTab = tab;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8, bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF536DFE) : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (context.isDarkMode ? const Color(0xFF2E3B4E) : const Color(0xFFE2E8F0)),
                  width: 1.0,
                ),
              ),
              child: Text(
                tab,
                style: TextStyle(
                  color: isSelected ? Colors.white : context.textColor70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String labelText, IconData prefixIcon) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: context.textColor30),
      prefixIcon: Icon(prefixIcon, color: context.textColor30, size: 18),
      filled: true,
      fillColor: Theme.of(context).cardColor,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: context.isDarkMode ? const Color(0x1AFFFFFF) : const Color(0x15000000),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF536DFE)),
      ),
    );
  }

  InputDecoration _buildInputDecorationWithLocation(
    String labelText,
    IconData prefixIcon,
    VoidCallback onLocationPressed,
  ) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: context.textColor30),
      prefixIcon: Icon(prefixIcon, color: context.textColor30, size: 18),
      suffixIcon: IconButton(
        icon: const Icon(Icons.my_location_rounded, color: Color(0xFF536DFE), size: 20),
        tooltip: 'Use Current Location',
        onPressed: onLocationPressed,
      ),
      filled: true,
      fillColor: Theme.of(context).cardColor,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: context.isDarkMode ? const Color(0x1AFFFFFF) : const Color(0x15000000),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF536DFE)),
      ),
    );
  }

  Widget _buildShopForm(AppState appState) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Form(
        key: _shopFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add your shop details and upload vehicle/shop photo to buy & sell old vehicles.',
              style: TextStyle(
                color: context.textColor54,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _shopNameController,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(color: context.textColor, fontSize: 14),
              decoration: _buildInputDecoration('Shop Name / Vehicle For Sale', Icons.storefront_rounded),
              validator: (value) => value == null || value.trim().isEmpty ? 'Enter shop/vehicle name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _shopOwnerController,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(color: context.textColor, fontSize: 14),
              decoration: _buildInputDecoration('Owner Name', Icons.person_outline_rounded),
              validator: (value) => value == null || value.trim().isEmpty ? 'Enter owner name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _shopPhoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: context.textColor, fontSize: 14),
              decoration: _buildInputDecoration('Phone Number', Icons.phone_rounded),
              validator: (value) => value == null || value.trim().isEmpty ? 'Enter phone number' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _shopAddressController,
              maxLines: 1,
              style: TextStyle(color: context.textColor, fontSize: 14),
              textCapitalization: TextCapitalization.words,
              decoration: _buildInputDecorationWithLocation('Address', Icons.location_on_rounded, () async {
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
                _shopAddressController.text = appState.currentAddress;
              }),
              validator: (value) => value == null || value.trim().isEmpty ? 'Enter address' : null,
            ),
            const SizedBox(height: 16),
            Text(
              'VEHICLE / SHOP PHOTO',
              style: TextStyle(
                color: context.textColor30,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickShopImage,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: context.isDarkMode ? const Color(0x1AFFFFFF) : const Color(0x15000000),
                    width: 1.5,
                  ),
                ),
                child: _pickedShopPhotoPath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_pickedShopPhotoPath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF536DFE), size: 28),
                          const SizedBox(height: 8),
                          Text(
                            'Upload vehicle or shop photo',
                            style: TextStyle(color: context.textColor54, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (!_shopFormKey.currentState!.validate()) return;
                final messenger = ScaffoldMessenger.of(context);

                if (_pickedShopPhotoPath == null) {
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Please select vehicle or shop photo.'),
                      backgroundColor: Colors.orangeAccent,
                    ),
                  );
                  return;
                }

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
                        Text('Adding Shop...'),
                      ],
                    ),
                    duration: Duration(days: 1),
                  ),
                );

                try {
                  final finalPhotoUrl = await appState.uploadToCloudinary(_pickedShopPhotoPath!);
                  if (finalPhotoUrl == null) {
                    messenger.clearSnackBars();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Failed to upload photo. Please try again.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  final docId = 'shop_${DateTime.now().millisecondsSinceEpoch}';
                  await FirebaseFirestore.instance.collection('shops').doc(docId).set({
                    'id': docId,
                    'shopName': _shopNameController.text.trim(),
                    'ownerName': _shopOwnerController.text.trim(),
                    'phoneNumber': _shopPhoneController.text.trim(),
                    'address': _shopAddressController.text.trim(),
                    'photoUrl': finalPhotoUrl,
                    'latitude': appState.customerLatitude + (Random().nextDouble() - 0.5) * 0.02,
                    'longitude': appState.customerLongitude + (Random().nextDouble() - 0.5) * 0.02,
                    'ownerGmail': appState.currentGmail ?? 'guest.customer@gmail.com',
                    'timestamp': DateTime.now().millisecondsSinceEpoch,
                  });

                  messenger.clearSnackBars();
                  setState(() {
                    _shopNameController.clear();
                    _shopOwnerController.clear();
                    _shopPhoneController.clear();
                    _shopAddressController.clear();
                    _pickedShopPhotoPath = null;
                  });

                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Shop Registered Successfully!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                } catch (e) {
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to add shop: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF536DFE),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Add Shop', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverForm(AppState appState) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Form(
        key: _driverFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add your driver details and upload license to list on our platform.',
              style: TextStyle(
                color: context.textColor54,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _driverNameController,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(color: context.textColor, fontSize: 14),
              decoration: _buildInputDecoration('Driver Name', Icons.person_outline_rounded),
              validator: (value) => value == null || value.trim().isEmpty ? 'Enter driver name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _driverPhoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: context.textColor, fontSize: 14),
              decoration: _buildInputDecoration('Phone Number', Icons.phone_rounded),
              validator: (value) => value == null || value.trim().isEmpty ? 'Enter phone number' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _driverAddressController,
              maxLines: 1,
              style: TextStyle(color: context.textColor, fontSize: 14),
              textCapitalization: TextCapitalization.words,
              decoration: _buildInputDecorationWithLocation('Address', Icons.location_on_rounded, () async {
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
                _driverAddressController.text = appState.currentAddress;
              }),
              validator: (value) => value == null || value.trim().isEmpty ? 'Enter address' : null,
            ),
            const SizedBox(height: 16),
            Text(
              'DRIVING LICENSE PHOTO',
              style: TextStyle(
                color: context.textColor30,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickLicenseImage,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: context.isDarkMode ? const Color(0x1AFFFFFF) : const Color(0x15000000),
                    width: 1.5,
                  ),
                ),
                child: _pickedLicensePhotoPath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_pickedLicensePhotoPath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF536DFE), size: 28),
                          const SizedBox(height: 8),
                          Text(
                            'Upload driving license photo',
                            style: TextStyle(color: context.textColor54, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (!_driverFormKey.currentState!.validate()) return;
                final messenger = ScaffoldMessenger.of(context);
                
                if (_pickedLicensePhotoPath == null) {
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Please select driving license photo.'),
                      backgroundColor: Colors.orangeAccent,
                    ),
                  );
                  return;
                }

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
                        Text('Adding Driver...'),
                      ],
                    ),
                    duration: Duration(days: 1),
                  ),
                );

                try {
                  final finalPhotoUrl = await appState.uploadToCloudinary(_pickedLicensePhotoPath!);
                  if (finalPhotoUrl == null) {
                    messenger.clearSnackBars();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Failed to upload license photo. Please try again.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  final docId = 'driver_${DateTime.now().millisecondsSinceEpoch}';
                  await FirebaseFirestore.instance.collection('drivers').doc(docId).set({
                    'id': docId,
                    'driverName': _driverNameController.text.trim(),
                    'phoneNumber': _driverPhoneController.text.trim(),
                    'address': _driverAddressController.text.trim(),
                    'licensePhotoUrl': finalPhotoUrl,
                    'latitude': appState.customerLatitude + (Random().nextDouble() - 0.5) * 0.02,
                    'longitude': appState.customerLongitude + (Random().nextDouble() - 0.5) * 0.02,
                    'driverGmail': appState.currentGmail ?? 'guest.customer@gmail.com',
                    'timestamp': DateTime.now().millisecondsSinceEpoch,
                  });

                  messenger.clearSnackBars();
                  setState(() {
                    _driverNameController.clear();
                    _driverPhoneController.clear();
                    _driverAddressController.clear();
                    _pickedLicensePhotoPath = null;
                  });

                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Driver Registered Successfully!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                } catch (e) {
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to add driver: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF536DFE),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Add Driver', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCenterForm(AppState appState) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Form(
        key: _serviceCenterFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add service center details to list on our platform.',
              style: TextStyle(
                color: context.textColor54,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _serviceCenterNameController,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(color: context.textColor, fontSize: 14),
              decoration: _buildInputDecoration('Service Center Name', Icons.build_rounded),
              validator: (value) => value == null || value.trim().isEmpty ? 'Enter service center name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _serviceCenterPhoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: context.textColor, fontSize: 14),
              decoration: _buildInputDecoration('Phone Number', Icons.phone_rounded),
              validator: (value) => value == null || value.trim().isEmpty ? 'Enter phone number' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _serviceCenterAddressController,
              maxLines: 1,
              style: TextStyle(color: context.textColor, fontSize: 14),
              textCapitalization: TextCapitalization.words,
              decoration: _buildInputDecorationWithLocation('Address', Icons.location_on_rounded, () async {
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
                _serviceCenterAddressController.text = appState.currentAddress;
              }),
              validator: (value) => value == null || value.trim().isEmpty ? 'Enter address' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (!_serviceCenterFormKey.currentState!.validate()) return;
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
                        Text('Adding Service Center...'),
                      ],
                    ),
                    duration: Duration(days: 1),
                  ),
                );

                try {
                  final docId = 'service_center_${DateTime.now().millisecondsSinceEpoch}';
                  await FirebaseFirestore.instance.collection('service_centers').doc(docId).set({
                    'id': docId,
                    'serviceCenterName': _serviceCenterNameController.text.trim(),
                    'phoneNumber': _serviceCenterPhoneController.text.trim(),
                    'address': _serviceCenterAddressController.text.trim(),
                    'latitude': appState.customerLatitude + (Random().nextDouble() - 0.5) * 0.02,
                    'longitude': appState.customerLongitude + (Random().nextDouble() - 0.5) * 0.02,
                    'ownerGmail': appState.currentGmail ?? 'guest.customer@gmail.com',
                    'timestamp': DateTime.now().millisecondsSinceEpoch,
                  });

                  messenger.clearSnackBars();
                  setState(() {
                    _serviceCenterNameController.clear();
                    _serviceCenterPhoneController.clear();
                    _serviceCenterAddressController.clear();
                  });

                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Service Center Registered Successfully!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                } catch (e) {
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to add service center: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF536DFE),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Add Service Center', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdsForm(AppState appState) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Form(
        key: _adFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add your advertisement banner and details to list on our platform.',
              style: TextStyle(
                color: context.textColor54,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _adTitleController,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: context.textColor, fontSize: 14),
              decoration: _buildInputDecoration('Ad Title', Icons.featured_play_list_rounded),
              validator: (value) => value == null || value.trim().isEmpty ? 'Enter ad title' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _adDescController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              style: TextStyle(color: context.textColor, fontSize: 14),
              decoration: _buildInputDecoration('Ad Description', Icons.description_rounded),
              validator: (value) => value == null || value.trim().isEmpty ? 'Enter ad description' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _adPhoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: context.textColor, fontSize: 14),
              decoration: _buildInputDecoration('Contact Phone Number', Icons.phone_rounded),
              validator: (value) => value == null || value.trim().isEmpty ? 'Enter phone number' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _adAddressController,
              maxLines: 1,
              style: TextStyle(color: context.textColor, fontSize: 14),
              textCapitalization: TextCapitalization.words,
              decoration: _buildInputDecorationWithLocation('Address', Icons.location_on_rounded, () async {
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
                _adAddressController.text = appState.currentAddress;
              }),
              validator: (value) => value == null || value.trim().isEmpty ? 'Enter address' : null,
            ),
            const SizedBox(height: 16),
            Text(
              'AD BANNER PHOTO',
              style: TextStyle(
                color: context.textColor30,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickAdImage,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: context.isDarkMode ? const Color(0x1AFFFFFF) : const Color(0x15000000),
                    width: 1.5,
                  ),
                ),
                child: _pickedAdPhotoPath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_pickedAdPhotoPath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF536DFE), size: 28),
                          const SizedBox(height: 8),
                          Text(
                            'Upload ad banner photo',
                            style: TextStyle(color: context.textColor54, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (!_adFormKey.currentState!.validate()) return;
                final messenger = ScaffoldMessenger.of(context);

                if (_pickedAdPhotoPath == null) {
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Please select ad banner photo.'),
                      backgroundColor: Colors.orangeAccent,
                    ),
                  );
                  return;
                }

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
                        Text('Adding Ad Banner...'),
                      ],
                    ),
                    duration: Duration(days: 1),
                  ),
                );

                try {
                  final finalAdPhotoUrl = await appState.uploadToCloudinary(_pickedAdPhotoPath!);
                  if (finalAdPhotoUrl == null) {
                    messenger.clearSnackBars();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Failed to upload ad photo. Please try again.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  final docId = 'ad_${DateTime.now().millisecondsSinceEpoch}';
                  await FirebaseFirestore.instance.collection('ads').doc(docId).set({
                    'id': docId,
                    'title': _adTitleController.text.trim(),
                    'description': _adDescController.text.trim(),
                    'phoneNumber': _adPhoneController.text.trim(),
                    'address': _adAddressController.text.trim(),
                    'adPhotoUrl': finalAdPhotoUrl,
                    'latitude': appState.customerLatitude + (Random().nextDouble() - 0.5) * 0.02,
                    'longitude': appState.customerLongitude + (Random().nextDouble() - 0.5) * 0.02,
                    'ownerGmail': appState.currentGmail ?? 'guest.customer@gmail.com',
                    'timestamp': DateTime.now().millisecondsSinceEpoch,
                  });

                  messenger.clearSnackBars();
                  setState(() {
                    _adTitleController.clear();
                    _adDescController.clear();
                    _adPhoneController.clear();
                    _adAddressController.clear();
                    _pickedAdPhotoPath = null;
                  });

                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Ad Registered Successfully!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                } catch (e) {
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to add ad: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF536DFE),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Add Ad Banner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddRequestTab(AppState appState) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAddTabSelector(),
          const SizedBox(height: 8),
          if (_selectedAddTab == 'Vehicle') ...[
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
          ] else if (_selectedAddTab == 'Shop')
            _buildShopForm(appState)
          else if (_selectedAddTab == 'Driver')
            _buildDriverForm(appState)
          else if (_selectedAddTab == 'Service Center')
            _buildServiceCenterForm(appState)
          else if (_selectedAddTab == 'Ads')
            _buildAdsForm(appState),
        ],
      ),
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
                  icon: Icons.account_circle_outlined,
                  title: 'My Profile',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MyProfileDetailScreen()),
                    );
                  },
                ),
                _buildDivider(context),
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
          ],
        ),
      ),
    );
  }

  Widget _buildShopsList(AppState appState) {
    return StreamBuilder<QuerySnapshot>(
      stream: _shopsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF536DFE)));
        }
        final docs = snapshot.data!.docs;
        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (appState.searchQuery.isNotEmpty) {
            final query = appState.searchQuery.toLowerCase();
            final nameMatch = (data['shopName'] as String? ?? '').toLowerCase().contains(query);
            final ownerMatch = (data['ownerName'] as String? ?? '').toLowerCase().contains(query);
            final addressMatch = (data['address'] as String? ?? '').toLowerCase().contains(query);
            if (!nameMatch && !ownerMatch && !addressMatch) return false;
          }
          return true;
        }).toList();

        if (filteredDocs.isEmpty) {
          return _buildCustomEmptyState('No Shops Registered', 'There are no registered shops selling/buying vehicles yet.');
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final data = filteredDocs[index].data() as Map<String, dynamic>;
            return _buildShopCard(context, appState, data);
          },
        );
      },
    );
  }

  Widget _buildShopCard(BuildContext context, AppState appState, Map<String, dynamic> data) {
    final photoUrl = data['photoUrl'] as String?;
    final shopName = data['shopName'] as String? ?? 'Shop Name';
    final ownerName = data['ownerName'] as String? ?? 'Owner Name';
    final ownerGmail = data['ownerGmail'] as String? ?? '';

    final initial = ownerName.isNotEmpty ? ownerName[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShopDetailScreen(data: data),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.isDarkMode ? const Color(0x0AFFFFFF) : const Color(0x08000000),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Flipkart-style Product Image
              Expanded(
                child: Container(
                  color: context.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      photoUrl != null && photoUrl.isNotEmpty
                          ? Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.storefront_rounded,
                                size: 36,
                                color: Color(0xFF536DFE),
                              ),
                            )
                          : const Icon(
                              Icons.storefront_rounded,
                              size: 36,
                              color: Color(0xFF536DFE),
                            ),
                    ],
                  ),
                ),
              ),
              // Below image info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Shop/Vehicle Name
                    Text(
                      shopName,
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Poster's Profile Image + Name ONLY
                    Row(
                      children: [
                        // Poster's Profile Image
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .where('email', isEqualTo: ownerGmail)
                              .limit(1)
                              .snapshots(),
                          builder: (context, snapshot) {
                            String? userPhoto;
                            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                              userPhoto = snapshot.data!.docs.first.data()['photoUrl'] as String?;
                            }
                            final hasPhoto = userPhoto != null && userPhoto.isNotEmpty;
                            return CircleAvatar(
                              radius: 10,
                              backgroundColor: const Color(0xFF536DFE).withValues(alpha: 0.1),
                              backgroundImage: hasPhoto ? NetworkImage(userPhoto) : null,
                              child: hasPhoto
                                  ? null
                                  : Text(
                                      initial,
                                      style: const TextStyle(
                                        color: Color(0xFF536DFE),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 8,
                                      ),
                                    ),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        // Poster's Name
                        Expanded(
                          child: Text(
                            ownerName,
                            style: TextStyle(
                              color: context.textColor70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriversList(AppState appState) {
    return StreamBuilder<QuerySnapshot>(
      stream: _driversStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF536DFE)));
        }
        final docs = snapshot.data!.docs;
        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (appState.searchQuery.isNotEmpty) {
            final query = appState.searchQuery.toLowerCase();
            final nameMatch = (data['driverName'] as String? ?? '').toLowerCase().contains(query);
            final addressMatch = (data['address'] as String? ?? '').toLowerCase().contains(query);
            if (!nameMatch && !addressMatch) return false;
          }
          return true;
        }).toList();

        if (filteredDocs.isEmpty) {
          return _buildCustomEmptyState('No Drivers Registered', 'There are no registered drivers yet.');
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final data = filteredDocs[index].data() as Map<String, dynamic>;
            return _buildDriverCard(context, appState, data);
          },
        );
      },
    );
  }

  Widget _buildDriverCard(BuildContext context, AppState appState, Map<String, dynamic> data) {
    final photoUrl = data['licensePhotoUrl'] as String?;
    final driverName = data['driverName'] as String? ?? 'Driver Name';
    final address = data['address'] as String? ?? 'Address';
    final phone = data['phoneNumber'] as String? ?? '';
    final driverGmail = data['driverGmail'] as String? ?? '';
    final lat = data['latitude'] as double? ?? 0.0;
    final lon = data['longitude'] as double? ?? 0.0;
    final distance = appState.getDistanceFromUser(lat, lon);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.isDarkMode ? const Color(0x0AFFFFFF) : const Color(0x08000000),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 120,
                color: context.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                child: photoUrl != null && photoUrl.isNotEmpty
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.badge_rounded, size: 40, color: Color(0xFF536DFE)),
                      )
                    : const Icon(Icons.badge_rounded, size: 40, color: Color(0xFF536DFE)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              driverName,
                              style: TextStyle(
                                color: context.textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: () => _openMap(lat, lon, address),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF536DFE).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${distance.toStringAsFixed(1)} Km',
                                style: const TextStyle(
                                  color: Color(0xFF536DFE),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () => _openMap(lat, lon, address),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 12),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                address,
                                style: TextStyle(
                                  color: context.textColor54,
                                  fontSize: 11,
                                  decoration: TextDecoration.underline,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (phone.isNotEmpty)
                            IconButton(
                              onPressed: () async {
                                final Uri launchUri = Uri(
                                  scheme: 'tel',
                                  path: phone,
                                );
                                await launchUrl(launchUri);
                              },
                              icon: const Icon(Icons.phone_rounded, color: Color(0xFF10B981), size: 18),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                          const SizedBox(width: 8),
                          if (driverGmail != appState.currentGmail)
                            ElevatedButton.icon(
                              onPressed: () {
                                final dummyVehicle = Vehicle(
                                  id: data['id'] as String? ?? 'driver',
                                  ownerName: driverName,
                                  ownerGmail: driverGmail,
                                  type: VehicleType.car,
                                  model: 'Driver Profile',
                                  insidePhotoUrl: '',
                                  outsidePhotoUrl: '',
                                  ratePerKm: 0.0,
                                  isServiceOn: true,
                                  latitude: lat,
                                  longitude: lon,
                                  phoneNumber: phone,
                                  address: address,
                                );
                                final thread = appState.getOrCreateThread(dummyVehicle);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(threadId: thread.threadId),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                              label: const Text('Chat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF536DFE),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
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
    );
  }

  Widget _buildServiceCentersList(AppState appState) {
    return StreamBuilder<QuerySnapshot>(
      stream: _serviceCentersStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF536DFE)));
        }
        final docs = snapshot.data!.docs;
        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (appState.searchQuery.isNotEmpty) {
            final query = appState.searchQuery.toLowerCase();
            final nameMatch = (data['serviceCenterName'] as String? ?? '').toLowerCase().contains(query);
            final addressMatch = (data['address'] as String? ?? '').toLowerCase().contains(query);
            if (!nameMatch && !addressMatch) return false;
          }
          return true;
        }).toList();

        if (filteredDocs.isEmpty) {
          return _buildCustomEmptyState('No Service Stations', 'There are no registered service centers yet.');
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final data = filteredDocs[index].data() as Map<String, dynamic>;
            return _buildServiceCenterCard(context, appState, data);
          },
        );
      },
    );
  }

  Widget _buildServiceCenterCard(BuildContext context, AppState appState, Map<String, dynamic> data) {
    final serviceCenterName = data['serviceCenterName'] as String? ?? 'Service Center Name';
    final address = data['address'] as String? ?? 'Address';
    final phone = data['phoneNumber'] as String? ?? '';
    final ownerGmail = data['ownerGmail'] as String? ?? '';
    final lat = data['latitude'] as double? ?? 0.0;
    final lon = data['longitude'] as double? ?? 0.0;
    final distance = appState.getDistanceFromUser(lat, lon);
    final initial = serviceCenterName.isNotEmpty ? serviceCenterName[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.isDarkMode ? const Color(0x0AFFFFFF) : const Color(0x08000000),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 100,
                color: context.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                alignment: Alignment.center,
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('email', isEqualTo: ownerGmail)
                      .limit(1)
                      .snapshots(),
                  builder: (context, snapshot) {
                    String? userPhoto;
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      userPhoto = snapshot.data!.docs.first.data()['photoUrl'] as String?;
                    }
                    final hasPhoto = userPhoto != null && userPhoto.isNotEmpty;
                    return CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFF536DFE).withValues(alpha: 0.1),
                      backgroundImage: hasPhoto ? NetworkImage(userPhoto) : null,
                      child: hasPhoto
                          ? null
                          : Text(
                              initial,
                              style: const TextStyle(
                                color: Color(0xFF536DFE),
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                    );
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              serviceCenterName,
                              style: TextStyle(
                                color: context.textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: () => _openMap(lat, lon, address),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF536DFE).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${distance.toStringAsFixed(1)} Km',
                                style: const TextStyle(
                                  color: Color(0xFF536DFE),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _openMap(lat, lon, address),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 12),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                address,
                                style: TextStyle(
                                  color: context.textColor54,
                                  fontSize: 11,
                                  decoration: TextDecoration.underline,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (phone.isNotEmpty)
                            IconButton(
                              onPressed: () async {
                                final Uri launchUri = Uri(
                                  scheme: 'tel',
                                  path: phone,
                                );
                                await launchUrl(launchUri);
                              },
                              icon: const Icon(Icons.phone_rounded, color: Color(0xFF10B981), size: 18),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                          const SizedBox(width: 8),
                          if (ownerGmail != appState.currentGmail)
                            ElevatedButton.icon(
                              onPressed: () {
                                final dummyVehicle = Vehicle(
                                  id: data['id'] as String? ?? 'service_center',
                                  ownerName: serviceCenterName,
                                  ownerGmail: ownerGmail,
                                  type: VehicleType.car,
                                  model: 'Service Center Profile',
                                  insidePhotoUrl: '',
                                  outsidePhotoUrl: '',
                                  ratePerKm: 0.0,
                                  isServiceOn: true,
                                  latitude: lat,
                                  longitude: lon,
                                  phoneNumber: phone,
                                  address: address,
                                );
                                final thread = appState.getOrCreateThread(dummyVehicle);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(threadId: thread.threadId),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                              label: const Text('Chat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF536DFE),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
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
    );
  }

  Widget _buildCustomEmptyState(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, color: context.textColor30, size: 48),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textColor54, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Future<void> _openMap(double latitude, double longitude, String address) async {
    Uri uri;
    if (latitude != 0.0 || longitude != 0.0) {
      uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$latitude,$longitude");
    } else {
      uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}");
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open maps: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
