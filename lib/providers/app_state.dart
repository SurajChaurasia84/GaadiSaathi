import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/vehicle.dart';
import '../models/chat.dart';

// ── Vercel Backend URL ──────────────────────────────────────────────────────
// Replace with your actual Vercel deployment URL after `vercel deploy`
const String _kVercelBaseUrl = 'https://gaadisaathi-backend.vercel.app';

class AppState extends ChangeNotifier {
  // Current user info
  String? currentGmail;
  String? currentUserName;
  String? currentUserRole; // 'Owner' or 'Customer'
  String? currentUserPhotoUrl;
  String? currentUserPhone;
  String? currentUserAddress;

  // Location state
  bool isLocationOn = false;
  bool isFetchingLocation = true;
  double customerLatitude = 0.0;
  double customerLongitude = 0.0;
  double searchRadiusKm = 5.0; // Default requirement: 5.0 Km
  String searchQuery = '';
  VehicleType? selectedCategoryFilter;
  String currentAddress = 'Fetching...';

  // Owner state
  Vehicle? ownerVehicle;
  bool isRentPaid = false;
  DateTime rentDueDate = DateTime.now().add(const Duration(days: 28));

  // Chat threads
  List<ChatThread> chatThreads = [];

  // Track last read timestamp for each chat thread (threadId -> epoch ms)
  final Map<String, int> _lastReadTimes = {};

  // Check if a specific thread has unread messages
  bool hasUnreadMessages(String threadId) {
    final threadIndex = chatThreads.indexWhere((t) => t.threadId == threadId);
    if (threadIndex < 0) return false;
    final thread = chatThreads[threadIndex];
    if (thread.messages.isEmpty) return false;

    final lastRead = _lastReadTimes[threadId] ?? 0;
    
    // Check if there are any messages sent by the other user after the lastRead timestamp
    for (var msg in thread.messages) {
      if (msg.senderId != currentGmail && msg.timestamp.millisecondsSinceEpoch > lastRead) {
        return true;
      }
    }
    return false;
  }

  // Check if any thread has unread messages
  bool get hasAnyUnreadMessages {
    for (var thread in chatThreads) {
      if (hasUnreadMessages(thread.threadId)) {
        return true;
      }
    }
    return false;
  }

