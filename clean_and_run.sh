@"#!/usr/bin/env bash
# Flutter web build fix

# Clean all Flutter build artifacts
echo "Cleaning Flutter build artifacts..."
if [ -d ".dart_tool/flutter_build" ]; then
    rm -rf ".dart_tool/flutter_build"
fi
if [ -d "build" ]; then
    rm -rf "build"
fi

# Run Flutter clean
echo "Running Flutter clean..."
flutter clean

# Get dependencies
echo "Installing dependencies..."
flutter pub get

# Run Flutter on Chrome in profile mode
echo "Running Flutter app on Chrome in profile mode..."
flutter run -d chrome --profile
"@ > clean_and_run.sh
chmod +x clean_and_run.sh