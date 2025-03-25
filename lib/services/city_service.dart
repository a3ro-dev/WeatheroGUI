import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/city_model.dart';

class CityService extends ChangeNotifier {
  static const String _savedCitiesKey = 'saved_cities';
  List<City> _savedCities = [];
  City? _currentCity;

  List<City> get savedCities => _savedCities;
  City? get currentCity => _currentCity;

  Future<void> initialize() async {
    await _loadSavedCities();
  }

  Future<void> _loadSavedCities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final citiesJson = prefs.getStringList(_savedCitiesKey) ?? [];

      _savedCities = citiesJson
          .map((cityJson) => City.fromJson(jsonDecode(cityJson)))
          .toList();

      if (_savedCities.isNotEmpty && _currentCity == null) {
        _currentCity = _savedCities.first;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading saved cities: $e');
      _savedCities = [];
    }
  }

  Future<void> saveCity(City city) async {
    try {
      if (!_savedCities.contains(city)) {
        _savedCities.add(city);

        if (_currentCity == null) {
          _currentCity = city;
        }

        await _persistCities();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error saving city: $e');
    }
  }

  Future<void> removeCity(City city) async {
    try {
      _savedCities.removeWhere((c) => c.name == city.name);

      if (_currentCity?.name == city.name) {
        _currentCity = _savedCities.isNotEmpty ? _savedCities.first : null;
      }

      await _persistCities();
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing city: $e');
    }
  }

  void setCurrentCity(City city) {
    _currentCity = city;
    notifyListeners();
  }

  Future<void> _persistCities() async {
    final prefs = await SharedPreferences.getInstance();
    final citiesJson =
        _savedCities.map((city) => jsonEncode(city.toJson())).toList();

    await prefs.setStringList(_savedCitiesKey, citiesJson);
  }
}
