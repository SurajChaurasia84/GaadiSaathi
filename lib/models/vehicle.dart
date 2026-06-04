enum VehicleType {
  car,
  eRickshaw,
  loading,
}

extension VehicleTypeExtension on VehicleType {
  String get displayName {
    switch (this) {
      case VehicleType.car:
        return 'Car';
      case VehicleType.eRickshaw:
        return 'E-Rickshaw';
      case VehicleType.loading:
        return 'Loading Vehicle';
    }
  }
}

class Vehicle {
  final String id;
  final String ownerName;
  final String ownerGmail;
  final VehicleType type;
  final String model;
  final String insidePhotoUrl;
  final String outsidePhotoUrl;
  final double ratePerKm;
  final bool isServiceOn;
  final double latitude;
  final double longitude;

  Vehicle({
    required this.id,
    required this.ownerName,
    required this.ownerGmail,
    required this.type,
    required this.model,
    required this.insidePhotoUrl,
    required this.outsidePhotoUrl,
    required this.ratePerKm,
    required this.isServiceOn,
    required this.latitude,
    required this.longitude,
  });

  Vehicle copyWith({
    String? id,
    String? ownerName,
    String? ownerGmail,
    VehicleType? type,
    String? model,
    String? insidePhotoUrl,
    String? outsidePhotoUrl,
    double? ratePerKm,
    bool? isServiceOn,
    double? latitude,
    double? longitude,
  }) {
    return Vehicle(
      id: id ?? this.id,
      ownerName: ownerName ?? this.ownerName,
      ownerGmail: ownerGmail ?? this.ownerGmail,
      type: type ?? this.type,
      model: model ?? this.model,
      insidePhotoUrl: insidePhotoUrl ?? this.insidePhotoUrl,
      outsidePhotoUrl: outsidePhotoUrl ?? this.outsidePhotoUrl,
      ratePerKm: ratePerKm ?? this.ratePerKm,
      isServiceOn: isServiceOn ?? this.isServiceOn,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
