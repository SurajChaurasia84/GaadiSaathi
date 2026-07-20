import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  String? _pickedPhotoPath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _nameController = TextEditingController(text: appState.currentUserName);
    _emailController = TextEditingController(text: appState.currentGmail);
    final phone = appState.currentUserPhone ?? '';
    _phoneController = TextEditingController(text: (phone == 'No phone added' ? '' : phone));
    final address = appState.currentUserAddress ?? '';
    _addressController = TextEditingController(text: (address == 'No address added' ? '' : address));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Profile Photo',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFF536DFE).withValues(alpha: 0.1),
                            child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF536DFE), size: 28),
                          ),
                          const SizedBox(height: 8),
                          const Text('Camera', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                            child: const Icon(Icons.photo_library_rounded, color: Color(0xFF10B981), size: 28),
                          ),
                          const SizedBox(height: 8),
                          const Text('Gallery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source != null) {
      final image = await picker.pickImage(source: source, imageQuality: 85);
      if (image != null) {
        setState(() {
          _pickedPhotoPath = image.path;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final photoUrl = appState.currentUserPhotoUrl;
    final initial = (_nameController.text.isNotEmpty ? _nameController.text[0] : 'G').toUpperCase();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Edit Profile',
          style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Incomplete Profile Warning Banner
              if (appState.isProfileIncomplete) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade700, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile Incomplete!',
                              style: TextStyle(
                                color: context.textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Please fill missing details: ${appState.missingProfileFields.join(', ')}',
                              style: TextStyle(color: context.textColor54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Avatar Section with Camera Badge
              Center(
                child: GestureDetector(
                  onTap: _pickProfilePhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: const Color(0xFF536DFE),
                        backgroundImage: _pickedPhotoPath != null
                            ? FileImage(File(_pickedPhotoPath!)) as ImageProvider
                            : (photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null),
                        child: (_pickedPhotoPath == null && (photoUrl == null || photoUrl.isEmpty))
                            ? Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF536DFE),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 2.5,
                            ),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _pickProfilePhoto,
                  icon: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF536DFE)),
                  label: const Text(
                    'Change Profile Photo',
                    style: TextStyle(color: Color(0xFF536DFE), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Name field
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: context.textColor, fontSize: 14),
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: TextStyle(color: context.textColor30),
                  prefixIcon: Icon(Icons.person_outline_rounded, color: context.textColor30, size: 18),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: context.isDarkMode ? const Color(0x1AFFFFFF) : const Color(0x15000000),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF536DFE)),
                  ),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),

              // Email field (uneditable)
              TextFormField(
                controller: _emailController,
                readOnly: true,
                style: TextStyle(color: context.textColor30, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Email Address (Uneditable)',
                  labelStyle: TextStyle(color: context.textColor30),
                  prefixIcon: Icon(Icons.email_outlined, color: context.textColor30, size: 18),
                  filled: true,
                  fillColor: context.isDarkMode
                      ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                      : const Color(0xFFF1F5F9),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: context.isDarkMode ? const Color(0x1AFFFFFF) : const Color(0x15000000),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: context.isDarkMode ? const Color(0x1AFFFFFF) : const Color(0x15000000),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Phone Number field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: context.textColor, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: TextStyle(color: context.textColor30),
                  prefixIcon: Icon(Icons.phone_outlined, color: context.textColor30, size: 18),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: context.isDarkMode ? const Color(0x1AFFFFFF) : const Color(0x15000000),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF536DFE)),
                  ),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Please enter phone number' : null,
              ),
              const SizedBox(height: 16),

              // Address field with GPS button
              TextFormField(
                controller: _addressController,
                maxLines: 1,
                style: TextStyle(color: context.textColor, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Location / Address',
                  labelStyle: TextStyle(color: context.textColor30),
                  prefixIcon: Icon(Icons.location_on_outlined, color: context.textColor30, size: 18),
                  suffixIcon: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF536DFE),
                    ),
                    icon: const Icon(Icons.my_location_rounded, size: 16),
                    label: const Text(
                      'GPS',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
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
                              Text('Fetching current GPS location...'),
                            ],
                          ),
                          duration: Duration(days: 1),
                        ),
                      );
                      await appState.fetchCurrentLocation();
                      messenger.clearSnackBars();
                      if (!mounted) return;
                      setState(() {
                        _addressController.text = appState.currentAddress;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: context.isDarkMode ? const Color(0x1AFFFFFF) : const Color(0x15000000),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF536DFE)),
                  ),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Please enter address' : null,
              ),
              const SizedBox(height: 32),

              // Save Profile Button
              ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;

                        setState(() => _isSaving = true);
                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(context);

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
                                Text('Saving profile...'),
                              ],
                            ),
                            duration: Duration(days: 1),
                          ),
                        );

                        String? uploadedPhotoUrl;
                        if (_pickedPhotoPath != null) {
                          uploadedPhotoUrl = await appState.uploadToCloudinary(_pickedPhotoPath!);
                        }

                        await appState.updateProfile(
                          name: _nameController.text.trim(),
                          phone: _phoneController.text.trim(),
                          address: _addressController.text.trim(),
                          photoUrl: uploadedPhotoUrl,
                        );

                        messenger.clearSnackBars();
                        if (mounted) {
                          setState(() => _isSaving = false);
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Profile Updated Successfully!'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                          nav.pop();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF536DFE),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Save Profile',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
