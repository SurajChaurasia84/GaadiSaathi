import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_state.dart';
import '../../models/vehicle.dart';
import '../chat_screen.dart';
import '../../widgets/cached_user_avatar.dart';

class ShopDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const ShopDetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final photoUrl = data['photoUrl'] as String?;
    final shopName = data['shopName'] as String? ?? 'Shop Details';
    final ownerName = data['ownerName'] as String? ?? 'Owner Name';
    final ownerGmail = data['ownerGmail'] as String? ?? '';
    final lat = data['latitude'] as double? ?? 0.0;
    final lon = data['longitude'] as double? ?? 0.0;
    final phone = data['phoneNumber'] as String? ?? '';
    final address = data['address'] as String? ?? 'Address';
    final priceVal = data['price'];
    
    String price = '';
    if (priceVal != null) {
      if (priceVal is num) {
        price = priceVal % 1 == 0 ? priceVal.toInt().toString() : priceVal.toString();
      } else {
        price = priceVal.toString();
      }
    }
    
    final distance = appState.getDistanceFromUser(lat, lon);
    final initial = ownerName.isNotEmpty ? ownerName[0].toUpperCase() : '?';

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
                                Icons.storefront_rounded,
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
                                shopName,
                                style: TextStyle(
                                  color: context.textColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                              if (price.isNotEmpty && price != '0' && price != '0.0') ...[
                                const SizedBox(height: 6),
                                Text(
                                  '₹$price',
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
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
                    _buildSectionDivider(context),
                    const SizedBox(height: 16),

                    // Owner Card Section
                    Text(
                      'POSTED BY',
                      style: TextStyle(
                        color: context.textColor30,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: context.isDarkMode
                              ? const Color(0x0AFFFFFF)
                              : const Color(0x08000000),
                        ),
                      ),
                      child: Row(
                        children: [
                           CachedUserAvatar(
                             email: ownerGmail,
                             radius: 24,
                             fallbackInitial: initial,
                             textStyle: const TextStyle(
                               color: Color(0xFF536DFE),
                               fontWeight: FontWeight.bold,
                               fontSize: 16,
                             ),
                           ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ownerName,
                                  style: TextStyle(
                                    color: context.textColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  shopName,
                                  style: TextStyle(
                                    color: context.textColor54,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Information details
                    Text(
                      'POST DETAILS',
                      style: TextStyle(
                        color: context.textColor30,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      context,
                      icon: Icons.location_on_rounded,
                      iconColor: const Color(0xFFEF4444),
                      title: 'Location / Address',
                      value: address,
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
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      icon: Icons.phone_android_rounded,
                      iconColor: const Color(0xFF10B981),
                      title: 'Phone / Mobile',
                      value: phone.isNotEmpty ? phone : 'Not Provided',
                    ),
                  ]),
                ),
              ),
            ],
          ),
          // Premium Bottom Sticky Button Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Call Button
                    if (phone.isNotEmpty) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final Uri launchUri = Uri(
                              scheme: 'tel',
                              path: phone,
                            );
                            if (await canLaunchUrl(launchUri)) {
                              await launchUrl(launchUri);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.phone_rounded, size: 20),
                          label: const Text(
                            'Call Now',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    // Chat Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final dummyVehicle = Vehicle(
                            id: data['id'] as String? ?? 'shop',
                            ownerName: ownerName,
                            ownerGmail: ownerGmail,
                            type: VehicleType.car,
                            model: shopName,
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                        label: const Text(
                          'Chat',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDivider(BuildContext context) {
    return Divider(
      height: 1,
      color: context.isDarkMode
          ? const Color(0x0AFFFFFF)
          : const Color(0x08000000),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.isDarkMode
                ? const Color(0x0AFFFFFF)
                : const Color(0x08000000),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.textColor54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: context.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
