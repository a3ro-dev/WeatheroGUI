import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:weatherapp/models/weathermodel.dart';

class WeatherWidgetService {
  static const platform = MethodChannel('com.example.weatherapp/widget');

  // Update the Android widget with current weather data
  Future<void> updateWidget(Weather weather) async {
    try {
      await platform.invokeMethod('updateWidget', weather.toJsonMap());
      debugPrint('Android widget updated successfully');
    } on PlatformException catch (e) {
      debugPrint('Failed to update Android widget: ${e.message}');
    }
  }

  // Check if widget exists on the homescreen
  Future<bool> hasActiveWidgets() async {
    try {
      final bool result = await platform.invokeMethod('hasActiveWidgets');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Failed to check widget status: ${e.message}');
      return false;
    }
  }
}
