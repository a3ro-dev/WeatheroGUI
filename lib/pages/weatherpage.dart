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

  static const int duskHour = 18;
  static const int dawnHour = 6;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  _fetchWeather() async {
    try {
      String cityName = await _weatherService.getCurrentCity();

      if (cityName.toLowerCase() == "prayagraj") {
        cityName = "Allahabad";
      }

      final weather = await _weatherService.getWeather(cityName);

      setState(() {
        _weather = weather;
        _weatherLoadSuccess = true;
        _isNight = _isNightTime();
      });
    } catch (e) {
      showErrorSnackBar("Error fetching weather data");
      setState(() {
        _weatherLoadSuccess = false;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  bool _isNightTime() {
    int hour = DateTime.now().hour;
    return hour >= duskHour || hour < dawnHour;
  }

  String getWeatherAnimation(String? mainCondition) {
    if (mainCondition == null) return 'animation-icons/sunny.json';

    String timeOfDay = _isNight ? 'night-' : '';

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

  void showErrorSnackBar(String message) {
    // Show a snackbar with the error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
        color: Colors.red,
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
