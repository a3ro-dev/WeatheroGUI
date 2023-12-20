import 'dart:convert';

class Weather {
  final String cityName;
  final double temperature;
  final String mainCondition;

  Weather({
    required this.cityName,
    required this.mainCondition,
    required this.temperature,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    try {
      return Weather(
        cityName: json['name'],
        temperature: (json['main']['temp'].toDouble()).roundToDouble(),
        mainCondition: json['weather'][0]['main'],
      );
    } catch (e) {
      // Handle parsing errors, e.g., log the error or throw a custom exception.
      throw FormatException("Error parsing Weather JSON: $e");
    }
  }

  // Named constructor for creating a Weather object from a JSON map
  factory Weather.fromMap(Map<String, dynamic> map) {
    return Weather(
      cityName: map['cityName'],
      temperature: map['temperature'],
      mainCondition: map['mainCondition'],
    );
  }

  // Converts a Weather object to a JSON string
  String toJson() => json.encode(toJsonMap());

  // Converts a Weather object to a JSON map
  Map<String, dynamic> toJsonMap() {
    return {
      'cityName': cityName,
      'temperature': temperature,
      'mainCondition': mainCondition,
    };
  }
}
