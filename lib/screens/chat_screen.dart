import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/chat.dart';
import '../providers/app_state.dart';

class ChatScreen extends StatefulWidget {
  final String threadId;

  const ChatScreen({super.key, required this.threadId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isRetrievingLocation = false;
  String? _selectedImagePath;
  int _messageCount = 0;

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty && _selectedImagePath == null) return;

    final appState = Provider.of<AppState>(context, listen: false);

    if (_selectedImagePath != null) {
      final imagePath = _selectedImagePath!;
      setState(() {
        _selectedImagePath = null;
      });
      _msgController.clear();
      _scrollToBottom();

      final msgId = await appState.sendChatMessage(widget.threadId, 'local_image:$imagePath');
      _uploadImageInBackground(msgId, imagePath);
    } else {
      appState.sendChatMessage(widget.threadId, text);
      _msgController.clear();
      _scrollToBottom();
      setState(() {});
    }
  }

  void _sendBookingProposal(double rate) {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.sendChatMessage(
      widget.threadId,
      'I am proposing a booking for my vehicle at the official rate of ₹${rate.toStringAsFixed(1)}/Km.',
      isBookingProposal: true,
      ratePerKm: rate,
    );
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        _selectedImagePath = image.path;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _uploadImageInBackground(String msgId, String imagePath) async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final imageUrl = await appState.uploadToCloudinary(imagePath);

      if (imageUrl != null) {
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.threadId)
            .collection('messages')
            .doc(msgId)
            .update({'text': imageUrl});
      } else {
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.threadId)
            .collection('messages')
            .doc(msgId)
            .update({'text': 'local_image_failed:$imagePath'});
      }
    } catch (e) {
      debugPrint('Error uploading in background: $e');
      try {
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.threadId)
            .collection('messages')
            .doc(msgId)
            .update({'text': 'local_image_failed:$imagePath'});
      } catch (_) {}
    }
  }

  Future<void> _sendLocation() async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.customerLatitude != 0.0 && appState.customerLongitude != 0.0) {
        final mapsUrl = 'https://www.google.com/maps/search/?api=1&query=${appState.customerLatitude},${appState.customerLongitude}';
        if (mounted) {
          setState(() {
            _msgController.text = mapsUrl;
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied.')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are permanently denied.')),
          );
        }
        return;
      }

      setState(() {
        _isRetrievingLocation = true;
      });

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final mapsUrl = 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
      
      if (mounted) {
        setState(() {
          _msgController.text = mapsUrl;
          _isRetrievingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRetrievingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error retrieving location: $e')),
        );
      }
    }
  }

  Future<void> _makeCall(String partnerEmail) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: partnerEmail)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        final String? phone = data['phone'] as String?;
        if (phone != null && phone.trim().isNotEmpty) {
          final Uri phoneUri = Uri(scheme: 'tel', path: phone.trim());
          if (await canLaunchUrl(phoneUri)) {
            await launchUrl(phoneUri);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Could not open dialer app.'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Contact number not available.'),
                backgroundColor: Colors.orangeAccent,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contact number not available.'),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking contact: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final threadIndex = appState.chatThreads.indexWhere((t) => t.threadId == widget.threadId);

    if (threadIndex < 0) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: context.textColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF536DFE),
          ),
        ),
      );
    }

    final thread = appState.chatThreads[threadIndex];
    final isOwner = appState.currentGmail == thread.ownerGmail;
    final chatPartnerName = isOwner ? thread.customerName : thread.ownerName;
    final messages = thread.messages;

    // Mark messages in this thread as read
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appState.markThreadAsRead(widget.threadId);
    });

    // Trigger auto-scroll when new messages arrive
    if (messages.length != _messageCount) {
      _messageCount = messages.length;
      _scrollToBottom();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 2,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('email', isEqualTo: isOwner ? thread.customerGmail : thread.ownerGmail)
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
                  radius: 18,
                  backgroundColor: const Color(0xFF10B981),
                  backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                  child: hasPhoto
                      ? null
                      : Text(
                          chatPartnerName.isNotEmpty ? chatPartnerName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                );
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chatPartnerName,
                    style: TextStyle(color: context.textColor, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Vehicle: ${thread.vehicleModel}',
                    style: TextStyle(color: context.textColor54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.phone_rounded, color: context.textColor),
            tooltip: 'Call User',
            onPressed: () => _makeCall(isOwner ? thread.customerGmail : thread.ownerGmail),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top warning/info banner: "₹0 Booking Fee!"
            Container(
              color: context.isDarkMode ? const Color(0xFF1B2C24) : const Color(0xFFE6F4EA),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 14),
                  SizedBox(width: 8),
                  Text(
                    'Note: ₹0 Booking Charge. Deal directly with the owner.',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg.senderId == appState.currentGmail;

                  final bool showDateHeader = index == 0 ||
                      !_isSameDay(messages[index - 1].timestamp, msg.timestamp);

                  Widget bubble;
                  if (msg.isBookingProposal) {
                    bubble = _buildBookingProposalCard(context, appState, msg, index, isOwner);
                  } else {
                    bubble = _buildNormalMessageBubble(msg, isMe);
                  }

                  if (showDateHeader) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDateHeaderWidget(msg.timestamp),
                        bubble,
                      ],
                    );
                  }

                  return bubble;
                },
              ),
            ),

            // Quick Actions Panel
            if (thread.messages.isEmpty)
              _buildQuickActions(appState, thread),

            // Text Input Box
            _buildTextInputPanel(),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);

    if (msgDate == today) {
      return 'Today';
    } else if (msgDate == yesterday) {
      return 'Yesterday';
    } else {
      final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }

  Widget _buildDateHeaderWidget(DateTime date) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? const Color(0x1AFFFFFF)
              : const Color(0x0F000000),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          _formatDateHeader(date),
          style: TextStyle(
            color: context.textColor54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildNormalMessageBubble(ChatMessage msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF536DFE) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMessageContent(msg, isMe),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: isMe ? Colors.white.withValues(alpha: 0.6) : context.textColor54,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage msg, bool isMe) {
    final text = msg.text;
    if (text.startsWith('local_image:')) {
      final path = text.substring('local_image:'.length);
      if (isMe) {
        return GestureDetector(
          onTap: () => _openImagePreview(context, path, isLocal: true),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.file(
                  File(path),
                  width: 200,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 200,
                      height: 150,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    );
                  },
                ),
                Container(
                  width: 200,
                  height: 150,
                  color: Colors.black26,
                ),
                const CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),
        );
      } else {
        return Container(
          width: 200,
          height: 150,
          decoration: BoxDecoration(
            color: context.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF536DFE)),
                SizedBox(height: 10),
                Text(
                  'Receiving image...',
                  style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        );
      }
    } else if (text.startsWith('local_image_failed:')) {
      final path = text.substring('local_image_failed:'.length);
      if (isMe) {
        return GestureDetector(
          onTap: () => _openImagePreview(context, path, isLocal: true),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.file(
                  File(path),
                  width: 200,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 200,
                      height: 150,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    );
                  },
                ),
                Container(
                  width: 200,
                  height: 150,
                  color: Colors.black45,
                ),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 28),
                    SizedBox(height: 6),
                    Text(
                      'Failed to upload',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      } else {
        return Container(
          width: 200,
          height: 150,
          decoration: BoxDecoration(
            color: context.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image_outlined, color: Colors.grey, size: 28),
                SizedBox(height: 6),
                Text(
                  'Failed to receive image',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        );
      }
    } else if (text.startsWith('http') && (text.contains('cloudinary.com') || text.contains('.jpg') || text.contains('.png') || text.contains('.jpeg') || text.contains('.gif') || text.contains('.webp'))) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _openImagePreview(context, text, isLocal: false),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: text,
                width: 200,
                height: 150,
                fit: BoxFit.cover,
                placeholder: (context, url) => const SizedBox(
                  width: 200,
                  height: 150,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                  ),
                ),
                errorWidget: (context, url, error) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Image failed to load', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (text.startsWith('https://www.google.com/maps/search/?api=1&query=')) {
      return GestureDetector(
        onTap: () async {
          final uri = Uri.parse(text);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: _LocationBubbleContent(mapsUrl: text, isMe: isMe),
      );
    } else {
      return Text(
        text,
        style: TextStyle(color: isMe ? Colors.white : context.textColor, fontSize: 14),
      );
    }
  }

  Widget _buildBookingProposalCard(
    BuildContext context,
    AppState appState,
    ChatMessage msg,
    int msgIndex,
    bool isOwner,
  ) {
    final status = msg.bookingStatus ?? BookingStatus.pending;
    final rate = msg.ratePerKm ?? 10.0;

    Color statusColor;
    String statusText;
    switch (status) {
      case BookingStatus.pending:
        statusColor = Colors.orange;
        statusText = 'Pending Confirmation';
        break;
      case BookingStatus.confirmed:
        statusColor = const Color(0xFF10B981);
        statusText = 'Booking Confirmed';
        break;
      case BookingStatus.cancelled:
        statusColor = const Color(0xFFEF4444);
        statusText = 'Declined';
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF131C30) : const Color(0xFFEEF2F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x33536DFE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF536DFE).withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.event_note_rounded, color: Color(0xFF536DFE), size: 20),
              const SizedBox(width: 8),
              Text(
                'BOOKING INVOICE PROPOSAL',
                style: TextStyle(
                  color: context.textColor70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Calculated Rate:', style: TextStyle(color: context.textColor54, fontSize: 13)),
              Text(
                '₹${rate.toStringAsFixed(1)} / Km',
                style: TextStyle(color: context.textColor, fontWeight: FontWeight.w900, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Platform Booking Fee:', style: TextStyle(color: context.textColor54, fontSize: 13)),
              const Text(
                '₹0.0 (Free)',
                style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0x11FFFFFF), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Booking Status:', style: TextStyle(color: context.textColor54, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  statusText.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Show action buttons if status is pending
          if (status == BookingStatus.pending) ...[
            if (!isOwner) ...[
              // Customer can accept/decline owner's proposal
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        appState.updateBookingStatus(widget.threadId, msgIndex, BookingStatus.cancelled);
                        appState.sendChatMessage(widget.threadId, 'Declined the booking proposal.');
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Decline', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        appState.updateBookingStatus(widget.threadId, msgIndex, BookingStatus.confirmed);
                        appState.sendChatMessage(
                          widget.threadId,
                          '🎉 Confirmed! I have booked the vehicle at ₹${rate.toStringAsFixed(1)}/Km.',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Confirm Booking', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ] else ...[
              Center(
                child: Text(
                  'Waiting for Customer Response...',
                  style: TextStyle(color: context.textColor30, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ]
          ] else if (status == BookingStatus.confirmed) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Trip Booking Scheduled Successfully!',
                    style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            )
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Proposal Declined',
                    style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildQuickActions(AppState appState, ChatThread thread) {
    final isOwner = appState.currentGmail == thread.ownerGmail;

    // Fetch the rate from the owner's vehicle
    double activeRate = 12.0;
    if (isOwner && appState.ownerVehicle != null) {
      activeRate = appState.ownerVehicle!.ratePerKm;
    } else {
      // Find the vehicle rate by owner name
      final match = appState.filteredVehicles.where((v) => v.ownerGmail == thread.ownerGmail);
      if (match.isNotEmpty) {
        activeRate = match.first.ratePerKm;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (isOwner) ...[
              _buildQuickActionChip(
                label: 'Propose Booking at ₹${activeRate.toStringAsFixed(1)}/Km',
                icon: Icons.assignment_turned_in_rounded,
                onTap: () => _sendBookingProposal(activeRate),
              ),
              const SizedBox(width: 8),
              _buildQuickActionChip(
                label: 'Where are you now?',
                icon: Icons.question_mark_rounded,
                onTap: () {
                  _msgController.text = 'Where is your pickup location right now?';
                  _sendMessage();
                },
              ),
            ] else ...[
              _buildQuickActionChip(
                label: 'Confirm Booking Request',
                icon: Icons.directions_rounded,
                onTap: () {
                  _msgController.text = 'I want to book the vehicle. Please propose the rate.';
                  _sendMessage();
                },
              ),
              const SizedBox(width: 8),
              _buildQuickActionChip(
                label: 'Are you available?',
                icon: Icons.check_rounded,
                onTap: () {
                  _msgController.text = 'Hi! Is the vehicle available for booking right now?';
                  _sendMessage();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionChip({required String label, required IconData icon, required VoidCallback onTap}) {
    return ActionChip(
      avatar: Icon(icon, size: 13, color: context.textColor70),
      label: Text(label, style: TextStyle(color: context.textColor70, fontSize: 11)),
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      onPressed: onTap,
    );
  }

  Widget _buildTextInputPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: context.isDarkMode ? const Color(0x11FFFFFF) : const Color(0x0A000000))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedImagePath != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_selectedImagePath!),
                          height: 70,
                          width: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImagePath = null;
                            });
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Image selected. Tap send to share.',
                      style: TextStyle(
                        color: context.textColor54,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgController,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (text) {
                    setState(() {});
                  },
                  onSubmitted: (_) => _sendMessage(),
                  style: TextStyle(color: context.textColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(color: context.textColor30),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Color(0xFF536DFE)),
                    ),
                    suffixIcon: _msgController.text.isNotEmpty
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(Icons.image_outlined, color: context.textColor54, size: 20),
                                onPressed: _pickImage,
                              ),
                              // const SizedBox(width: 6),
                              _isRetrievingLocation
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                        color: context.textColor54,
                                      ),
                                    )
                                  : IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: Icon(Icons.location_on_outlined, color: context.textColor54, size: 20),
                                      onPressed: _sendLocation,
                                    ),
                              const SizedBox(width: 5),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF536DFE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openImagePreview(BuildContext context, String url, {bool isLocal = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenImagePreview(
          imageUrl: url,
          isLocal: isLocal,
        ),
      ),
    );
  }
}

class _LocationBubbleContent extends StatefulWidget {
  final String mapsUrl;
  final bool isMe;

  const _LocationBubbleContent({
    required this.mapsUrl,
    required this.isMe,
  });

  @override
  State<_LocationBubbleContent> createState() => _LocationBubbleContentState();
}

class _LocationBubbleContentState extends State<_LocationBubbleContent> {
  static final Map<String, String> _addressCache = {};
  String _address = 'Loading location...';

  @override
  void initState() {
    super.initState();
    _resolveAddress();
  }

  Future<void> _resolveAddress() async {
    if (_addressCache.containsKey(widget.mapsUrl)) {
      if (mounted) {
        setState(() {
          _address = _addressCache[widget.mapsUrl]!;
        });
      }
      return;
    }

    try {
      final uri = Uri.tryParse(widget.mapsUrl);
      if (uri != null) {
        final query = uri.queryParameters['query'];
        if (query != null) {
          final parts = query.split(',');
          if (parts.length == 2) {
            final lat = double.tryParse(parts[0]);
            final lng = double.tryParse(parts[1]);
            if (lat != null && lng != null) {
              final placemarks = await placemarkFromCoordinates(lat, lng);
              if (placemarks.isNotEmpty) {
                final place = placemarks.first;
                final partsList = <String>[];
                if (place.subLocality != null && place.subLocality!.isNotEmpty) {
                  partsList.add(place.subLocality!);
                }
                if (place.locality != null && place.locality!.isNotEmpty) {
                  partsList.add(place.locality!);
                }
                if (partsList.isEmpty) {
                  if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
                    partsList.add(place.administrativeArea!);
                  } else if (place.country != null && place.country!.isNotEmpty) {
                    partsList.add(place.country!);
                  }
                }
                
                final addressStr = partsList.isNotEmpty ? partsList.join(', ') : 'Location Shared';
                _addressCache[widget.mapsUrl] = addressStr;
                if (mounted) {
                  setState(() {
                    _address = addressStr;
                  });
                }
                return;
              }
            }
          }
        }
      }
    } catch (_) {
      // Fallback
    }

    if (mounted) {
      setState(() {
        _address = 'Location Shared';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.isMe;
    final primaryColor = isMe ? Colors.white : const Color(0xFF536DFE);
    final secondaryColor = isMe ? Colors.white.withValues(alpha: 0.7) : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_rounded,
              color: primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          widget.mapsUrl,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: secondaryColor,
            fontSize: 11,
            decoration: TextDecoration.underline,
          ),
        ),
      ],
    );
  }
}

class _FullScreenImagePreview extends StatelessWidget {
  final String imageUrl;
  final bool isLocal;

  const _FullScreenImagePreview({
    required this.imageUrl,
    this.isLocal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: isLocal
                  ? Image.file(
                      File(imageUrl),
                      fit: BoxFit.contain,
                    )
                  : CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
                      errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white, size: 50),
                    ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
