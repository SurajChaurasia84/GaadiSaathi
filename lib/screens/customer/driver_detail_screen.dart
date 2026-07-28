import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_state.dart';
import '../../models/vehicle.dart';
import '../chat_screen.dart';
import '../../widgets/cached_user_avatar.dart';

class DriverDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const DriverDetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final selfieUrl = data['selfieUrl'] as String?;
    final licensePhotoUrl = data['licensePhotoUrl'] as String?;
    final photoUrl = selfieUrl ?? licensePhotoUrl;
    final driverName = data['driverName'] as String? ?? 'Driver Details';
    final phone = data['phoneNumber'] as String? ?? '';
    final address = data['address'] as String? ?? 'Address';
    final experienceVal = data['experience'];
    final experience = experienceVal != null ? '$experienceVal Years' : 'N/A';
    final driverGmail = data['driverGmail'] as String? ?? '';
    final lat = data['latitude'] as double? ?? 0.0;
    final lon = data['longitude'] as double? ?? 0.0;

    final distance = appState.getDistanceFromUser(lat, lon);
    final initial = driverName.isNotEmpty ? driverName[0].toUpperCase() : '?';

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
                                Icons.badge_rounded,
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
                                driverName,
                                style: TextStyle(
                                  color: context.textColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
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
                    Divider(color: context.isDarkMode ? const Color(0x0AFFFFFF) : const Color(0x08000000), height: 1),
                    const SizedBox(height: 16),

                    // Address / Location Row
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
                        } catch (_) {}
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Address / Location',
                                  style: TextStyle(
                                    color: context.textColor54,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  address,
                                  style: TextStyle(
                                    color: context.textColor,
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: context.isDarkMode ? const Color(0x0AFFFFFF) : const Color(0x08000000), height: 1),
                    const SizedBox(height: 16),

                    // Experience Section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.workspace_premium_rounded, color: Color(0xFF10B981), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Experience',
                                style: TextStyle(
                                  color: context.textColor54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                experience,
                                style: TextStyle(
                                  color: context.textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: context.isDarkMode ? const Color(0x0AFFFFFF) : const Color(0x08000000), height: 1),
                    const SizedBox(height: 16),

                    // Driving License Photo Section (if available)
                    if (licensePhotoUrl != null && licensePhotoUrl.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.badge_rounded, color: Color(0xFF536DFE), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Driving License',
                                  style: TextStyle(
                                    color: context.textColor54,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                GestureDetector(
                                  onTap: () => _openFullScreenImage(context, licensePhotoUrl),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      licensePhotoUrl,
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Divider(color: context.isDarkMode ? const Color(0x0AFFFFFF) : const Color(0x08000000), height: 1),
                      const SizedBox(height: 16),
                    ],

                    // Owner Profile Info Row
                    Row(
                      children: [
                        CachedUserAvatar(
                          email: driverGmail,
                          radius: 20,
                          fallbackInitial: initial,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driverName,
                                style: TextStyle(
                                  color: context.textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                phone,
                                style: TextStyle(
                                  color: context.textColor54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ]),
                ),
              ),
            ],
          ),

          // Sticky Bottom Actions Panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: context.isDarkMode ? const Color(0x0AFFFFFF) : const Color(0x08000000),
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (appState.currentGmail != null && appState.currentGmail!.isNotEmpty && driverGmail == appState.currentGmail) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showEditDriverBottomSheet(context, appState, data),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF536DFE),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text(
                          'Edit Listing',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ] else ...[
                    if (phone.isNotEmpty) ...[
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.phone_rounded),
                          label: const Text(
                            'Call Driver',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final dummyVehicle = Vehicle(
                            id: data['id'] as String? ?? 'driver',
                            ownerName: driverName,
                            ownerGmail: driverGmail,
                            type: VehicleType.car,
                            model: 'Driver Profile',
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: const Text(
                          'Chat',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openFullScreenImage(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(url),
            ),
          ),
        ),
      ),
    );
  }


  void _showEditDriverBottomSheet(BuildContext context, AppState appState, Map<String, dynamic> currentData) {
    final formKey = GlobalKey<FormState>();
    final driverNameController = TextEditingController(text: currentData['driverName'] as String? ?? '');
    final phoneController = TextEditingController(text: currentData['phoneNumber'] as String? ?? '');
    final experienceController = TextEditingController(text: currentData['experience']?.toString() ?? '');
    final addressController = TextEditingController(text: currentData['address'] as String? ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final textColor = isDark ? Colors.white : Colors.black;
            final textColor30 = isDark ? Colors.white30 : Colors.black38;

            InputDecoration inputDecoration(String label, IconData icon) => InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: textColor30),
              prefixIcon: Icon(icon, color: textColor30, size: 18),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? const Color(0x1AFFFFFF) : const Color(0x15000000),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF536DFE)),
              ),
            );

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: textColor30,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Edit Driver Profile',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: driverNameController,
                        textCapitalization: TextCapitalization.words,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: inputDecoration('Driver Name', Icons.person_outline_rounded),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Enter driver name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: inputDecoration('Phone Number', Icons.phone_rounded),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Enter phone number' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: experienceController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: inputDecoration('Experience (Years)', Icons.workspace_premium_rounded),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Enter experience';
                          if (int.tryParse(value) == null) return 'Enter a valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: addressController,
                        maxLines: 1,
                        style: TextStyle(color: textColor, fontSize: 14),
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Address / Location',
                          labelStyle: TextStyle(color: textColor30),
                          prefixIcon: Icon(Icons.location_on_rounded, color: textColor30, size: 18),
                          suffixIcon: TextButton.icon(
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFF536DFE)),
                            icon: const Icon(Icons.my_location_rounded, size: 16),
                            label: const Text('GPS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              messenger.clearSnackBars();
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      ),
                                      SizedBox(width: 12),
                                      Text('Fetching location...'),
                                    ],
                                  ),
                                  duration: Duration(days: 1),
                                ),
                              );
                              await appState.fetchCurrentLocation();
                              messenger.clearSnackBars();
                              addressController.text = appState.currentAddress;
                            },
                          ),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0x1AFFFFFF) : const Color(0x15000000),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF536DFE)),
                          ),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Enter address' : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;

                                setModalState(() => isSaving = true);
                                final messenger = ScaffoldMessenger.of(context);
                                final nav = Navigator.of(context);

                                try {
                                  await FirebaseFirestore.instance
                                      .collection('drivers')
                                      .doc(currentData['id'] as String)
                                      .update({
                                        'driverName': driverNameController.text.trim(),
                                        'phoneNumber': phoneController.text.trim(),
                                        'experience': int.tryParse(experienceController.text.trim()) ?? 0,
                                        'address': addressController.text.trim(),
                                      });

                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Driver profile updated successfully!'),
                                      backgroundColor: Color(0xFF10B981),
                                    ),
                                  );
                                  nav.pop(); // Close edit sheet
                                  nav.pop(); // Close details view
                                } catch (e) {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Error updating: $e')),
                                  );
                                } finally {
                                  setModalState(() => isSaving = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF536DFE),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
