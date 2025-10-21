import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:atma_farm_app/models/weather_model.dart';

class WeatherService {
  // =======================================================================
  // ==  PASTE YOUR API KEY HERE                                          ==
  // =======================================================================
  // V V V V V V V V V V V V V V V V V V V V V V V V V V V V V V V V V V V V V V
  
  final String _apiKey = '6c4c32b0782e64cf3449c3419d883ce0';

  // ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^
  // =======================================================================

  final String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<Weather> getWeather(double latitude, double longitude) async {
    if (_apiKey == 'YOUR_OPENWEATHERMAP_API_KEY_GOES_HERE' || _apiKey.isEmpty) {
      // This is the error you are seeing.
      throw Exception('Please add your OpenWeatherMap API key to weather_service.dart');
    }

    final response = await http.get(Uri.parse('$_baseUrl?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric'));

    if (response.statusCode == 200) {
      return Weather.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load weather data. Status code: ${response.statusCode}');
    }
  }
}

