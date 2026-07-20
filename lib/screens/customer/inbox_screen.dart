import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/app_state.dart';
import '../../models/chat.dart';
import '../chat_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final Set<String> _selectedThreadIds = {};

  void _toggleSelection(String threadId) {
    setState(() {
      if (_selectedThreadIds.contains(threadId)) {
        _selectedThreadIds.remove(threadId);
      } else {
        _selectedThreadIds.add(threadId);
      }
    });
  }

  void _selectAll(List<ChatThread> chats) {
    setState(() {
      if (_selectedThreadIds.length == chats.length) {
        _selectedThreadIds.clear();
      } else {
        _selectedThreadIds.addAll(chats.map((c) => c.threadId));
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedThreadIds.clear();
    });
  }

  void _confirmDeleteSelected(BuildContext context, AppState appState) {
    final count = _selectedThreadIds.length;
    if (count == 0) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Delete $count Conversation${count > 1 ? 's' : ''}?',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete the selected conversation${count > 1 ? 's' : ''}? All message history will be permanently removed.',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _deleteSelectedThreads(context, appState);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSelectedThreads(BuildContext context, AppState appState) async {
    final idsToDelete = List<String>.from(_selectedThreadIds);
    if (idsToDelete.isEmpty) return;

    // Show non-dismissible loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) {
        final isDark = Theme.of(loadingContext).brightness == Brightness.dark;
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Row(
              children: [
                const CircularProgressIndicator(color: Color(0xFF536DFE)),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    'Deleting conversation${idsToDelete.length > 1 ? 's' : ''}...',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
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
    final nav = Navigator.of(context);

    try {
      await appState.deleteChatThreads(idsToDelete);

      if (mounted) {
        nav.pop(); // Close loading dialog
        setState(() {
          _selectedThreadIds.clear();
        });
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text('${idsToDelete.length} conversation${idsToDelete.length > 1 ? 's' : ''} deleted'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (mounted) {
        nav.pop(); // Close loading dialog
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to delete conversations: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isSelectionMode = _selectedThreadIds.isNotEmpty;

    // Support both Owner and Customer roles in Inbox view
    final chats = appState.chatThreads
        .where((t) => t.customerGmail == appState.currentGmail || t.ownerGmail == appState.currentGmail)
        .toList();

    // Sort by last message timestamp descending so most recent is at the top
    chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

    final isAllSelected = chats.isNotEmpty && _selectedThreadIds.length == chats.length;

    return PopScope(
      canPop: !isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && isSelectionMode) {
          _clearSelection();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: isSelectionMode
              ? (context.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF))
              : Colors.transparent,
          elevation: 0,
          title: Text(
            isSelectionMode ? '${_selectedThreadIds.length} Selected' : 'My Inbox',
            style: TextStyle(
              color: isSelectionMode ? const Color(0xFF536DFE) : context.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              isSelectionMode ? Icons.close_rounded : Icons.arrow_back_rounded,
              color: context.textColor,
            ),
            onPressed: () {
              if (isSelectionMode) {
                _clearSelection();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            if (isSelectionMode) ...[
              IconButton(
                icon: Icon(
                  isAllSelected ? Icons.deselect_rounded : Icons.select_all_rounded,
                  color: context.textColor,
                ),
                tooltip: isAllSelected ? 'Deselect All' : 'Select All',
                onPressed: () => _selectAll(chats),
              ),
              IconButton(
                icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                tooltip: 'Delete Selected',
                onPressed: () => _confirmDeleteSelected(context, appState),
              ),
              const SizedBox(width: 4),
            ],
          ],
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
                  final isSelected = _selectedThreadIds.contains(chat.threadId);
                  final isOwner = appState.currentGmail == chat.ownerGmail;
                  final partnerName = isOwner ? chat.customerName : chat.ownerName;
                  final partnerEmail = isOwner ? chat.customerGmail : chat.ownerGmail;
                  final partnerInitial = partnerName.isNotEmpty ? partnerName[0].toUpperCase() : '?';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF536DFE).withValues(alpha: 0.12)
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF536DFE)
                            : (context.isDarkMode ? const Color(0x0AFFFFFF) : const Color(0x08000000)),
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Stack(
                        children: [
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                          if (isSelected)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF536DFE),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                padding: const EdgeInsets.all(2),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        partnerName,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF536DFE) : context.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
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
                      trailing: isSelectionMode
                          ? Checkbox(
                              value: isSelected,
                              activeColor: const Color(0xFF536DFE),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (_) => _toggleSelection(chat.threadId),
                            )
                          : Row(
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
                        if (isSelectionMode) {
                          _toggleSelection(chat.threadId);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(threadId: chat.threadId),
                            ),
                          );
                        }
                      },
                      onLongPress: () {
                        _toggleSelection(chat.threadId);
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
