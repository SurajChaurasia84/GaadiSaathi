import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/vehicle.dart';
import '../../models/chat.dart';
import '../../widgets/theme_selector.dart';
import '../chat_screen.dart';
import '../role_selection_screen.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final vehicle = appState.ownerVehicle;
    final chats = appState.chatThreads.where((t) => t.ownerGmail == appState.currentGmail).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Owner Console',
          style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Quick Switch Simulator Mode helper
          TextButton.icon(
            onPressed: () {
              appState.setRole('Customer');
              appState.triggerLocationOn();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF536DFE), size: 16),
            label: const Text(
              'Switch to Cust',
              style: TextStyle(color: Color(0xFF536DFE), fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          buildThemeSelector(context, appState),
          IconButton(
            icon: Icon(Icons.logout_rounded, color: context.textColor54),
            onPressed: () {
              appState.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                (route) => false,
              );
            },
          )
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
          color: const Color(0xFF10B981),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (vehicle == null) ...[
                  _buildNoVehicleCard(context),
                ] else ...[
                  // 1. Service Status Toggle Card
                  _buildServiceToggleCard(context, appState, vehicle),
                  const SizedBox(height: 20),

                  // 2. Rent Payment Status Card (Rs 50 requirement)
                  _buildRentCard(context, appState),
                  const SizedBox(height: 20),

                  // 3. Vehicle Preview Card
                  _buildVehicleDetailCard(context, vehicle),
                  const SizedBox(height: 24),

                  // 4. Chat Inbox List
                  Text(
                    'INBOX / INCOMING BOOKINGS',
                    style: TextStyle(
                      color: context.textColor30,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  chats.isEmpty
                      ? _buildEmptyInboxCard(context)
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: chats.length,
                          itemBuilder: (context, index) {
                            final chat = chats[index];
                            return _buildChatTile(context, chat);
                          },
                        ),
                ],
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoVehicleCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
          const SizedBox(height: 16),
          Text(
            'No Registered Vehicle Found',
            style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Please register a vehicle to begin receiving customer booking inquiries.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textColor54, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Redirect to register
            },
            child: const Text('Register Now'),
          )
        ],
      ),
    );
  }

  Widget _buildServiceToggleCard(BuildContext context, AppState appState, Vehicle vehicle) {
    final isOn = vehicle.isServiceOn;

    final isDark = context.isDarkMode;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isOn 
            ? (isDark ? const Color(0xFF132D24) : const Color(0xFFE6F4EA)) 
            : (isDark ? const Color(0xFF2E1A1A) : const Color(0xFFFCE8E6)),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isOn ? const Color(0xFF10B981).withOpacity(0.5) : const Color(0xFFEF4444).withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isOn 
                ? const Color(0xFF10B981).withOpacity(isDark ? 0.2 : 0.05) 
                : const Color(0xFFEF4444).withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            spreadRadius: 1,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 6,
                      backgroundColor: isOn ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOn ? 'SERVICE ON (Green)' : 'SERVICE OFF (Red)',
                      style: TextStyle(
                        color: isOn ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isOn
                      ? 'Your vehicle is visible to customers within 3 km. Get ready for chats!'
                      : 'Your vehicle is hidden. Toggle ON to start taking bookings.',
                  style: TextStyle(
                    color: context.textColor70,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Custom Styled Switch Button
          Switch(
            value: isOn,
            onChanged: (val) {
              appState.toggleServiceStatus(val);
            },
            activeColor: const Color(0xFF10B981),
            activeTrackColor: const Color(0x4410B981),
            inactiveThumbColor: const Color(0xFFEF4444),
            inactiveTrackColor: const Color(0x44EF4444),
          ),
        ],
      ),
    );
  }

  Widget _buildRentCard(BuildContext context, AppState appState) {
    final isPaid = appState.isRentPaid;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.isDarkMode ? const Color(0x11FFFFFF) : const Color(0x0A000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.payments_rounded, color: context.textColor70, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Monthly Platform Rent',
                    style: TextStyle(
                      color: context.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaid ? const Color(0x2210B981) : const Color(0x22EF4444),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isPaid ? const Color(0x8810B981) : const Color(0x88EF4444)),
                ),
                child: Text(
                  isPaid ? 'PAID' : 'DUE',
                  style: TextStyle(
                    color: isPaid ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Vehicle Owners are charged ₹50 every month to list. Booking fees are ₹0.',
            style: TextStyle(
              color: context.textColor54,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          if (!isPaid) ...[
            ElevatedButton(
              onPressed: () {
                _showPayDialog(context, appState);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF536DFE),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Pay Monthly Rent (₹50)', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 14),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                const SizedBox(width: 8),
                Text(
                  'Next payment due on: ${appState.rentDueDate.day}/${appState.rentDueDate.month}/${appState.rentDueDate.year}',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showPayDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Simulate Platform Rent Payment', style: TextStyle(color: context.textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will simulate charging ₹50 from your Gmail account to fulfill the owner monthly fee.',
                style: TextStyle(color: context.textColor70, fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                'Fee Amount: ₹50.00\nBooking Fee: ₹0.00 (Free)',
                style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: context.textColor54)),
            ),
            ElevatedButton(
              onPressed: () {
                appState.payRent();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment Successful! ₹50 rent settled for 30 days.'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              child: const Text('Confirm Payment'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVehicleDetailCard(BuildContext context, Vehicle vehicle) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.isDarkMode ? const Color(0x0AFFFFFF) : const Color(0x08000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.network(
              vehicle.outsidePhotoUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      vehicle.model,
                      style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF536DFE).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        vehicle.type.displayName,
                        style: const TextStyle(color: Color(0xFF536DFE), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your Rate: ₹${vehicle.ratePerKm.toStringAsFixed(1)} / Km',
                  style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyInboxCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.isDarkMode ? const Color(0x0AFFFFFF) : const Color(0x08000000)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.chat_bubble_outline_rounded, color: context.textColor30, size: 36),
            const SizedBox(height: 12),
            Text(
              'No Booking Chats Yet',
              style: TextStyle(color: context.textColor30, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'When customers chat with you, they show here.',
              style: TextStyle(color: context.textColor30.withOpacity(0.8), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, ChatThread chat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.isDarkMode ? const Color(0x0AFFFFFF) : const Color(0x08000000)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF536DFE),
          child: Text(
            chat.customerName[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          chat.customerName,
          style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              chat.lastMessageText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.textColor54, fontSize: 12),
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, color: context.textColor30, size: 14),
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
  }
}
