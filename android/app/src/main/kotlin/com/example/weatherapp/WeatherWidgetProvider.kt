package com.example.weatherapp

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import io.flutter.plugin.common.MethodChannel
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.view.FlutterMain

class WeatherWidgetProvider : AppWidgetProvider() {
    
    companion object {
        const val ACTION_UPDATE_WIDGET = "com.example.weatherapp.ACTION_UPDATE_WIDGET"
        const val EXTRA_CITY_NAME = "city_name"
        const val EXTRA_TEMPERATURE = "temperature"
        const val EXTRA_CONDITION = "condition"
        
        // Update all active widgets
        fun updateWidgets(context: Context, cityName: String, temperature: Double, condition: String) {
            val intent = Intent(context, WeatherWidgetProvider::class.java).apply {
                action = ACTION_UPDATE_WIDGET
                putExtra(EXTRA_CITY_NAME, cityName)
                putExtra(EXTRA_TEMPERATURE, temperature)
                putExtra(EXTRA_CONDITION, condition)
            }
            context.sendBroadcast(intent)
        }
        
        // Check if any widgets are active
        fun hasActiveWidgets(context: Context): Boolean {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(ComponentName(context, WeatherWidgetProvider::class.java))
            return appWidgetIds.isNotEmpty()
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        if (intent.action == ACTION_UPDATE_WIDGET) {
            val cityName = intent.getStringExtra(EXTRA_CITY_NAME) ?: "Unknown"
            val temperature = intent.getDoubleExtra(EXTRA_TEMPERATURE, 0.0)
            val condition = intent.getStringExtra(EXTRA_CONDITION) ?: "Clear"
            
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(ComponentName(context, WeatherWidgetProvider::class.java))
            
            updateWidgetContent(context, appWidgetManager, appWidgetIds, cityName, temperature, condition)
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val prefs = context.getSharedPreferences("WeatherWidgetPrefs", Context.MODE_PRIVATE)
        
        // Get stored weather data
        val cityName = prefs.getString("cityName", "Unknown Location") ?: "Unknown Location"
        val temperature = prefs.getFloat("temperature", 0f)
        val condition = prefs.getString("mainCondition", "Clear") ?: "Clear"
        
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId, cityName, temperature, condition)
        }
        
        // Request fresh data from Flutter
        requestWeatherUpdate(context)
    }
    
    private fun updateWidgetContent(context: Context, appWidgetManager: AppWidgetManager, 
                                   appWidgetIds: IntArray, cityName: String, 
                                   temperature: Double, condition: String) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId, cityName, temperature.toFloat(), condition)
        }
    }
    
    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        cityName: String,
        temperature: Float,
        condition: String
    ) {
        // Create widget layout
        val views = RemoteViews(context.packageName, R.layout.weather_widget)
        
        // Update text views with weather data
        views.setTextViewText(R.id.widget_city, cityName)
        views.setTextViewText(R.id.widget_temperature, "${temperature.toInt()}°C")
        views.setTextViewText(R.id.widget_condition, condition)
        
        // Set appropriate weather icon based on condition
        val iconResId = getWeatherIcon(condition)
        views.setImageViewResource(R.id.widget_icon, iconResId)
        
        // Create pending intent to open app when widget is tapped
        val pendingIntent = android.app.PendingIntent.getActivity(
            context,
            0,
            context.packageManager.getLaunchIntentForPackage(context.packageName),
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_layout, pendingIntent)
        
        // Update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
    
    private fun getWeatherIcon(condition: String): Int {
        return when (condition.toLowerCase()) {
            "clouds", "mist", "fog", "haze", "dust", "smoke" -> R.drawable.ic_cloudy
            "rain", "drizzle", "shower rain" -> R.drawable.ic_rainy
            "thunderstorm" -> R.drawable.ic_thunder
            "snow" -> R.drawable.ic_snowy
            else -> R.drawable.ic_sunny
        }
    }
    
    private fun requestWeatherUpdate(context: Context) {
        // This function requests fresh data from Flutter
        // Implementation requires starting Flutter engine headlessly
        // For simplicity, you can omit this in initial implementation
    }
}
