# 📱 Android App Setup Guide

## Current Status

✅ **Web app**: Working perfectly!  
⚠️ **Android app**: No Android devices/emulators detected

## Available Devices

You currently have:

- ✅ **macOS** (for running as desktop app)
- ✅ **Chrome** (for web testing)

## Options to Run Android App

### Option 1: Start Android Emulator (Recommended)

```bash
# List available Android emulators
emulator -list-avds

# Start an emulator (replace with your AVD name)
emulator -avd Pixel_8_API_35 &

# Or use Android Studio to start one:
# Android Studio → Tools → Device Manager → Play button
```

### Option 2: Connect Physical Android Device

1. **Enable Developer Options** on your Android phone:
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times

2. **Enable USB Debugging**:
   - Settings → Developer Options → USB Debugging

3. **Connect via USB** and authorize the computer

4. **Verify connection**:

```bash
adb devices
```

### Option 3: Build APK for Manual Installation

```bash
# Build release APK
cd recall_butler/recall_butler_flutter
flutter build apk --release

# APK will be at:
# build/app/outputs/flutter-apk/app-release.apk

# Install on connected device:
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Option 4: Run on macOS (Quick Test)

Since you have macOS available, you can run it as a desktop app:

```bash
cd recall_butler/recall_butler_flutter
flutter run -d macos
```

## Once You Have a Device Connected

Run the app with:

```bash
cd recall_butler/recall_butler_flutter

# For Android
flutter run -d <device-id>

# Or just:
flutter run
# (Flutter will prompt you to choose if multiple devices)
```

## Server Configuration for Mobile

The mobile app needs to connect to your local server. Make sure:

1. **Server is running** (already is! ✅)

   ```
   http://localhost:8182
   ```

2. **For Android emulator**, use:
   - `http://10.0.2.2:8182` (Android emulator special address)

3. **For physical device on same WiFi**, use:

   ```bash
   # Find your Mac's IP address
   ifconfig | grep "inet " | grep -v 127.0.0.1
   
   # Then use http://<YOUR_IP>:8182
   ```

## Quick Commands

```bash
# Check Flutter setup
flutter doctor

# List all devices
flutter devices

# Run on specific device
flutter run -d android

# Build APK
flutter build apk --release

# Install on device
adb install build/app/outputs/flutter-apk/app-release.apk
```

## App Features on Android

Your Android app has all these configured permissions:

- ✅ Camera (for document scanning)
- ✅ Microphone (for voice notes)
- ✅ Storage (for file uploads)
- ✅ Notifications (for reminders)
- ✅ Calendar integration
- ✅ Location (for smart reminders)

## What Would You Like To Do?

1. **Start Android emulator** - I can help you identify available ones
2. **Build APK for physical device** - Creates installable file
3. **Run on macOS** - Quick way to test the mobile UI
4. **Set up Android Studio** - If you need to create an emulator

Let me know which option you prefer!