  // Mark all messages in a thread as read
  void markThreadAsRead(String threadId) async {
    if (!hasUnreadMessages(threadId)) return; // Prevents infinite rebuild loops

    final now = DateTime.now().millisecondsSinceEpoch;
    _lastReadTimes[threadId] = now;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _lastReadTimes.entries.map((e) => '${e.key}:${e.value}').toList();
      await prefs.setStringList('last_read_times', list);
    } catch (_) {}
  }

  // Load last read times from local storage
  void _loadLastReadTimes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('last_read_times');
      if (list != null) {
        for (var item in list) {
          final parts = item.split(':');
          if (parts.length == 2) {
            final threadId = parts[0];
            final timestamp = int.tryParse(parts[1]);
            if (timestamp != null) {
              _lastReadTimes[threadId] = timestamp;
            }
          }
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  // Load user data from local storage
  void _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      currentUserPhone = prefs.getString('user_phone');
      currentUserAddress = prefs.getString('user_address');
      notifyListeners();
    } catch (_) {}
  }

  // Sync user document from Firestore
  void _syncUserDoc() {
    _userDocSubscription?.cancel();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userDocSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((docSnapshot) {
        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          if (data != null) {
            currentUserName = data['name'] as String? ?? currentUserName;
            currentUserPhone = data['phone'] as String? ?? currentUserPhone;
            currentUserAddress = data['address'] as String? ?? currentUserAddress;
            currentUserPhotoUrl = data['photoUrl'] as String? ?? currentUserPhotoUrl;
            
            _persistUserDataLocally();
            notifyListeners();
          }
        }
      });
    }
  }

  void _persistUserDataLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (currentUserName != null) await prefs.setString('user_name', currentUserName!);
      if (currentUserPhone != null) await prefs.setString('user_phone', currentUserPhone!);
      if (currentUserAddress != null) await prefs.setString('user_address', currentUserAddress!);
      if (currentUserPhotoUrl != null) await prefs.setString('user_photo', currentUserPhotoUrl!);
    } catch (_) {}
  }

  // Update user profile in local cache and Firestore
  Future<void> updateProfile({
    required String name,
    required String phone,
    required String address,
  }) async {
    currentUserName = name;
    currentUserPhone = phone;
    currentUserAddress = address;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);
      await prefs.setString('user_phone', phone);
      await prefs.setString('user_address', address);
    } catch (_) {}

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': name,
          'phone': phone,
          'address': address,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  // All mock vehicles in system
  List<Vehicle> _allVehicles = [];

  // Firestore Subscriptions
  StreamSubscription? _vehiclesSubscription;
  StreamSubscription? _chatsSubscription;
  StreamSubscription? _userDocSubscription;
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
    _loadLastReadTimes();
    _loadUserData();
    _syncWithFirestore();
  }

  void _syncWithFirestore() {
    _syncUserDoc();
    // 1. Sync vehicles collection
    _vehiclesSubscription?.cancel();
    _vehiclesSubscription = FirebaseFirestore.instance
        .collection('vehicles')
        .snapshots()
        .listen((snapshot) {
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
    });

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
        final addressMatch = vehicle.address?.toLowerCase().contains(query) ?? false;
        if (!modelMatch && !ownerMatch && !locationMatch && !addressMatch) return false;
      }

      return true;
    }).toList();
  }

  // All vehicles registered by the current logged-in user
  List<Vehicle> get myVehicles {
    if (currentGmail == null) return [];
    return _allVehicles.where((v) => v.ownerGmail == currentGmail).toList();
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
    _lastReadTimes.clear();
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
    isFetchingLocation = true;
    currentAddress = 'Fetching...';
    notifyListeners();

    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        currentAddress = 'Location Unavailable';
        isLocationOn = true;
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          currentAddress = 'Location Unavailable';
          isLocationOn = true;
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        currentAddress = 'Location Unavailable';
        isLocationOn = true;
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
    } catch (e) {
      // Graceful fallback for simulator/emulator/errors
      customerLatitude = 0.0;
      customerLongitude = 0.0;
      currentAddress = 'Location Unavailable';
      isLocationOn = true;
    } finally {
      isFetchingLocation = false;
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

  Future<void> updateVehicle(Vehicle vehicle) async {
    await FirebaseFirestore.instance
        .collection('vehicles')
        .doc(vehicle.id)
        .update(vehicle.toMap());
    notifyListeners();
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
    if (currentGmail == vehicle.ownerGmail) {
      throw Exception('Self-messaging is not allowed.');
    }
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

    // Determine recipient and dispatch FCM push notification
    try {
      final thread = chatThreads.firstWhere((t) => t.threadId == threadId);
      final recipientEmail = (currentGmail == thread.customerGmail)
          ? thread.ownerGmail
          : thread.customerGmail;

      // Look up recipient's FCM token from Firestore
      final usersQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: recipientEmail)
          .limit(1)
          .get();

      if (usersQuery.docs.isNotEmpty) {
        final recipientToken = usersQuery.docs.first.data()['fcmToken'] as String?;
        if (recipientToken != null && recipientToken.isNotEmpty) {
          final senderName = currentUserName ?? currentGmail ?? 'Someone';
          final notifBody = isBookingProposal
              ? '$senderName sent a booking proposal'
              : text.length > 60 ? '${text.substring(0, 60)}…' : text;
          await sendNotificationViaVercel(
            fcmToken: recipientToken,
            title: '💬 $senderName',
            body: notifBody,
            data: {'threadId': threadId},
          );
        }
      }
    } catch (_) {
      // Notification failure should never block message delivery
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
    _userDocSubscription?.cancel();
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

  // Direct unsigned Cloudinary upload
  Future<String?> uploadToCloudinary(String filePath) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/dx0rpdnx5/image/upload');
    try {
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = 'vehicles'
        ..files.add(await http.MultipartFile.fromPath('file', filePath));
        
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final decodedData = json.decode(responseData);
        return decodedData['secure_url'] as String?;
      } else {
        debugPrint('Cloudinary upload failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  // Save/refresh FCM device token to Firestore for this user
  Future<void> saveFcmToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await messaging.getToken();
      if (token == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'email': user.email,
      }, SetOptions(merge: true));

      // Auto-refresh when token rotates
      messaging.onTokenRefresh.listen((newToken) async {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'fcmToken': newToken,
        });
      });
    } catch (e) {
      debugPrint('FCM token save error: $e');
    }
  }

  // Send push notification via Vercel backend
  Future<void> sendNotificationViaVercel({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final url = Uri.parse('$_kVercelBaseUrl/api/send-notification');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fcmToken': fcmToken,
          'title': title,
          'body': body,
          'data': data ?? {},
        }),
      );
      if (response.statusCode != 200) {
        debugPrint('Notification failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('sendNotificationViaVercel error: $e');
    }
  }

  // Parse Cloudinary public ID from imageUrl
  String? _getCloudinaryPublicId(String url) {
    if (!url.contains('res.cloudinary.com')) return null;
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex >= pathSegments.length - 1) return null;

      var subSegments = pathSegments.sublist(uploadIndex + 1);
      if (subSegments.isEmpty) return null;

      if (subSegments.first.startsWith('v') && RegExp(r'^v\d+$').hasMatch(subSegments.first)) {
        subSegments = subSegments.sublist(1);
      }

      if (subSegments.isEmpty) return null;

      final lastSegment = subSegments.last;
      final dotIndex = lastSegment.lastIndexOf('.');
      final nameWithoutExt = dotIndex == -1 ? lastSegment : lastSegment.substring(0, dotIndex);

      return [...subSegments.sublist(0, subSegments.length - 1), nameWithoutExt].join('/');
    } catch (e) {
      debugPrint('Error parsing Cloudinary public ID: $e');
      return null;
    }
  }

  // Deletes an image from Cloudinary using Vercel backend proxy
  Future<bool> deleteImageFromCloudinary(String imageUrl) async {
    final publicId = _getCloudinaryPublicId(imageUrl);
    if (publicId == null) {
      debugPrint('Not a Cloudinary URL or public ID couldn\'t be parsed: $imageUrl');
      return false;
    }

    try {
      final url = Uri.parse('$_kVercelBaseUrl/api/delete-image');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'public_id': publicId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          debugPrint('Cloudinary image deleted successfully: $publicId');
          return true;
        }
      }
      debugPrint('Cloudinary image deletion failed for $publicId: ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Error deleting image from Cloudinary: $e');
      return false;
    }
  }

  // Deletes vehicle document from Firestore and deletes its related images from Cloudinary
  Future<void> deleteVehicle(Vehicle vehicle) async {
    final futures = <Future>[];

    if (vehicle.insidePhotoUrl.isNotEmpty && vehicle.insidePhotoUrl.contains('res.cloudinary.com')) {
      futures.add(deleteImageFromCloudinary(vehicle.insidePhotoUrl));
    }
    if (vehicle.outsidePhotoUrl.isNotEmpty && vehicle.outsidePhotoUrl.contains('res.cloudinary.com')) {
      futures.add(deleteImageFromCloudinary(vehicle.outsidePhotoUrl));
    }

    futures.add(FirebaseFirestore.instance
        .collection('vehicles')
        .doc(vehicle.id)
        .delete());

    await Future.wait(futures);
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

