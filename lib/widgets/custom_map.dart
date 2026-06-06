import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../providers/app_state.dart';

class CustomMap extends StatefulWidget {
  final Function(Vehicle) onVehicleSelected;

  const CustomMap({super.key, required this.onVehicleSelected});

  @override
  State<CustomMap> createState() => _CustomMapState();
}

class _CustomMapState extends State<CustomMap> with SingleTickerProviderStateMixin {
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final vehicles = appState.filteredVehicles;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          color: context.isDarkMode ? const Color(0xDD0D1321) : const Color(0xFFE2E8F0),
          border: Border.all(
            color: context.isDarkMode ? const Color(0x22536DFE) : const Color(0x66536DFE),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x33536DFE).withOpacity(context.isDarkMode ? 0.08 : 0.04),
              blurRadius: 15,
              spreadRadius: 2,
            )
          ],
        ),
        child: AnimatedBuilder(
          animation: _radarController,
          builder: (context, child) {
            return Stack(
              children: [
                // Render the tactical map background & radar wave
                Positioned.fill(
                  child: CustomPaint(
                    painter: MapPainter(
                      radarSweepAngle: _radarController.value * 2 * pi,
                      maxRadiusKm: appState.searchRadiusKm,
                      isDarkMode: context.isDarkMode,
                    ),
                  ),
                ),
                // User center location pin (Pulse)
                const Center(
                  child: UserLocationMarker(),
                ),
                // Render interactive vehicle pins based on relative coordinates
                ...vehicles.map((v) {
                  // Calculate offsets relative to user center
                  // We simulate coordinate space mapping: Delhi lat 28.6139, lon 77.2090
                  double dLat = v.latitude - appState.customerLatitude;
                  double dLon = v.longitude - appState.customerLongitude;

                  // Scales: 1 degree latitude is approx 111 km. We map it to screen offset.
                  // Scale coordinates to fit visual range on map container (usually width ~350, height ~260)
                  // Let's project so that 3km distance fits within the visible container.
                  double maxRangeDegrees = (appState.searchRadiusKm / 111.0) * 1.5; // pad it slightly

                  // If radius is 0, avoid division by zero
                  if (maxRangeDegrees == 0) maxRangeDegrees = 0.001;

                  // Normalize to -1.0 to 1.0 coordinate space inside map widget
                  double xNormalized = dLon / maxRangeDegrees;
                  double yNormalized = -dLat / maxRangeDegrees; // invert y for screen coords

                  // Restrict to visible bounding box
                  xNormalized = xNormalized.clamp(-0.85, 0.85);
                  yNormalized = yNormalized.clamp(-0.85, 0.85);

                  return Align(
                    alignment: Alignment(xNormalized, yNormalized),
                    child: VehiclePin(
                      vehicle: v,
                      onTap: () => widget.onVehicleSelected(v),
                    ),
                  );
                }),
                // Radius info badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.isDarkMode ? const Color(0xAA1E293B) : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.isDarkMode ? const Color(0x33536DFE) : const Color(0xAA536DFE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.radar, color: Color(0xFF536DFE), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Radar: ${appState.searchRadiusKm.toStringAsFixed(1)} Km',
                          style: TextStyle(
                            color: context.textColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Indicator banner
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Text(
                    '${vehicles.length} vehicle(s) nearby',
                    style: TextStyle(
                      color: context.textColor54,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class MapPainter extends CustomPainter {
  final double radarSweepAngle;
  final double maxRadiusKm;
  final bool isDarkMode;

  MapPainter({required this.radarSweepAngle, required this.maxRadiusKm, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paintGrid = Paint()
      ..color = isDarkMode ? const Color(0x15536DFE) : const Color(0x25536DFE)
      ..strokeWidth = 1.0;

    // Draw concentric radar lines
    final paintRing = Paint()
      ..color = isDarkMode ? const Color(0x22536DFE) : const Color(0x44536DFE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Outer ring
    canvas.drawCircle(center, min(size.width, size.height) * 0.42, paintRing);
    // Middle ring
    canvas.drawCircle(center, min(size.width, size.height) * 0.25, paintRing);
    // Inner ring
    canvas.drawCircle(center, min(size.width, size.height) * 0.10, paintRing);

    // Draw grid lines
    int gridCount = 8;
    for (int i = 1; i < gridCount; i++) {
      double dx = (size.width / gridCount) * i;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paintGrid);

      double dy = (size.height / gridCount) * i;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paintGrid);
    }

    // Draw Radar Sweep
    final radarShader = SweepGradient(
      colors: [
        const Color(0x00536DFE),
        const Color(0x44536DFE),
        const Color(0x00536DFE),
      ],
      stops: const [0.0, 0.5, 1.0],
      transform: GradientRotation(radarSweepAngle),
    ).createShader(Rect.fromCircle(center: center, radius: size.width / 2));

    final radarFillPaint = Paint()
      ..shader = radarShader
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, size.width / 2, radarFillPaint);
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    return oldDelegate.radarSweepAngle != radarSweepAngle || 
           oldDelegate.maxRadiusKm != maxRadiusKm ||
           oldDelegate.isDarkMode != isDarkMode;
  }
}

class UserLocationMarker extends StatefulWidget {
  const UserLocationMarker({super.key});

  @override
  State<UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<UserLocationMarker> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 14 + (24 * _pulseController.value),
              height: 14 + (24 * _pulseController.value),
              decoration: BoxDecoration(
                color: const Color(0x55536DFE),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF536DFE).withOpacity(1.0 - _pulseController.value),
                  width: 1.5,
                ),
              ),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFF536DFE),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF536DFE),
                    blurRadius: 10,
                    spreadRadius: 3,
                  )
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class VehiclePin extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;

  const VehiclePin({
    super.key,
    required this.vehicle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color typeColor;
    IconData typeIcon;

    switch (vehicle.type) {
      case VehicleType.car:
        typeColor = const Color(0xFF3B82F6); // Blue
        typeIcon = Icons.directions_car_rounded;
        break;
      case VehicleType.eRickshaw:
        typeColor = const Color(0xFFF59E0B); // Amber/Orange
        typeIcon = Icons.electric_rickshaw_rounded;
        break;
      case VehicleType.loading:
        typeColor = const Color(0xFF8B5CF6); // Purple
        typeIcon = Icons.local_shipping_rounded;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: context.isDarkMode ? const Color(0xFF0F172A) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: typeColor, width: 2.0),
          boxShadow: [
            BoxShadow(
              color: typeColor.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1,
            )
          ],
        ),
        child: Center(
          child: Icon(
            typeIcon,
            color: typeColor,
            size: 16,
          ),
        ),
      ),
    );
  }
}
