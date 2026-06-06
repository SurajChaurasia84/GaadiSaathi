import 'dart:math';
import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../models/chat.dart';

class AppState extends ChangeNotifier {
  // Current user info
  String? currentGmail;
  String? currentUserName;
  String? currentUserRole; // 'Owner' or 'Customer'

  // Location simulation
  bool isLocationOn = false;
  double customerLatitude = 28.6139; // Delhi center as default
  double customerLongitude = 77.2090;
  double searchRadiusKm = 3.0; // Default requirement: 3.0 Km
  String searchQuery = '';
  VehicleType? selectedCategoryFilter;

  // Owner state
  Vehicle? ownerVehicle;
  bool isRentPaid = false;
  DateTime rentDueDate = DateTime.now().add(const Duration(days: 28));

  // Chat threads
  List<ChatThread> chatThreads = [];

  // All mock vehicles in system
  List<Vehicle> _allVehicles = [];

  AppState() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // We create mock vehicles scattered around 28.6139, 77.2090
    _allVehicles = [
      Vehicle(
        id: 'v1',
        ownerName: 'Amit Sharma',
        ownerGmail: 'amit.owner@gmail.com',
        type: VehicleType.car,
        model: 'Maruti Suzuki Swift (White)',
        insidePhotoUrl: 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?q=80&w=600&auto=format&fit=crop',
        outsidePhotoUrl: 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?q=80&w=600&auto=format&fit=crop',
        ratePerKm: 14.0,
        isServiceOn: true,
        latitude: 28.6210, // ~1.0 km North-East
        longitude: 77.2150,
      ),
      Vehicle(
        id: 'v2',
        ownerName: 'Rajesh Kumar',
        ownerGmail: 'rajesh.rickshaw@gmail.com',
        type: VehicleType.eRickshaw,
        model: 'Mayuri E-Rickshaw Pro',
        insidePhotoUrl: 'https://images.unsplash.com/photo-1517524206127-48bbd363f3d7?q=80&w=600&auto=format&fit=crop',
        outsidePhotoUrl: 'https://images.unsplash.com/photo-1626125345510-4603468eedfb?q=80&w=600&auto=format&fit=crop',
        ratePerKm: 8.0,
        isServiceOn: true,
        latitude: 28.6050, // ~1.3 km South
        longitude: 77.2050,
      ),
      Vehicle(
        id: 'v3',
        ownerName: 'Sanjay Singh',
        ownerGmail: 'sanjay.loading@gmail.com',
        type: VehicleType.loading,
        model: 'Tata Ace Gold (Chota Hathi)',
        insidePhotoUrl: 'https://images.unsplash.com/photo-1486006920555-c77dce18193b?q=80&w=600&auto=format&fit=crop',
        outsidePhotoUrl: 'https://images.unsplash.com/photo-1516576885230-101c05528b3f?q=80&w=600&auto=format&fit=crop',
        ratePerKm: 22.0,
        isServiceOn: true,
        latitude: 28.6250, // ~2.1 km North-West
        longitude: 77.1950,
      ),
      Vehicle(
        id: 'v4',
        ownerName: 'Vikram Aditya',
        ownerGmail: 'vikram.car@gmail.com',
        type: VehicleType.car,
        model: 'Hyundai i20 (Asta)',
        insidePhotoUrl: 'https://images.unsplash.com/photo-1563720223185-11003d516935?q=80&w=600&auto=format&fit=crop',
        outsidePhotoUrl: 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?q=80&w=600&auto=format&fit=crop',
        ratePerKm: 16.0,
        isServiceOn: true,
        latitude: 28.6380, // ~3.8 km North (outside the 3km radius!)
        longitude: 77.2180,
      ),
      Vehicle(
        id: 'v5',
        ownerName: 'Manpreet Singh',
        ownerGmail: 'manpreet.loading@gmail.com',
        type: VehicleType.loading,
        model: 'Mahindra Bolero Pickup',
        insidePhotoUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?q=80&w=600&auto=format&fit=crop',
        outsidePhotoUrl: 'https://images.unsplash.com/photo-1580273916550-e323be2ae537?q=80&w=600&auto=format&fit=crop',
        ratePerKm: 25.0,
        isServiceOn: true,
        latitude: 28.5950, // ~2.9 km South-East
        longitude: 77.2280,
      ),
    ];

