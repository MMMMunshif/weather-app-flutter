# Weather Travel App

A Flutter weather travel application developed by Mohammed Munshif.

## Description

Weather Travel App helps users check live weather, save favourite locations, manage app settings, and plan trips based on weather information.

The app includes Firebase Authentication and Firestore Database integration to store user details, saved locations, trips, and settings.

## Features

* User signup and login using Firebase Authentication
* Firestore Database integration
* Live current location weather
* Search and add worldwide locations
* Save and remove favourite locations
* View weather details for selected locations
* 5-day forecast display
* Trip planner with saved trip locations
* Dark mode and light mode
* Color theme selection
* Temperature unit settings: Celsius and Fahrenheit
* Wind speed unit settings: km/h and mph
* User settings saved in Firebase

## Technologies Used

* Flutter
* Dart
* Firebase Authentication
* Cloud Firestore
* Open-Meteo Weather API
* BLoC / Cubit state management

## Project Structure

```text
lib/
├── features/
│   ├── auth/
│   ├── settings/
│   └── weather/
├── placeholder_pages/
├── firebase_options.dart
└── main.dart
```

## How to Run

1. Install Flutter SDK.
2. Clone the project.
3. Run the following commands:

```bash
flutter pub get
flutter run -d edge
```

## Firebase Setup

The app uses Firebase for authentication and database storage.

Required Firebase services:

* Authentication

  * Email/Password sign-in method enabled
* Firestore Database

  * Users collection
  * Saved locations subcollection
  * Trips subcollection

## Current Progress

The following parts have been completed:

* Firebase Authentication setup
* Firestore user settings integration
* Saved locations feature
* Remove saved locations feature
* Trip planner save/load feature
* Dark mode and color theme support
* Temperature and wind speed unit settings
* Weather UI updates

## Author

Mohammed Munshif
