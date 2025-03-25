package com.example.weatherapp

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.weatherapp/widget"
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidget" -> {
                    val weatherData = call.arguments as Map<*, *>
                    updateWidgets(weatherData)
                    result.success(true)
                }
                "hasActiveWidgets" -> {
                    val hasWidgets = hasActiveWidgets()
                    result.success(hasWidgets)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun updateWidgets(weatherData: Map<*, *>) {
        // Store weather data in shared preferences
        val prefs = applicationContext.getSharedPreferences("WeatherWidgetPrefs", Context.MODE_PRIVATE)
        val editor = prefs.edit()
        
        editor.putString("cityName", weatherData["cityName"] as String)
        editor.putFloat("temperature", (weatherData["temperature"] as Number).toFloat())
        editor.putString("mainCondition", weatherData["mainCondition"] as String)
        editor.putLong("lastUpdated", System.currentTimeMillis())
        editor.apply()
        
        // Update widgets
        val intent = Intent(applicationContext, WeatherWidgetProvider::class.java)
        intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        
        val widgetManager = AppWidgetManager.getInstance(applicationContext)
        val ids = widgetManager.getAppWidgetIds(ComponentName(applicationContext, WeatherWidgetProvider::class.java))
        
        intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        applicationContext.sendBroadcast(intent)
    }
    
    private fun hasActiveWidgets(): Boolean {
        val widgetManager = AppWidgetManager.getInstance(applicationContext)
        val ids = widgetManager.getAppWidgetIds(ComponentName(applicationContext, WeatherWidgetProvider::class.java))
        return ids.isNotEmpty()
    }
}