    // Seed mock chats
    chatThreads = [
      ChatThread(
        threadId: 'v2_cust',
        customerName: 'Rohit Sharma (Customer)',
        customerGmail: 'rohit.customer@gmail.com',
        ownerName: 'Rajesh Kumar',
        ownerGmail: 'rajesh.rickshaw@gmail.com',
        vehicleModel: 'Mayuri E-Rickshaw Pro',
        messages: [
          ChatMessage(
            senderId: 'rohit.customer@gmail.com',
            text: 'Hello Rajesh, is your rickshaw available near Metro Station?',
            timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
          ChatMessage(
            senderId: 'rajesh.rickshaw@gmail.com',
            text: 'Yes! It is available. Where do you need to go?',
            timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
          ),
          ChatMessage(
            senderId: 'rohit.customer@gmail.com',
            text: 'Just 4 kms away to Sector 62.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
          ),
          ChatMessage(
            senderId: 'rajesh.rickshaw@gmail.com',
            text: 'Okay, let\'s book it. Rate is ₹8/Km.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
            isBookingProposal: true,
            bookingStatus: BookingStatus.pending,
            ratePerKm: 8.0,
          ),
        ],
      )
    ];
  }

  // Calculate distance between two lat/lons in Kilometers using Haversine
  double getDistanceFromUser(double lat, double lon) {
    var p = 0.017453292519943295;
    var a = 0.5 - cos((lat - customerLatitude) * p) / 2 +
        cos(customerLatitude * p) * cos(lat * p) *
            (1 - cos((lon - customerLongitude) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  // Filtered vehicles based on location, radius, search, category, and Service ON status
  List<Vehicle> get filteredVehicles {
    if (!isLocationOn) return [];

    return _allVehicles.where((vehicle) {
      // 1. Service must be ON (or it is the current owner viewing their own app, but for customer it must be ON)
      if (!vehicle.isServiceOn) return false;

      // 2. Distance check: must be <= searchRadiusKm
      double distance = getDistanceFromUser(vehicle.latitude, vehicle.longitude);
      if (distance > searchRadiusKm) return false;

      // 3. Category Filter
      if (selectedCategoryFilter != null && vehicle.type != selectedCategoryFilter) {
        return false;
      }

      // 4. Search Query filter (model or owner name)
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final modelMatch = vehicle.model.toLowerCase().contains(query);
        final ownerMatch = vehicle.ownerName.toLowerCase().contains(query);
        final locationMatch = vehicle.type.displayName.toLowerCase().contains(query);
        if (!modelMatch && !ownerMatch && !locationMatch) return false;
      }

      return true;
    }).toList();
  }

  // Actions
  void setRole(String role) {
    currentUserRole = role;
    notifyListeners();
  }

  void loginSimulated(String gmail, String name) {
    currentGmail = gmail;
    currentUserName = name;

    // Check if there is an existing vehicle for this owner
    if (currentUserRole == 'Owner') {
      try {
        ownerVehicle = _allVehicles.firstWhere((v) => v.ownerGmail == gmail);
      } catch (_) {
        ownerVehicle = null;
      }
    }
    notifyListeners();
  }

  void logout() {
    currentGmail = null;
    currentUserName = null;
    currentUserRole = null;
    ownerVehicle = null;
    notifyListeners();
  }

  // Simulation step: Auto Location on
  void triggerLocationOn() async {
    isLocationOn = false;
    notifyListeners();
    // Simulate minor delay for GPS sensor lookup
    await Future.delayed(const Duration(milliseconds: 800));
    isLocationOn = true;
    notifyListeners();
  }

  void setSearchRadius(double radius) {
    searchRadiusKm = radius;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(VehicleType? type) {
    selectedCategoryFilter = type;
    notifyListeners();
  }

  // Owner Operations
  void registerOwnerVehicle({
    required String model,
    required VehicleType type,
    required double ratePerKm,
    required String insidePhotoUrl,
    required String outsidePhotoUrl,
  }) {
    if (currentGmail == null) return;

    final newVehicle = Vehicle(
      id: 'owner_${currentGmail!.hashCode}',
      ownerName: currentUserName ?? 'Owner',
      ownerGmail: currentGmail!,
      type: type,
      model: model,
      insidePhotoUrl: insidePhotoUrl,
      outsidePhotoUrl: outsidePhotoUrl,
      ratePerKm: ratePerKm,
      isServiceOn: true,
      latitude: customerLatitude + 0.005, // simulated very close to customer
      longitude: customerLongitude + 0.005,
    );

    ownerVehicle = newVehicle;
    // Add or update in general list
    final existingIndex = _allVehicles.indexWhere((v) => v.ownerGmail == currentGmail);
    if (existingIndex >= 0) {
      _allVehicles[existingIndex] = newVehicle;
    } else {
      _allVehicles.add(newVehicle);
    }
    notifyListeners();
  }

  void toggleServiceStatus(bool isOn) {
    if (ownerVehicle != null) {
      ownerVehicle = ownerVehicle!.copyWith(isServiceOn: isOn);
      final index = _allVehicles.indexWhere((v) => v.id == ownerVehicle!.id);
      if (index >= 0) {
        _allVehicles[index] = ownerVehicle!;
      }
      notifyListeners();
    }
  }

  void payRent() {
    isRentPaid = true;
    rentDueDate = DateTime.now().add(const Duration(days: 30));
    notifyListeners();
  }

  // Chat Operations
  ChatThread getOrCreateThread(Vehicle vehicle) {
    final threadId = '${currentGmail}_${vehicle.ownerGmail}';
    final existingIndex = chatThreads.indexWhere((t) => t.threadId == threadId);

    if (existingIndex >= 0) {
      return chatThreads[existingIndex];
    }

    final newThread = ChatThread(
      threadId: threadId,
      customerName: currentUserName ?? 'Customer',
      customerGmail: currentGmail ?? 'customer@gmail.com',
      ownerName: vehicle.ownerName,
      ownerGmail: vehicle.ownerGmail,
      vehicleModel: vehicle.model,
      messages: [
        ChatMessage(
          senderId: vehicle.ownerGmail,
          text: 'Hi there! I am the owner of ${vehicle.model}. Do you want to book my service? The rate is ₹${vehicle.ratePerKm.toStringAsFixed(1)}/Km.',
          timestamp: DateTime.now(),
        ),
      ],
    );

    chatThreads.add(newThread);
    notifyListeners();
    return newThread;
  }

  void sendChatMessage(String threadId, String text, {bool isBookingProposal = false, double? ratePerKm}) {
    final index = chatThreads.indexWhere((t) => t.threadId == threadId);
    if (index >= 0) {
      final updatedMessages = List<ChatMessage>.from(chatThreads[index].messages)
        ..add(ChatMessage(
          senderId: currentGmail ?? 'unknown@gmail.com',
          text: text,
          timestamp: DateTime.now(),
          isBookingProposal: isBookingProposal,
          bookingStatus: isBookingProposal ? BookingStatus.pending : null,
          ratePerKm: ratePerKm,
        ));

      chatThreads[index] = chatThreads[index].copyWith(messages: updatedMessages);
      notifyListeners();

      // Simple simulator replies after 1.5 seconds if sent by customer, to make the chat feel responsive
      if (currentUserRole == 'Customer' && !isBookingProposal) {
        _simulateOwnerResponse(threadId, text);
      }
    }
  }

  void _simulateOwnerResponse(String threadId, String userText) async {
    await Future.delayed(const Duration(seconds: 1500));
    final index = chatThreads.indexWhere((t) => t.threadId == threadId);
    if (index >= 0) {
      String response = 'Okay, I understand. Let\'s coordinate!';
      final textLower = userText.toLowerCase();
      if (textLower.contains('available') || textLower.contains('free')) {
        response = 'Yes, my service is active and ready right now!';
      } else if (textLower.contains('discount') || textLower.contains('rate')) {
        final double currentRate = ownerVehicle?.ratePerKm ?? 12.0;
        response = 'The rate is fixed at ₹${currentRate.toStringAsFixed(1)}/Km as per the requirements, but I can offer smooth riding!';
      }

      final updatedMessages = List<ChatMessage>.from(chatThreads[index].messages)
        ..add(ChatMessage(
          senderId: chatThreads[index].ownerGmail,
          text: response,
          timestamp: DateTime.now(),
        ));

      chatThreads[index] = chatThreads[index].copyWith(messages: updatedMessages);
      notifyListeners();
    }
  }

  void updateBookingStatus(String threadId, int messageIndex, BookingStatus status) {
    final threadIdx = chatThreads.indexWhere((t) => t.threadId == threadId);
    if (threadIdx >= 0) {
      final thread = chatThreads[threadIdx];
      final updatedMessages = List<ChatMessage>.from(thread.messages);
      final msg = updatedMessages[messageIndex];

      updatedMessages[messageIndex] = msg.copyWith(bookingStatus: status);
      chatThreads[threadIdx] = thread.copyWith(messages: updatedMessages);
      notifyListeners();
    }
  }

  // Theme state settings
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}

extension ThemeHelper on BuildContext {
  bool get isDarkMode {
    final theme = Theme.of(this);
    return theme.brightness == Brightness.dark;
  }

  Color get textColor => isDarkMode ? Colors.white : const Color(0xFF0F172A);
  Color get textColor54 => isDarkMode ? Colors.white54 : const Color(0xFF475569);
  Color get textColor30 => isDarkMode ? Colors.white30 : const Color(0xFF94A3B8);
  Color get textColor70 => isDarkMode ? Colors.white70 : const Color(0xFF334155);
}

