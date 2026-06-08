import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/vehicle.dart';

class VehicleHistoryScreen extends StatelessWidget {
  const VehicleHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final vehicles = appState.myVehicles;

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
          'Vehicle History',
          style: TextStyle(
            color: context.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: vehicles.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                return _buildVehicleCard(context, vehicles[index]);
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF536DFE).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_car_outlined,
              color: Color(0xFF536DFE),
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Vehicles Registered Yet',
            style: TextStyle(
              color: context.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vehicles you add will appear here.',
            style: TextStyle(
              color: context.textColor54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, Vehicle vehicle) {
    final isActive = vehicle.isServiceOn;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.isDarkMode
              ? const Color(0x1AFFFFFF)
              : const Color(0x10000000),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDarkMode ? 0.15 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left - Vehicle Image
            SizedBox(
              width: 110,
              child: _buildVehicleImage(vehicle.outsidePhotoUrl),
            ),

            // Right - Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge + Status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF536DFE).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            vehicle.type.displayName,
                            style: const TextStyle(
                              color: Color(0xFF536DFE),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                : Colors.grey.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive
                                      ? const Color(0xFF10B981)
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  color: isActive
                                      ? const Color(0xFF10B981)
                                      : Colors.grey,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Vehicle Model Name
                    Text(
                      vehicle.model,
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Rate per km
                    Row(
                      children: [
                        Icon(Icons.speed_rounded,
                            color: context.textColor54, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          '₹${vehicle.ratePerKm.toStringAsFixed(0)}/km',
                          style: TextStyle(
                            color: context.textColor54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    // Address (if present)
                    if (vehicle.address != null &&
                        vehicle.address!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              color: context.textColor30, size: 12),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              vehicle.address!,
                              style: TextStyle(
                                color: context.textColor30,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Phone (if present)
                    if (vehicle.phoneNumber != null &&
                        vehicle.phoneNumber!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined,
                              color: context.textColor30, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            vehicle.phoneNumber!,
                            style: TextStyle(
                              color: context.textColor30,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleImage(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildImageError(),
      );
    } else {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildImageError(),
        );
      }
      return _buildImageError();
    }
  }

  Widget _buildImageError() {
    return Container(
      color: const Color(0xFF1E293B),
      child: const Center(
        child: Icon(Icons.directions_car_outlined,
            color: Colors.white24, size: 32),
      ),
    );
  }
}
