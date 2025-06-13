
# News & Weather App

A clean, professional Flutter app that integrates real-time weather forecasts and up-to-date news articles, with robust error handling, caching, and user experience.

## 📱 Features

- **Weather Forecast**
  - Current weather display for multiple locations
  - 5-day weather forecast
  - Weather alerts and notifications
  - Location-based weather detection
  - Multi-city weather comparison

- **News Integration**
  - Top headlines from major sources
  - Category-based news filtering (business, technology, sports)
  - News article search with debouncing
  - Bookmarking and saving news articles for offline reading
  - Sharing articles via social media or messaging

- **User Experience**
  - Clean, intuitive UI with professional presentation
  - Responsive design for all device sizes
  - Offline caching for news and weather data
  - Pull-to-refresh for latest updates
  - Error handling and user-friendly feedback

---

## 🛠️ Technical Stack

- **Frontend:** Flutter (Dart)
- **State Management:** Riverpod
- **Local Storage:** Hive
- **Networking:** Dio
- **News API:** NewsAPI
- **Weather API:** OpenWeatherMap (or similar)

---

## 🏗️ Project Structure

```
lib/
├── core/
│   ├── constants/                  # API keys and app constants
│   ├── models/                     # Data models (NewsModel, WeatherModel)
│   ├── services/                   # Network and storage services
│   └── utils/                      # Utility functions
├── features/
│   ├── weather/                    # Weather feature modules
│   │   ├── data/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── presentation/
│   │   │   ├── providers/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   └── news/                       # News feature modules
│       ├── data/
│       │   ├── models/
│       │   └── repositories/
│       ├── presentation/
│       │   ├── providers/
│       │   ├── screens/
│       │   └── widgets/
├── main.dart                       # App entry point
```

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** (latest stable version)
- **Hive** (for local storage)
- **Riverpod** (for state management)
- **Dio** (for HTTP requests)
- **API Keys** for NewsAPI and OpenWeatherMap

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/news_weather_app.git
   cd news_weather_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API keys**
   - Add your NewsAPI and OpenWeatherMap API keys to `lib/core/constants/api_keys.dart`

4. **Run the app**
   ```bash
   flutter run
   ```

---

## 📂 Data Storage

- **Weather Data:** Cached locally using Hive for offline access
- **News Data:** Cached locally with Hive, refreshed every 5 minutes
- **Bookmarks:** Stored in Hive for persistent access

**Location:**  
App data is stored in platform-specific directories (e.g., `app_flutter/` on Android, `Application Support/` on macOS).

---

## 📚 How to Use

1. **Weather Section**
   - View current weather for your location
   - Add and compare weather for multiple cities
   - See detailed 5-day forecasts

2. **News Section**
   - Browse top headlines in various categories
   - Search for news articles
   - Bookmark your favorite articles
   - Share articles with friends

3. **General**
   - Pull-to-refresh to update weather and news
   - Offline mode: view cached weather and news when not connected

---

## 🧩 Key Components

- **Riverpod Providers:** For state management and dependency injection
- **Hive Boxes:** For fast, type-safe local storage
- **Dio:** For robust HTTP requests and error handling
- **Clean Architecture:** Separation of data, domain, and presentation layers

---

## 🛡️ Error Handling

- **Network Errors:** Graceful fallback to cached data
- **API Errors:** User-friendly error messages and retry options
- **Cache Errors:** Automatic refresh and data integrity checks

---

## 🎨 UI/UX Highlights

- **Material Design:** Consistent and professional look
- **Responsive Layouts:** Works on phones and tablets
- **Loading Indicators:** Smooth transitions and feedback
- **Empty States:** Helpful messages when no data is available

---

## 📈 Future Enhancements

- **Dark/Light Theme:** User-selectable themes
- **More Weather Data:** UV index, humidity, wind speed
- **News Categories:** Expand supported categories

## Output Screen
![WhatsApp Image 2025-06-13 at 11 54 30_154a564e](https://github.com/user-attachments/assets/381e5e2f-d238-497f-ae55-36f184f7de76)
![WhatsApp Image 2025-06-13 at 11 54 30_fc6f2da4](https://github.com/user-attachments/assets/b62ab6ab-6998-47df-980d-64bc0bbfd29d)


## 🤝 Contributing

Contributions are welcome! Please fork the repository and submit pull requests.

---
