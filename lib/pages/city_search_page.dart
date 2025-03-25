import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/city_model.dart';
import '../services/city_service.dart';
import '../services/weatherservices.dart';

class CitySearchPage extends StatefulWidget {
  final WeatherService weatherService;

  const CitySearchPage({
    super.key,
    required this.weatherService,
  });

  @override
  State<CitySearchPage> createState() => _CitySearchPageState();
}

class _CitySearchPageState extends State<CitySearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<City> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchCities(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await widget.weatherService.searchCities(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error searching for cities: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cityService = Provider.of<CityService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Cities'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for a city...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                _searchCities(value);
              },
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            )
          else
            Expanded(
              child: _searchResults.isEmpty && _searchController.text.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search,
                            size: 80,
                            color: Colors.grey.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Search for a city to add',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _searchResults.isEmpty
                      ? const Center(child: Text('No cities found'))
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final city = _searchResults[index];
                            final bool isSaved = cityService.savedCities
                                .any((c) => c.name == city.name);

                            return ListTile(
                              title: Text(city.name),
                              subtitle: Text(city.country ?? ''),
                              trailing: IconButton(
                                icon: Icon(
                                  isSaved
                                      ? Icons.check_circle
                                      : Icons.add_circle_outline,
                                  color: isSaved ? Colors.green : null,
                                ),
                                onPressed: () {
                                  if (isSaved) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('City already saved'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  } else {
                                    cityService.saveCity(city);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '${city.name} added to saved cities'),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                },
                              ),
                              onTap: () {
                                // Set as current and navigate back
                                if (!isSaved) {
                                  cityService.saveCity(city);
                                }
                                cityService.setCurrentCity(city);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
            ),
        ],
      ),
    );
  }
}
