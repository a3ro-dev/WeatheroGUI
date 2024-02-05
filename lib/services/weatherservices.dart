import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:weatherapp/models/weathermodel.dart';

class WeatherService {
  static const BASE_URL = 'http://api.openweathermap.org/data/2.5/weather';

  final String apiKey;

  WeatherService(this.apiKey);

  Future<Weather> getWeather(String cityName) async {
    try {
      final response = await http
          .get(Uri.parse('$BASE_URL?q=$cityName&appid=$apiKey&units=metric'));

      if (response.statusCode == 200) {
        return Weather.fromJson(jsonDecode(response.body));
      } else {
        print(
            'Failed to load weather. Status code: ${response.statusCode}, Body: ${response.body}');
        throw WeatherApiException(
            'Failed to load weather. HTTP Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching weather data: $e');
      throw WeatherApiException('Failed to load weather. $e');
    }
  }

  Future<String> getCurrentCity() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low);
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      String? city = placemarks.isNotEmpty ? placemarks.first.locality : null;
      if (city != null) {
        return city;
      } else {
        throw LocationException(
            'Unable to determine the city from the current location.');
      }
    } catch (e) {
      print('Error getting current city: $e');
      throw LocationException('Failed to get current city. $e');
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
