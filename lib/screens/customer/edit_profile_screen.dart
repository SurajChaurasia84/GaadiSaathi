import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _nameController = TextEditingController(text: appState.currentUserName);
    _emailController = TextEditingController(text: appState.currentGmail);
    _phoneController = TextEditingController(text: appState.currentUserPhone ?? '');
    _addressController = TextEditingController(text: appState.currentUserAddress ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

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
              // Avatar Section
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF536DFE),
                  backgroundImage: appState.currentUserPhotoUrl != null &&
                          appState.currentUserPhotoUrl!.isNotEmpty
                      ? NetworkImage(appState.currentUserPhotoUrl!)
                      : null,
                  child: appState.currentUserPhotoUrl != null &&
                          appState.currentUserPhotoUrl!.isNotEmpty
                      ? null
                      : Text(
                          (appState.currentUserName ?? 'G').isNotEmpty
                              ? appState.currentUserName![0].toUpperCase()
                              : 'G',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 32),

              // Name field
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: context.textColor, fontSize: 14),
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: TextStyle(color: context.textColor30),
                  prefixIcon: Icon(Icons.person_outline_rounded,
                      color: context.textColor30, size: 18),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: context.isDarkMode
                            ? const Color(0x1AFFFFFF)
                            : const Color(0x15000000),
                        width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF536DFE)),
                  ),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter your name'
                    : null,
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
                  prefixIcon: Icon(Icons.email_outlined,
                      color: context.textColor30, size: 18),
                  filled: true,
                  fillColor: context.isDarkMode
                      ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                      : const Color(0xFFF1F5F9),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: context.isDarkMode
                            ? const Color(0x1AFFFFFF)
                            : const Color(0x15000000),
                        width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: context.isDarkMode
                            ? const Color(0x1AFFFFFF)
                            : const Color(0x15000000),
                        width: 1.5),
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
                  prefixIcon: Icon(Icons.phone_outlined,
                      color: context.textColor30, size: 18),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: context.isDarkMode
                            ? const Color(0x1AFFFFFF)
                            : const Color(0x15000000),
                        width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF536DFE)),
                  ),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter phone number'
                    : null,
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
                  prefixIcon: Icon(Icons.location_on_outlined,
                      color: context.textColor30, size: 18),
                  suffixIcon: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF536DFE),
                    ),
                    icon: const Icon(Icons.my_location_rounded, size: 16),
                    label: const Text('GPS',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
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
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
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
                        color: context.isDarkMode
                            ? const Color(0x1AFFFFFF)
                            : const Color(0x15000000),
                        width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF536DFE)),
                  ),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter address'
                    : null,
              ),
              const SizedBox(height: 32),

              // Save Profile Button
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Saving Profile...'),
                      duration: Duration(milliseconds: 1000),
                    ),
                  );

                  await appState.updateProfile(
                    name: _nameController.text.trim(),
                    phone: _phoneController.text.trim(),
                    address: _addressController.text.trim(),
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile Updated Successfully!'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF536DFE),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Save Profile',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
