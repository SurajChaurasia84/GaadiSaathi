import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final appState = Provider.of<AppState>(context, listen: false);
    appState.sendChatMessage(widget.threadId, text);
    _msgController.clear();
    _scrollToBottom();
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

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final threadIndex = appState.chatThreads.indexWhere((t) => t.threadId == widget.threadId);

    if (threadIndex < 0) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(child: Text('Chat not found', style: TextStyle(color: context.textColor))),
      );
    }

    final thread = appState.chatThreads[threadIndex];
    final isOwner = appState.currentUserRole == 'Owner';
    final chatPartnerName = isOwner ? thread.customerName : thread.ownerName;
    final messages = thread.messages;

    // Trigger auto-scroll when new messages arrive
    _scrollToBottom();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 2,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
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

                  if (msg.isBookingProposal) {
                    return _buildBookingProposalCard(context, appState, msg, index, isOwner);
                  }

                  return _buildNormalMessageBubble(msg, isMe);
                },
              ),
            ),

            // Quick Actions Panel
            _buildQuickActions(appState, thread),

            // Text Input Box
            _buildTextInputPanel(),
          ],
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
            Text(
              msg.text,
              style: TextStyle(color: isMe ? Colors.white : context.textColor, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: isMe ? Colors.white.withOpacity(0.6) : context.textColor54,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
            color: const Color(0xFF536DFE).withOpacity(0.1),
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
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
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
                          '🎉 Confirmed! I have booked the ride at ₹${rate.toStringAsFixed(1)}/Km.',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Confirm Ride', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
                color: const Color(0xFF10B981).withOpacity(0.1),
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
                color: const Color(0xFFEF4444).withOpacity(0.1),
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
    final isOwner = appState.currentUserRole == 'Owner';

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
                  _msgController.text = 'I want to confirm a ride. Please propose the rate.';
                  _sendMessage();
                },
              ),
              const SizedBox(width: 8),
              _buildQuickActionChip(
                label: 'Are you available?',
                icon: Icons.check_rounded,
                onTap: () {
                  _msgController.text = 'Hi! Are you available for a ride right now?';
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
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgController,
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
    );
  }
}
