class Pharmacy {
  final String kendraCode;
  final String name;
  final String contact;
  final String stateName;
  final String districtName;
  final String pinCode;
  final String address;
  final String latitude;
  final String longitude;
  final double? distance;

  Pharmacy({
    required this.kendraCode,
    required this.name,
    required this.contact,
    required this.stateName,
    required this.districtName,
    required this.pinCode,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.distance,
  });

  factory Pharmacy.fromJson(Map<String, dynamic> json) {
    return Pharmacy(
      kendraCode: json['Kendra Code'] ?? '',
      name: json['Name'] ?? '',
      contact: json['Contact'] ?? '',
      stateName: json['State Name'] ?? '',
      districtName: json['District Name'] ?? '',
      pinCode: json['Pin Code'] ?? '',
      address: json['Address'] ?? '',
      latitude: json['Latitude'] ?? '',
      longitude: json['Longitude'] ?? '',
      distance: json['distance']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Kendra Code': kendraCode,
      'Name': name,
      'Contact': contact,
      'State Name': stateName,
      'District Name': districtName,
      'Pin Code': pinCode,
      'Address': address,
      'Latitude': latitude,
      'Longitude': longitude,
      if (distance != null) 'distance': distance,
    };
  }
} 