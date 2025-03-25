class City {
  final String name;
  final String? country;
  final double? lat;
  final double? lon;

  City({
    required this.name,
    this.country,
    this.lat,
    this.lon,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      name: json['name'],
      country: json['country'],
      lat: json['lat']?.toDouble(),
      lon: json['lon']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'country': country,
      'lat': lat,
      'lon': lon,
    };
  }

  @override
  String toString() {
    return country != null ? '$name, $country' : name;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is City && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}
