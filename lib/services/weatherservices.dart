import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:weatherapp/models/weathermodel.dart';

class WeatherService {
 // Constant for the base URL of the weather API.
 static const BASE_URL = 'http://api.openweathermap.org/data/2.5/weather';

 // API key for accessing the weather API.
 final String apikey;

 // Constructor to initialize the API key.
 WeatherService(this.apikey);

 // Method to fetch the weather data for a given city.
 Future<Weather> getWeather(String cityName) async {
  try {
    final response = await http
        .get(Uri.parse('$BASE_URL?q=$cityName&appid=$apikey&units=metric'));

    if (response.statusCode == 200) {
      return Weather.fromJson(jsonDecode(response.body));
    } else {
      print('Failed to load weather. Status code: ${response.statusCode}, Body: ${response.body}');
      throw Exception('Failed to load weather');
    }
  } catch (e) {
    print('Error fetching weather data: $e');
    throw Exception('Failed to load weather');
  }
}


 // Method to fetch the current city using the device's location.
 Future<String> getCurrentCity() async {
    // Check and request location permissions if necessary.
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // Get the current device location.
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // Get the details of the current location, such as the city name.
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

    // Extract the city name from the location details.
    String? city = placemarks[0].locality;

    // Return the city name.
    return city!;
 }
}