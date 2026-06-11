import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/vehicle.dart';
import '../../providers/app_state.dart';
import '../chat_screen.dart';

class VehicleDetailScreen extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  bool _showingOutside = true;

  Future<void> _navigateToLocation(BuildContext context) async {
    final double lat = widget.vehicle.latitude;
    final double lng = widget.vehicle.longitude;
    final String? address = widget.vehicle.address;

    Uri uri;
    if (lat != 0.0 || lng != 0.0) {
      uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    } else if (address != null && address.isNotEmpty) {
      uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not available'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open maps: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showCallWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
              SizedBox(width: 8),
              Text(
                'Call Owner?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to call the owner? Please discuss terms and booking requirements carefully.',
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
                Navigator.pop(dialogContext);
                _makePhoneCall(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Call'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _makePhoneCall(BuildContext context) async {
    final String? phone = widget.vehicle.phoneNumber;
    if (phone == null || phone.isEmpty) return;

    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phone,
    );

    try {
      await launchUrl(phoneUri);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch dialer for $phone: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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
              child: _buildVehicleImage(
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

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final distance = appState.getDistanceFromUser(widget.vehicle.latitude, widget.vehicle.longitude);

    Color typeColor;
    IconData typeIcon;
    switch (widget.vehicle.type) {
      case VehicleType.car:
        typeColor = const Color(0xFF3B82F6);
        typeIcon = Icons.directions_car_rounded;
        break;
      case VehicleType.eRickshaw:
        typeColor = const Color(0xFFF59E0B);
        typeIcon = Icons.electric_rickshaw_rounded;
        break;
      case VehicleType.loading:
        typeColor = const Color(0xFF8B5CF6);
        typeIcon = Icons.local_shipping_rounded;
        break;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Elegant Header Image Section with Switchable Inside/Outside photos
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            leading: CircleAvatar(
              backgroundColor: const Color(0x66000000),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                   GestureDetector(
                     onTap: () {
                       _openFullScreenImage(
                         context,
                         _showingOutside ? widget.vehicle.outsidePhotoUrl : widget.vehicle.insidePhotoUrl,
                       );
                     },
                     child: _buildVehicleImage(
                       _showingOutside ? widget.vehicle.outsidePhotoUrl : widget.vehicle.insidePhotoUrl,
                       fit: BoxFit.cover,
                     ),
                   ),
                  // Dark shadow overlay at bottom
                  IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Theme.of(context).scaffoldBackgroundColor,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Photo Inside/Outside Picker overlay
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPhotoToggleBtn(
                          label: 'Outside View',
                          isSelected: _showingOutside,
                          onTap: () => setState(() => _showingOutside = true),
                        ),
                        const SizedBox(width: 12),
                        _buildPhotoToggleBtn(
                          label: 'Inside View',
                          isSelected: !_showingOutside,
                          onTap: () => setState(() => _showingOutside = false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content body details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Type Badge & Distance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: typeColor.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(typeIcon, color: typeColor, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              widget.vehicle.type.displayName,
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: widget.vehicle.isServiceOn ? const Color(0xFF10B981) : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.vehicle.isServiceOn ? 'Available' : 'Unavailable',
                            style: TextStyle(
                              color: widget.vehicle.isServiceOn ? const Color(0xFF10B981) : Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Vehicle Model Title
                  Text(
                    widget.vehicle.model,
                    style: TextStyle(
                      color: context.textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Owner Details Row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .where('email', isEqualTo: widget.vehicle.ownerGmail)
                              .limit(1)
                              .snapshots(),
                          builder: (context, snapshot) {
                            String? photoUrl;
                            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                              final data = snapshot.data!.docs.first.data();
                              photoUrl = data['photoUrl'] as String?;
                            }

                            final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
                            return CircleAvatar(
                              backgroundColor: const Color(0xFF536DFE),
                              backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                              child: hasPhoto
                                  ? null
                                  : Text(
                                      widget.vehicle.ownerName[0].toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.vehicle.ownerName,
                                style: TextStyle(
                                  color: context.textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              InkWell(
                                onTap: () => _navigateToLocation(context),
                                child: Text(
                                  '${(widget.vehicle.address != null && widget.vehicle.address!.isNotEmpty) ? widget.vehicle.address! : 'Location not specified'} • ${distance.toStringAsFixed(1)} Km away',
                                  style: TextStyle(
                                    color: context.textColor54,
                                    fontSize: 12,
                                  ),
                                ),
                              ),

                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Rate display card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VERIFIED VEHICLE RATE',
                              style: TextStyle(
                                color: context.textColor30,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Set directly by Owner',
                              style: TextStyle(
                                color: context.textColor54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Text(
                              '₹',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.vehicle.ratePerKm.toStringAsFixed(1),
                              style: TextStyle(
                                color: context.textColor,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '/Km',
                              style: TextStyle(
                                color: context.textColor54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Requirement specific note: ₹0 booking charge!
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0x1A10B981),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x3310B981)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Note: ₹0 Booking Charge. Pay only for vehicle usage.',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Chat to Book Action Button & Call Button Row or Self warning
                  if (widget.vehicle.ownerGmail == appState.currentGmail) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Colors.orangeAccent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Self-messaging/calling is not allowed.',
                              style: TextStyle(
                                color: context.textColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final thread = appState.getOrCreateThread(widget.vehicle);
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 5,
                              shadowColor: const Color(0xFF536DFE).withValues(alpha: 0.3),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline_rounded),
                                SizedBox(width: 10),
                                Text(
                                  'Chat to Book',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (widget.vehicle.phoneNumber != null && widget.vehicle.phoneNumber!.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => _showCallWarningDialog(context),
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.phone_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoToggleBtn({required String label, required bool isSelected, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xAA0F172A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF536DFE) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleImage(String url, {required BoxFit fit, double? height, double? width}) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildErrorImage(height ?? 280),
      );
    } else {
      return Image.file(
        File(url),
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildErrorImage(height ?? 280),
      );
    }
  }

  Widget _buildErrorImage(double height) {
    return Container(
      height: height,
      color: const Color(0xFF0F172A),
      child: const Center(
        child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
      ),
    );
  }
}
