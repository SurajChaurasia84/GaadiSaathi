import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/vehicle.dart';
import '../../widgets/vehicle_card.dart';
import '../../widgets/theme_selector.dart';
import '../login_screen.dart';
import 'inbox_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  // Active registered vehicles list (for current session/user)
  final List<Vehicle> _addedVehicles = [];

  // Form keys and controllers for custom vehicle addition
  final _addFormKey = GlobalKey<FormState>();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _modelNameController = TextEditingController();
  final _rateController = TextEditingController();
  VehicleType _selectedVehicleType = VehicleType.car;
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    // Simulate automatic GPS location activation on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).triggerLocationOn();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _modelNameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  String _getDefaultOutsidePhoto(VehicleType type) {
    switch (type) {
      case VehicleType.car:
        return 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?q=80&w=600&auto=format&fit=crop';
      case VehicleType.eRickshaw:
        return 'https://images.unsplash.com/photo-1626125345510-4603468eedfb?q=80&w=600&auto=format&fit=crop';
      case VehicleType.loading:
        return 'https://images.unsplash.com/photo-1516576885230-101c05528b3f?q=80&w=600&auto=format&fit=crop';
    }
  }

  String _getDefaultInsidePhoto(VehicleType type) {
    switch (type) {
      case VehicleType.car:
        return 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?q=80&w=600&auto=format&fit=crop';
      case VehicleType.eRickshaw:
        return 'https://images.unsplash.com/photo-1517524206127-48bbd363f3d7?q=80&w=600&auto=format&fit=crop';
      case VehicleType.loading:
        return 'https://images.unsplash.com/photo-1486006920555-c77dce18193b?q=80&w=600&auto=format&fit=crop';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _currentIndex == 0
              ? 'GaadiSaathi'
              : _currentIndex == 1
                  ? 'Add Vehicle'
                  : 'My Profile',
          style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold),
        ),
        actions: _currentIndex == 0
            ? [
                _buildNotificationAction(context),
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
                    maxLines: 2,
                    style: TextStyle(color: context.textColor, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Address',
                      labelStyle: TextStyle(color: context.textColor30),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Icon(Icons.location_on_rounded, color: context.textColor30, size: 18),
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
                          activeColor: const Color(0xFF10B981),
                          activeTrackColor: const Color(0xFF10B981).withOpacity(0.3),
                          onChanged: (value) {
                            setState(() {
                              _isAvailable = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    onPressed: () {
                      if (!_addFormKey.currentState!.validate()) return;
                      final appState = Provider.of<AppState>(context, listen: false);

                      // Create and add new vehicle
                      final newVehicle = Vehicle(
                        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                        ownerName: _ownerNameController.text.trim(),
                        ownerGmail: appState.currentGmail ?? 'guest.customer@gmail.com',
                        type: _selectedVehicleType,
                        model: _modelNameController.text.trim(),
                        insidePhotoUrl: _getDefaultInsidePhoto(_selectedVehicleType),
                        outsidePhotoUrl: _getDefaultOutsidePhoto(_selectedVehicleType),
                        ratePerKm: double.tryParse(_rateController.text.trim()) ?? 0.0,
                        isServiceOn: _isAvailable,
                        latitude: appState.customerLatitude + (Random().nextDouble() - 0.5) * 0.02,
                        longitude: appState.customerLongitude + (Random().nextDouble() - 0.5) * 0.02,
                        phoneNumber: _phoneController.text.trim(),
                        address: _addressController.text.trim(),
                      );

                      appState.addCustomVehicle(newVehicle);

                      setState(() {
                        _addedVehicles.insert(0, newVehicle);
                        _ownerNameController.clear();
                        _phoneController.clear();
                        _addressController.clear();
                        _modelNameController.clear();
                        _rateController.clear();
                        _isAvailable = true;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
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
          Text(
            'MY REGISTERED VEHICLES',
            style: TextStyle(
              color: context.textColor30,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          if (_addedVehicles.isEmpty)
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
                      style: TextStyle(color: context.textColor30.withOpacity(0.8), fontSize: 11),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _addedVehicles.length,
              itemBuilder: (context, idx) {
                final vehicle = _addedVehicles[idx];
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.isDarkMode ? const Color(0x0AFFFFFF) : const Color(0x08000000)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFF536DFE),
                  child: Text(
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
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF536DFE).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'CUSTOMER MODE (GUEST)',
                    style: TextStyle(
                      color: Color(0xFF536DFE),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.isDarkMode ? const Color(0x0AFFFFFF) : const Color(0x08000000)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Rentals Completed', '12'),
                _buildStatItem('Total Spent', '₹840'),
                _buildStatItem('My Vehicles', '${_addedVehicles.length}'),
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
                ListTile(
                  leading: const Icon(Icons.palette_rounded, color: Color(0xFF536DFE)),
                  title: Text('Theme Settings', style: TextStyle(color: context.textColor, fontSize: 14)),
                  subtitle: Text('Change application theme layout', style: TextStyle(color: context.textColor54, fontSize: 12)),
                  trailing: buildThemeSelector(context, appState),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  title: Text('Log Out', style: TextStyle(color: context.textColor, fontSize: 14)),
                  subtitle: Text('Log out of this guest session', style: TextStyle(color: context.textColor54, fontSize: 12)),
                  onTap: () {
                    appState.logout();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: Color(0xFF536DFE), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: context.textColor54, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildNotificationAction(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.notifications_rounded, color: context.textColor),
          onPressed: () => _showNotificationsBottomSheet(context),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Text(
              '2',
              style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatAction(BuildContext context, AppState appState) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.chat_bubble_rounded, color: context.textColor),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const InboxScreen()),
            );
          },
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Text(
              '1',
              style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  void _showNotificationsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: context.textColor54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildNotificationItem(
                context,
                title: 'Booking Confirmed!',
                body: 'Amit Sharma confirmed your booking request for White Swift.',
                time: '10 mins ago',
                icon: Icons.check_circle_rounded,
                iconColor: const Color(0xFF10B981),
              ),
              const SizedBox(height: 12),
              _buildNotificationItem(
                context,
                title: 'New Service Active',
                body: 'Sanjay Singh logged a Tata Ace Gold near Delhi.',
                time: '2 hours ago',
                icon: Icons.local_shipping_rounded,
                iconColor: const Color(0xFF536DFE),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(BuildContext context, {
    required String title,
    required String body,
    required String time,
    required IconData icon,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(body, style: TextStyle(color: context.textColor54, fontSize: 12, height: 1.3)),
              const SizedBox(height: 4),
              Text(time, style: TextStyle(color: context.textColor30, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

}
