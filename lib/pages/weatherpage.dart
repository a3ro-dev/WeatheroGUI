import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weatherapp/models/weathermodel.dart';
import 'package:weatherapp/services/weatherservices.dart';
import 'package:weatherapp/services/city_service.dart';
import 'package:weatherapp/services/theme_service.dart';
import 'package:weatherapp/models/city_model.dart';
import 'package:lottie/lottie.dart';
import 'package:weatherapp/pages/city_search_page.dart';
import 'package:intl/intl.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({Key? key}) : super(key: key);

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage>
    with SingleTickerProviderStateMixin {
  final WeatherService _weatherService =
      WeatherService('054b217266c57c45c2c6dca381babd9f');
  Weather? _weather;
  bool _loading = true;
  String? _errorMessage;
  bool _isNight = false;
  late AnimationController _animationController;

  static const int duskHour = 18;
  static const int dawnHour = 6;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _initializeWeather();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeWeather() async {
    final cityService = Provider.of<CityService>(context, listen: false);

    try {
      // Try to get weather for current city if one exists
      if (cityService.currentCity != null) {
        await _fetchWeather(cityService.currentCity!);
        return;
      }

      // No saved cities, try to get the current location
      await _fetchCurrentLocationWeather();
    } catch (e) {
      _setError("Could not determine your location or load weather data");
    }
  }

  Future<void> _fetchCurrentLocationWeather() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // Get current city
      City currentCity = await _weatherService.getCurrentCity();

      // Get weather for that city
      await _fetchWeatherForCity(currentCity);

      // Save this city
      Provider.of<CityService>(context, listen: false).saveCity(currentCity);
    } catch (e) {
      _setError("Error detecting your location: ${e.toString()}");
    }
  }

  Future<void> _fetchWeather(City city) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      if (city.lat != null && city.lon != null) {
        final weather = await _weatherService.getWeatherByCoordinates(
          city.lat!,
          city.lon!,
        );
        _updateWeather(weather);
      } else {
        await _fetchWeatherForCity(city);
      }
    } catch (e) {
      _setError("Could not load weather for ${city.name}");
    }
  }

  Future<void> _fetchWeatherForCity(City city) async {
    try {
      // For cities without coordinates (or as fallback)
      final weather = await _weatherService.getWeather(city.name);
      _updateWeather(weather);
    } catch (e) {
      _setError("Error fetching weather for ${city.name}");
    }
  }

  void _updateWeather(Weather weather) {
    setState(() {
      _weather = weather;
      _loading = false;
      _errorMessage = null;
      _isNight = _isNightTime();
      _animationController.forward(from: 0.0);
    });
  }

  void _setError(String message) {
    setState(() {
      _errorMessage = message;
      _loading = false;
    });
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

  @override
  Widget build(BuildContext context) {
    return Consumer2<CityService, ThemeService>(
      builder: (context, cityService, themeService, child) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Weather App',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CitySearchPage(
                        weatherService: _weatherService,
                      ),
                    ),
                  );

                  // Refresh weather for current city when returning
                  if (cityService.currentCity != null) {
                    _fetchWeather(cityService.currentCity!);
                  }
                },
              ),
              IconButton(
                icon: Icon(themeService.themeMode == ThemeMode.dark
                    ? Icons.light_mode
                    : Icons.dark_mode),
                onPressed: () {
                  themeService.setThemeMode(
                      themeService.themeMode == ThemeMode.dark
                          ? ThemeMode.light
                          : ThemeMode.dark);
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  if (cityService.currentCity != null) {
                    _fetchWeather(cityService.currentCity!);
                  } else {
                    _fetchCurrentLocationWeather();
                  }
                },
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _getBackgroundGradient(context),
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 56),
                if (cityService.savedCities.isNotEmpty)
                  Container(
                    height: 60,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: cityService.savedCities.length,
                      itemBuilder: (context, index) {
                        final city = cityService.savedCities[index];
                        final isSelected =
                            city.name == cityService.currentCity?.name;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(city.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                cityService.setCurrentCity(city);
                                _fetchWeather(city);
                              }
                            },
                            backgroundColor: Theme.of(context).cardColor,
                            selectedColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        );
                      },
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      if (cityService.currentCity != null) {
                        await _fetchWeather(cityService.currentCity!);
                      } else {
                        await _fetchCurrentLocationWeather();
                      }
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: _buildResponsiveWeatherContent(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: cityService.savedCities.length > 1
              ? FloatingActionButton(
                  onPressed: () {
                    _showCityManagementDialog(context, cityService);
                  },
                  child: const Icon(Icons.edit),
                )
              : null,
        );
      },
    );
  }

  List<Color> _getBackgroundGradient(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_weather == null) {
      return isDarkMode
          ? [Colors.blueGrey.shade900, Colors.blueGrey.shade800]
          : [Colors.blue.shade300, Colors.blue.shade100];
    }

    final condition = _weather!.mainCondition.toLowerCase();

    if (isDarkMode) {
      if (_isNight) {
        return [Colors.indigo.shade900, Colors.blueGrey.shade900];
      }

      if (condition.contains('rain') || condition.contains('thunderstorm')) {
        return [Colors.blueGrey.shade900, Colors.blueGrey.shade800];
      } else if (condition.contains('cloud')) {
        return [Colors.blueGrey.shade800, Colors.blueGrey.shade700];
      } else {
        return [Colors.indigo.shade800, Colors.blue.shade900];
      }
    } else {
      if (_isNight) {
        return [Colors.indigo.shade700, Colors.indigo.shade300];
      }

      if (condition.contains('rain') || condition.contains('thunderstorm')) {
        return [Colors.blueGrey.shade400, Colors.blueGrey.shade200];
      } else if (condition.contains('cloud')) {
        return [Colors.blue.shade300, Colors.lightBlue.shade100];
      } else {
        return [Colors.blue.shade400, Colors.lightBlue.shade100];
      }
    }
  }

  Widget _buildResponsiveWeatherContent(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;

    if (_loading) {
      return SizedBox(
        height: screenHeight - 150,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading weather data...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return SizedBox(
        height: screenHeight - 150,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    _fetchCurrentLocationWeather();
                  },
                  icon: const Icon(Icons.my_location),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_weather == null) {
      return SizedBox(
        height: screenHeight - 150,
        child: const Center(
          child: Text('No weather data available'),
        ),
      );
    }

    // Weather content with animation
    if (isLandscape && screenWidth > 600) {
      // Landscape layout for tablets and larger screens
      return FadeTransition(
        opacity: _animationController,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _weather!.cityName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Lottie.asset(
                      getWeatherAnimation(_weather?.mainCondition),
                      width: 180,
                      height: 180,
                    ),
                    Text(
                      '${_weather!.temperature.round()}°C',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _weather?.mainCondition ?? "",
                      style: const TextStyle(
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: _buildWeatherDetailsCard(context),
              ),
            ],
          ),
        ),
      );
    } else {
      // Portrait layout for phones
      return FadeTransition(
        opacity: _animationController,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _weather!.cityName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Lottie.asset(
                getWeatherAnimation(_weather?.mainCondition),
                width: 180,
                height: 180,
              ),
              Text(
                '${_weather!.temperature.round()}°C',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _weather?.mainCondition ?? "",
                style: const TextStyle(
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 24),
              _buildWeatherDetailsCard(context),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildWeatherDetailsCard(BuildContext context) {
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, MMMM d');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(now),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  timeFormat.format(now),
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildWeatherDetailRow(
              Icons.thermostat,
              'Feels Like',
              '${_weather!.temperature.round()}°C',
            ),
            _buildWeatherDetailRow(
              Icons.water_drop,
              'Humidity',
              '65%', // Would need actual API data
            ),
            _buildWeatherDetailRow(
              Icons.air,
              'Wind',
              '5 km/h', // Would need actual API data
            ),
            _buildWeatherDetailRow(
              Icons.compress,
              'Pressure',
              '1015 hPa', // Would need actual API data
            ),
            _buildWeatherDetailRow(
              Icons.visibility,
              'Visibility',
              '10 km', // Would need actual API data
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Last Updated: ${timeFormat.format(now)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showCityManagementDialog(
      BuildContext context, CityService cityService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Cities'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: cityService.savedCities.length,
            itemBuilder: (context, index) {
              final city = cityService.savedCities[index];
              return ListTile(
                title: Text(city.name),
                subtitle: Text(city.country ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    cityService.removeCity(city);
                    if (cityService.savedCities.isEmpty) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
                onTap: () {
                  cityService.setCurrentCity(city);
                  _fetchWeather(city);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
