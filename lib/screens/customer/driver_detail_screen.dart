import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_state.dart';
import '../../models/vehicle.dart';
import '../chat_screen.dart';
import '../../widgets/cached_user_avatar.dart';

class DriverDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const DriverDetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final selfieUrl = data['selfieUrl'] as String?;
    final licensePhotoUrl = data['licensePhotoUrl'] as String?;
    final photoUrl = selfieUrl ?? licensePhotoUrl;
    final driverName = data['driverName'] as String? ?? 'Driver Details';
    final phone = data['phoneNumber'] as String? ?? '';
    final address = data['address'] as String? ?? 'Address';
    final experienceVal = data['experience'];
    final experience = experienceVal != null ? '$experienceVal Years' : 'N/A';
    final driverGmail = data['driverGmail'] as String? ?? '';
    final lat = data['latitude'] as double? ?? 0.0;
    final lon = data['longitude'] as double? ?? 0.0;

    final distance = appState.getDistanceFromUser(lat, lon);
    final initial = driverName.isNotEmpty ? driverName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Premium Hero Image Header
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                stretch: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                  if (driverGmail == appState.currentGmail)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                        color: Theme.of(context).cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (value) {
                          if (value == 'delete') {
                            _showDeleteConfirmationDialog(context, data['id'] as String);
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 18),
                                const SizedBox(width: 8),
                                const Text('Delete', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      photoUrl != null && photoUrl.isNotEmpty
                          ? GestureDetector(
                              onTap: () => _openFullScreenImage(context, photoUrl),
                              child: Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              color: context.isDarkMode
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF1F5F9),
                              child: const Icon(
                                Icons.badge_rounded,
                                size: 80,
                                color: Color(0xFF536DFE),
                              ),
                            ),
                      // Top shadow overlay for text readability
                      const IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black38,
                                Colors.transparent,
                                Colors.black54,
                              ],
                              stops: [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Post Details
              SliverPadding(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 24,
                  bottom: 100, // extra padding for bottom sticky panel
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Title and Distance Badge Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                driverName,
                                style: TextStyle(
                                  color: context.textColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () async {
                            Uri uri;
                            if (lat != 0.0 || lon != 0.0) {
                              uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lon");
                            } else {
                              uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}");
                            }
                            try {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } catch (e) {
                              debugPrint(e.toString());
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF536DFE).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${distance.toStringAsFixed(1)} Km',
                              style: const TextStyle(
                                color: Color(0xFF536DFE),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: context.isDarkMode ? const Color(0x0AFFFFFF) : const Color(0x08000000), height: 1),
                    const SizedBox(height: 16),

                    // Address / Location Row
                    GestureDetector(
                      onTap: () async {
                        Uri uri;
                        if (lat != 0.0 || lon != 0.0) {
                          uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lon");
                        } else {
                          uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}");
                        }
                        try {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (_) {}
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Address / Location',
                                  style: TextStyle(
                                    color: context.textColor54,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  address,
                                  style: TextStyle(
                                    color: context.textColor,
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: context.isDarkMode ? const Color(0x0AFFFFFF) : const Color(0x08000000), height: 1),
                    const SizedBox(height: 16),

                    // Experience Section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.workspace_premium_rounded, color: Color(0xFF10B981), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Experience',
                                style: TextStyle(
                                  color: context.textColor54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                experience,
                                style: TextStyle(
                                  color: context.textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: context.isDarkMode ? const Color(0x0AFFFFFF) : const Color(0x08000000), height: 1),
                    const SizedBox(height: 16),

                    // Driving License Photo Section (if available)
                    if (licensePhotoUrl != null && licensePhotoUrl.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.badge_rounded, color: Color(0xFF536DFE), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Driving License',
                                  style: TextStyle(
                                    color: context.textColor54,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                GestureDetector(
                                  onTap: () => _openFullScreenImage(context, licensePhotoUrl),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      licensePhotoUrl,
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Divider(color: context.isDarkMode ? const Color(0x0AFFFFFF) : const Color(0x08000000), height: 1),
                      const SizedBox(height: 16),
                    ],

                    // Owner Profile Info Row
                    Row(
                      children: [
                        CachedUserAvatar(
                          email: driverGmail,
                          radius: 20,
                          fallbackInitial: initial,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driverName,
                                style: TextStyle(
                                  color: context.textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                phone,
                                style: TextStyle(
                                  color: context.textColor54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ]),
                ),
              ),
            ],
          ),

          // Sticky Bottom Actions Panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: context.isDarkMode ? const Color(0x0AFFFFFF) : const Color(0x08000000),
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (phone.isNotEmpty)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final Uri launchUri = Uri(
                            scheme: 'tel',
                            path: phone,
                          );
                          await launchUrl(launchUri);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.phone_rounded),
                        label: const Text(
                          'Call Driver',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  if (phone.isNotEmpty && driverGmail != appState.currentGmail)
                    const SizedBox(width: 12),
                  if (driverGmail != appState.currentGmail)
                    Expanded(
                      child: ElevatedButton.icon(
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF536DFE),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: const Text(
                          'Chat',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openFullScreenImage(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(url),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text(
                'Delete Post?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete this driver listing? This action cannot be undone.',
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
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog
                Navigator.pop(context); // Go back to Explore screen
                try {
                  await FirebaseFirestore.instance
                      .collection('drivers')
                      .doc(docId)
                      .delete();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Driver listing deleted successfully.'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete listing: $e'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
