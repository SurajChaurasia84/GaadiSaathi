import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/vehicle.dart';
import '../providers/app_state.dart';
import '../screens/customer/vehicle_detail_screen.dart';

class VehicleCard extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleCard({super.key, required this.vehicle});

  @override
  State<VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends State<VehicleCard> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _reviewsStream;

  @override
  void initState() {
    super.initState();
    _reviewsStream = FirebaseFirestore.instance
        .collection('vehicles')
        .doc(widget.vehicle.id)
        .collection('reviews')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final distance = appState.getDistanceFromUser(widget.vehicle.latitude, widget.vehicle.longitude);
    final isDark = context.isDarkMode;

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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.isDarkMode ? const Color(0x11FFFFFF) : const Color(0x0A000000), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VehicleDetailScreen(vehicle: widget.vehicle),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Vehicle Image Header
            Stack(
              children: [
                _buildVehicleImage(
                  widget.vehicle.outsidePhotoUrl,
                  height: 150,
                  width: double.infinity,
                ),
                // Gradient Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Theme.of(context).cardColor.withValues(alpha: 0.9),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Distance Pill
                Positioned(
                  top: 12,
                  left: 12,
                  child: GestureDetector(
                    onTap: () async {
                      final lat = widget.vehicle.latitude;
                      final lng = widget.vehicle.longitude;
                      final address = widget.vehicle.address;
                      Uri uri;
                      if (lat != 0.0 || lng != 0.0) {
                        uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
                      } else if (address != null && address.isNotEmpty) {
                        uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}");
                      } else {
                        return;
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
                        color: const Color(0xCC0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0x33FFFFFF)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${distance.toStringAsFixed(1)} Km away',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Category Tag
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: typeColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(typeIcon, color: typeColor, size: 12),
                        const SizedBox(width: 4),
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
                ),
              ],
            ),
            // Info Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _reviewsStream,
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? [];
                      double averageRating = 0.0;
                      int reviewCount = docs.length;

                      if (reviewCount > 0) {
                        double totalRating = 0.0;
                        for (var doc in docs) {
                          totalRating += (doc.data()['rating'] as num?)?.toDouble() ?? 0.0;
                        }
                        averageRating = totalRating / reviewCount;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.vehicle.model,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: context.textColor,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (reviewCount > 0)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      averageRating.toStringAsFixed(1),
                                      style: TextStyle(
                                        color: context.textColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    _buildStarRow(averageRating, size: 12),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(Icons.person, color: context.textColor54, size: 14),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Owner: ${widget.vehicle.ownerName}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: context.textColor54,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (reviewCount > 0) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '($reviewCount reviews)',
                                  style: TextStyle(
                                    color: context.textColor54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Divider(color: context.isDarkMode ? const Color(0x11FFFFFF) : const Color(0x0A000000), height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RENTAL RATE',
                            style: TextStyle(
                              color: context.textColor30,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              const Text(
                                '₹',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.vehicle.ratePerKm.toStringAsFixed(1),
                                style: TextStyle(
                                  color: context.textColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                ' / Km',
                                style: TextStyle(
                                  color: context.textColor54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VehicleDetailScreen(vehicle: widget.vehicle),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF536DFE),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Details',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleImage(String url, {required double height, double? width, BoxFit fit = BoxFit.cover}) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildErrorImage(height),
      );
    } else {
      return Image.file(
        File(url),
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildErrorImage(height),
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

  Widget _buildStarRow(double rating, {double size = 20, Color color = Colors.amber}) {
    List<Widget> stars = [];
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    for (int i = 1; i <= 5; i++) {
      if (i <= fullStars) {
        stars.add(Icon(Icons.star_rounded, color: color, size: size));
      } else if (i == fullStars + 1 && hasHalfStar) {
        stars.add(Icon(Icons.star_half_rounded, color: color, size: size));
      } else {
        stars.add(Icon(Icons.star_border_rounded, color: color.withValues(alpha: 0.3), size: size));
      }
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: stars,
    );
  }
}
