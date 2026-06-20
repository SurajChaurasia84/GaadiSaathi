import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/app_state.dart';
import '../chat_screen.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    // Support both Owner and Customer roles in Inbox view
    final chats = appState.chatThreads
        .where((t) => t.customerGmail == appState.currentGmail || t.ownerGmail == appState.currentGmail)
        .toList();

    // Sort by last message timestamp descending so most recent is at the top
    chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Inbox',
          style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: chats.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, color: context.textColor30, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'No active conversations',
                    style: TextStyle(color: context.textColor30, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Conversations about vehicle bookings will appear here.',
                    style: TextStyle(color: context.textColor30.withValues(alpha: 0.8), fontSize: 12),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                final isOwner = appState.currentGmail == chat.ownerGmail;
                final partnerName = isOwner ? chat.customerName : chat.ownerName;
                final partnerEmail = isOwner ? chat.customerGmail : chat.ownerGmail;
                final partnerInitial = partnerName.isNotEmpty ? partnerName[0].toUpperCase() : '?';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.isDarkMode ? const Color(0x0AFFFFFF) : const Color(0x08000000)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .where('email', isEqualTo: partnerEmail)
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
                          backgroundColor: const Color(0xFF10B981),
                          backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                          child: hasPhoto
                              ? null
                              : Text(
                                  partnerInitial,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                        );
                      },
                    ),
                    title: Text(
                      partnerName,
                      style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          'Vehicle: ${chat.vehicleModel}',
                          style: const TextStyle(color: Color(0xFF536DFE), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          chat.lastMessageText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: context.textColor54, fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (appState.hasUnreadMessages(chat.threadId))
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Icon(Icons.arrow_forward_ios_rounded, color: context.textColor30, size: 14),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(threadId: chat.threadId),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
