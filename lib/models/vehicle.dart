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
  final String? phoneNumber;
  final String? address;

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
    this.phoneNumber,
    this.address,
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
    String? phoneNumber,
    String? address,
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
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerName': ownerName,
      'ownerGmail': ownerGmail,
      'type': type.name,
      'model': model,
      'insidePhotoUrl': insidePhotoUrl,
      'outsidePhotoUrl': outsidePhotoUrl,
      'ratePerKm': ratePerKm,
      'isServiceOn': isServiceOn,
      'latitude': latitude,
      'longitude': longitude,
      'phoneNumber': phoneNumber,
      'address': address,
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map, String docId) {
    VehicleType parsedType = VehicleType.car;
    final typeStr = map['type'] as String?;
    if (typeStr != null) {
      for (var val in VehicleType.values) {
        if (val.name == typeStr) {
          parsedType = val;
          break;
        }
      }
    }

    return Vehicle(
      id: docId,
      ownerName: map['ownerName'] as String? ?? '',
      ownerGmail: map['ownerGmail'] as String? ?? '',
      type: parsedType,
      model: map['model'] as String? ?? '',
      insidePhotoUrl: map['insidePhotoUrl'] as String? ?? '',
      outsidePhotoUrl: map['outsidePhotoUrl'] as String? ?? '',
      ratePerKm: (map['ratePerKm'] as num?)?.toDouble() ?? 0.0,
      isServiceOn: map['isServiceOn'] as bool? ?? false,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      phoneNumber: map['phoneNumber'] as String?,
      address: map['address'] as String?,
    );
  }
}
