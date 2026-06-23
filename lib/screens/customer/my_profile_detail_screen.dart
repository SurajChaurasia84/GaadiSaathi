import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/app_state.dart';
import '../../models/vehicle.dart';
import 'package:url_launcher/url_launcher.dart';
import '../chat_screen.dart';
import 'vehicle_detail_screen.dart';
import 'edit_profile_screen.dart';

class MyProfileDetailScreen extends StatefulWidget {
  final String? userEmail;
  const MyProfileDetailScreen({super.key, this.userEmail});

  @override
  State<MyProfileDetailScreen> createState() => _MyProfileDetailScreenState();
}

class _MyProfileDetailScreenState extends State<MyProfileDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isMe = widget.userEmail == null || widget.userEmail == appState.currentGmail;
    final targetEmail = widget.userEmail ?? appState.currentGmail ?? '';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: targetEmail)
          .limit(1)
          .snapshots(),
      builder: (context, userSnap) {
        String name = 'Loading...';
        String photoUrl = '';
        String phone = 'No phone added';
        String address = 'No address added';

        if (isMe) {
          name = appState.currentUserName ?? 'Guest User';
          photoUrl = appState.currentUserPhotoUrl ?? '';
          phone = appState.currentUserPhone ?? 'No phone added';
          address = appState.currentUserAddress ?? 'No address added';
        } else if (userSnap.hasData && userSnap.data!.docs.isNotEmpty) {
          final userData = userSnap.data!.docs.first.data();
          name = userData['name'] as String? ?? 'User';
          photoUrl = userData['photoUrl'] as String? ?? '';
          phone = userData['phone'] as String? ?? 'No phone added';
          address = userData['address'] as String? ?? 'No address added';
        }

        final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              targetEmail.isNotEmpty ? targetEmail.split('@').first : 'profile',
              style: TextStyle(
                color: context.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.share_rounded, color: context.textColor),
                onPressed: () {
                  final username = targetEmail.split('@').first;
                  // ignore: deprecated_member_use
                  Share.share(
                    'Check out this profile on GaadiSaathi!\n'
                    'Name: $name\n'
                    'Link: gaadisaathi://profile?u=@$username'
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('vehicles').where('ownerGmail', isEqualTo: targetEmail).snapshots(),
            builder: (context, vehicleSnap) {
              final vehicleCount = vehicleSnap.hasData ? vehicleSnap.data!.docs.length : 0;

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('shops').where('ownerGmail', isEqualTo: targetEmail).snapshots(),
                builder: (context, shopSnap) {
                  final shopCount = shopSnap.hasData ? shopSnap.data!.docs.length : 0;

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('service_centers').where('ownerGmail', isEqualTo: targetEmail).snapshots(),
                    builder: (context, serviceSnap) {
                      final serviceCount = serviceSnap.hasData ? serviceSnap.data!.docs.length : 0;

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('ads').where('ownerGmail', isEqualTo: targetEmail).snapshots(),
                        builder: (context, adSnap) {
                          final adCount = adSnap.hasData ? adSnap.data!.docs.length : 0;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Instagram Profile Header
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Avatar
                                        CircleAvatar(
                                          radius: 40,
                                          backgroundColor: const Color(0xFF536DFE),
                                          backgroundImage: photoUrl.isNotEmpty
                                              ? NetworkImage(photoUrl)
                                              : null,
                                          child: photoUrl.isNotEmpty
                                              ? null
                                              : Text(
                                                  initial,
                                                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                                                ),
                                        ),
                                        const SizedBox(width: 20),
                                        // Stats Row
                                        Expanded(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                                            children: [
                                              _buildStatItem('Vehicles', vehicleCount),
                                              _buildStatItem('Shops', shopCount),
                                              _buildStatItem('Services', serviceCount),
                                              _buildStatItem('Ads', adCount),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    // User Bio Details
                                    Text(
                                      name,
                                      style: TextStyle(
                                        color: context.textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      targetEmail,
                                      style: TextStyle(
                                        color: context.textColor54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.phone_rounded, size: 12, color: context.textColor30),
                                        const SizedBox(width: 6),
                                        Text(
                                          phone,
                                          style: TextStyle(color: context.textColor70, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_rounded, size: 12, color: context.textColor30),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            address,
                                            style: TextStyle(color: context.textColor70, fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    // Edit Profile Button or Call/Chat buttons for other users
                                    if (isMe)
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                              color: context.isDarkMode ? const Color(0x2AFFFFFF) : const Color(0x1F000000),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                          ),
                                          child: Text(
                                            'Edit Profile',
                                            style: TextStyle(
                                              color: context.textColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      Row(
                                        children: [
                                          if (phone.isNotEmpty && phone != 'No phone added')
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
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  elevation: 0,
                                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                                ),
                                                icon: const Icon(Icons.phone_rounded, size: 16),
                                                label: const Text('Call', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                              ),
                                            ),
                                          if (phone.isNotEmpty && phone != 'No phone added') const SizedBox(width: 10),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                final dummyVehicle = Vehicle(
                                                  id: 'profile_chat',
                                                  ownerName: name,
                                                  ownerGmail: targetEmail,
                                                  type: VehicleType.car,
                                                  model: 'Profile Chat',
                                                  insidePhotoUrl: '',
                                                  outsidePhotoUrl: '',
                                                  ratePerKm: 0.0,
                                                  isServiceOn: true,
                                                  latitude: 0.0,
                                                  longitude: 0.0,
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
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                elevation: 0,
                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                              ),
                                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                                              label: const Text('Chat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1, thickness: 0.5),
                              // Tab Bar
                              TabBar(
                                controller: _tabController,
                                indicatorColor: context.textColor,
                                labelColor: const Color(0xFF536DFE),
                                unselectedLabelColor: context.textColor30,
                                tabs: const [
                                  Tab(icon: Icon(Icons.directions_car_filled_outlined, size: 22)),
                                  Tab(icon: Icon(Icons.storefront_outlined, size: 22)),
                                  Tab(icon: Icon(Icons.build_circle_outlined, size: 22)),
                                  Tab(icon: Icon(Icons.featured_play_list_outlined, size: 22)),
                                ],
                              ),
                              const Divider(height: 1, thickness: 0.5),
                              // Tab Views
                              Expanded(
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _buildVehiclesTab(vehicleSnap),
                                    _buildShopsTab(shopSnap),
                                    _buildServicesTab(serviceSnap),
                                    _buildAdsTab(adSnap),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            color: context.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: context.textColor54,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildVehiclesTab(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF536DFE)));
    }
    final docs = snapshot.data!.docs;
    if (docs.isEmpty) {
      return _buildEmptyTabState(Icons.directions_car_filled_outlined, 'No Vehicles', 'Vehicles you register will show up here.');
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final outsidePhotoUrl = data['outsidePhotoUrl'] as String? ?? '';
        final vehicle = Vehicle.fromMap(data, docs[index].id);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VehicleDetailScreen(vehicle: vehicle),
              ),
            );
          },
          child: Container(
            color: context.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            child: outsidePhotoUrl.isNotEmpty
                ? Image.network(outsidePhotoUrl, fit: BoxFit.cover)
                : const Icon(Icons.directions_car_filled_outlined, size: 28, color: Color(0xFF536DFE)),
          ),
        );
      },
    );
  }

  Widget _buildShopsTab(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF536DFE)));
    }
    final docs = snapshot.data!.docs;
    if (docs.isEmpty) {
      return _buildEmptyTabState(Icons.storefront_outlined, 'No Shops', 'Shops you register will show up here.');
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final photoUrl = data['photoUrl'] as String? ?? '';
        final shopName = data['shopName'] as String? ?? 'Shop Name';

        return GestureDetector(
          onTap: () => _showDetailsDialog(shopName, data, photoUrl, isShop: true),
          child: Container(
            color: context.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            child: photoUrl.isNotEmpty
                ? Image.network(photoUrl, fit: BoxFit.cover)
                : const Icon(Icons.storefront_outlined, size: 28, color: Color(0xFF536DFE)),
          ),
        );
      },
    );
  }

  Widget _buildServicesTab(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF536DFE)));
    }
    final docs = snapshot.data!.docs;
    if (docs.isEmpty) {
      return _buildEmptyTabState(Icons.build_circle_outlined, 'No Service Centers', 'Service centers you register will show up here.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final name = data['serviceCenterName'] as String? ?? 'Service Center';
        final address = data['address'] as String? ?? 'Address';
        final phone = data['phoneNumber'] as String? ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Theme.of(context).cardColor,
          elevation: 0,
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0x1A536DFE),
              child: Icon(Icons.build_rounded, color: Color(0xFF536DFE), size: 20),
            ),
            title: Text(name, style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(address, style: TextStyle(color: context.textColor54, fontSize: 12)),
            trailing: phone.isNotEmpty ? Icon(Icons.phone_rounded, color: context.textColor30, size: 18) : null,
          ),
        );
      },
    );
  }

  Widget _buildAdsTab(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF536DFE)));
    }
    final docs = snapshot.data!.docs;
    if (docs.isEmpty) {
      return _buildEmptyTabState(Icons.featured_play_list_outlined, 'No Ads', 'Advertisements you post will show up here.');
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final bannerUrl = data['adPhotoUrl'] as String? ?? '';
        final title = data['title'] as String? ?? 'Ad Banner';

        return GestureDetector(
          onTap: () => _showDetailsDialog(title, data, bannerUrl, isShop: false),
          child: Container(
            color: context.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            child: bannerUrl.isNotEmpty
                ? Image.network(bannerUrl, fit: BoxFit.cover)
                : const Icon(Icons.featured_play_list_outlined, size: 28, color: Color(0xFF536DFE)),
          ),
        );
      },
    );
  }

  Widget _buildEmptyTabState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: context.textColor30, size: 40),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textColor54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailsDialog(String title, Map<String, dynamic> data, String imageUrl, {required bool isShop}) {
    showDialog(
      context: context,
      builder: (context) {
        final address = data['address'] as String? ?? '';
        final phone = data['phoneNumber'] as String? ?? '';
        final desc = data['description'] as String? ?? '';
        final owner = data['ownerName'] as String? ?? '';

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Theme.of(context).cardColor,
          contentPadding: EdgeInsets.zero,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(imageUrl, height: 160, fit: BoxFit.cover),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    if (isShop && owner.isNotEmpty) ...[
                      Text('Owner: $owner', style: TextStyle(color: context.textColor70, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                    ],
                    if (desc.isNotEmpty) ...[
                      Text(desc, style: TextStyle(color: context.textColor70, fontSize: 13)),
                      const SizedBox(height: 12),
                    ],
                    if (address.isNotEmpty) ...[
                      GestureDetector(
                        onTap: () async {
                          final lat = data['latitude'] as double? ?? 0.0;
                          final lon = data['longitude'] as double? ?? 0.0;
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
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                address,
                                style: TextStyle(
                                  color: context.textColor54,
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (phone.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.phone_rounded, color: context.textColor30, size: 16),
                          const SizedBox(width: 8),
                          Text(phone, style: TextStyle(color: context.textColor54, fontSize: 12)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Color(0xFF536DFE), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
