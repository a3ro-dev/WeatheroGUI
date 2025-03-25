import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:weatherapp/models/weathermodel.dart';
import 'package:weatherapp/models/city_model.dart';

class WeatherService {
  static const String WEATHER_BASE_URL =
      'https://api.openweathermap.org/data/2.5/weather';
  static const String GEO_BASE_URL =
      'https://api.openweathermap.org/geo/1.0/direct';

  final String apiKey;

  WeatherService(this.apiKey);

  Future<Weather> getWeather(String cityName) async {
    try {
      final response = await http.get(Uri.parse(
          '$WEATHER_BASE_URL?q=$cityName&appid=$apiKey&units=metric'));

      if (response.statusCode == 200) {
        return Weather.fromJson(jsonDecode(response.body));
      } else {
        debugPrint(
            'Failed to load weather. Status code: ${response.statusCode}, Body: ${response.body}');
        throw WeatherApiException(
            'Failed to load weather. HTTP Status Code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching weather data: $e');
      throw WeatherApiException('Failed to load weather. $e');
    }
  }

  Future<Weather> getWeatherByCoordinates(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$WEATHER_BASE_URL?lat=$lat&lon=$lon&appid=$apiKey&units=metric'),
      );

      if (response.statusCode == 200) {
        return Weather.fromJson(jsonDecode(response.body));
      } else {
        throw WeatherApiException(
            'Failed to load weather. HTTP Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw WeatherApiException('Failed to load weather by coordinates: $e');
    }
  }

  Future<City> getCurrentCity() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationException('Location services are disabled');
      }

      // Check location permissions
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw LocationException('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw LocationException('Location permissions are permanently denied');
      }

      // Get the current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );

      // Get placemark from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
        localeIdentifier: 'en_US',
      );

      String? cityName =
          placemarks.isNotEmpty ? placemarks.first.locality : null;
      String? countryName =
          placemarks.isNotEmpty ? placemarks.first.country : null;

      if (cityName == null || cityName.isEmpty) {
        throw LocationException('Unable to determine the city name');
      }

      return City(
        name: cityName,
        country: countryName,
        lat: position.latitude,
        lon: position.longitude,
      );
    } catch (e) {
      debugPrint('Error getting current city: $e');
      throw LocationException('Failed to get current city: $e');
    }
  }

  Future<List<City>> searchCities(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse('$GEO_BASE_URL?q=$query&limit=5&appid=$apiKey'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((city) => City(
                  name: city['name'],
                  country: city['country'],
                  lat: city['lat']?.toDouble(),
                  lon: city['lon']?.toDouble(),
                ))
            .toList();
      } else {
        throw WeatherApiException(
            'Failed to search cities. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error searching cities: $e');
      throw WeatherApiException('Failed to search cities: $e');
    }
  }
}

class WeatherApiException implements Exception {
  final String message;

  WeatherApiException(this.message);

  @override
  String toString() => 'WeatherApiException: $message';
}

class LocationException implements Exception {
  final String message;

  LocationException(this.message);

  @override
  String toString() => 'LocationException: $message';
}
