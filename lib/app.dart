import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/weather/presentation/providers/weather_provider.dart';
import 'features/weather/presentation/screens/weather_screen.dart';
import 'features/news/presentation/screens/news_screen.dart';

class NewsWeatherApp extends ConsumerStatefulWidget {
  const NewsWeatherApp({super.key});

  @override
  ConsumerState<NewsWeatherApp> createState() => _NewsWeatherAppState();
}

class _NewsWeatherAppState extends ConsumerState<NewsWeatherApp> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const WeatherScreen(),
    const NewsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Weather & News Dashboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.wb_sunny),
              label: 'Weather',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article),
              label: 'News',
            ),
          ],
        ),
      ),
    );
  }
}
