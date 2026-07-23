# Youth Income Predictor — Flutter App

Single-page mobile app that calls the Task 2 FastAPI `/predict` endpoint and
shows the estimated hourly & monthly income for a Rwandan youth given their
education, location, sector, and hours worked.

## Before running

Open `lib/main.dart` and replace this line with your real deployed Render URL:

```dart
const String apiBaseUrl = "https://YOUR-RENDER-URL.onrender.com";
```

## Run locally

```bash
flutter pub get
flutter run
```

Pick a connected device or emulator when prompted. If running on an Android
emulator while testing against a *local* API (not Render), use
`http://10.0.2.2:8000` instead of `127.0.0.1` — the emulator maps that
special address back to your host machine.

## What's on the page

- Text fields: age, hours worked per week
- Dropdowns: education level, sex, urban/rural, province, sector
  (7 inputs total, matching the 7 features the model expects)
- **Predict** button
- A result card showing predicted hourly + monthly income (RWF), or an
  error banner if inputs are invalid/missing or the API call fails
