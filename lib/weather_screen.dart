import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:weather_app/secrets.dart';
import 'package:weather_app/additionl_info_item.dart';
import 'package:weather_app/hourly_forecast_item.dart';
import 'package:http/http.dart' as http;

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late Future<Map<String, dynamic>> weather;
  String cityName = ""; // default city
  final TextEditingController _searchController = TextEditingController();

  // Keep track of recent searched cities
  final List<String> recentCities = [];

  Future<Map<String, dynamic>> getCurrentWeather(String city) async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$openWeatherAPIKey',
        ),
      );

      final data = jsonDecode(res.body);

      if (data['cod'] != "200") {
        throw "City not found!";
      }

      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  @override
  void initState() {
    super.initState();
    weather = getCurrentWeather(cityName);
  }

  void _searchCity(String city) {
    setState(() {
      cityName = city;
      weather = getCurrentWeather(cityName);

      // Save to history (avoid duplicates)
      if (!recentCities.contains(cityName)) {
        recentCities.insert(0, cityName);
        if (recentCities.length > 5) {
          recentCities.removeLast(); // keep only last 5
        }
      }
    });

    Navigator.pop(context); // close dialog
    _searchController.clear();
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Search City"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(hintText: "Enter city name"),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _searchCity(value.trim());
                }
              },
            ),
            const SizedBox(height: 10),

            // Recent Cities List
            if (recentCities.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  "Recent Searches:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            if (recentCities.isNotEmpty)
              Wrap(
                spacing: 8,
                children: recentCities
                    .map(
                      (city) => ActionChip(
                        label: Text(city),
                        onPressed: () => _searchCity(city),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (_searchController.text.trim().isNotEmpty) {
                _searchCity(_searchController.text.trim());
              }
            },
            child: const Text("Search"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Weather App',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          // Search button
          IconButton(
            onPressed: _showSearchDialog,
            icon: const Icon(Icons.search),
          ),

          // Refresh button
          IconButton(
            onPressed: () {
              setState(() {
                weather = getCurrentWeather(cityName);
              });
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: FutureBuilder(
        future: weather,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final data = snapshot.data!;
          final currentWeatherdata = data['list'][0];

          final currentTemp = currentWeatherdata["main"]['temp'];
          final currentSky = currentWeatherdata['weather'][0]['main'];
          final currentPressure = currentWeatherdata['main']['pressure'];
          final currentWindSpeed = currentWeatherdata['wind']['speed'];
          final currentHumidity = currentWeatherdata['main']['humidity'];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // main card
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                ' $currentTemp K',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Icon(
                                currentSky == 'Clouds' || currentSky == 'Rain'
                                    ? Icons.cloud
                                    : Icons.sunny,
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                currentSky,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                const Text(
                  'Hourly Forecast',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    itemCount: 5,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final hourlyForecast = data['list'][index + 1];
                      final hourlySky =
                          data['list'][index + 1]['weather'][0]['main'];
                      final hourlyTemp = hourlyForecast['main']['temp']
                          .toString();
                      final time = DateTime.parse(hourlyForecast['dt_txt']);
                      return HourlyForecastItem(
                        time: DateFormat('EEE h a').format(time),
                        tempture: hourlyTemp,
                        icon: hourlySky == 'Clouds' || hourlySky == 'Rain'
                            ? Icons.cloud
                            : Icons.sunny,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),
                const Text(
                  'Additional information',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AdditionalInfoItem(
                      icon: Icons.water_drop,
                      label: 'Humidity',
                      value: currentHumidity.toString(),
                    ),
                    AdditionalInfoItem(
                      icon: Icons.wind_power,
                      label: 'Wind',
                      value: currentWindSpeed.toString(),
                    ),
                    AdditionalInfoItem(
                      icon: Icons.beach_access,
                      label: 'Pressure',
                      value: currentPressure.toString(),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
