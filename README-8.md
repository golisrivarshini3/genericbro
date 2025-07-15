<!-- Project Logo -->
<p align="center">
  <img src="logo.png" width="180" alt="GenericBuddy Logo"/>
</p>

<h1 align="center">💊 GenericBuddy – Generic Medicine Finder & Pharmacy Locator</h1>

<p align="center"><b>A Flutter-powered app to find affordable generic alternatives to branded medicines and locate nearby pharmacies.</b></p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Flutter-02569B?style=for-the-badge&logo=flutter" />
  <img src="https://img.shields.io/badge/Language-Dart-0175C2?style=for-the-badge&logo=dart" />
  <img src="https://img.shields.io/badge/Backend-Render-46E3B7?style=for-the-badge" />
  <img src="https://img.shields.io/badge/UI-Mobile%20Friendly-green?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Status-Active-brightgreen?style=for-the-badge" />
</p>

---

## 📦 Setup & Installation

### ✅ **1. Prerequisites**
Make sure you have the following installed:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.16.0 or newer recommended)
- Dart (comes with Flutter)
- Android Studio or VS Code (for running the emulator)
- A connected physical device or emulator
- Render account (for backend deployment)

---

### ✅ **2. Create the Flutter App**

```bash
# Create a new Flutter project
flutter create genericbuddy

# Move into the project directory
cd genericbuddy

# Add required dependencies (update pubspec.yaml as needed)
flutter pub add http
flutter pub add provider
flutter pub add intl
flutter pub add shared_preferences
```

---

### ✅ **3. Run the App Locally**

```bash
# Run on connected device or emulator
flutter run
```

For a specific device:

```bash
flutter devices      # Lists all devices
flutter run -d <device_id>
```

---

### ✅ **4. Build APK (Optional)**

```bash
# Release build for Android
flutter build apk --release

# Output will be in build/app/outputs/flutter-apk/app-release.apk
```

---

### ✅ **5. Backend Deployment (Render)**

1. Create a new **Web Service** in [Render](https://render.com/).  
2. Push your **backend Dart/Node/Python service** to GitHub.  
3. Link the repository in Render and deploy.  
4. Update your API endpoints in the Flutter app (`api_service.dart`).

---

## 💡 Overview

GenericBuddy helps users:  
- 🔍 Search branded medicines and discover *generic substitutes*  
- 📊 Compare formulation, cost, dosage, and savings  
- 📍 Locate pharmacies via *PIN, city, or area* (No GPS tracking)  
- 📈 View *price comparisons as bar graphs* and *savings shares as pie charts*  
- 🎚 Toggle between *Dark Mode* and *Light Mode*  
- 🧪 Filter medicines by *formulation type*: Pure, Mixed, or All  
- 🩺 Search by *ailment name* (e.g., "fever", "diabetes")  

---

## 🎯 Who’s It For?

| Target            | Benefit                                   |
|-------------------|-------------------------------------------|
| 🧑‍⚕ Patients     | Lower medication costs & better access    |
| 💊 Pharmacists    | Recommend effective generic substitutions |
| 🏥 NGOs           | Budget-friendly public-health outreach    |
| 📚 Students       | Study drug equivalence & pharmacology     |

---

## ✨ Feature Highlights

### 💊 Generic Medicine Finder

| Feature                                  | Description                                                                 |
|------------------------------------------|-----------------------------------------------------------------------------|
| 🔍 Smart Search                          | Search by *brand name* or *formulation name*                           |
| 🧬 Exact + Formulation Matches           | Lists both *exact brand matches* and *same formulation* alternatives   |
| 💸 Price-Based Filtering                 | Filter by *branded price, generic price, or % savings*                  |
| 🧪 Therapeutic & Dosage Filters          | Narrow results by *therapeutic type* or *dosage strength*              |
| 📊 Rich Comparison Data                  | View *brand price, generic price, and savings %* for each entry        |
| 📉 Bar Graph Price Comparison            | Compare selected medicines in a *bar graph*                            |
| 🥧 Savings Pie Chart                     | Visualize savings share in a *pie chart*                               |
| 🎚 Theme Toggle                         | Switch between *light* and *dark* modes                                 |
| 🧪 Formulation Filter                    | Filter by *Pure, Mixed, or All* formulations                            |
| 🩺 Ailment-Based Search                  | Find medicines by entering a *condition or disease name*               |

---

### 🗺 Pharmacy Locator

| Feature                                  | Description                                                                 |
|------------------------------------------|-----------------------------------------------------------------------------|
| 📍 Multi-mode Search                     | Search by *pincode, area, or city* (No GPS tracking)                       |
| 📤 Export Results                        | Download list of results as *CSV* or *PDF*                                |

---

## 🧪 Tech Stack

| Technology     | Purpose                          |
|----------------|----------------------------------|
| *Flutter*      | Cross-platform mobile frontend   |
| *Dart*         | Application logic & state mgmt   |
| *Render*       | Backend deployment               |

---

📚 *For detailed setup and contribution guidelines, please refer to the Documentation.*
