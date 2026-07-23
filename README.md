# Youth Earning Potential — Rwanda

Rwanda's youth face high unemployment and underemployment, often due to skills and
location mismatches with the labour market. This project predicts hourly cash income
for employed Rwandan youth (16–30) from education, sector, and location, using the
**NISR Rwanda Labour Force Survey 2021** — to help target skills and opportunity-access
interventions where they matter most.

## API Endpoint

**https://linear-regression-model-kkrq.onrender.com/docs**

Public Swagger UI — test `POST /predict` directly from that page (no localhost required).

> Hosted on Render's free tier: it spins down after ~15 minutes idle, so the first
> request after a pause can take 30–60 seconds to wake up. This is expected.

## Video Demo

**[Youtube link](https://youtu.be/AO0QTkf6FgM)**

## Running the Mobile App

```bash
cd summative/FlutterApp
flutter pub get
flutter run
```

Select a connected device or emulator when prompted. The app already points at the
live API above (`lib/main.dart` → `apiBaseUrl`), so no configuration is needed —
just run it and predict.

> **If running as a web build** (`flutter run -d chrome`), you must serve it on
> **port 8080**, since that's the origin explicitly allowed by the API's CORS
> config (`http://localhost:8080` in `ALLOWED_ORIGINS`). Run it with:
> ```bash
> flutter run -d chrome --web-port 8080
> ```
> Any other port will be blocked by the browser with a CORS error. This restriction
> does not apply to native Android/iOS builds — only to running Flutter in a browser.

---

## Endpoints
- `GET /` — health check
- `POST /predict` — predict hourly & monthly income given a youth's profile
- `POST /retrain` — upload a CSV of new labour-force-style rows to retrain the model on combined data

## Running the API locally

```bash
# from the repo root (where this README and pyproject.toml live)
uv sync
cd summative/API
uv run --project ../.. uvicorn prediction:app --reload
```

Then open http://127.0.0.1:8000/docs in your browser.

## Project structure

```
linear_regression_model/
├── summative/
│   ├── linear_regression/
│   │   └── multivariate.ipynb      # Task 1: EDA, feature engineering, model comparison
│   ├── API/
│   │   ├── prediction.py           # Task 2: FastAPI service
│   │   ├── requirements.txt
│   │   └── model/
│   │       ├── train.py            # shared preprocessing + training, used by notebook & /retrain
│   │       ├── best_model.pkl
│   │       ├── scaler.pkl
│   │       ├── feature_columns.pkl
│   │       └── training_data.csv
│   └── FlutterApp/                 # Task 3: Flutter mobile app
├── pyproject.toml
└── uv.lock
```

## Dataset

National Institute of Statistics of Rwanda (NISR), Rwanda Labour Force Survey 2021 — annual
estimates from four quarterly CAPI rounds (Feb/May/Aug/Nov 2021), covering employment status,
income, education, and location for individuals aged 16+.
https://data.gov.rw/datasets/0f776f1e-9458-403e-983f-0b50ce741d8e
