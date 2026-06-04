import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vehicle.dart';
import '../../providers/app_state.dart';
import 'owner_dashboard_screen.dart';

class OwnerRegisterScreen extends StatefulWidget {
  const OwnerRegisterScreen({super.key});

  @override
  State<OwnerRegisterScreen> createState() => _OwnerRegisterScreenState();
}

class _OwnerRegisterScreenState extends State<OwnerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _modelController = TextEditingController();
  final _rateController = TextEditingController();
  VehicleType _selectedType = VehicleType.car;

  // Preset images so the demo application looks extremely clean
  final Map<VehicleType, List<Map<String, String>>> _presetPhotos = {
    VehicleType.car: [
      {
        'label': 'Swift Hatchback',
        'outside': 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?q=80&w=600&auto=format&fit=crop',
        'inside': 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?q=80&w=600&auto=format&fit=crop',
      },
      {
        'label': 'Luxury Sedan',
        'outside': 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?q=80&w=600&auto=format&fit=crop',
        'inside': 'https://images.unsplash.com/photo-1563720223185-11003d516935?q=80&w=600&auto=format&fit=crop',
      }
    ],
    VehicleType.eRickshaw: [
      {
        'label': 'Eco Green Rickshaw',
        'outside': 'https://images.unsplash.com/photo-1626125345510-4603468eedfb?q=80&w=600&auto=format&fit=crop',
        'inside': 'https://images.unsplash.com/photo-1517524206127-48bbd363f3d7?q=80&w=600&auto=format&fit=crop',
      }
    ],
    VehicleType.loading: [
      {
        'label': 'Heavy Duty Truck',
        'outside': 'https://images.unsplash.com/photo-1516576885230-101c05528b3f?q=80&w=600&auto=format&fit=crop',
        'inside': 'https://images.unsplash.com/photo-1486006920555-c77dce18193b?q=80&w=600&auto=format&fit=crop',
      },
      {
        'label': 'Mini Cargo Van',
        'outside': 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?q=80&w=600&auto=format&fit=crop',
        'inside': 'https://images.unsplash.com/photo-1580273916550-e323be2ae537?q=80&w=600&auto=format&fit=crop',
      }
    ]
  };

  int _selectedPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    // Default model suggestions based on type
    _updateDefaultModel();
  }

  void _updateDefaultModel() {
    if (_selectedType == VehicleType.car) {
      _modelController.text = 'Maruti Swift LXi';
      _rateController.text = '14.0';
    } else if (_selectedType == VehicleType.eRickshaw) {
      _modelController.text = 'Lohia Comfort E-Rickshaw';
      _rateController.text = '8.0';
    } else {
      _modelController.text = 'Tata Ace Gold Cargo';
      _rateController.text = '22.0';
    }
    _selectedPhotoIndex = 0;
  }

  @override
  void dispose() {
    _modelController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _registerVehicle() {
    if (!_formKey.currentState!.validate()) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final photoPair = _presetPhotos[_selectedType]![_selectedPhotoIndex];

    appState.registerOwnerVehicle(
      model: _modelController.text.trim(),
      type: _selectedType,
      ratePerKm: double.parse(_rateController.text.trim()),
      insidePhotoUrl: photoPair['inside']!,
      outsidePhotoUrl: photoPair['outside']!,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const OwnerDashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoList = _presetPhotos[_selectedType]!;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Register Vehicle',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white54),
            onPressed: () {
              Provider.of<AppState>(context, listen: false).logout();
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'List Your Vehicle',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Provide your vehicle details. Customers will view these photos and rates to initiate bookings.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),

                // Vehicle Type Segment Picker
                const Text(
                  'VEHICLE TYPE',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: VehicleType.values.map((type) {
                    final isSelected = _selectedType == type;
                    IconData icon;
                    switch (type) {
                      case VehicleType.car:
                        icon = Icons.directions_car_rounded;
                        break;
                      case VehicleType.eRickshaw:
                        icon = Icons.electric_rickshaw_rounded;
                        break;
                      case VehicleType.loading:
                        icon = Icons.local_shipping_rounded;
                        break;
                    }
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedType = type;
                            _updateDefaultModel();
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF10B981) : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? Colors.transparent : const Color(0xFF2E3B4E),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                icon,
                                color: isSelected ? Colors.white : Colors.white70,
                                size: 24,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                type.displayName,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Vehicle Model Input
                TextFormField(
                  controller: _modelController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Vehicle Model Name',
                    labelStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.commute_rounded, color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF10B981)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter vehicle name/model';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Rate Input
                TextFormField(
                  controller: _rateController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Rate (Rs/Km)',
                    labelStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF10B981)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter billing rate';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid rate amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Select Vehicle Photo Pairing
                const Text(
                  'VEHICLE PHOTO THEME (MATCHED INSIDE/OUTSIDE)',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: photoList.length,
                    itemBuilder: (context, index) {
                      final photo = photoList[index];
                      final isSelected = _selectedPhotoIndex == index;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPhotoIndex = index;
                          });
                        },
                        child: Container(
                          width: 140,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF10B981) : const Color(0xFF2E3B4E),
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  photo['outside']!,
                                  fit: BoxFit.cover,
                                ),
                                Container(
                                  color: Colors.black38,
                                ),
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    width: double.infinity,
                                    color: Colors.black87,
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Text(
                                      photo['label']!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Positioned(
                                    top: 6,
                                    right: 6,
                                    child: CircleAvatar(
                                      radius: 10,
                                      backgroundColor: Color(0xFF10B981),
                                      child: Icon(Icons.check, color: Colors.white, size: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: _registerVehicle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Complete Registration',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
