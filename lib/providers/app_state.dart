import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/vehicle.dart';
import '../models/chat.dart';

class AppState extends ChangeNotifier {
  // Current user info
  String? currentGmail;
  String? currentUserName;
  String? currentUserRole; // 'Owner' or 'Customer'
  String? currentUserPhotoUrl;

  // Location state
  bool isLocationOn = false;
  double customerLatitude = 28.6139; // Delhi center as default
  double customerLongitude = 77.2090;
  double searchRadiusKm = 3.0; // Default requirement: 3.0 Km
  String searchQuery = '';
  VehicleType? selectedCategoryFilter;
  String currentAddress = 'Delhi, India';

  // Owner state
  Vehicle? ownerVehicle;
  bool isRentPaid = false;
  DateTime rentDueDate = DateTime.now().add(const Duration(days: 28));

  // Chat threads
  List<ChatThread> chatThreads = [];

  // All mock vehicles in system
  List<Vehicle> _allVehicles = [];

  // Firestore Subscriptions
  StreamSubscription? _vehiclesSubscription;
  StreamSubscription? _chatsSubscription;
  final Map<String, StreamSubscription> _messageSubscriptions = {};

  AppState({
    String? initialEmail,
    String? initialName,
    String? initialPhoto,
    ThemeMode initialThemeMode = ThemeMode.system,
  }) {
    currentGmail = initialEmail;
    currentUserName = initialName;
    currentUserPhotoUrl = initialPhoto;
    _themeMode = initialThemeMode;
    _syncWithFirestore();
  }

