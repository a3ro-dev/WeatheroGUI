import 'dart:convert';

/// Weather model class that encapsulates cityName, temperature, and mainCondition
class Weather {
 // Name of the city
 final String cityName;

 // Temperature of the city in degrees Celsius
 final double temperature;

 // Main condition of the weather
 final String mainCondition;

 // Constructor for Weather model
 Weather({
    required this.cityName,
    required this.mainCondition,
    required this.temperature,
 });

 // Factory constructor for creating a Weather object from JSON data
 factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      cityName: json['name'],
      temperature: (json['main']['temp'].toDouble()).roundToDouble(),
      mainCondition: json['weather'][0]['main'],
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