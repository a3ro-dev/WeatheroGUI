import 'package:flutter/material.dart';
import 'package:weatherapp/models/weathermodel.dart';
import 'package:weatherapp/services/weatherservices.dart';
import 'package:lottie/lottie.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({Key? key}) : super(key: key);

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final WeatherService _weatherService =
      WeatherService('054b217266c57c45c2c6dca381babd9f');
  Weather? _weather;
  bool _loading = true;
  bool _weatherLoadSuccess = false;
  bool _isNight = false;

  // Function to fetch the weather data.
  _fetchWeather() async {
    // Get the current city name.
    String cityName = await _weatherService.getCurrentCity();

    // Check if the city is recognized as "Prayagraj" by the weather service.
    if (cityName.toLowerCase() == "prayagraj") {
      // If recognized as "Prayagraj," use the known alternative name "Allahabad."
      cityName = "Allahabad";
    }

    try {
      // Fetch the weather data for the current city.
      final weather = await _weatherService.getWeather(cityName);

      // Determine if it's night based on current time (assuming dusk and dawn times).
      DateTime now = DateTime.now();
      int hour = now.hour;

      setState(() {
        _weather = weather;
        _weatherLoadSuccess = true; // Weather data loaded successfully
        _isNight = (hour >= 18 || hour < 6); // Assuming dusk at 6 PM and dawn at 6 AM
      });
    } catch (e) {
      // Handle any exceptions that might occur during the fetching process.
      print('Error fetching weather data: $e');
      setState(() {
        _weatherLoadSuccess = false; // Loading failed
      });
    } finally {
      setState(() {
        _loading = false; // Loading is done
      });
    }
  }

  // Weather animations
  String getWeatherAnimation(String? mainCondition) {
    if (mainCondition == null) return 'animation-icons/sunny.json'; // Default to sunny

    String timeOfDay = _isNight ? 'night-' : ''; // Prefix for night animations

    switch (mainCondition.toLowerCase()) {
      case 'clouds':
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        return 'animation-icons/${timeOfDay}cloudy.json';
      case 'rain':
      case 'drizzle':
      case 'shower rain':
        return 'animation-icons/${timeOfDay}rain.json';
      case 'thunderstorm':
        return 'animation-icons/${timeOfDay}rainandthunder.json';
      case 'clear':
        return 'animation-icons/${timeOfDay}sunny.json';
      default:
        return 'animation-icons/${timeOfDay}sunny.json';
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              child: Center(
                child: _loading
                    ? const CircularProgressIndicator()
                    : _weather != null
                        ? _buildWeatherContent()
                        : _buildErrorIndicator(),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: _loading
                  ? Container()
                  : _weatherLoadSuccess
                      ? _buildStatusIndicator(Colors.green)
                      : _buildStatusIndicator(Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _weather!.cityName,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
          ),
        ),
        Lottie.asset(getWeatherAnimation(_weather?.mainCondition)),
        Text(
          '${_weather!.temperature.round()}°C',
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
          ),
        ),
        Text(
          _weather?.mainCondition ?? "",
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorIndicator() {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.red, // Use your desired color for the error indicator
      ),
    );
  }

  Widget _buildStatusIndicator(Color color) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