  List<Vehicle> _allMockVehicles() {
    return [
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
  }

  void _syncWithFirestore() {
    // 1. Sync vehicles collection
    _vehiclesSubscription?.cancel();
    _vehiclesSubscription = FirebaseFirestore.instance
        .collection('vehicles')
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isEmpty) {
        // Seed initial mock data to Firestore if completely empty
        for (var vehicle in _allMockVehicles()) {
          await FirebaseFirestore.instance
              .collection('vehicles')
              .doc(vehicle.id)
              .set(vehicle.toMap());
        }
      } else {
        _allVehicles = snapshot.docs
            .map((doc) => Vehicle.fromMap(doc.data(), doc.id))
            .toList();

        // Update owner vehicle if logged in
        if (currentGmail != null) {
          try {
            ownerVehicle = _allVehicles.firstWhere((v) => v.ownerGmail == currentGmail);
          } catch (_) {
            ownerVehicle = null;
          }
        }
        notifyListeners();
      }
    });

    // Seed initial chat if empty
    _seedInitialChats();

    // 2. Sync chats collection
    _chatsSubscription?.cancel();
    _chatsSubscription = FirebaseFirestore.instance
        .collection('chats')
        .snapshots()
        .listen((snapshot) {
      final userEmail = currentGmail ?? 'guest.customer@gmail.com';

      // Clean up old subscriptions for deleted threads
      final currentDocIds = snapshot.docs.map((d) => d.id).toSet();
      final keysToRemove = <String>[];
      _messageSubscriptions.forEach((key, sub) {
        if (!currentDocIds.contains(key)) {
          sub.cancel();
          keysToRemove.add(key);
        }
      });
      for (var key in keysToRemove) {
        _messageSubscriptions.remove(key);
        chatThreads.removeWhere((t) => t.threadId == key);
      }

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final threadId = doc.id;
        final customerGmail = data['customerGmail'] as String? ?? '';
        final ownerGmail = data['ownerGmail'] as String? ?? '';

        // Filter chat threads related to current logged-in user
        if (customerGmail != userEmail && ownerGmail != userEmail) {
          if (_messageSubscriptions.containsKey(threadId)) {
            _messageSubscriptions[threadId]?.cancel();
            _messageSubscriptions.remove(threadId);
            chatThreads.removeWhere((t) => t.threadId == threadId);
          }
          continue;
        }

        _listenToMessagesForThread(threadId, data);
      }
      notifyListeners();
    });
  }

  void _listenToMessagesForThread(String threadId, Map<String, dynamic> threadData) {
    if (_messageSubscriptions.containsKey(threadId)) return;

    final subscription = FirebaseFirestore.instance
        .collection('chats')
        .doc(threadId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((msgSnapshot) {
      final messages = msgSnapshot.docs.map((doc) => ChatMessage.fromMap(doc.data())).toList();
      final updatedThread = ChatThread.fromMap(threadData, threadId, messages);

      final index = chatThreads.indexWhere((t) => t.threadId == threadId);
      if (index >= 0) {
        chatThreads[index] = updatedThread;
      } else {
        chatThreads.add(updatedThread);
      }
      notifyListeners();
    });

    _messageSubscriptions[threadId] = subscription;
  }

  Future<void> _seedInitialChats() async {
    final chatSnapshot = await FirebaseFirestore.instance.collection('chats').get();
    if (chatSnapshot.docs.isEmpty) {
      final threadId = 'v2_cust';
      final threadData = {
        'customerName': 'Rohit Sharma (Customer)',
        'customerGmail': 'rohit.customer@gmail.com',
        'ownerName': 'Rajesh Kumar',
        'ownerGmail': 'rajesh.rickshaw@gmail.com',
        'vehicleModel': 'Mayuri E-Rickshaw Pro',
      };

      await FirebaseFirestore.instance.collection('chats').doc(threadId).set(threadData);

      final messages = [
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
      ];

      for (var msg in messages) {
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(threadId)
            .collection('messages')
            .add(msg.toMap());
      }
    }
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
      if (!vehicle.isServiceOn) return false;

      double distance = getDistanceFromUser(vehicle.latitude, vehicle.longitude);
      if (distance > searchRadiusKm) return false;

      if (selectedCategoryFilter != null && vehicle.type != selectedCategoryFilter) {
        return false;
      }

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

  Future<void> loginSimulated(String gmail, String name, {String? photoUrl}) async {
    currentGmail = gmail;
    currentUserName = name;
    currentUserPhotoUrl = photoUrl;

    try {
      ownerVehicle = _allVehicles.firstWhere((v) => v.ownerGmail == gmail);
    } catch (_) {
      ownerVehicle = null;
    }

    // Reset subscriptions for the new user
    for (var sub in _messageSubscriptions.values) {
      sub.cancel();
    }
    _messageSubscriptions.clear();
    chatThreads.clear();

    _syncWithFirestore();
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', gmail);
      await prefs.setString('user_name', name);
      if (photoUrl != null) {
        await prefs.setString('user_photo', photoUrl);
      } else {
        await prefs.remove('user_photo');
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    currentGmail = null;
    currentUserName = null;
    currentUserRole = null;
    currentUserPhotoUrl = null;
    ownerVehicle = null;
    chatThreads.clear();
    for (var sub in _messageSubscriptions.values) {
      sub.cancel();
    }
    _messageSubscriptions.clear();
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.remove('user_photo');
    } catch (_) {}

    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    } catch (_) {}
  }

  // Simulation step: Auto Location on
  void triggerLocationOn() async {
    isLocationOn = false;
    notifyListeners();
    await fetchCurrentLocation();
  }

  Future<void> fetchCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        currentAddress = 'GPS Disabled (Connaught Place, Delhi)';
        isLocationOn = true;
        notifyListeners();
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          currentAddress = 'Permission Denied (Connaught Place, Delhi)';
          isLocationOn = true;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        currentAddress = 'Permission Denied (Connaught Place, Delhi)';
        isLocationOn = true;
        notifyListeners();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      customerLatitude = position.latitude;
      customerLongitude = position.longitude;
      isLocationOn = true;

      // Reverse geocoding
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        final parts = <String>[];
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          parts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        }
        currentAddress = parts.isNotEmpty ? parts.join(', ') : 'Location Detected';
      } else {
        currentAddress = 'Location Detected';
      }
      notifyListeners();
    } catch (e) {
      // Graceful fallback for simulator/emulator/errors
      customerLatitude = 28.6139;
      customerLongitude = 77.2090;
      currentAddress = 'Connaught Place, New Delhi';
      isLocationOn = true;
      notifyListeners();
    }
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
  }) async {
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
      latitude: customerLatitude + 0.005,
      longitude: customerLongitude + 0.005,
    );

    ownerVehicle = newVehicle;
    await FirebaseFirestore.instance
        .collection('vehicles')
        .doc(newVehicle.id)
        .set(newVehicle.toMap());
  }

  void addCustomVehicle(Vehicle vehicle) async {
    await FirebaseFirestore.instance
        .collection('vehicles')
        .doc(vehicle.id)
        .set(vehicle.toMap());
  }

  void toggleServiceStatus(bool isOn) async {
    if (ownerVehicle != null) {
      ownerVehicle = ownerVehicle!.copyWith(isServiceOn: isOn);
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(ownerVehicle!.id)
          .update({'isServiceOn': isOn});
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
      messages: [],
    );

    FirebaseFirestore.instance.collection('chats').doc(threadId).set({
      'customerName': newThread.customerName,
      'customerGmail': newThread.customerGmail,
      'ownerName': newThread.ownerName,
      'ownerGmail': newThread.ownerGmail,
      'vehicleModel': newThread.vehicleModel,
    });

    final firstMsg = ChatMessage(
      senderId: vehicle.ownerGmail,
      text: 'Hi there! I am the owner of ${vehicle.model}. Do you want to book my service? The rate is ₹${vehicle.ratePerKm.toStringAsFixed(1)}/Km.',
      timestamp: DateTime.now(),
    );

    FirebaseFirestore.instance
        .collection('chats')
        .doc(threadId)
        .collection('messages')
        .add(firstMsg.toMap());

    return newThread;
  }

  void sendChatMessage(String threadId, String text, {bool isBookingProposal = false, double? ratePerKm}) async {
    final msg = ChatMessage(
      senderId: currentGmail ?? 'unknown@gmail.com',
      text: text,
      timestamp: DateTime.now(),
      isBookingProposal: isBookingProposal,
      bookingStatus: isBookingProposal ? BookingStatus.pending : null,
      ratePerKm: ratePerKm,
    );

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(threadId)
        .collection('messages')
        .add(msg.toMap());

    // Auto-respond for simulation
    final index = chatThreads.indexWhere((t) => t.threadId == threadId);
    if (index >= 0) {
      final thread = chatThreads[index];
      if (currentGmail == thread.customerGmail && !isBookingProposal) {
        _simulateOwnerResponse(threadId, text);
      }
    }
  }

  void _simulateOwnerResponse(String threadId, String userText) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final index = chatThreads.indexWhere((t) => t.threadId == threadId);
    if (index >= 0) {
      final thread = chatThreads[index];
      String response = 'Okay, I understand. Let\'s coordinate!';
      final textLower = userText.toLowerCase();
      if (textLower.contains('available') || textLower.contains('free')) {
        response = 'Yes, my service is active and ready right now!';
      } else if (textLower.contains('discount') || textLower.contains('rate')) {
        final double currentRate = ownerVehicle?.ratePerKm ?? 12.0;
        response = 'The rate is fixed at ₹${currentRate.toStringAsFixed(1)}/Km as per the requirements, but I can offer smooth transport!';
      }

      final msg = ChatMessage(
        senderId: thread.ownerGmail,
        text: response,
        timestamp: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(threadId)
          .collection('messages')
          .add(msg.toMap());
    }
  }

  void updateBookingStatus(String threadId, int messageIndex, BookingStatus status) async {
    final index = chatThreads.indexWhere((t) => t.threadId == threadId);
    if (index >= 0) {
      final thread = chatThreads[index];
      final targetMsg = thread.messages[messageIndex];

      final msgQuery = await FirebaseFirestore.instance
          .collection('chats')
          .doc(threadId)
          .collection('messages')
          .where('senderId', isEqualTo: targetMsg.senderId)
          .where('text', isEqualTo: targetMsg.text)
          .get();

      if (msgQuery.docs.isNotEmpty) {
        await msgQuery.docs.first.reference.update({
          'bookingStatus': status.name,
        });
      }
    }
  }

  @override
  void dispose() {
    _vehiclesSubscription?.cancel();
    _chatsSubscription?.cancel();
    for (var sub in _messageSubscriptions.values) {
      sub.cancel();
    }
    _messageSubscriptions.clear();
    super.dispose();
  }

  // Theme state settings
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;


  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('theme_mode', mode.index);
    } catch (_) {}
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

