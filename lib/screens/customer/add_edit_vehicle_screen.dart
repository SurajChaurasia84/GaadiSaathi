import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/vehicle.dart';
import '../../providers/app_state.dart';

/// A standalone screen for both **adding** a new vehicle and **editing**
/// an existing one.
///
/// Pass [initialVehicle] to pre-fill all fields in edit mode.
class AddEditVehicleScreen extends StatefulWidget {
  final Vehicle? initialVehicle;

  const AddEditVehicleScreen({super.key, this.initialVehicle});

  @override
  State<AddEditVehicleScreen> createState() => _AddEditVehicleScreenState();
}

class _AddEditVehicleScreenState extends State<AddEditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _ownerNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _modelNameController;
  late final TextEditingController _rateController;

  late VehicleType _selectedType;
  late bool _isAvailable;

  String? _pickedOutsidePhotoPath;
  String? _pickedInsidePhotoPath;

  bool get _isEditing => widget.initialVehicle != null;

  @override
  void initState() {
    super.initState();
    final v = widget.initialVehicle;
    _ownerNameController = TextEditingController(text: v?.ownerName ?? '');
    _phoneController = TextEditingController(text: v?.phoneNumber ?? '');
    _addressController = TextEditingController(text: v?.address ?? '');
    _modelNameController = TextEditingController(text: v?.model ?? '');
    _rateController =
        TextEditingController(text: v != null ? v.ratePerKm.toStringAsFixed(0) : '');
    _selectedType = v?.type ?? VehicleType.car;
    _isAvailable = v?.isServiceOn ?? true;
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _modelNameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required bool isOutside}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() {
        if (isOutside) {
          _pickedOutsidePhotoPath = picked.path;
        } else {
          _pickedInsidePhotoPath = picked.path;
        }
      });
    }
  }



  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    // Validate that images are picked in Add mode
    if (!_isEditing) {
      if (_pickedOutsidePhotoPath == null || _pickedInsidePhotoPath == null) {
        messenger.clearSnackBars();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Please select both Outside and Inside photos of the vehicle.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        return;
      }
    }

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(_isEditing ? 'Updating Vehicle...' : 'Adding Vehicle...'),
          ],
        ),
        duration: const Duration(days: 1),
      ),
    );

    // Upload new photos if picked
    String? finalOutsideUrl;
    String? finalInsideUrl;

    if (_pickedOutsidePhotoPath != null) {
      finalOutsideUrl = await appState.uploadToCloudinary(_pickedOutsidePhotoPath!);
      if (finalOutsideUrl == null) {
        messenger.clearSnackBars();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to upload Outside photo. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }
    if (_pickedInsidePhotoPath != null) {
      finalInsideUrl = await appState.uploadToCloudinary(_pickedInsidePhotoPath!);
      if (finalInsideUrl == null) {
        messenger.clearSnackBars();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to upload Inside photo. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    messenger.clearSnackBars();

    if (_isEditing) {
      // ── Edit mode ──────────────────────────────────────────────────────────
      final updated = widget.initialVehicle!.copyWith(
        ownerName: _ownerNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        type: _selectedType,
        model: _modelNameController.text.trim(),
        ratePerKm: double.tryParse(_rateController.text.trim()) ?? 0.0,
        isServiceOn: _isAvailable,
        outsidePhotoUrl: finalOutsideUrl ?? widget.initialVehicle!.outsidePhotoUrl,
        insidePhotoUrl: finalInsideUrl ?? widget.initialVehicle!.insidePhotoUrl,
      );
      await appState.updateVehicle(updated);

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Vehicle updated successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.pop(context);
    } else {
      // ── Add mode ───────────────────────────────────────────────────────────
      final rng = Random();
      final newVehicle = Vehicle(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        ownerName: _ownerNameController.text.trim(),
        ownerGmail: appState.currentGmail ?? 'guest@example.com',
        type: _selectedType,
        model: _modelNameController.text.trim(),
        insidePhotoUrl: finalInsideUrl!,
        outsidePhotoUrl: finalOutsideUrl!,
        ratePerKm: double.tryParse(_rateController.text.trim()) ?? 0.0,
        isServiceOn: _isAvailable,
        latitude: appState.customerLatitude + (rng.nextDouble() - 0.5) * 0.02,
        longitude: appState.customerLongitude + (rng.nextDouble() - 0.5) * 0.02,
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );
      appState.addCustomVehicle(newVehicle);

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Vehicle registered successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.pop(context);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Vehicle' : 'Add Vehicle',
          style: TextStyle(
            color: context.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing
                    ? 'Update your vehicle details below.'
                    : 'Add your vehicle details to list it on our platform.',
                style: TextStyle(color: context.textColor54, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 16),

              // Owner Name
              _field(
                controller: _ownerNameController,
                label: 'Owner Name',
                icon: Icons.person_outline_rounded,
                capitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter owner name' : null,
              ),
              const SizedBox(height: 12),

              // Phone
              _field(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter phone number' : null,
              ),
              const SizedBox(height: 12),

              // Address
              _field(
                controller: _addressController,
                label: 'Address',
                icon: Icons.location_on_rounded,
                capitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter address' : null,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.my_location_rounded,
                      color: Color(0xFF536DFE), size: 20),
                  tooltip: 'Use Current Location',
                  onPressed: () async {
                    final m = ScaffoldMessenger.of(context);
                    m.clearSnackBars();
                    m.showSnackBar(const SnackBar(
                      content: Text('Fetching location...'),
                      duration: Duration(days: 1),
                    ));
                    await appState.fetchCurrentLocation();
                    m.clearSnackBars();
                    _addressController.text = appState.currentAddress;
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Vehicle Type
              Text('VEHICLE TYPE',
                  style: TextStyle(
                      color: context.textColor30,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0)),
              const SizedBox(height: 8),
              Row(
                children: VehicleType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = type),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF536DFE)
                              : Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : (context.isDarkMode
                                    ? const Color(0xFF2E3B4E)
                                    : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            type.displayName,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : context.textColor70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Model Name
              _field(
                controller: _modelNameController,
                label: 'Vehicle Model Name',
                icon: Icons.commute_rounded,
                capitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter model name' : null,
              ),
              const SizedBox(height: 12),

              // Rate per Km
              _field(
                controller: _rateController,
                label: 'Charge per Km (₹)',
                icon: Icons.currency_rupee_rounded,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter rate per Km';
                  if (double.tryParse(v) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Availability Toggle
              _availabilityToggle(),
              const SizedBox(height: 16),

              // Photos
              Text('VEHICLE PHOTOS',
                  style: TextStyle(
                      color: context.textColor30,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _photoPicker(
                      label: 'Outside Photo',
                      localPath: _pickedOutsidePhotoPath,
                      existingUrl: _isEditing
                          ? widget.initialVehicle!.outsidePhotoUrl
                          : null,
                      onTap: () => _pickImage(isOutside: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _photoPicker(
                      label: 'Inside Photo',
                      localPath: _pickedInsidePhotoPath,
                      existingUrl: _isEditing
                          ? widget.initialVehicle!.insidePhotoUrl
                          : null,
                      onTap: () => _pickImage(isOutside: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF536DFE),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  _isEditing ? 'Update Vehicle' : 'Add Vehicle',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      style: TextStyle(color: context.textColor, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.textColor30),
        prefixIcon: Icon(icon, color: context.textColor30, size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: context.isDarkMode
                ? const Color(0x1AFFFFFF)
                : const Color(0x15000000),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF536DFE)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
      validator: validator,
    );
  }

  Widget _availabilityToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.isDarkMode
              ? const Color(0x1AFFFFFF)
              : const Color(0x15000000),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Availability Status',
                    style: TextStyle(
                        color: context.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  _isAvailable
                      ? 'Service is ON (Available for bookings)'
                      : 'Service is OFF (Unavailable)',
                  style: TextStyle(
                    color: _isAvailable
                        ? const Color(0xFF10B981)
                        : context.textColor30,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isAvailable,
            activeThumbColor: const Color(0xFF10B981),
            activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.3),
            onChanged: (v) => setState(() => _isAvailable = v),
          ),
        ],
      ),
    );
  }

  Widget _photoPicker({
    required String label,
    required String? localPath,
    required String? existingUrl,
    required VoidCallback onTap,
  }) {
    Widget content;

    if (localPath != null) {
      // Newly picked local file
      content = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(File(localPath), fit: BoxFit.cover),
      );
    } else if (existingUrl != null && existingUrl.isNotEmpty) {
      // Existing Cloudinary URL (edit mode)
      content = Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(existingUrl, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, color: Colors.white38)),
          ),
          // "Tap to change" overlay
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: const BoxDecoration(
                color: Color(0xCC000000),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: const Text('Tap to change',
                  style: TextStyle(color: Colors.white70, fontSize: 9)),
            ),
          ),
        ],
      );
    } else {
      // Empty placeholder
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_photo_alternate_outlined,
              color: Color(0xFF536DFE), size: 24),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  color: context.textColor54,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: context.isDarkMode
                ? const Color(0x1AFFFFFF)
                : const Color(0x15000000),
            width: 1.5,
          ),
        ),
        child: content,
      ),
    );
  }
}
