#!/usr/bin/env bash
# Fix Flutter Web build issue by cleaning and rebuilding

# Clean all Flutter build artifacts
echo "Cleaning Flutter project..."
flutter clean

# Install dependencies
echo "Installing dependencies..."
flutter pub get

# Run the Flutter app on Chrome in profile mode
echo "Running Flutter app..."
flutter run -d chrome --profile
