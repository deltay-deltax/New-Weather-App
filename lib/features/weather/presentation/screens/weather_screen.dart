import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/weather_provider.dart';
import '../widgets/weather_card.dart';
import '../widgets/forecast_list.dart';

class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentWeatherAsync = ref.watch(currentWeatherProvider);
    final forecastAsync = ref.watch(forecastProvider);
    final locationWeatherAsync = ref.watch(locationWeatherProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () => ref.refresh(locationWeatherProvider.future),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showCitySearch(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(currentWeatherProvider.future);
          ref.refresh(forecastProvider.future);
        },
        child: CustomScrollView(
          slivers: [
            // Current Location Weather
            SliverToBoxAdapter(
              child: locationWeatherAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Container(),
                data: (weather) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: WeatherCard(
                    weather: weather,
                    title: 'Current Location',
                    isCurrentLocation: true,
                  ),
                ),
              ),
            ),

            // Selected City Weather
            SliverToBoxAdapter(
              child: currentWeatherAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text('Error: $error'),
                          ElevatedButton(
                            onPressed: () =>
                                ref.refresh(currentWeatherProvider.future),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                data: (weather) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: WeatherCard(
                    weather: weather,
                    title: weather['name'],
                  ),
                ),
              ),
            ),

            // 5-Day Forecast
            SliverToBoxAdapter(
              child: forecastAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Forecast Error: $error'),
                ),
                data: (forecast) => ForecastList(forecast: forecast),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCitySearch(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search City'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter city name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (city) {
            if (city.isNotEmpty) {
              ref.read(selectedCityProvider.notifier).state = city;
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }
}
