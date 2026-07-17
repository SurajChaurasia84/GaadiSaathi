import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/app_state.dart';
import '../../models/vehicle.dart';
import 'add_edit_vehicle_screen.dart';
import 'shop_detail_screen.dart';
import 'driver_detail_screen.dart';

class VehicleHistoryScreen extends StatelessWidget {
  const VehicleHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Service History',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          bottom: TabBar(
            isScrollable: true,
            labelColor: const Color(0xFF536DFE),
            unselectedLabelColor: isDarkMode ? Colors.white54 : Colors.black54,
            indicatorColor: const Color(0xFF536DFE),
            indicatorWeight: 3,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Vehicles'),
              Tab(text: 'Shops'),
              Tab(text: 'Drivers'),
              Tab(text: 'Service Centers'),
              Tab(text: 'Ads'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Vehicles
            _buildVehiclesTab(context, appState),
            // Tab 2: Shops
            _buildShopsTab(context, appState),
            // Tab 3: Drivers
            _buildDriversTab(context, appState),
            // Tab 4: Service Centers
            _buildServiceCentersTab(context, appState),
            // Tab 5: Ads
            _buildAdsTab(context, appState),
          ],
        ),
      ),
    );
  }

  // ── Tab 1: Vehicles ────────────────────────────────────────────────────────
  Widget _buildVehiclesTab(BuildContext context, AppState appState) {
    final vehicles = appState.myVehicles;
    if (vehicles.isEmpty) {
      return _buildEmptyState(
        context,
        'No Vehicles Registered Yet',
        'Vehicles you add will appear here.',
        Icons.directions_car_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: vehicles.length,
      itemBuilder: (ctx, index) {
        final vehicle = vehicles[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => AddEditVehicleScreen(initialVehicle: vehicle),
              ),
            );
          },
          onLongPress: () {
            _showDeleteConfirmDialog(
              context: context,
              title: 'Delete Vehicle?',
              message: 'Are you sure you want to delete ${vehicle.model}? This will permanently delete the vehicle from Firestore.',
              onDelete: () => _deleteVehicleWithLoading(context, vehicle),
            );
          },
          child: _buildVehicleCard(ctx, vehicle),
        );
      },
    );
  }

  // ── Tab 2: Shops ───────────────────────────────────────────────────────────
  Widget _buildShopsTab(BuildContext context, AppState appState) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('shops')
          .where('ownerGmail', isEqualTo: appState.currentGmail)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF536DFE)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            context,
            'No Shops Registered',
            'Shops you register will appear here.',
            Icons.storefront_rounded,
          );
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          itemCount: docs.length,
          itemBuilder: (ctx, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final shopName = data['shopName'] as String? ?? 'Shop';
            final ownerName = data['ownerName'] as String? ?? 'Owner';
            final photoUrl = data['photoUrl'] as String? ?? '';
            final address = data['address'] as String? ?? '';
            final price = data['price']?.toString() ?? '0';

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  ctx,
                  MaterialPageRoute(builder: (_) => ShopDetailScreen(data: data)),
                );
              },
              onLongPress: () {
                _showDeleteConfirmDialog(
                  context: context,
                  title: 'Delete Shop?',
                  message: 'Are you sure you want to delete $shopName? This will permanently delete the shop post.',
                  onDelete: () => _deleteDocumentWithLoading(
                    context: context,
                    collectionName: 'shops',
                    docId: doc.id,
                    itemName: shopName,
                    loadingText: 'Deleting shop...',
                    successText: 'Shop deleted successfully!',
                  ),
                );
              },
              child: _buildHistoryCard(
                context: ctx,
                title: shopName,
                subtitle1: 'Owner: $ownerName',
                subtitle2: 'Price: ₹$price',
                address: address,
                photoUrl: photoUrl,
                badgeLabel: 'Shop Buy/Sell',
              ),
            );
          },
        );
      },
    );
  }

  // ── Tab 3: Drivers ─────────────────────────────────────────────────────────
  Widget _buildDriversTab(BuildContext context, AppState appState) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('drivers')
          .where('driverGmail', isEqualTo: appState.currentGmail)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF536DFE)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            context,
            'No Drivers Registered',
            'Drivers you register will appear here.',
            Icons.badge_outlined,
          );
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          itemCount: docs.length,
          itemBuilder: (ctx, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final driverName = data['driverName'] as String? ?? 'Driver';
            final address = data['address'] as String? ?? '';
            final experience = data['experience']?.toString() ?? '0';
            final phone = data['phoneNumber'] as String? ?? '';
            final photoUrl = data['licensePhotoUrl'] as String? ?? '';

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  ctx,
                  MaterialPageRoute(builder: (_) => DriverDetailScreen(data: data)),
                );
              },
              onLongPress: () {
                _showDeleteConfirmDialog(
                  context: context,
                  title: 'Delete Driver?',
                  message: 'Are you sure you want to delete driver profile of $driverName? This will permanently delete the driver profile.',
                  onDelete: () => _deleteDocumentWithLoading(
                    context: context,
                    collectionName: 'drivers',
                    docId: doc.id,
                    itemName: driverName,
                    loadingText: 'Deleting driver...',
                    successText: 'Driver deleted successfully!',
                  ),
                );
              },
              child: _buildHistoryCard(
                context: ctx,
                title: driverName,
                subtitle1: 'Experience: $experience Years',
                subtitle2: 'Phone: $phone',
                address: address,
                photoUrl: photoUrl,
                badgeLabel: 'Driver',
              ),
            );
          },
        );
      },
    );
  }

  // ── Tab 4: Service Centers ────────────────────────────────────────────────
  Widget _buildServiceCentersTab(BuildContext context, AppState appState) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('service_centers')
          .where('ownerGmail', isEqualTo: appState.currentGmail)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF536DFE)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            context,
            'No Stations Registered',
            'Service Centers you register will appear here.',
            Icons.build_circle_outlined,
          );
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          itemCount: docs.length,
          itemBuilder: (ctx, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final centerName = data['serviceCenterName'] as String? ?? 'Service Center';
            final address = data['address'] as String? ?? '';
            final phone = data['phoneNumber'] as String? ?? '';
            final photoUrl = data['photoUrl'] as String? ?? '';

            return GestureDetector(
              onTap: () {
                _showServiceCenterDetailsBottomSheet(ctx, appState, data);
              },
              onLongPress: () {
                _showDeleteConfirmDialog(
                  context: context,
                  title: 'Delete Service Center?',
                  message: 'Are you sure you want to delete $centerName? This will permanently delete the service center.',
                  onDelete: () => _deleteDocumentWithLoading(
                    context: context,
                    collectionName: 'service_centers',
                    docId: doc.id,
                    itemName: centerName,
                    loadingText: 'Deleting service center...',
                    successText: 'Service center deleted successfully!',
                  ),
                );
              },
              child: _buildHistoryCard(
                context: ctx,
                title: centerName,
                subtitle1: 'Phone: $phone',
                subtitle2: '',
                address: address,
                photoUrl: photoUrl,
                badgeLabel: 'Service Station',
              ),
            );
          },
        );
      },
    );
  }

  // ── Tab 5: Ads ────────────────────────────────────────────────────────────
  Widget _buildAdsTab(BuildContext context, AppState appState) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ads')
          .where('ownerGmail', isEqualTo: appState.currentGmail)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF536DFE)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            context,
            'No Ads Promoted',
            'Ads you promote will appear here.',
            Icons.campaign_outlined,
          );
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          itemCount: docs.length,
          itemBuilder: (ctx, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final adTitle = data['title'] as String? ?? 'Ad Banner';
            final adDesc = data['desc'] as String? ?? '';
            final photoUrl = data['photoUrl'] as String? ?? '';

            return GestureDetector(
              onTap: () {
                _showAdDetailsBottomSheet(ctx, data);
              },
              onLongPress: () {
                _showDeleteConfirmDialog(
                  context: context,
                  title: 'Delete Ad?',
                  message: 'Are you sure you want to delete $adTitle? This will permanently delete the advertisement.',
                  onDelete: () => _deleteDocumentWithLoading(
                    context: context,
                    collectionName: 'ads',
                    docId: doc.id,
                    itemName: adTitle,
                    loadingText: 'Deleting ad...',
                    successText: 'Ad deleted successfully!',
                  ),
                );
              },
              child: _buildHistoryCard(
                context: ctx,
                title: adTitle,
                subtitle1: adDesc,
                subtitle2: '',
                address: '',
                photoUrl: photoUrl,
                badgeLabel: 'Ad Campaign',
              ),
            );
          },
        );
      },
    );
  }

  // ── General Confirmation Dialog ───────────────────────────────────────────
  void _showDeleteConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onDelete,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: dialogContext.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(color: dialogContext.textColor70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close confirm dialog
                onDelete();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // ── Firestore Deletion Helper ─────────────────────────────────────────────
  void _deleteDocumentWithLoading({
    required BuildContext context,
    required String collectionName,
    required String docId,
    required String itemName,
    required String loadingText,
    required String successText,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext loadingContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Row(
              children: [
                const CircularProgressIndicator(
                  color: Color(0xFF536DFE),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    loadingText,
                    style: TextStyle(
                      color: loadingContext.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    final messenger = ScaffoldMessenger.of(context);

    try {
      await FirebaseFirestore.instance.collection(collectionName).doc(docId).delete();

      // Close the loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(successText),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      // Close the loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to delete: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _deleteVehicleWithLoading(BuildContext context, Vehicle vehicle) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext loadingContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Row(
              children: [
                const CircularProgressIndicator(
                  color: Color(0xFF536DFE),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    'Deleting vehicle...',
                    style: TextStyle(
                      color: loadingContext.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    final appState = Provider.of<AppState>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await appState.deleteVehicle(vehicle);

      // Close the loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text('${vehicle.model} deleted successfully!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      // Close the loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to delete vehicle: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ── General Empty State Builder ───────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context, String title, String desc, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF536DFE).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF536DFE),
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              color: context.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(color: context.textColor54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Card Builder for Vehicles ─────────────────────────────────────────────
  Widget _buildVehicleCard(BuildContext context, Vehicle vehicle) {
    final isActive = vehicle.isServiceOn;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.isDarkMode
              ? const Color(0x1AFFFFFF)
              : const Color(0x10000000),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: context.isDarkMode ? 0.15 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVehicleImage(vehicle.outsidePhotoUrl),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _badge(
                          vehicle.type.displayName,
                          const Color(0xFF536DFE),
                        ),
                        const Spacer(),
                        _statusBadge(isActive),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      vehicle.model,
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.speed_rounded,
                            color: context.textColor54, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          '₹${vehicle.ratePerKm.toStringAsFixed(0)}/km',
                          style: TextStyle(
                            color: context.textColor54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (vehicle.address != null &&
                        vehicle.address!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              color: context.textColor30, size: 12),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              vehicle.address!,
                              style: TextStyle(
                                  color: context.textColor30, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (vehicle.phoneNumber != null &&
                        vehicle.phoneNumber!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined,
                              color: context.textColor30, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            vehicle.phoneNumber!,
                            style: TextStyle(
                                color: context.textColor30, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card Builder for Shops, Drivers, Service Centers, and Ads ─────────────
  Widget _buildHistoryCard({
    required BuildContext context,
    required String title,
    required String subtitle1,
    required String subtitle2,
    required String address,
    required String photoUrl,
    required String badgeLabel,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.isDarkMode
              ? const Color(0x1AFFFFFF)
              : const Color(0x10000000),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: context.isDarkMode ? 0.15 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVehicleImage(photoUrl),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _badge(badgeLabel, const Color(0xFF536DFE)),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (subtitle1.isNotEmpty) ...[
                      Text(
                        subtitle1,
                        style: TextStyle(
                          color: context.textColor54,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    if (subtitle2.isNotEmpty) ...[
                      Text(
                        subtitle2,
                        style: TextStyle(
                          color: context.textColor54,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    if (address.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              color: context.textColor30, size: 12),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              address,
                              style: TextStyle(
                                  color: context.textColor30, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleImage(String url) {
    const double w = 110;
    const double h = 120;

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        width: w,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _imageError(w, h),
      );
    }

    final file = File(url);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: w,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _imageError(w, h),
      );
    }

    return _imageError(w, h);
  }

  Widget _imageError(double w, double h) {
    return Container(
      width: w,
      height: h,
      color: const Color(0xFF1E293B),
      child: const Center(
        child: Icon(Icons.broken_image_rounded, color: Colors.white24, size: 32),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _statusBadge(bool isActive) {
    final color = isActive ? const Color(0xFF10B981) : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ── Bottom Sheets for Details ─────────────────────────────────────────────
  void _showServiceCenterDetailsBottomSheet(BuildContext context, AppState appState, Map<String, dynamic> data) {
    final name = data['serviceCenterName'] as String? ?? 'Service Station';
    final address = data['address'] as String? ?? 'Address';
    final phone = data['phoneNumber'] as String? ?? '';
    final photoUrl = data['photoUrl'] as String?;
    final types = List<String>.from(data['types'] ?? []);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (photoUrl != null && photoUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    photoUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                name,
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      address,
                      style: TextStyle(color: context.textColor54, fontSize: 13),
                    ),
                  ),
                ],
              ),
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.phone_rounded, color: const Color(0xFF10B981), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      phone,
                      style: TextStyle(color: context.textColor54, fontSize: 13),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Text(
                'SERVICED VEHICLES',
                style: TextStyle(
                  color: context.textColor30,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: types.map((type) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF536DFE).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF536DFE).withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      type,
                      style: const TextStyle(
                        color: Color(0xFF536DFE),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showAdDetailsBottomSheet(BuildContext context, Map<String, dynamic> data) {
    final title = data['title'] as String? ?? 'Ad Banner';
    final desc = data['desc'] as String? ?? '';
    final photoUrl = data['photoUrl'] as String?;
    final phone = data['phoneNumber'] as String? ?? '';
    final address = data['address'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.isDarkMode ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (photoUrl != null && photoUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    photoUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                title,
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                desc,
                style: TextStyle(
                  color: context.textColor70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              if (address.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        address,
                        style: TextStyle(color: context.textColor54, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.phone_rounded, color: const Color(0xFF10B981), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      phone,
                      style: TextStyle(color: context.textColor54, fontSize: 13),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
