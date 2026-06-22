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
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _ownerStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _reviewsStream;

  @override
  void initState() {
    super.initState();
    _ownerStream = FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: widget.vehicle.ownerGmail)
        .limit(1)
        .snapshots();
    _reviewsStream = FirebaseFirestore.instance
        .collection('vehicles')
        .doc(widget.vehicle.id)
        .collection('reviews')
        .snapshots();
  }

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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _ownerStream,
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.vehicle.ownerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: context.textColor54,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹${widget.vehicle.ratePerKm.toStringAsFixed(1)}',
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '/Km',
                              style: TextStyle(
                                color: context.textColor54,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
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

                  // Ratings & Reviews Section
                  const Divider(height: 40, thickness: 1),
                  Text(
                    'Ratings & Reviews',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _reviewsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

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

                      // Sort documents in memory by timestamp descending (newest first)
                      final sortedDocs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(docs);
                      sortedDocs.sort((a, b) {
                        final tsA = a.data()['timestamp'] as int? ?? 0;
                        final tsB = b.data()['timestamp'] as int? ?? 0;
                        return tsB.compareTo(tsA);
                      });

                      final currentGmail = appState.currentGmail;
                      QueryDocumentSnapshot<Map<String, dynamic>>? userReview;
                      if (currentGmail != null && currentGmail.isNotEmpty) {
                        for (var doc in docs) {
                          if (doc.data()['userGmail'] == currentGmail) {
                            userReview = doc;
                            break;
                          }
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildReviewsSummaryCard(averageRating, reviewCount, userReview),
                          const SizedBox(height: 24),
                          _buildReviewsList(sortedDocs),
                        ],
                      );
                    },
                  ),
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

  Widget _buildReviewsSummaryCard(double avgRating, int count, QueryDocumentSnapshot<Map<String, dynamic>>? userReview) {
    final hasReviewed = userReview != null;
    return GestureDetector(
      onTap: () {
        if (hasReviewed) {
          final data = userReview.data();
          _showWriteReviewBottomSheet(
            context,
            existingDocId: userReview.id,
            existingRating: (data['rating'] as num?)?.toInt() ?? 5,
            existingComment: data['comment'] as String? ?? '',
          );
        } else {
          _showWriteReviewBottomSheet(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF536DFE).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  count > 0 ? avgRating.toStringAsFixed(1) : '0.0',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                _buildStarRow(avgRating, size: 16),
                const SizedBox(height: 4),
                Text(
                  '$count reviews',
                  style: TextStyle(
                    color: context.textColor54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasReviewed ? 'Update your review!' : 'Share your feedback!',
                    style: TextStyle(
                      color: context.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasReviewed
                        ? 'Tap here to edit or update your existing review.'
                        : 'Tap here to rate this vehicle and write a review.',
                    style: TextStyle(
                      color: context.textColor54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.textColor30,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsList(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (docs.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.rate_review_outlined, color: context.textColor30, size: 40),
            const SizedBox(height: 12),
            Text(
              'No reviews yet. Be the first to review!',
              style: TextStyle(color: context.textColor54, fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      );
    }

    final appState = Provider.of<AppState>(context, listen: false);
    final currentGmail = appState.currentGmail;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data();
        final reviewerName = data['userName'] as String? ?? 'Anonymous';
        final userGmail = data['userGmail'] as String? ?? '';
        final rating = (data['rating'] as num?)?.toDouble() ?? 5.0;
        final comment = data['comment'] as String? ?? '';
        final docId = docs[index].id;
        final isMyReview = currentGmail != null && currentGmail.isNotEmpty && userGmail == currentGmail;

        DateTime date = DateTime.now();
        final ts = data['timestamp'];
        if (ts is int) {
          date = DateTime.fromMillisecondsSinceEpoch(ts);
        }

        final formattedDate = '${date.day}/${date.month}/${date.year}';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ReviewerAvatar(
                    email: userGmail,
                    fallbackInitial: reviewerName.isNotEmpty ? reviewerName[0].toUpperCase() : '?',
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reviewerName,
                          style: TextStyle(
                            color: context.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            _buildStarRow(rating, size: 12),
                            const SizedBox(width: 8),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                color: context.textColor30,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isMyReview) ...[
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      onPressed: () => _confirmDeleteReview(context, docId),
                    ),
                  ],
                ],
              ),
              if (comment.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  comment,
                  style: TextStyle(
                    color: context.textColor70,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteReview(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text(
                'Delete Review?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete your review? This action cannot be undone.',
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
                Navigator.pop(dialogContext);
                try {
                  await FirebaseFirestore.instance
                      .collection('vehicles')
                      .doc(widget.vehicle.id)
                      .collection('reviews')
                      .doc(docId)
                      .delete();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Review deleted successfully.'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete review: $e'),
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
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showWriteReviewBottomSheet(
    BuildContext context, {
    String? existingDocId,
    int? existingRating,
    String? existingComment,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ReviewInputSheet(
        vehicleId: widget.vehicle.id,
        existingDocId: existingDocId,
        existingRating: existingRating,
        existingComment: existingComment,
      ),
    );
  }
}

class _ReviewInputSheet extends StatefulWidget {
  final String vehicleId;
  final String? existingDocId;
  final int? existingRating;
  final String? existingComment;

  const _ReviewInputSheet({
    required this.vehicleId,
    this.existingDocId,
    this.existingRating,
    this.existingComment,
  });

  @override
  State<_ReviewInputSheet> createState() => _ReviewInputSheetState();
}

class _ReviewInputSheetState extends State<_ReviewInputSheet> {
  int _selectedRating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.existingRating ?? 5;
    _commentController.text = widget.existingComment ?? '';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final comment = _commentController.text.trim();

    final appState = Provider.of<AppState>(context, listen: false);
    final userName = appState.currentUserName ?? 'Anonymous';
    final userGmail = appState.currentGmail ?? 'unknown@gmail.com';

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (widget.existingDocId != null) {
        await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(widget.vehicleId)
            .collection('reviews')
            .doc(widget.existingDocId)
            .update({
          'rating': _selectedRating,
          'comment': comment,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(widget.vehicleId)
            .collection('reviews')
            .add({
          'userName': userName,
          'userGmail': userGmail,
          'rating': _selectedRating,
          'comment': comment,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.existingDocId != null ? 'Edit Your Review' : 'Write a Review',
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return IconButton(
                  iconSize: 36,
                  icon: Icon(
                    starValue <= _selectedRating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedRating = starValue;
                    });
                  },
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _commentController,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(color: context.textColor, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Share details of your experience...',
              hintStyle: TextStyle(color: context.textColor30),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitReview,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF536DFE),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    widget.existingDocId != null ? 'Update Review' : 'Submit Review',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReviewerAvatar extends StatefulWidget {
  final String email;
  final String fallbackInitial;

  const _ReviewerAvatar({required this.email, required this.fallbackInitial});

  @override
  State<_ReviewerAvatar> createState() => _ReviewerAvatarState();
}

class _ReviewerAvatarState extends State<_ReviewerAvatar> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _userStream;

  @override
  void initState() {
    super.initState();
    _userStream = FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: widget.email)
        .limit(1)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.email.isEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: const Color(0xFF536DFE).withValues(alpha: 0.15),
        child: Text(
          widget.fallbackInitial,
          style: const TextStyle(
            color: Color(0xFF536DFE),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _userStream,
      builder: (context, snapshot) {
        String? photoUrl;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final data = snapshot.data!.docs.first.data();
          photoUrl = data['photoUrl'] as String?;
        }

        final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
        return CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFF536DFE).withValues(alpha: 0.15),
          backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
          child: hasPhoto
              ? null
              : Text(
                  widget.fallbackInitial,
                  style: const TextStyle(
                    color: Color(0xFF536DFE),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
        );
      },
    );
  }
}
